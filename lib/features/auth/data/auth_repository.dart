import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/services/supabase_service.dart';


/// Репозиторий для управления авторизацией через Supabase.
class AuthRepository {
  AuthRepository();

  SupabaseClient? get _client => SupabaseService.client;

  /// Текущий авторизованный пользователь (null если не вошел).
  User? get currentUser => _client?.auth.currentUser;

  /// Поток изменений состояния авторизации.
  Stream<AuthState>? get authStateChanges => _client?.auth.onAuthStateChange;

  /// Проверка, включена ли сессия авторизации.
  bool get isAuthenticated => currentUser != null;

  /// Вход по Email и Паролю.
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase не инициализирован. Проверьте ключи в .env');
    }
    return await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Регистрация нового пользователя по Email и Паролю.
  Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    String? name,
  }) async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase не инициализирован. Проверьте ключи в .env');
    }
    return await client.auth.signUp(
      email: email.trim(),
      password: password,
      data: name != null ? {'name': name} : null,
    );
  }

  /// Выход из аккаунта.
  Future<void> signOut() async {
    final client = _client;
    if (client != null) {
      await client.auth.signOut();
    }
  }

  /// Вход через Google OAuth.
  Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase не инициализирован. Проверьте ключи в .env');
    }
    return await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: kIsWeb ? null : 'io.supabase.asr://login-callback',
    );
  }

  /// Вход через Apple OAuth.
  Future<bool> signInWithApple() async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase не инициализирован. Проверьте ключи в .env');
    }
    return await client.auth.signInWithOAuth(
      OAuthProvider.apple,
      redirectTo: kIsWeb ? null : 'io.supabase.asr://login-callback',
    );
  }

  /// Полное удаление аккаунта пользователя (App Store & GDPR Compliant).
  /// Вызывает RPC-функцию delete_user_account в Supabase PostgreSQL.
  Future<void> deleteAccount() async {
    final client = _client;
    if (client == null) return;

    // Вызов RPC функции удаляющей все фото из Storage и все записи из БД
    await client.rpc('delete_user_account');
    await signOut();
  }
}

