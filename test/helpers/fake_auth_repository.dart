import 'dart:async';
import 'package:asr/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Ручная Fake-реализация AuthRepository для изолированного тестирования
/// без сетевых запросов и сторонних библиотек моков.
class FakeAuthRepository extends AuthRepository {
  User? _currentUser;
  final StreamController<AuthState> _authStateController =
      StreamController<AuthState>.broadcast();

  // Счётчики и аргументы вызовов
  int signInWithEmailCalls = 0;
  String? lastSignInEmail;
  String? lastSignInPassword;
  Completer<AuthResponse>? signInWithEmailCompleter;
  AuthResponse? signInWithEmailResult;
  Object? signInWithEmailException;

  int signUpWithEmailCalls = 0;
  String? lastSignUpEmail;
  String? lastSignUpPassword;
  String? lastSignUpName;
  Completer<AuthResponse>? signUpWithEmailCompleter;
  AuthResponse? signUpWithEmailResult;
  Object? signUpWithEmailException;

  int signOutCalls = 0;
  Completer<void>? signOutCompleter;
  Object? signOutException;

  int signInWithGoogleCalls = 0;
  Completer<bool>? signInWithGoogleCompleter;
  bool signInWithGoogleResult = true;
  Object? signInWithGoogleException;

  int signInWithAppleCalls = 0;
  Completer<bool>? signInWithAppleCompleter;
  bool signInWithAppleResult = true;
  Object? signInWithAppleException;

  int deleteAccountCalls = 0;
  Completer<void>? deleteAccountCompleter;
  Object? deleteAccountException;

  FakeAuthRepository({User? initialUser}) : _currentUser = initialUser;

  @override
  User? get currentUser => _currentUser;

  set currentUser(User? user) {
    _currentUser = user;
  }

  @override
  Stream<AuthState> get authStateChanges => _authStateController.stream;

  void emitAuthState(AuthState state) {
    if (!_authStateController.isClosed) {
      _authStateController.add(state);
    }
  }

  @override
  bool get isAuthenticated => _currentUser != null;

  @override
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    signInWithEmailCalls++;
    lastSignInEmail = email;
    lastSignInPassword = password;

    if (signInWithEmailCompleter != null) {
      final response = await signInWithEmailCompleter!.future;
      _currentUser = response.user;
      return response;
    }

    if (signInWithEmailException != null) {
      throw signInWithEmailException!;
    }

    final response = signInWithEmailResult ??
        createTestAuthResponse(
          user: createTestUser(email: email),
          session: createTestSession(user: createTestUser(email: email)),
        );
    _currentUser = response.user;
    return response;
  }

  @override
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    signUpWithEmailCalls++;
    lastSignUpEmail = email;
    lastSignUpPassword = password;
    lastSignUpName = name;

    if (signUpWithEmailCompleter != null) {
      final response = await signUpWithEmailCompleter!.future;
      if (response.session != null) {
        _currentUser = response.user;
      }
      return response;
    }

    if (signUpWithEmailException != null) {
      throw signUpWithEmailException!;
    }

    final response = signUpWithEmailResult ??
        createTestAuthResponse(
          user: createTestUser(email: email, name: name ?? ''),
          session: createTestSession(
            user: createTestUser(email: email, name: name ?? ''),
          ),
        );
    if (response.session != null) {
      _currentUser = response.user;
    }
    return response;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;

    if (signOutCompleter != null) {
      await signOutCompleter!.future;
    }

    if (signOutException != null) {
      throw signOutException!;
    }

    _currentUser = null;
  }

  @override
  Future<bool> signInWithGoogle() async {
    signInWithGoogleCalls++;

    final bool result;
    if (signInWithGoogleCompleter != null) {
      result = await signInWithGoogleCompleter!.future;
    } else if (signInWithGoogleException != null) {
      throw signInWithGoogleException!;
    } else {
      result = signInWithGoogleResult;
    }

    if (result) {
      _currentUser = createTestUser(
        id: 'google-user-id',
        email: 'google.user@example.com',
        name: 'Google User',
      );
    }
    return result;
  }

  @override
  Future<bool> signInWithApple() async {
    signInWithAppleCalls++;

    final bool result;
    if (signInWithAppleCompleter != null) {
      result = await signInWithAppleCompleter!.future;
    } else if (signInWithAppleException != null) {
      throw signInWithAppleException!;
    } else {
      result = signInWithAppleResult;
    }

    if (result) {
      _currentUser = createTestUser(
        id: 'apple-user-id',
        email: 'apple.user@example.com',
        name: 'Apple User',
      );
    }
    return result;
  }

  @override
  Future<void> deleteAccount() async {
    deleteAccountCalls++;

    if (deleteAccountCompleter != null) {
      await deleteAccountCompleter!.future;
    }

    if (deleteAccountException != null) {
      throw deleteAccountException!;
    }

    _currentUser = null;
  }

  void dispose() {
    _authStateController.close();
  }
}

/// Фабрика тестового пользователя Supabase
User createTestUser({
  String id = 'test-user-id',
  String email = 'user@example.com',
  String name = 'Test User',
}) {
  return User(
    id: id,
    appMetadata: const {},
    userMetadata: {'name': name},
    aud: 'authenticated',
    createdAt: '2026-01-01T00:00:00.000Z',
    email: email,
  );
}

/// Фабрика тестовой сессии Supabase
Session createTestSession({required User user}) {
  return Session(
    accessToken: 'mock-access-token',
    tokenType: 'bearer',
    user: user,
  );
}

/// Фабрика тестового ответа AuthResponse
AuthResponse createTestAuthResponse({
  User? user,
  Session? session,
}) {
  return AuthResponse(
    user: user,
    session: session,
  );
}
