import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/core/constants/activity_category.dart';
import 'package:asr/core/utils/date_utils.dart' as du;
import 'package:asr/features/profile/application/milestones_provider.dart';
import 'package:asr/features/stats/application/stats_provider.dart';
import 'package:asr/features/stats/data/stats_repository.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('milestonesProvider', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late StatsRepository statsRepository;
    late ProviderContainer container;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'milestones_test');
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
      required String categoryKey,
      required int hours,
    }) async {
      final now = DateTime.now();
      final entry = ActivityEntry()
        ..syncId = 'sync-${now.microsecondsSinceEpoch}'
        ..name = 'Тест'
        ..categoryKey = categoryKey
        ..startedAt = now.millisecondsSinceEpoch - (hours * 3600000)
        ..endedAt = now.millisecondsSinceEpoch
        ..durationSeconds = hours * 3600
        ..dateKey = du.DateUtils.dateKey(now);

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(entry);
      });
    }

    test('при пустой базе все milestones заблокированы, прогресс равен 0', () async {
      final milestones = await container.read(milestonesProvider.future);

      expect(milestones.isNotEmpty, isTrue);
      for (final m in milestones) {
        expect(m.isUnlocked, isFalse);
        expect(m.currentProgress, equals(0));
        expect(m.ratio, equals(0.0));
      }
    });

    test('first_step разблокируется при первой завершённой активности', () async {
      await insertEntry(categoryKey: 'rest', hours: 1);

      final milestones = await container.read(milestonesProvider.future);
      final firstStep = milestones.firstWhere((m) => m.id == 'first_step');

      expect(firstStep.isUnlocked, isTrue);
      expect(firstStep.currentProgress, equals(1));
      expect(firstStep.ratio, equals(1.0));
    });

    test('разблокирует часовые milestones по категориям и рассчитывает ratio', () async {
      // 6 часов роста (откроет growth_5h, но не growth_25h)
      await insertEntry(categoryKey: ActivityCategory.growth.storageKey, hours: 6);
      // 21 час работы (откроет work_20h)
      await insertEntry(categoryKey: ActivityCategory.work.storageKey, hours: 21);

      final milestones = await container.read(milestonesProvider.future);

      final growth5 = milestones.firstWhere((m) => m.id == 'growth_5h');
      expect(growth5.isUnlocked, isTrue);
      expect(growth5.currentProgress, equals(6));
      expect(growth5.ratio, equals(1.0)); // зажато до 1.0

      final growth25 = milestones.firstWhere((m) => m.id == 'growth_25h');
      expect(growth25.isUnlocked, isFalse);
      expect(growth25.currentProgress, equals(6));
      expect(growth25.ratio, closeTo(6 / 25, 0.001));

      final work20 = milestones.firstWhere((m) => m.id == 'work_20h');
      expect(work20.isUnlocked, isTrue);
      expect(work20.currentProgress, equals(21));
    });
  });
}
