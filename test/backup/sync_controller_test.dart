import 'dart:async';

import 'package:asr/features/auth/application/auth_controller.dart';
import 'package:asr/features/backup/application/sync_controller.dart';
import 'package:asr/features/backup/data/cloud_sync_service.dart';
import 'package:asr/features/premium/application/premium_controller.dart';
import 'package:asr/features/timer/application/timer_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_auth_repository.dart';
import '../helpers/test_localization_helper.dart';

class FakeSyncService implements SyncService {
  int calls = 0;
  SyncResult result = const SyncResult(isSuccess: true, message: 'ok');
  Object? error;
  Completer<SyncResult>? completer;

  @override
  Future<SyncResult> performFullSync() async {
    calls++;
    if (error != null) throw error!;
    if (completer != null) return completer!.future;
    return result;
  }
}

class SyncTestIsProNotifier extends StateNotifier<bool>
    implements IsProNotifier {
  SyncTestIsProNotifier(super.state);

  @override
  Future<void> setProStatus(bool value) async => state = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(initTestLocalization);

  group('SyncController', () {
    late FakeAuthRepository authRepository;
    late FakeSyncService syncService;
    late ProviderContainer container;

    Future<ProviderContainer> createContainer({
      bool isPro = true,
      bool authenticated = true,
      bool backupEnabled = true,
      Duration debounce = const Duration(milliseconds: 10),
    }) async {
      SharedPreferences.setMockInitialValues({
        'cloud_backup_enabled': backupEnabled,
      });
      authRepository = FakeAuthRepository(
        initialUser: authenticated ? createTestUser() : null,
      );
      syncService = FakeSyncService();
      final result = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(authRepository),
          isProProvider.overrideWith(
            (ref) => SyncTestIsProNotifier(false),
          ),
          syncServiceProvider.overrideWithValue(syncService),
          syncDebounceDurationProvider.overrideWithValue(debounce),
        ],
      );
      result.read(authControllerProvider);
      result.read(syncControllerProvider);
      await Future<void>.delayed(Duration.zero);
      await result.read(isProProvider.notifier).setProStatus(isPro);
      return result;
    }

    tearDown(() {
      container.dispose();
      authRepository.dispose();
    });

    test('не запускает сервис без PRO', () async {
      container = await createContainer(isPro: false);

      final result = await container
          .read(syncControllerProvider.notifier)
          .triggerSync();

      expect(result.isSuccess, isFalse);
      expect(syncService.calls, 0);
      expect(container.read(syncControllerProvider).isSyncing, isFalse);
    });

    test('не запускает сервис без авторизации', () async {
      container = await createContainer(authenticated: false);

      final result = await container
          .read(syncControllerProvider.notifier)
          .triggerSync();

      expect(result.isSuccess, isFalse);
      expect(syncService.calls, 0);
    });

    test('не допускает два параллельных запуска', () async {
      container = await createContainer();
      syncService.completer = Completer<SyncResult>();
      final controller = container.read(syncControllerProvider.notifier);

      final first = controller.triggerSync();
      expect(container.read(syncControllerProvider).isSyncing, isTrue);
      final second = await controller.triggerSync();

      expect(second.isSuccess, isFalse);
      expect(syncService.calls, 1);
      syncService.completer!.complete(
        const SyncResult(isSuccess: true, message: 'done'),
      );
      await first;
      expect(container.read(syncControllerProvider).isSyncing, isFalse);
    });

    test('успех обновляет lastSyncedAt и состояние', () async {
      container = await createContainer();

      final result = await container
          .read(syncControllerProvider.notifier)
          .triggerSync();

      final state = container.read(syncControllerProvider);
      expect(result.isSuccess, isTrue);
      expect(state.isSyncing, isFalse);
      expect(state.isSuccess, isTrue);
      expect(state.lastSyncedAt, isNotNull);
    });

    test('неожиданная ошибка сервиса не оставляет вечную загрузку', () async {
      container = await createContainer();
      syncService.error = Exception('unexpected');

      final result = await container
          .read(syncControllerProvider.notifier)
          .triggerSync();

      final state = container.read(syncControllerProvider);
      expect(result.isSuccess, isFalse);
      expect(state.isSyncing, isFalse);
      expect(state.isSuccess, isFalse);
      expect(state.lastSyncedAt, isNull);
    });

    test('изменения записей запускают один отложенный автобэкап', () async {
      container = await createContainer();

      container.read(entriesChangedProvider.notifier).state++;
      container.read(entriesChangedProvider.notifier).state++;
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(syncService.calls, 1);
      expect(container.read(syncControllerProvider).isSyncing, isFalse);
    });

    test('выключенный бэкап не запускает автоматическую синхронизацию', () async {
      container = await createContainer(backupEnabled: false);

      container.read(entriesChangedProvider.notifier).state++;
      await Future<void>.delayed(const Duration(milliseconds: 40));

      expect(syncService.calls, 0);
    });
  });
}
