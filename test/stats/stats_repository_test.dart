import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/core/constants/activity_category.dart';
import 'package:asr/core/utils/date_utils.dart' as du;
import 'package:asr/features/stats/data/stats_repository.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('StatsRepository', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late StatsRepository repository;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'stats_repo_test');
      isar = dbHandle.isar;
      repository = StatsRepository(isar);
    });

    tearDown(() async {
      await dbHandle.dispose();
    });

    Future<ActivityEntry> insertEntry({
      required String name,
      required String categoryKey,
      required int startedAt,
      required int durationSeconds,
      required String dateKey,
      bool isDeleted = false,
      String? note,
      List<String>? photoPaths,
    }) async {
      final entry = ActivityEntry()
        ..syncId = 'sync-$startedAt'
        ..updatedAt = startedAt
        ..name = name
        ..categoryKey = categoryKey
        ..startedAt = startedAt
        ..endedAt = startedAt + (durationSeconds * 1000)
        ..durationSeconds = durationSeconds
        ..dateKey = dateKey
        ..isDeleted = isDeleted
        ..note = note
        ..photoPaths = photoPaths;

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(entry);
      });
      return entry;
    }

    test('getCategoryBreakdown возвращает все 9 категорий с нулями при пустой базе', () async {
      final breakdown = await repository.getCategoryBreakdown(
        startDateKey: '2026-08-01',
        endDateKey: '2026-08-21',
      );

      expect(breakdown.length, equals(9));
      for (final cat in ActivityCategory.values) {
        expect(breakdown[cat.storageKey], equals(0));
      }
    });

    test('getCategoryBreakdown суммирует длительности и исключает удалённые записи', () async {
      await insertEntry(
        name: 'Код 1',
        categoryKey: 'work',
        startedAt: 1000,
        durationSeconds: 3600, // 1 час
        dateKey: '2026-08-20',
      );
      await insertEntry(
        name: 'Код 2',
        categoryKey: 'work',
        startedAt: 5000,
        durationSeconds: 1800, // 30 мин
        dateKey: '2026-08-21',
      );
      await insertEntry(
        name: 'Удалённый спорт',
        categoryKey: 'sport',
        startedAt: 8000,
        durationSeconds: 3600,
        dateKey: '2026-08-21',
        isDeleted: true,
      );
      await insertEntry(
        name: 'Чтение',
        categoryKey: 'growth',
        startedAt: 12000,
        durationSeconds: 1200, // 20 мин
        dateKey: '2026-08-21',
      );

      final breakdown = await repository.getCategoryBreakdown(
        startDateKey: '2026-08-20',
        endDateKey: '2026-08-21',
      );

      expect(breakdown['work'], equals(5400));
      expect(breakdown['growth'], equals(1200));
      expect(breakdown['sport'], equals(0)); // удалённая запись не учтена
      expect(breakdown['rest'], equals(0));
    });

    test('getActivityBreakdownForCategory группирует дела и сортирует по убыванию секунд', () async {
      await insertEntry(
        name: 'Бег',
        categoryKey: 'sport',
        startedAt: 1000,
        durationSeconds: 1800,
        dateKey: '2026-08-21',
      );
      await insertEntry(
        name: 'Турники',
        categoryKey: 'sport',
        startedAt: 3000,
        durationSeconds: 3600,
        dateKey: '2026-08-21',
      );
      await insertEntry(
        name: 'Бег',
        categoryKey: 'sport',
        startedAt: 7000,
        durationSeconds: 1800,
        dateKey: '2026-08-21',
      );
      // Другая категория не должна попасть
      await insertEntry(
        name: 'Чтение',
        categoryKey: 'growth',
        startedAt: 10000,
        durationSeconds: 5000,
        dateKey: '2026-08-21',
      );

      final breakdown = await repository.getActivityBreakdownForCategory(
        categoryKey: 'sport',
        startDateKey: '2026-08-20',
        endDateKey: '2026-08-21',
      );

      // Турники: 3600, Бег: 1800 + 1800 = 3600
      expect(breakdown.length, equals(2));
      expect(breakdown.containsKey('Чтение'), isFalse);
      expect(breakdown['Бег'], equals(3600));
      expect(breakdown['Турники'], equals(3600));
    });

    test('getPeriodSessionSummary вычисляет количество сессий и среднюю длительность', () async {
      final emptySummary = await repository.getPeriodSessionSummary(
        startDateKey: '2026-08-01',
        endDateKey: '2026-08-21',
      );
      expect(emptySummary.totalSessions, equals(0));
      expect(emptySummary.averageSeconds, equals(0));

      await insertEntry(
        name: 'Сессия 1',
        categoryKey: 'work',
        startedAt: 1000,
        durationSeconds: 1200, // 20 мин
        dateKey: '2026-08-21',
      );
      await insertEntry(
        name: 'Сессия 2',
        categoryKey: 'work',
        startedAt: 3000,
        durationSeconds: 2400, // 40 мин
        dateKey: '2026-08-21',
      );

      final summary = await repository.getPeriodSessionSummary(
        startDateKey: '2026-08-21',
        endDateKey: '2026-08-21',
      );
      expect(summary.totalSessions, equals(2));
      expect(summary.averageSeconds, equals(1800)); // (1200 + 2400) / 2 = 1800
    });

    test('getCategoryDailyTotals заполняет дни без записей нулевыми значениями', () async {
      // Запись только 2026-08-10
      await insertEntry(
        name: 'Работа',
        categoryKey: 'work',
        startedAt: 1000,
        durationSeconds: 3600,
        dateKey: '2026-08-10',
      );

      // Диапазон с 2026-08-10 по 2026-08-12 (3 дня)
      final dailyTotals = await repository.getCategoryDailyTotals(
        startDateKey: '2026-08-10',
        endDateKey: '2026-08-12',
      );

      expect(dailyTotals.length, equals(3));
      expect(dailyTotals['2026-08-10']!['work'], equals(3600));
      expect(dailyTotals['2026-08-11']!['work'], equals(0));
      expect(dailyTotals['2026-08-12']!['work'], equals(0));
    });

    test('getOverallStreak считает непрерывный стрик от сегодняшнего дня назад', () async {
      final now = DateTime.now();
      final todayKey = du.DateUtils.dateKey(now);
      final yesterdayKey = du.DateUtils.dateKey(now.subtract(const Duration(days: 1)));
      final twoDaysAgoKey = du.DateUtils.dateKey(now.subtract(const Duration(days: 2)));
      final fourDaysAgoKey = du.DateUtils.dateKey(now.subtract(const Duration(days: 4)));

      // Сегодня, вчера и 2 дня назад (стрик 3 дня), 3 дня назад - пропуск, 4 дня назад - активность
      await insertEntry(
        name: 'Сегодня',
        categoryKey: 'work',
        startedAt: now.millisecondsSinceEpoch - 3600000,
        durationSeconds: 3600,
        dateKey: todayKey,
      );
      await insertEntry(
        name: 'Вчера',
        categoryKey: 'sport',
        startedAt: now.millisecondsSinceEpoch - 90000000,
        durationSeconds: 1800,
        dateKey: yesterdayKey,
      );
      await insertEntry(
        name: '2 дня назад',
        categoryKey: 'growth',
        startedAt: now.millisecondsSinceEpoch - 180000000,
        durationSeconds: 2400,
        dateKey: twoDaysAgoKey,
      );
      await insertEntry(
        name: '4 дня назад',
        categoryKey: 'work',
        startedAt: now.millisecondsSinceEpoch - 350000000,
        durationSeconds: 3600,
        dateKey: fourDaysAgoKey,
      );

      final streak = await repository.getOverallStreak();
      expect(streak, equals(3));
    });

    test('getLifetimeJourneyStats точно агрегирует время, активности, заметки, фото и дни', () async {
      final emptyStats = await repository.getLifetimeJourneyStats();
      expect(emptyStats.totalSeconds, equals(0));
      expect(emptyStats.totalActivities, equals(0));
      expect(emptyStats.totalNotes, equals(0));
      expect(emptyStats.totalPhotos, equals(0));
      expect(emptyStats.daysSinceStart, equals(0));

      final now = DateTime.now();
      final threeDaysAgo = now.subtract(const Duration(days: 3));

      await insertEntry(
        name: 'Первая активность 3 дня назад',
        categoryKey: 'work',
        startedAt: threeDaysAgo.millisecondsSinceEpoch,
        durationSeconds: 3600,
        dateKey: du.DateUtils.dateKey(threeDaysAgo),
        note: 'Заметка 1',
        photoPaths: ['p1.jpg', 'p2.jpg'],
      );

      await insertEntry(
        name: 'Вторая активность сегодня',
        categoryKey: 'sport',
        startedAt: now.millisecondsSinceEpoch,
        durationSeconds: 1800,
        dateKey: du.DateUtils.dateKey(now),
        note: null,
        photoPaths: ['p3.jpg'],
      );

      final stats = await repository.getLifetimeJourneyStats();
      expect(stats.totalSeconds, equals(5400));
      expect(stats.totalActivities, equals(2));
      expect(stats.totalNotes, equals(1));
      expect(stats.totalPhotos, equals(3));
      expect(stats.daysSinceStart, equals(4)); // 3 дня разницы + 1 (включая сегодня)
    });
  });
}
