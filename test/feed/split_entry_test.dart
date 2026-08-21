import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/features/feed/data/feed_repository.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('FeedRepository.splitEntry', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late FeedRepository repository;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'split_entry_test');
      isar = dbHandle.isar;
      repository = FeedRepository(isar);
    });

    tearDown(() async {
      await dbHandle.dispose();
    });

    Future<ActivityEntry> createSampleEntry({
      int startedAt = 1000000000000,
      int endedAt = 1000003600000, // 1 час (3600 сек)
      bool isDeleted = false,
      String name = 'Исходная работа',
      String categoryKey = 'work',
      String? note = 'Важная заметка',
      List<String>? photoPaths = const ['path/to/photo1.jpg', 'path/to/photo2.jpg'],
      String? mood = 'fire',
      List<String>? obstacles = const ['phone'],
      String? nextExperiment = 'Попробовать без уведомлений',
      String syncId = 'orig-uuid-1234',
    }) async {
      final entry = ActivityEntry()
        ..syncId = syncId
        ..updatedAt = startedAt
        ..name = name
        ..categoryKey = categoryKey
        ..startedAt = startedAt
        ..endedAt = endedAt
        ..durationSeconds = ((endedAt - startedAt) / 1000).floor()
        ..dateKey = '2026-08-21'
        ..isDeleted = isDeleted
        ..note = note
        ..photoPaths = photoPaths != null ? List<String>.from(photoPaths) : null
        ..mood = mood
        ..obstacles = obstacles != null ? List<String>.from(obstacles) : null
        ..nextExperiment = nextExperiment;

      await isar.writeTxn(() async {
        await isar.activityEntrys.put(entry);
      });
      return entry;
    }

    test('разделение создаёт две записи в базе данных', () async {
      final original = await createSampleEntry();
      final splitAt = original.startedAt + 1800000; // 30 минут

      await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      final allEntries = await isar.activityEntrys.where().findAll();
      expect(allEntries.length, equals(2));
    });

    test('общая длительность после разделения сохраняется неизменной', () async {
      final original = await createSampleEntry();
      final originalDuration = original.durationSeconds;
      final splitAt = original.startedAt + 1200000; // 20 минут

      final secondPart = await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      final firstPart = (await isar.activityEntrys.get(original.id))!;
      expect(firstPart.durationSeconds + secondPart.durationSeconds, equals(originalDuration));
    });

    test('отсутствует разрыв во времени между первой и второй частью', () async {
      final original = await createSampleEntry();
      final splitAt = original.startedAt + 900000; // 15 минут

      final secondPart = await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      final firstPart = (await isar.activityEntrys.get(original.id))!;
      expect(firstPart.endedAt, equals(splitAt));
      expect(secondPart.startedAt, equals(splitAt));
      expect(firstPart.endedAt, equals(secondPart.startedAt));
    });

    test('отсутствует пересечение интервалов частей', () async {
      final original = await createSampleEntry();
      final splitAt = original.startedAt + 1500000; // 25 минут

      final secondPart = await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      final firstPart = (await isar.activityEntrys.get(original.id))!;
      expect(firstPart.endedAt <= secondPart.startedAt, isTrue);
    });

    test('начало первой записи остаётся идентичным исходному началу', () async {
      final original = await createSampleEntry();
      final originalStart = original.startedAt;
      final splitAt = original.startedAt + 1800000;

      await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      final firstPart = (await isar.activityEntrys.get(original.id))!;
      expect(firstPart.startedAt, equals(originalStart));
    });

    test('конец второй записи остаётся идентичным исходному концу', () async {
      final original = await createSampleEntry();
      final originalEnd = original.endedAt;
      final splitAt = original.startedAt + 1800000;

      final secondPart = await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      expect(secondPart.endedAt, equals(originalEnd));
    });

    test('длительности первой и второй части рассчитываются точно в секундах', () async {
      final original = await createSampleEntry();
      final splitAt = original.startedAt + 1800000; // 30 минут (1800 секунд)

      final secondPart = await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      final firstPart = (await isar.activityEntrys.get(original.id))!;
      expect(firstPart.durationSeconds, equals(1800));
      expect(secondPart.durationSeconds, equals(1800));
    });

    test('первая и вторая записи получают различные syncId UUID', () async {
      final original = await createSampleEntry(syncId: 'unique-orig-id');
      final splitAt = original.startedAt + 1800000;

      final secondPart = await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      final firstPart = (await isar.activityEntrys.get(original.id))!;
      expect(firstPart.syncId, equals('unique-orig-id'));
      expect(secondPart.syncId, isNotEmpty);
      expect(secondPart.syncId, isNot(equals(firstPart.syncId)));
    });

    test('заметки, фото, mood, obstacles и nextExperiment сохраняются у первой записи', () async {
      final original = await createSampleEntry(
        note: 'Заметка 1',
        photoPaths: ['photo_a.jpg', 'photo_b.jpg'],
        mood: 'fire',
        obstacles: ['distracted'],
        nextExperiment: 'Отключить звук',
      );
      final splitAt = original.startedAt + 1800000;

      await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      final firstPart = (await isar.activityEntrys.get(original.id))!;
      expect(firstPart.note, equals('Заметка 1'));
      expect(firstPart.photoPaths, equals(['photo_a.jpg', 'photo_b.jpg']));
      expect(firstPart.mood, equals('fire'));
      expect(firstPart.obstacles, equals(['distracted']));
      expect(firstPart.nextExperiment, equals('Отключить звук'));
    });

    test('вторая запись создаётся чистой: без заметок, фото и ревью настроения', () async {
      final original = await createSampleEntry(
        note: 'Заметка 1',
        photoPaths: ['photo_a.jpg'],
        mood: 'bad',
        obstacles: ['tired'],
        nextExperiment: 'Лечь спать раньше',
      );
      final splitAt = original.startedAt + 1800000;

      final secondPart = await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: 'Часть 1',
        firstCategoryKey: 'work',
        secondName: 'Часть 2',
        secondCategoryKey: 'growth',
      );

      expect(secondPart.note, isNull);
      expect(secondPart.photoPaths, isNull);
      expect(secondPart.mood, isNull);
      expect(secondPart.obstacles, isNull);
      expect(secondPart.nextExperiment, isNull);
    });

    test('названия и категории корректно обновляются для обеих частей', () async {
      final original = await createSampleEntry(
        name: 'Исходное имя',
        categoryKey: 'work',
      );
      final splitAt = original.startedAt + 1800000;

      final secondPart = await repository.splitEntry(
        original.id,
        splitAt: splitAt,
        firstName: '  Новая часть 1  ',
        firstCategoryKey: 'sport',
        secondName: '  Новая часть 2  ',
        secondCategoryKey: 'family',
      );

      final firstPart = (await isar.activityEntrys.get(original.id))!;
      expect(firstPart.name, equals('Новая часть 1'));
      expect(firstPart.categoryKey, equals('sport'));
      expect(secondPart.name, equals('Новая часть 2'));
      expect(secondPart.categoryKey, equals('family'));
    });

    test('запрет разделения, если первая часть короче одной минуты', () async {
      final original = await createSampleEntry();
      final splitAt = original.startedAt + 30000; // 30 секунд

      expect(
        () => repository.splitEntry(
          original.id,
          splitAt: splitAt,
          firstName: 'Часть 1',
          firstCategoryKey: 'work',
          secondName: 'Часть 2',
          secondCategoryKey: 'growth',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('запрет разделения, если вторая часть короче одной минуты', () async {
      final original = await createSampleEntry();
      final splitAt = original.endedAt - 30000; // 30 секунд до конца

      expect(
        () => repository.splitEntry(
          original.id,
          splitAt: splitAt,
          firstName: 'Часть 1',
          firstCategoryKey: 'work',
          secondName: 'Часть 2',
          secondCategoryKey: 'growth',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('невозможно разделить мягко удалённую запись', () async {
      final original = await createSampleEntry(isDeleted: true);
      final splitAt = original.startedAt + 1800000;

      expect(
        () => repository.splitEntry(
          original.id,
          splitAt: splitAt,
          firstName: 'Часть 1',
          firstCategoryKey: 'work',
          secondName: 'Часть 2',
          secondCategoryKey: 'growth',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('невозможно разделить несуществующую запись', () async {
      expect(
        () => repository.splitEntry(
          999999,
          splitAt: 1000001800000,
          firstName: 'Часть 1',
          firstCategoryKey: 'work',
          secondName: 'Часть 2',
          secondCategoryKey: 'growth',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('атомарность: при ошибке валидации исходная запись остаётся без изменений', () async {
      final original = await createSampleEntry(
        name: 'Исходная запись до сбоя',
        categoryKey: 'work',
      );
      final invalidSplitAt = original.startedAt + 10000; // 10 секунд (невалидно)

      try {
        await repository.splitEntry(
          original.id,
          splitAt: invalidSplitAt,
          firstName: 'Новое имя',
          firstCategoryKey: 'sport',
          secondName: 'Вторая часть',
          secondCategoryKey: 'growth',
        );
      } catch (_) {
        // Ожидаем исключение
      }

      final unchanged = (await isar.activityEntrys.get(original.id))!;
      expect(unchanged.name, equals('Исходная запись до сбоя'));
      expect(unchanged.categoryKey, equals('work'));
      expect(unchanged.endedAt, equals(original.endedAt));

      final allEntries = await isar.activityEntrys.where().findAll();
      expect(allEntries.length, equals(1));
    });
  });
}
