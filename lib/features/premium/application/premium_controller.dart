import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import '../../../core/services/purchases_service.dart';
import '../../../data/isar_service.dart';
import '../../profile/domain/models/user_profile.dart';

/// Реактивный провайдер текущего статуса ASR PRO.
final isProProvider = StateNotifierProvider<IsProNotifier, bool>((ref) {
  return IsProNotifier();
});

class IsProNotifier extends StateNotifier<bool> {
  IsProNotifier() : super(false) {
    _checkStatus();
  }

  Isar get _isar => IsarService.instance;

  Future<void> _checkStatus() async {
    // 1. Сначала считываем локальное состояние из Isar DB
    final profile = await _isar.userProfiles.get(0);
    if (profile != null) {
      state = profile.isPro;
    }

    // 2. Если подключен RevenueCat, запрашиваем актуальный статус
    if (PurchasesService.isInitialized) {
      final isProActive = await PurchasesService.isProActive();
      setProStatus(isProActive);
    }
  }

  /// Явное обновление статуса PRO (локально и в памяти).
  Future<void> setProStatus(bool value) async {
    state = value;
    await _isar.writeTxn(() async {
      var profile = await _isar.userProfiles.get(0);
      profile ??= UserProfile();
      profile.isPro = value;
      await _isar.userProfiles.put(profile);
    });
  }
}

/// Провайдер получения актуальных тарифов от RevenueCat.
final offeringsProvider = FutureProvider<Offerings?>((ref) async {
  return await PurchasesService.getOfferings();
});

/// Провайдер для выполнения операций покупки и восстановления.
final premiumControllerProvider = Provider<PremiumController>((ref) {
  return PremiumController(ref);
});

class PremiumController {
  PremiumController(this._ref);

  final Ref _ref;

  /// Покупка выбранного тарифа.
  Future<bool> purchasePackage(Package package) async {
    try {
      final customerInfo = await PurchasesService.purchasePackage(package);
      final isProActive = customerInfo?.entitlements.all['pro']?.isActive ??
          customerInfo?.entitlements.all['premium']?.isActive ??
          false;

      if (isProActive) {
        await _ref.read(isProProvider.notifier).setProStatus(true);
        return true;
      }
      return false;
    } catch (e) {
      rethrow;
    }
  }

  /// Восстановление покупок.
  Future<bool> restorePurchases() async {
    try {
      final customerInfo = await PurchasesService.restorePurchases();
      final isProActive = customerInfo?.entitlements.all['pro']?.isActive ??
          customerInfo?.entitlements.all['premium']?.isActive ??
          false;

      await _ref.read(isProProvider.notifier).setProStatus(isProActive);
      return isProActive;
    } catch (e) {
      rethrow;
    }
  }
}
