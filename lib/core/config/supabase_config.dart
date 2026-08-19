import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Конфигурация Supabase, считываемая из .env файла.
class SupabaseConfig {
  SupabaseConfig._();

  static String get url => dotenv.env['SUPABASE_URL'] ?? '';
  static String get anonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? '';
  static String get googleWebClientId =>
      dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';


  /// Проверка, заполнены ли реальные ключи (не плейсхолдеры).
  static bool get isConfigured {
    final currentUrl = url;
    final currentKey = anonKey;

    if (currentUrl.isEmpty || currentKey.isEmpty) return false;
    if (currentUrl.contains('your-project') || currentKey.contains('placeholder')) {
      return false;
    }
    return true;
  }
}
