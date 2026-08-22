import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:easy_localization/easy_localization.dart';

import 'package:asr/features/auth/application/auth_controller.dart';
import 'package:asr/features/premium/application/premium_controller.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/test_localization_helper.dart';

class FakeIsProNotifier extends StateNotifier<bool> implements IsProNotifier {
  FakeIsProNotifier([super.state = false]);

  @override
  Future<void> setProStatus(bool value) async {
    state = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestLocalization();
  });

  group('AuthController', () {
    late FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          isProProvider.overrideWith((ref) => FakeIsProNotifier(false)),
        ],
      );
      // Инициализируем контроллер
      container.read(authControllerProvider);
      await Future<void>.delayed(Duration.zero);
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
    });

    group('Initial State', () {
      test('начальное состояние без пользователя: не авторизован, ошибки и загрузки отсутствуют', () async {
        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isFalse);
        expect(state.user, isNull);
        expect(state.loadingAction, isNull);
        expect(state.isLoading, isFalse);
        expect(state.errorMessage, isNull);
        expect(state.isCloudBackupEnabled, isFalse);
      });

      test('начальное состояние с уже авторизованным пользователем из репозитория', () async {
        final existingUser = createTestUser(
          id: 'pre-existing-user-id',
          email: 'logged.in@example.com',
          name: 'Logged In User',
        );

        final localRepo = FakeAuthRepository(initialUser: existingUser);
        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(localRepo),
            isProProvider.overrideWith((ref) => FakeIsProNotifier(false)),
          ],
        );

        localContainer.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);

        final state = localContainer.read(authControllerProvider);
        expect(state.isAuthenticated, isTrue);
        expect(state.user?.id, equals('pre-existing-user-id'));
        expect(state.user?.email, equals('logged.in@example.com'));

        localContainer.dispose();
        localRepo.dispose();
      });

      test('начальное состояние восстанавливает флаг cloud_backup_enabled из SharedPreferences', () async {
        SharedPreferences.setMockInitialValues({'cloud_backup_enabled': true});

        final localRepo = FakeAuthRepository();
        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(localRepo),
            isProProvider.overrideWith((ref) => FakeIsProNotifier(false)),
          ],
        );

        localContainer.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);

        final state = localContainer.read(authControllerProvider);
        expect(state.isCloudBackupEnabled, isTrue);

        localContainer.dispose();
        localRepo.dispose();
      });
    });

    group('Email & Password Sign In', () {
      test('успешный вход: промежуточный loadingAction==email, установка пользователя и флага бэкапа', () async {
        fakeRepo.signInWithEmailCompleter = Completer<AuthResponse>();
        final controller = container.read(authControllerProvider.notifier);

        final future = controller.signIn('user@test.com', 'password123');

        expect(
          container.read(authControllerProvider).loadingAction,
          equals(AuthLoadingAction.email),
        );
        expect(container.read(authControllerProvider).isLoading, isTrue);

        final testUser = createTestUser(email: 'user@test.com');
        final response = createTestAuthResponse(
          user: testUser,
          session: createTestSession(user: testUser),
        );
        fakeRepo.signInWithEmailCompleter!.complete(response);

        final success = await future;

        expect(success, isTrue);
        final finalState = container.read(authControllerProvider);
        expect(finalState.loadingAction, isNull);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isAuthenticated, isTrue);
        expect(finalState.user?.email, equals('user@test.com'));
        expect(finalState.errorMessage, isNull);
        expect(finalState.isCloudBackupEnabled, isTrue);

        expect(fakeRepo.signInWithEmailCalls, equals(1));
        expect(fakeRepo.lastSignInEmail, equals('user@test.com'));
        expect(fakeRepo.lastSignInPassword, equals('password123'));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('cloud_backup_enabled'), isTrue);
      });

      test('AuthException при Email-входе: сброс загрузки, пользователь не установлен, корректный errorMessage', () async {
        fakeRepo.signInWithEmailException = const AuthException('Invalid login credentials');
        final controller = container.read(authControllerProvider.notifier);

        final success = await controller.signIn('wrong@test.com', 'wrongpass');

        expect(success, isFalse);
        final finalState = container.read(authControllerProvider);
        expect(finalState.loadingAction, isNull);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isAuthenticated, isFalse);
        expect(finalState.user, isNull);
        expect(finalState.errorMessage, equals('Invalid login credentials'));
      });

      test('обычный Exception при Email-входе: локализованное сообщение auth.login_error, отсутствие краша, готовность к повтору', () async {
        fakeRepo.signInWithEmailException = Exception('Socket timeout');
        final controller = container.read(authControllerProvider.notifier);

        final success = await controller.signIn('user@test.com', 'password123');

        expect(success, isFalse);
        final finalState = container.read(authControllerProvider);
        expect(finalState.loadingAction, isNull);
        expect(finalState.isLoading, isFalse);
        expect(finalState.isAuthenticated, isFalse);
        expect(
          finalState.errorMessage,
          equals('auth.login_error'.tr(args: ['Exception: Socket timeout'])),
        );

        fakeRepo.signInWithEmailException = null;
        fakeRepo.signInWithEmailResult = createTestAuthResponse(
          user: createTestUser(email: 'user@test.com'),
          session: createTestSession(user: createTestUser(email: 'user@test.com')),
        );

        final retrySuccess = await controller.signIn('user@test.com', 'password123');
        expect(retrySuccess, isTrue);
        expect(container.read(authControllerProvider).isAuthenticated, isTrue);
        expect(container.read(authControllerProvider).errorMessage, isNull);
      });
    });

    group('Email & Password Sign Up', () {
      test('успешная регистрация с активной сессией: loadingAction==email, пользователь сохранён, аргументы переданы', () async {
        fakeRepo.signUpWithEmailCompleter = Completer<AuthResponse>();
        final controller = container.read(authControllerProvider.notifier);

        final future = controller.signUp('new@test.com', 'pass12345', name: 'Иван');

        expect(
          container.read(authControllerProvider).loadingAction,
          equals(AuthLoadingAction.email),
        );

        final newUser = createTestUser(email: 'new@test.com', name: 'Иван');
        final response = createTestAuthResponse(
          user: newUser,
          session: createTestSession(user: newUser),
        );
        fakeRepo.signUpWithEmailCompleter!.complete(response);

        final success = await future;

        expect(success, isTrue);
        final state = container.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.isAuthenticated, isTrue);
        expect(state.user?.email, equals('new@test.com'));
        expect(state.isCloudBackupEnabled, isTrue);

        expect(fakeRepo.signUpWithEmailCalls, equals(1));
        expect(fakeRepo.lastSignUpEmail, equals('new@test.com'));
        expect(fakeRepo.lastSignUpPassword, equals('pass12345'));
        expect(fakeRepo.lastSignUpName, equals('Иван'));
      });

      test('регистрация с подтверждением Email (Supabase создал пользователя, но response.session == null)', () async {
        final unconfirmedUser = createTestUser(email: 'unconfirmed@test.com', name: 'Анна');
        fakeRepo.signUpWithEmailResult = createTestAuthResponse(
          user: unconfirmedUser,
          session: null, // Сессия отсутствует, требуется подтверждение почты
        );

        final controller = container.read(authControllerProvider.notifier);
        final success = await controller.signUp('unconfirmed@test.com', 'secret123', name: 'Анна');

        expect(success, isFalse, reason: 'При отсутствии сессии метод должен возвращать false');
        final state = container.read(authControllerProvider);
        expect(state.isAuthenticated, isFalse, reason: 'Пользователь не должен считаться авторизованным без сессии');
        expect(state.user, isNull, reason: 'В состоянии не должен сохраняться неавторизованный пользователь');
        expect(state.loadingAction, isNull);
        expect(
          state.errorMessage,
          equals('auth.registration_confirmation'.tr()),
          reason: 'Должно отображаться локализованное сообщение о необходимости подтвердить email',
        );
      });

      test('AuthException при регистрации: сброс загрузки, errorMessage содержит текст ошибки', () async {
        fakeRepo.signUpWithEmailException = const AuthException('User already registered');
        final controller = container.read(authControllerProvider.notifier);

        final success = await controller.signUp('existing@test.com', 'pass123');

        expect(success, isFalse);
        final state = container.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.isAuthenticated, isFalse);
        expect(state.errorMessage, equals('User already registered'));
      });

      test('обычный Exception при регистрации: локализованное сообщение auth.registration_error', () async {
        fakeRepo.signUpWithEmailException = Exception('Database unreachable');
        final controller = container.read(authControllerProvider.notifier);

        final success = await controller.signUp('test@test.com', 'pass123');

        expect(success, isFalse);
        final state = container.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(
          state.errorMessage,
          equals('auth.registration_error'.tr(args: ['Exception: Database unreachable'])),
        );
      });
    });

    group('Google Sign In', () {
      test('успешный Google-вход: loadingAction==google, установка пользователя, бэкап включен', () async {
        fakeRepo.signInWithGoogleCompleter = Completer<bool>();
        final controller = container.read(authControllerProvider.notifier);

        final future = controller.signInWithGoogle();

        expect(
          container.read(authControllerProvider).loadingAction,
          equals(AuthLoadingAction.google),
        );

        fakeRepo.signInWithGoogleCompleter!.complete(true);
        final success = await future;

        expect(success, isTrue);
        final state = container.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.isAuthenticated, isTrue);
        expect(state.user?.id, equals('google-user-id'));
        expect(state.isCloudBackupEnabled, isTrue);
        expect(state.errorMessage, isNull);
        expect(fakeRepo.signInWithGoogleCalls, equals(1));
      });

      test('отмена Google-входа: пользователь не устанавливается, ошибка отсутствует, сброс загрузки', () async {
        fakeRepo.signInWithGoogleResult = false; // Пользователь закрыл диалог
        final controller = container.read(authControllerProvider.notifier);

        final success = await controller.signInWithGoogle();

        expect(success, isFalse);
        final state = container.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.isAuthenticated, isFalse);
        expect(state.user, isNull);
        expect(state.errorMessage, isNull);
      });

      test('ошибка Google-входа: локализованное сообщение auth.google_error, сброс загрузки', () async {
        fakeRepo.signInWithGoogleException = Exception('Google Play Services unavailable');
        final controller = container.read(authControllerProvider.notifier);

        final success = await controller.signInWithGoogle();

        expect(success, isFalse);
        final state = container.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.isAuthenticated, isFalse);
        expect(
          state.errorMessage,
          equals('auth.google_error'.tr(args: ['Exception: Google Play Services unavailable'])),
        );
      });
    });

    group('Apple Sign In', () {
      test('успешный Apple-вход: loadingAction==apple, установка пользователя', () async {
        fakeRepo.signInWithAppleCompleter = Completer<bool>();
        final controller = container.read(authControllerProvider.notifier);

        final future = controller.signInWithApple();

        expect(
          container.read(authControllerProvider).loadingAction,
          equals(AuthLoadingAction.apple),
        );

        fakeRepo.signInWithAppleCompleter!.complete(true);
        final success = await future;

        expect(success, isTrue);
        final state = container.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.isAuthenticated, isTrue);
        expect(state.user?.id, equals('apple-user-id'));
      });

      test('ошибка Apple-входа: локализованное сообщение auth.apple_error, сброс загрузки', () async {
        fakeRepo.signInWithAppleException = Exception('Apple OAuth error');
        final controller = container.read(authControllerProvider.notifier);

        final success = await controller.signInWithApple();

        expect(success, isFalse);
        final state = container.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(
          state.errorMessage,
          equals('auth.apple_error'.tr(args: ['Exception: Apple OAuth error'])),
        );
      });
    });

    group('Sign Out', () {
      test('успешный выход: loadingAction==account, очистка пользователя, сброс loadingAction', () async {
        final testUser = createTestUser();
        fakeRepo.currentUser = testUser;

        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            isProProvider.overrideWith((ref) => FakeIsProNotifier(false)),
          ],
        );
        localContainer.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);

        expect(localContainer.read(authControllerProvider).isAuthenticated, isTrue);

        fakeRepo.signOutCompleter = Completer<void>();
        final controller = localContainer.read(authControllerProvider.notifier);
        final future = controller.signOut();

        expect(
          localContainer.read(authControllerProvider).loadingAction,
          equals(AuthLoadingAction.account),
        );

        fakeRepo.signOutCompleter!.complete();
        await future;

        final state = localContainer.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.user, isNull);
        expect(state.isAuthenticated, isFalse);
        expect(fakeRepo.signOutCalls, equals(1));

        localContainer.dispose();
      });

      test('ошибка signOut: исключение перехвачено, loadingAction сброшен, пользователь сохранён, errorMessage содержит auth.logout_error', () async {
        final testUser = createTestUser();
        fakeRepo.currentUser = testUser;

        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            isProProvider.overrideWith((ref) => FakeIsProNotifier(false)),
          ],
        );
        localContainer.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);

        fakeRepo.signOutException = Exception('SignOut network error');
        final controller = localContainer.read(authControllerProvider.notifier);

        // Исключение не должно выходить наружу
        await controller.signOut();

        expect(fakeRepo.signOutCalls, equals(1));
        final state = localContainer.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.isLoading, isFalse);
        expect(state.user, isNotNull, reason: 'Пользователь должен быть сохранен, так как выход не удался');
        expect(state.user?.id, equals('test-user-id'));
        expect(state.isAuthenticated, isTrue);
        expect(
          state.errorMessage,
          equals('auth.logout_error'.tr(args: ['Exception: SignOut network error'])),
        );

        localContainer.dispose();
      });
    });

    group('Delete Account', () {
      test('успешное удаление: loadingAction==account, очистка пользователя, удаление флага бэкапа из prefs', () async {
        SharedPreferences.setMockInitialValues({'cloud_backup_enabled': true});
        final testUser = createTestUser();
        fakeRepo.currentUser = testUser;

        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            isProProvider.overrideWith((ref) => FakeIsProNotifier(false)),
          ],
        );
        localContainer.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);

        fakeRepo.deleteAccountCompleter = Completer<void>();
        final controller = localContainer.read(authControllerProvider.notifier);
        final future = controller.deleteAccount();

        expect(
          localContainer.read(authControllerProvider).loadingAction,
          equals(AuthLoadingAction.account),
        );

        fakeRepo.deleteAccountCompleter!.complete();
        final success = await future;

        expect(success, isTrue);
        final state = localContainer.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.user, isNull);
        expect(state.isAuthenticated, isFalse);
        expect(state.isCloudBackupEnabled, isFalse);
        expect(fakeRepo.deleteAccountCalls, equals(1));

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.containsKey('cloud_backup_enabled'), isFalse);

        localContainer.dispose();
      });

      test('ошибка удаления аккаунта: пользователь не очищается ошибочно, SharedPreferences не удаляется, сообщение об ошибке', () async {
        SharedPreferences.setMockInitialValues({'cloud_backup_enabled': true});
        final testUser = createTestUser();
        fakeRepo.currentUser = testUser;

        final localContainer = ProviderContainer(
          overrides: [
            authRepositoryProvider.overrideWithValue(fakeRepo),
            isProProvider.overrideWith((ref) => FakeIsProNotifier(false)),
          ],
        );
        localContainer.read(authControllerProvider);
        await Future<void>.delayed(Duration.zero);

        fakeRepo.deleteAccountException = Exception('RPC delete_user_account failed');
        final controller = localContainer.read(authControllerProvider.notifier);

        final success = await controller.deleteAccount();

        expect(success, isFalse);
        final state = localContainer.read(authControllerProvider);
        expect(state.loadingAction, isNull);
        expect(state.user, isNotNull, reason: 'Пользователь не должен очищаться при сбое удаления');
        expect(
          state.errorMessage,
          equals('auth.delete_error'.tr(args: ['Exception: RPC delete_user_account failed'])),
        );

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('cloud_backup_enabled'), isTrue, reason: 'Флаг бэкапа не должен удаляться при ошибке');

        localContainer.dispose();
      });
    });

    group('Cloud Backup Toggle', () {
      test('переключение флага бэкапа сохраняется в SharedPreferences и обновляет состояние', () async {
        final controller = container.read(authControllerProvider.notifier);

        await controller.toggleCloudBackup(true);
        expect(container.read(authControllerProvider).isCloudBackupEnabled, isTrue);
        var prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('cloud_backup_enabled'), isTrue);

        await controller.toggleCloudBackup(false);
        expect(container.read(authControllerProvider).isCloudBackupEnabled, isFalse);
        prefs = await SharedPreferences.getInstance();
        expect(prefs.getBool('cloud_backup_enabled'), isFalse);
      });
    });

    group('Supabase Auth State Changes Stream', () {
      test('поток authStateChanges обновляет состояние пользователя при входе и выходе', () async {
        expect(container.read(authControllerProvider).user, isNull);

        final streamUser = createTestUser(id: 'stream-user-1', email: 'stream@test.com');
        final session = createTestSession(user: streamUser);

        // Эмитим состояние входа
        fakeRepo.emitAuthState(AuthState(AuthChangeEvent.signedIn, session));
        await Future<void>.delayed(Duration.zero);

        expect(container.read(authControllerProvider).user?.id, equals('stream-user-1'));
        expect(container.read(authControllerProvider).isAuthenticated, isTrue);

        // Эмитим состояние выхода
        fakeRepo.emitAuthState(const AuthState(AuthChangeEvent.signedOut, null));
        await Future<void>.delayed(Duration.zero);

        expect(container.read(authControllerProvider).user, isNull);
        expect(container.read(authControllerProvider).isAuthenticated, isFalse);
      });
    });
  });
}
