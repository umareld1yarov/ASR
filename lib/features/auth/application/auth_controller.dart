import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

const String _kCloudBackupEnabledKey = 'cloud_backup_enabled';

/// Провайдер репозитория авторизации.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Состояние подключения облачного бэкапа и авторизации.
class AuthStateModel {
  final User? user;
  final bool isCloudBackupEnabled;
  final bool isLoading;
  final String? errorMessage;

  const AuthStateModel({
    this.user,
    this.isCloudBackupEnabled = false,
    this.isLoading = false,
    this.errorMessage,
  });

  bool get isAuthenticated => user != null;

  AuthStateModel copyWith({
    User? user,
    bool? isCloudBackupEnabled,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool clearUser = false,
  }) {
    return AuthStateModel(
      user: clearUser ? null : (user ?? this.user),
      isCloudBackupEnabled: isCloudBackupEnabled ?? this.isCloudBackupEnabled,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Контроллер управления состоянием авторизации и включения бэкапа.
class AuthController extends StateNotifier<AuthStateModel> {
  AuthController(this._repository) : super(const AuthStateModel()) {
    _init();
  }

  final AuthRepository _repository;

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isEnabled = prefs.getBool(_kCloudBackupEnabledKey) ?? false;
    final currentUser = _repository.currentUser;

    state = state.copyWith(
      isCloudBackupEnabled: isEnabled,
      user: currentUser,
    );

    // Подписка на изменения состояния Supabase Auth
    _repository.authStateChanges?.listen((data) {
      final user = data.session?.user;
      state = state.copyWith(user: user, clearUser: user == null);
    });
  }

  /// Переключение тумблера Облачного бэкапа.
  Future<void> toggleCloudBackup(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kCloudBackupEnabledKey, value);
    state = state.copyWith(isCloudBackupEnabled: value);
  }

  /// Вход через Email/Пароль.
  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.signInWithEmail(
        email: email,
        password: password,
      );
      state = state.copyWith(
        isLoading: false,
        user: response.user,
        isCloudBackupEnabled: true, // Включаем бэкап при входе
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCloudBackupEnabledKey, true);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка входа: $e',
      );
      return false;
    }
  }

  /// Регистрация нового аккаунта.
  Future<bool> signUp(String email, String password, {String? name}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final response = await _repository.signUpWithEmail(
        email: email,
        password: password,
        name: name,
      );
      state = state.copyWith(
        isLoading: false,
        user: response.user,
        isCloudBackupEnabled: true,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCloudBackupEnabledKey, true);
      return true;
    } on AuthException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка регистрации: $e',
      );
      return false;
    }
  }

  /// Выход из аккаунта.
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    await _repository.signOut();
    state = state.copyWith(
      isLoading: false,
      clearUser: true,
    );
  }

  /// Вход через Google.
  Future<bool> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _repository.signInWithGoogle();
      if (success) {
        state = state.copyWith(
          isLoading: false,
          isCloudBackupEnabled: true,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kCloudBackupEnabledKey, true);
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка Google входа: $e',
      );
      return false;
    }
  }

  /// Вход через Apple.
  Future<bool> signInWithApple() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final success = await _repository.signInWithApple();
      if (success) {
        state = state.copyWith(
          isLoading: false,
          isCloudBackupEnabled: true,
        );
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_kCloudBackupEnabledKey, true);
      }
      return success;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Ошибка Apple входа: $e',
      );
      return false;
    }
  }

  /// Полное удаление аккаунта и очистка базы данных.
  Future<bool> deleteAccount() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.deleteAccount();

      // Очистка локального переключателя
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kCloudBackupEnabledKey, false);

      state = state.copyWith(
        isLoading: false,
        clearUser: true,
        isCloudBackupEnabled: false,
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Не удалось удалить аккаунт: $e',
      );
      return false;
    }
  }
}


final authControllerProvider =
    StateNotifierProvider<AuthController, AuthStateModel>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});
