import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/core/utils/date_utils.dart' as du;
import 'package:asr/features/feed/application/feed_provider.dart';
import 'package:asr/features/feed/data/feed_repository.dart';
import 'package:asr/features/timer/application/timer_provider.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('FeedController and Feed Providers', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late FeedRepository feedRepository;
    late ProviderContainer container;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'feed_controller_test');
      isar = dbHandle.isar;
      feedRepository = FeedRepository(isar);

      container = ProviderContainer(
        overrides: [
          feedRepositoryProvider.overrideWithValue(feedRepository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await dbHandle.dispose();
    });

    test('goToNextDay не позволяет переключаться на даты в будущем', () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      // Изначально установлена сегодняшняя дата
      expect(container.read(selectedDateProvider), equals(today));

      final controller = container.read(feedControllerProvider);
      controller.goToNextDay();

      // Дата остаётся сегодняшней
      expect(container.read(selectedDateProvider), equals(today));
    });

    test('goToPreviousDay и goToNextDay корректно переключают дни в допустимом диапазоне', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final threeDaysAgo = today.subtract(const Duration(days: 3));

      // Создаём запись 3 дня назад, чтобы earliestDateProvider позволил листать назад
      final oldEntry = ActivityEntry()
        ..syncId = 'old-1'
        ..name = 'Старая запись'
        ..categoryKey = 'work'
        ..startedAt = threeDaysAgo.millisecondsSinceEpoch
        ..endedAt = threeDaysAgo.millisecondsSinceEpoch + 3600000
        ..durationSeconds = 3600
        ..dateKey = du.DateUtils.dateKey(threeDaysAgo);

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(oldEntry);
      });

      final controller = container.read(feedControllerProvider);

      await controller.goToPreviousDay();
      expect(container.read(selectedDateProvider), equals(yesterday));

      controller.goToNextDay();
      expect(container.read(selectedDateProvider), equals(today));
    });

    test('goToPreviousDay блокирует переход раньше самой ранней записи', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));

      // Самая ранняя запись - вчера
      final entry = ActivityEntry()
        ..syncId = 'yesterday-1'
        ..name = 'Вчерашняя запись'
        ..categoryKey = 'work'
        ..startedAt = yesterday.millisecondsSinceEpoch
        ..endedAt = yesterday.millisecondsSinceEpoch + 3600000
        ..durationSeconds = 3600
        ..dateKey = du.DateUtils.dateKey(yesterday);

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(entry);
      });

      final controller = container.read(feedControllerProvider);

      // Шаг 1: переходим на вчера
      await controller.goToPreviousDay();
      expect(container.read(selectedDateProvider), equals(yesterday));

      // Шаг 2: пробуем перейти на позавчера (раньше earliest)
      await controller.goToPreviousDay();
      // Должен остаться на вчера
      expect(container.read(selectedDateProvider), equals(yesterday));
    });

    test('updateEntry, addPhoto, removePhoto и deleteEntry увеличивают entriesChangedProvider', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final entry = ActivityEntry()
        ..syncId = 'e-ctrl-1'
        ..name = 'Активность'
        ..categoryKey = 'work'
        ..startedAt = now - 3600000
        ..endedAt = now
        ..durationSeconds = 3600
        ..dateKey = du.DateUtils.dateKeyFromMillis(now);

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(entry);
      });

      final controller = container.read(feedControllerProvider);
      final initialVersion = container.read(entriesChangedProvider);

      await controller.updateEntry(entry.id, name: 'Обновлённое');
      expect(container.read(entriesChangedProvider), equals(initialVersion + 1));

      await controller.addPhoto(entry.id, 'p1.jpg');
      expect(container.read(entriesChangedProvider), equals(initialVersion + 2));

      await controller.removePhoto(entry.id, 'p1.jpg');
      expect(container.read(entriesChangedProvider), equals(initialVersion + 3));

      await controller.deleteEntry(entry.id);
      expect(container.read(entriesChangedProvider), equals(initialVersion + 4));
    });
  });
}
