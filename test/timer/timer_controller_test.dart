import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/core/utils/date_utils.dart' as du;
import 'package:asr/features/timer/application/timer_provider.dart';
import 'package:asr/features/timer/data/timer_repository.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import '../helpers/test_db_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initTestIsarCore();

    // Безопасная тестовая подмена каналов audioplayers и path_provider,
    // чтобы AudioService не обращался к реальным нативным плагинам во время тестов
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async => Directory.systemTemp.path,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => 1,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => 1,
    );
  });

  tearDownAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      null,
    );

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      null,
    );
  });

  group('TimerController and Timer Providers', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late TimerRepository timerRepository;
    late ProviderContainer container;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'timer_ctrl_test');
      isar = dbHandle.isar;
      timerRepository = TimerRepository(isar);

      container = ProviderContainer(
        overrides: [
          timerRepositoryProvider.overrideWithValue(timerRepository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await dbHandle.dispose();
    });

    test('switchActivity переключает активность и инкрементирует entriesChangedProvider', () async {
      final initialVersion = container.read(entriesChangedProvider);
      final controller = container.read(timerControllerProvider);

      await controller.switchActivity(
        name: 'Новая задача',
        categoryKey: 'growth',
      );

      expect(container.read(entriesChangedProvider), equals(initialVersion + 1));

      final current = await container.read(currentActivityProvider.future);
      expect(current?.name, equals('Новая задача'));
      expect(current?.categoryKey, equals('growth'));
    });

    test('closedStatsProvider суммирует закрытые записи за сегодня по категориям', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final today = du.DateUtils.dateKeyFromMillis(now);

      final entry1 = ActivityEntry()
        ..syncId = 'e1'
        ..name = 'Код'
        ..categoryKey = 'work'
        ..startedAt = now - 7200000
        ..endedAt = now - 3600000
        ..durationSeconds = 3600
        ..dateKey = today;

      final entry2 = ActivityEntry()
        ..syncId = 'e2'
        ..name = 'Бег'
        ..categoryKey = 'sport'
        ..startedAt = now - 3600000
        ..endedAt = now - 1800000
        ..durationSeconds = 1800
        ..dateKey = today;

      await isar.writeTxn(() async {
        await isar.activityEntrys.putAll([entry1, entry2]);
      });

      container.read(entriesChangedProvider.notifier).state++;

      final stats = await container.read(closedStatsProvider.future);
      expect(stats['work'], equals(3600));
      expect(stats['sport'], equals(1800));
      expect(stats['rest'], equals(0));
    });

    test('categoryEntriesProvider фильтрует сегодняшние записи по категории', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final today = du.DateUtils.dateKeyFromMillis(now);

      final entry1 = ActivityEntry()
        ..syncId = 'e1'
        ..name = 'Английский'
        ..categoryKey = 'growth'
        ..startedAt = now - 3600000
        ..endedAt = now - 1800000
        ..durationSeconds = 1800
        ..dateKey = today;

      final entry2 = ActivityEntry()
        ..syncId = 'e2'
        ..name = 'Работа'
        ..categoryKey = 'work'
        ..startedAt = now - 1800000
        ..endedAt = now
        ..durationSeconds = 1800
        ..dateKey = today;

      await isar.writeTxn(() async {
        await isar.activityEntrys.putAll([entry1, entry2]);
      });

      container.read(entriesChangedProvider.notifier).state++;

      final growthEntries = await container.read(
        categoryEntriesProvider('growth').future,
      );
      expect(growthEntries.length, equals(1));
      expect(growthEntries.first.name, equals('Английский'));
    });
  });
}
