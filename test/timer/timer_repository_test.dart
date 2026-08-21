import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/core/constants/activity_category.dart';
import 'package:asr/core/utils/date_utils.dart' as du;
import 'package:asr/features/profile/domain/models/goal.dart';
import 'package:asr/features/timer/data/timer_repository.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import 'package:asr/features/timer/domain/models/current_activity.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('TimerRepository', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late TimerRepository repository;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'timer_repo_test');
      isar = dbHandle.isar;
      repository = TimerRepository(isar);
    });

    tearDown(() async {
      await dbHandle.dispose();
    });

    test('getCurrent возвращает null, если активность не запущена', () async {
      final current = await repository.getCurrent();
      expect(current, isNull);
    });

    test('switchActivity устанавливает новую текущую активность', () async {
      await repository.switchActivity(
        name: 'Разработка фичи',
        categoryKey: 'work',
      );

      final current = await repository.getCurrent();
      expect(current, isNotNull);
      expect(current!.name, equals('Разработка фичи'));
      expect(current.categoryKey, equals('work'));
      expect(current.startedAt, isPositive);
    });

    test('активность короче 5 секунд отбрасывается и не создаёт запись в истории', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      // Устанавливаем текущую активность, начатую 2 секунды назад
      final initialCurrent = CurrentActivity()
        ..name = 'Короткий клик'
        ..categoryKey = 'waste'
        ..startedAt = now - 2000;

      await isar.writeTxn(() async {
        await isar.currentActivitys.put(initialCurrent);
      });

      // Переключаем на новую активность
      await repository.switchActivity(
        name: 'Новая задача',
        categoryKey: 'work',
      );

      final entries = await isar.activityEntrys.where().findAll();
      expect(entries, isEmpty);

      final newCurrent = await repository.getCurrent();
      expect(newCurrent?.name, equals('Новая задача'));
    });

    test('активность длительностью 5 секунд и более сохраняется в ActivityEntry', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final initialCurrent = CurrentActivity()
        ..name = 'Программирование'
        ..categoryKey = 'work'
        ..startedAt = now - 60000; // 60 секунд назад

      await isar.writeTxn(() async {
        await isar.currentActivitys.put(initialCurrent);
      });

      await repository.switchActivity(
        name: 'Чтение книги',
        categoryKey: 'growth',
      );

      final entries = await isar.activityEntrys.where().findAll();
      expect(entries.length, equals(1));

      final saved = entries.first;
      expect(saved.name, equals('Программирование'));
      expect(saved.categoryKey, equals('work'));
      expect(saved.durationSeconds, equals(60));
      expect(saved.isDeleted, isFalse);
      expect(saved.syncId, isNotEmpty);
    });

    test('время окончания предыдущей активности и начала новой строго совпадают', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final initialCurrent = CurrentActivity()
        ..name = 'Спорт'
        ..categoryKey = 'sport'
        ..startedAt = now - 1800000; // 30 мин назад

      await isar.writeTxn(() async {
        await isar.currentActivitys.put(initialCurrent);
      });

      await repository.switchActivity(
        name: 'Отдых',
        categoryKey: 'rest',
      );

      final entries = await isar.activityEntrys.where().findAll();
      final finished = entries.first;
      final current = (await repository.getCurrent())!;

      expect(finished.endedAt, equals(current.startedAt));
    });

    test('нарезка по полуночи при смене активности создаёт две записи по разным дням', () async {
      // 2026-08-20 23:00:00 (до полуночи)
      final startDay1 = DateTime(2026, 8, 20, 23, 0, 0).millisecondsSinceEpoch;

      final initialCurrent = CurrentActivity()
        ..name = 'Ночная работа'
        ..categoryKey = 'work'
        ..startedAt = startDay1;

      await isar.writeTxn(() async {
        await isar.currentActivitys.put(initialCurrent);
      });

      // Переключаем активность
      await repository.switchActivity(
        name: 'Утренняя зарядка',
        categoryKey: 'sport',
      );

      final entries = await isar.activityEntrys
          .where()
          .sortByStartedAt()
          .findAll();

      // Должно быть как минимум 2 записи (кусок за 20-е и кусок за 21-е)
      expect(entries.length, greaterThanOrEqualTo(2));

      final firstChunk = entries.first;
      final midnight = du.DateUtils.nextMidnight(
        DateTime.fromMillisecondsSinceEpoch(startDay1),
      ).millisecondsSinceEpoch;

      expect(firstChunk.dateKey, equals('2026-08-20'));
      expect(firstChunk.startedAt, equals(startDay1));
      expect(firstChunk.endedAt, equals(midnight));
      expect(firstChunk.durationSeconds, equals(3600)); // ровно 1 час (23:00 -> 00:00)

      final secondChunk = entries[1];
      expect(secondChunk.startedAt, equals(midnight));
      expect(secondChunk.dateKey, isNot(equals('2026-08-20')));
    });

    test('initializeOnStart нарезает активность, если телефон лежал включённым через полночь', () async {
      // 2026-08-20 23:30:00
      final startedAt = DateTime(2026, 8, 20, 23, 30, 0).millisecondsSinceEpoch;

      final overnightActivity = CurrentActivity()
        ..name = 'Сон / Отдых'
        ..categoryKey = 'rest'
        ..startedAt = startedAt;

      await isar.writeTxn(() async {
        await isar.currentActivitys.put(overnightActivity);
      });

      await repository.initializeOnStart();

      final entries = await isar.activityEntrys.where().findAll();
      expect(entries.isNotEmpty, isTrue);

      final midnight = du.DateUtils.nextMidnight(
        DateTime.fromMillisecondsSinceEpoch(startedAt),
      ).millisecondsSinceEpoch;

      final chunk = entries.first;
      expect(chunk.dateKey, equals('2026-08-20'));
      expect(chunk.endedAt, equals(midnight));
      expect(chunk.durationSeconds, equals(1800)); // 30 минут

      final updatedCurrent = (await repository.getCurrent())!;
      expect(updatedCurrent.name, equals('Сон / Отдых'));
      // Начало текущего куска перенесено на полночь
      expect(updatedCurrent.startedAt, equals(midnight));
    });

    test('getActivitySuggestions агрегирует уникальные названия, частоту и цели', () async {
      // Добавляем исторические записи
      final entry1 = ActivityEntry()
        ..syncId = 's1'
        ..name = 'Бег'
        ..categoryKey = 'sport'
        ..startedAt = 1000
        ..endedAt = 2000
        ..durationSeconds = 1000
        ..dateKey = '2026-08-21';

      final entry2 = ActivityEntry()
        ..syncId = 's2'
        ..name = 'бег' // Другой регистр
        ..categoryKey = 'sport'
        ..startedAt = 3000
        ..endedAt = 4000
        ..durationSeconds = 1000
        ..dateKey = '2026-08-21';

      final entry3 = ActivityEntry()
        ..syncId = 's3'
        ..name = 'Плавание'
        ..categoryKey = 'sport'
        ..startedAt = 5000
        ..endedAt = 6000
        ..durationSeconds = 1000
        ..dateKey = '2026-08-21';

      // Активная цель с именем активности
      final goal = Goal()
        ..categoryKey = 'sport'
        ..activityName = 'Турники'
        ..targetSeconds = 3600
        ..periodType = 'week'
        ..createdAt = 7000;

      await isar.writeTxn(() async {
        await isar.activityEntrys.putAll([entry1, entry2, entry3]);
        await isar.goals.put(goal);
      });

      final suggestions = await repository.getActivitySuggestions('sport');

      // 'бег' встречался дважды, поэтому должен быть на 1 месте с usesCount = 2
      expect(suggestions.length, equals(3));
      expect(suggestions[0].name.toLowerCase(), equals('бег'));
      expect(suggestions[0].usesCount, equals(2));

      final names = suggestions.map((s) => s.name).toList();
      expect(names, contains('Плавание'));
      expect(names, contains('Турники'));
    });

    test('getTodayStats возвращает секунды по всем 9 категориям', () async {
      final stats = await repository.getTodayStats();

      expect(stats.length, equals(9));
      for (final cat in ActivityCategory.values) {
        expect(stats.containsKey(cat.storageKey), isTrue);
        expect(stats[cat.storageKey], equals(0));
      }
    });

    test('getTodayStats суммирует закрытые записи и текущую активность', () async {
      final now = DateTime.now().millisecondsSinceEpoch;
      final today = du.DateUtils.dateKeyFromMillis(now);

      final entry = ActivityEntry()
        ..syncId = 'e1'
        ..name = 'Код'
        ..categoryKey = 'work'
        ..startedAt = now - 7200000
        ..endedAt = now - 3600000
        ..durationSeconds = 3600 // 1 час
        ..dateKey = today;

      final current = CurrentActivity()
        ..name = 'Ещё код'
        ..categoryKey = 'work'
        ..startedAt = now - 60000; // 60 секунд

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(entry);
        await isar.currentActivitys.put(current);
      });

      final stats = await repository.getTodayStats();
      expect(stats['work'], greaterThanOrEqualTo(3660));
    });

    test('updateEntry и deleteEntry корректно обновляют и помечают запись удалённой', () async {
      final entry = ActivityEntry()
        ..syncId = 'edit-1'
        ..name = 'Старое имя'
        ..categoryKey = 'work'
        ..startedAt = 1000
        ..endedAt = 2000
        ..durationSeconds = 1000
        ..dateKey = '2026-08-21';

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(entry);
      });

      await repository.updateEntry(entry.id, name: 'Новое имя', categoryKey: 'growth');
      var updated = (await isar.activityEntrys.get(entry.id))!;
      expect(updated.name, equals('Новое имя'));
      expect(updated.categoryKey, equals('growth'));
      expect(updated.updatedAt, isPositive);

      await repository.deleteEntry(entry.id);
      var deleted = (await isar.activityEntrys.get(entry.id))!;
      expect(deleted.isDeleted, isTrue);
    });
  });
}
