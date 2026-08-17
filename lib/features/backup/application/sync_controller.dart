import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  SyncController(this._service) : super(const SyncState());

  final CloudSyncService _service;

  /// Вызов синхронизации.
  Future<SyncResult> triggerSync() async {
    if (state.isSyncing) {
      return const SyncResult(
        isSuccess: false,
        message: 'Синхронизация уже выполняется...',
      );
    }

    state = state.copyWith(isSyncing: true, statusMessage: 'Синхронизация...');

    final result = await _service.performFullSync();

    state = state.copyWith(
      isSyncing: false,
      lastSyncedAt: result.isSuccess ? DateTime.now() : state.lastSyncedAt,
      statusMessage: result.message,
      isSuccess: result.isSuccess,
    );

    return result;
  }
}

final syncControllerProvider =
    StateNotifierProvider<SyncController, SyncState>((ref) {
  final service = ref.watch(syncServiceProvider);
  return SyncController(service);
});
