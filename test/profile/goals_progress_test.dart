import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/core/utils/date_utils.dart' as du;
import 'package:asr/features/profile/application/profile_provider.dart';
import 'package:asr/features/profile/domain/models/goal.dart';
import 'package:asr/features/stats/application/stats_provider.dart';
import 'package:asr/features/stats/data/stats_repository.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('goalProgressProvider calculation', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late StatsRepository statsRepository;
    late ProviderContainer container;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'goals_progress_test');
      isar = dbHandle.isar;
      statsRepository = StatsRepository(isar);

      container = ProviderContainer(
        overrides: [
          statsRepositoryProvider.overrideWithValue(statsRepository),
        ],
      );
    });

    tearDown(() async {
      container.dispose();
      await dbHandle.dispose();
    });

    Future<void> insertEntry({
      required String name,
      required String categoryKey,
      required DateTime date,
      required int durationSeconds,
    }) async {
      final entry = ActivityEntry()
        ..syncId = 'sync-${date.millisecondsSinceEpoch}'
        ..name = name
        ..categoryKey = categoryKey
        ..startedAt = date.millisecondsSinceEpoch
        ..endedAt = date.millisecondsSinceEpoch + (durationSeconds * 1000)
        ..durationSeconds = durationSeconds
        ..dateKey = du.DateUtils.dateKey(date);

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(entry);
      });
    }

    test('вычисляет прогресс цели на категорию за текущую неделю', () async {
      final now = DateTime.now();
      final monday = du.DateUtils.startOfWeek(now);
      final lastSunday = monday.subtract(const Duration(days: 1));

      // Запись прошлой недели (не должна учитываться)
      await insertEntry(
        name: 'Прошлый спорт',
        categoryKey: 'sport',
        date: lastSunday,
        durationSeconds: 3600,
      );

      // Запись текущей недели
      await insertEntry(
        name: 'Текущий спорт',
        categoryKey: 'sport',
        date: monday,
        durationSeconds: 1800,
      );

      final goal = Goal()
        ..categoryKey = 'sport'
        ..targetSeconds = 7200
        ..periodType = 'week'
        ..createdAt = monday.millisecondsSinceEpoch;

      final progress = await container.read(goalProgressProvider(goal).future);
      expect(progress, equals(1800));
    });

    test('вычисляет прогресс цели на категорию за текущий месяц', () async {
      final now = DateTime.now();
      final firstDay = du.DateUtils.startOfMonth(now);
      final prevMonthDay = firstDay.subtract(const Duration(days: 1));

      // Запись прошлого месяца
      await insertEntry(
        name: 'Прошлая работа',
        categoryKey: 'work',
        date: prevMonthDay,
        durationSeconds: 10000,
      );

      // Запись текущего месяца
      await insertEntry(
        name: 'Работа в этом месяце',
        categoryKey: 'work',
        date: firstDay,
        durationSeconds: 5000,
      );

      final goal = Goal()
        ..categoryKey = 'work'
        ..targetSeconds = 50000
        ..periodType = 'month'
        ..createdAt = firstDay.millisecondsSinceEpoch;

      final progress = await container.read(goalProgressProvider(goal).future);
      expect(progress, equals(5000));
    });

    test('фильтрует прогресс по точному названию активности без учёта регистра и пробелов', () async {
      final now = DateTime.now();

      // Целевая активность
      await insertEntry(
        name: '  Таджвид  ',
        categoryKey: 'religion',
        date: now,
        durationSeconds: 1800,
      );
      await insertEntry(
        name: 'таджвид',
        categoryKey: 'religion',
        date: now,
        durationSeconds: 1200,
      );
      // Другая активность в той же категории
      await insertEntry(
        name: 'Намаз',
        categoryKey: 'religion',
        date: now,
        durationSeconds: 900,
      );

      final goal = Goal()
        ..categoryKey = 'religion'
        ..activityName = 'Таджвид'
        ..targetSeconds = 7200
        ..periodType = 'month'
        ..createdAt = now.millisecondsSinceEpoch;

      final progress = await container.read(goalProgressProvider(goal).future);
      // 1800 + 1200 = 3000 (Намаз не должен войти)
      expect(progress, equals(3000));
    });
  });
}
