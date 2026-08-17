import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// Единый сервис инициализации и доступа к клиентскому SDK Supabase.
class SupabaseService {
  SupabaseService._();

  static bool _isInitialized = false;

  static bool get isInitialized => _isInitialized;

  /// Инициализация клиентского SDK Supabase.
  /// Безопасно обрабатывает отсутствие ключей без падения приложения.
  static Future<void> initialize() async {
    if (!SupabaseConfig.isConfigured) {
      if (kDebugMode) {
        print(
          '[SupabaseService] Ключи Supabase не настроены в .env. '
          'Приложение работает в 100% локальном режиме (Isar DB).',
        );
      }
      return;
    }

    try {
      await Supabase.initialize(
        url: SupabaseConfig.url,
        anonKey: SupabaseConfig.anonKey,
      );

      _isInitialized = true;
      if (kDebugMode) {
        print('[SupabaseService] Успешно инициализировано!');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[SupabaseService] Ошибка инициализации Supabase: $e');
      }
    }
  }

  /// Геттер для получения экземпляра SupabaseClient (null если не инициализирован).
  static SupabaseClient? get client {
    if (!_isInitialized) return null;
    return Supabase.instance.client;
  }
}
