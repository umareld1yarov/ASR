import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../premium/application/premium_controller.dart';
import '../../timer/application/timer_provider.dart';
import '../data/cloud_sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  return CloudSyncService();
});

final syncDebounceDurationProvider = Provider<Duration>((ref) {
  return const Duration(seconds: 3);
});

class SyncState {
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final String? statusMessage;
  final bool isSuccess;

  const SyncState({
    this.isSyncing = false,
    this.lastSyncedAt,
    this.statusMessage,
    this.isSuccess = true,
  });

  SyncState copyWith({
    bool? isSyncing,
    DateTime? lastSyncedAt,
    String? statusMessage,
    bool? isSuccess,
  }) {
    return SyncState(
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      statusMessage: statusMessage ?? this.statusMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class SyncController extends StateNotifier<SyncState> {
  SyncController(this._service, this._ref) : super(const SyncState()) {
    _initAutoSyncListener();
  }

  final SyncService _service;
  final Ref _ref;
  Timer? _debounceTimer;

  void _initAutoSyncListener() {
    _ref.listen<int>(entriesChangedProvider, (previous, next) {
      if (previous != null && next > previous) {
        _scheduleAutoSync();
      }
    });
  }

  void _scheduleAutoSync() {
    final isPro = _ref.read(isProProvider);
    final authState = _ref.read(authControllerProvider);

    // Авто-бэкап работает ТОЛЬКО для PRO пользователей с включенным бэкапом
    if (!isPro ||
        !authState.isAuthenticated ||
        !authState.isCloudBackupEnabled) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_ref.read(syncDebounceDurationProvider), () {
      triggerSync(silent: true);
    });
  }

  /// Вызов синхронизации.
  Future<SyncResult> triggerSync({bool silent = false}) async {
    final isPro = _ref.read(isProProvider);
    if (!isPro) {
      return SyncResult(isSuccess: false, message: 'sync.pro_required'.tr());
    }

    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      return SyncResult(isSuccess: false, message: 'sync.login_required'.tr());
    }

    if (state.isSyncing) {
      return SyncResult(isSuccess: false, message: 'sync.already_running'.tr());
    }

    if (!silent) {
      state = state.copyWith(
        isSyncing: true,
        statusMessage: 'sync.in_progress'.tr(),
      );
    } else {
      state = state.copyWith(isSyncing: true);
    }

    late SyncResult result;
    try {
      result = await _service.performFullSync();
    } catch (e) {
      // CloudSyncService штатно превращает ошибки в SyncResult, но этот
      // защитный слой не позволит внешней ошибке оставить UI в вечной загрузке.
      result = SyncResult(
        isSuccess: false,
        message: 'sync.error'.tr(args: ['$e']),
      );
    }

    state = state.copyWith(
      isSyncing: false,
      lastSyncedAt: result.isSuccess ? DateTime.now() : state.lastSyncedAt,
      statusMessage: result.message,
      isSuccess: result.isSuccess,
    );

    return result;
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

final syncControllerProvider = StateNotifierProvider<SyncController, SyncState>(
  (ref) {
    final service = ref.watch(syncServiceProvider);
    return SyncController(service, ref);
  },
);
