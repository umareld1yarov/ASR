import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
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

  /// Вход через Google (Нативный 1-Click UX с OAuth fallback).
  Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) {
      throw Exception('Supabase не инициализирован. Проверьте ключи в .env');
    }

    final webClientId = SupabaseConfig.googleWebClientId;

    // Если Web Client ID не настроен в .env, пробуем OAuth через браузер
    if (webClientId.isEmpty ||
        webClientId.contains('placeholder') ||
        webClientId.contains('your_google_web_client_id')) {
      return await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.asr://login-callback',
      );
    }

    final googleSignIn = GoogleSignIn(
      serverClientId: webClientId,
      scopes: const ['email', 'profile'],
    );

    final googleUser = await googleSignIn.signIn().timeout(
      const Duration(seconds: 25),
      onTimeout: () => null,
    );
    if (googleUser == null) return false;

    final googleAuth = await googleUser.authentication.timeout(
      const Duration(seconds: 15),
      onTimeout: () => throw Exception('auth.google_tokens_timeout'.tr()),
    );
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;

    if (idToken == null) {
      throw Exception('auth.google_id_token_error'.tr());
    }

    final response = await client.auth
        .signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        )
        .timeout(
          const Duration(seconds: 15),
          onTimeout: () => throw Exception('auth.supabase_timeout'.tr()),
        );

    return response.user != null;
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
