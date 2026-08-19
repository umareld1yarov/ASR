import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/application/auth_controller.dart';
import '../../premium/application/premium_controller.dart';
import '../../timer/application/timer_provider.dart';
import '../data/cloud_sync_service.dart';

final syncServiceProvider = Provider<CloudSyncService>((ref) {
  return CloudSyncService();
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

  final CloudSyncService _service;
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
    if (!isPro || !authState.isAuthenticated || !authState.isCloudBackupEnabled) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(seconds: 3), () {
      triggerSync(silent: true);
    });
  }

  /// Вызов синхронизации.
  Future<SyncResult> triggerSync({bool silent = false}) async {
    final isPro = _ref.read(isProProvider);
    if (!isPro) {
      return const SyncResult(
        isSuccess: false,
        message: 'Облачный бэкап и синхронизация доступны только в ASR PRO',
      );
    }

    final authState = _ref.read(authControllerProvider);
    if (!authState.isAuthenticated) {
      return const SyncResult(
        isSuccess: false,
        message: 'Для синхронизации необходимо войти в аккаунт',
      );
    }

    if (state.isSyncing) {
      return const SyncResult(
        isSuccess: false,
        message: 'Синхронизация уже выполняется...',
      );
    }

    if (!silent) {
      state = state.copyWith(isSyncing: true, statusMessage: 'Синхронизация...');
    } else {
      state = state.copyWith(isSyncing: true);
    }

    final result = await _service.performFullSync();

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

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  final service = ref.watch(syncServiceProvider);
  return SyncController(service, ref);
});
