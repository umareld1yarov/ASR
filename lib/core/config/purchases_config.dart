import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Конфигурация RevenueCat SDK.
class PurchasesConfig {
  PurchasesConfig._();

  static String get apiKey => dotenv.env['REVENUECAT_PUBLIC_SDK_KEY'] ?? '';

  /// Проверка, задан ли валидный ключ RevenueCat.
  static bool get isConfigured {
    final key = apiKey;
    if (key.isEmpty || key.contains('placeholder')) return false;
    return true;
  }
}
