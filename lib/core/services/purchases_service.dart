import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../config/purchases_config.dart';

/// Сервис управления встроенными покупками и подписками через RevenueCat.
class PurchasesService {
  PurchasesService._();

  static bool _isInitialized = false;
  static bool get isInitialized => _isInitialized;

  /// Инициализация SDK RevenueCat.
  static Future<void> initialize() async {
    if (!PurchasesConfig.isConfigured) {
      if (kDebugMode) {
        print(
          '[PurchasesService] Ключ RevenueCat не настроен в .env. '
          'Приложение работает в тестовом/локальном режиме подписок.',
        );
      }
      return;
    }

    try {
      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.info);

      final configuration =
          PurchasesConfiguration(PurchasesConfig.apiKey);

      await Purchases.configure(configuration);
      _isInitialized = true;

      if (kDebugMode) {
        print('[PurchasesService] RevenueCat SDK успешно инициализирован.');
      }
    } catch (e) {
      if (kDebugMode) {
        print('[PurchasesService] Ошибка инициализации RevenueCat: $e');
      }
    }
  }

  /// Связывание подписки с ID пользователя Supabase Auth.
  static Future<void> logIn(String appUserId) async {
    if (!_isInitialized) return;
    try {
      await Purchases.logIn(appUserId);
    } catch (e) {
      if (kDebugMode) {
        print('[PurchasesService] Ошибка logIn: $e');
      }
    }
  }

  /// Сброс пользователя RevenueCat при выходе.
  static Future<void> logOut() async {
    if (!_isInitialized) return;
    try {
      await Purchases.logOut();
    } catch (e) {
      if (kDebugMode) {
        print('[PurchasesService] Ошибка logOut: $e');
      }
    }
  }

  /// Проверка, активна ли ASR PRO подписка (entitlement "pro" или "premium").
  static Future<bool> isProActive() async {
    if (!_isInitialized) return false;
    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final proEntitlement = customerInfo.entitlements.all['pro'] ??
          customerInfo.entitlements.all['premium'];
      return proEntitlement?.isActive ?? false;
    } catch (e) {
      if (kDebugMode) {
        print('[PurchasesService] Ошибка проверки подписки: $e');
      }
      return false;
    }
  }

  /// Получение текущих тарифов (Offerings).
  static Future<Offerings?> getOfferings() async {
    if (!_isInitialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      if (kDebugMode) {
        print('[PurchasesService] Ошибка получения тарифов: $e');
      }
      return null;
    }
  }

  /// Покупка пакета (Monthly / Yearly).
  static Future<CustomerInfo?> purchasePackage(Package package) async {
    if (!_isInitialized) {
      throw Exception('RevenueCat не настроен. Добавьте валидный SDK ключ в .env');
    }
    return await Purchases.purchasePackage(package);
  }

  /// Восстановление покупок (Restore Purchases).
  static Future<CustomerInfo?> restorePurchases() async {
    if (!_isInitialized) {
      throw Exception('RevenueCat не настроен. Добавьте валидный SDK ключ в .env');
    }
    return await Purchases.restorePurchases();
  }
}
