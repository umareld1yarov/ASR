import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/purchases_service.dart';
import '../../backup/application/sync_controller.dart';
import '../../premium/application/premium_controller.dart';
import '../data/auth_repository.dart';

const String _kCloudBackupEnabledKey = 'cloud_backup_enabled';

enum AuthLoadingAction { email, google, apple, account }

/// Провайдер репозитория авторизации.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Состояние подключения облачного бэкапа и авторизации.
class AuthStateModel {
  final User? user;
  final bool isCloudBackupEnabled;
  final AuthLoadingAction? loadingAction;
  final String? errorMessage;

  const AuthStateModel({
    this.user,
    this.isCloudBackupEnabled = false,
    this.loadingAction,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;
  bool get isLoading => loadingAction != null;

  AuthStateModel copyWith({
    User? user,
    bool? isCloudBackupEnabled,
    AuthLoadingAction? loadingAction,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
    bool clearLoading = false,
  }) {
    return AuthStateModel(
      user: clearUser ? null : (user ?? this.user),
      isCloudBackupEnabled: isCloudBackupEnabled ?? this.isCloudBackupEnabled,
      loadingAction: clearLoading
          ? null
          : (loadingAction ?? this.loadingAction),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Контроллер управления состоянием авторизации и включения бэкапа.
class AuthController extends StateNotifier<AuthStateModel> {
  AuthController(this._repository, this._ref) : super(const AuthStateModel()) {
    _init();
  }

  final AuthRepository _repository;
  final Ref _ref;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kCloudBackupEnabledKey) ?? false;
    final currentUser = _repository.currentUser;

    state = state.copyWith(isCloudBackupEnabled: isEnabled, user: currentUser);

    if (currentUser != null) {
      PurchasesService.logIn(currentUser.id);
      _triggerAutoSync();
    }

    // Подписка на изменения состояния Supabase Auth
    _repository.authStateChanges?.listen((data) {
      final user = data.session?.user;
      state = state.copyWith(user: user, clearUser: user == null);
      if (user != null) {
        PurchasesService.logIn(user.id);
        _triggerAutoSync();
      } else {
        PurchasesService.logOut();
      }
    });
  }

  void _triggerAutoSync() {
    Future.microtask(() {
      try {
        final isPro = _ref.read(isProProvider);
        if (isPro) {
          _ref.read(syncControllerProvider.notifier).triggerSync(silent: true);
        }
      } catch (_) {}
    });
  }

  /// Переключение тумблера Облачного бэкапа.
  Future<void> toggleCloudBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCloudBackupEnabledKey, value);
    state = state.copyWith(isCloudBackupEnabled: value);
    if (value) {
      _triggerAutoSync();
    }
  }

  /// Вход через Email/Пароль.
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(
      loadingAction: AuthLoadingAction.email,
      clearError: true,
    );
    try {
      final response = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWith(
        clearLoading: true,
        user: response.user,
        isCloudBackupEnabled: true, // Включаем бэкап при входе
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCloudBackupEnabledKey, true);
      _triggerAutoSync();
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(clearLoading: true, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        clearLoading: true,
        errorMessage: 'auth.login_error'.tr(args: ['$e']),
      );
      return false;
    }
  }

  /// Регистрация нового аккаунта.
  Future<bool> signUp(String email, String password, {String? name}) async {
    state = state.copyWith(
      loadingAction: AuthLoadingAction.email,
      clearError: true,
    );
    try {
      final response = await _repository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );

      final sessionUser = response.user ?? response.session?.user;

      if (sessionUser == null && response.user != null) {
        // Требуется подтверждение email от Supabase
        state = state.copyWith(
          clearLoading: true,
          errorMessage: 'auth.registration_confirmation'.tr(),
        );
        return false;
      }

      state = state.copyWith(
        clearLoading: true,
        user: sessionUser,
        isCloudBackupEnabled: sessionUser != null,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCloudBackupEnabledKey, sessionUser != null);
      if (sessionUser != null) {
        _triggerAutoSync();
      }
      return sessionUser != null;
    } on AuthException catch (e) {
      state = state.copyWith(clearLoading: true, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        clearLoading: true,
        errorMessage: 'auth.registration_error'.tr(args: ['$e']),
      );
      return false;
    }
  }

  /// Выход из аккаунта.
  Future<void> signOut() async {
    state = state.copyWith(loadingAction: AuthLoadingAction.account);
    await _repository.signOut();
    state = state.copyWith(clearLoading: true, clearUser: true);
  }

  /// Вход через Google.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(
      loadingAction: AuthLoadingAction.google,
      clearError: true,
    );
    try {
      final success = await _repository.signInWithGoogle();
      final user = _repository.currentUser;
      state = state.copyWith(
        clearLoading: true,
        user: success ? user : state.user,
        isCloudBackupEnabled: success ? true : state.isCloudBackupEnabled,
      );
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kCloudBackupEnabledKey, true);
        _triggerAutoSync();
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        clearLoading: true,
        errorMessage: 'auth.google_error'.tr(args: ['$e']),
      );
      return false;
    }
  }

  /// Вход через Apple.
  Future<bool> signInWithApple() async {
    state = state.copyWith(
      loadingAction: AuthLoadingAction.apple,
      clearError: true,
    );
    try {
      final success = await _repository.signInWithApple();
      final user = _repository.currentUser;
      state = state.copyWith(
        clearLoading: true,
        user: success ? user : state.user,
        isCloudBackupEnabled: success ? true : state.isCloudBackupEnabled,
      );
      if (success) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kCloudBackupEnabledKey, true);
        _triggerAutoSync();
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        clearLoading: true,
        errorMessage: 'auth.apple_error'.tr(args: ['$e']),
      );
      return false;
    }
  }

  /// Полное удаление аккаунта и очистка базы данных.
  Future<bool> deleteAccount() async {
    state = state.copyWith(
      loadingAction: AuthLoadingAction.account,
      clearError: true,
    );
    try {
      await _repository.deleteAccount();

      // Очистка локального переключателя
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kCloudBackupEnabledKey);

      state = state.copyWith(
        clearLoading: true,
        clearUser: true,
        isCloudBackupEnabled: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        clearLoading: true,
        errorMessage: 'auth.delete_error'.tr(args: ['$e']),
      );
      return false;
    }
  }
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AuthStateModel>((ref) {
      final repository = ref.watch(authRepositoryProvider);
      return AuthController(repository, ref);
    });
