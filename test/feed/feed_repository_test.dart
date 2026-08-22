import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/features/feed/data/feed_repository.dart';
import 'package:asr/features/timer/domain/models/activity_entry.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('FeedRepository', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late FeedRepository repository;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'feed_repo_test');
      isar = dbHandle.isar;
      repository = FeedRepository(isar);
    });

    tearDown(() async {
      await dbHandle.dispose();
    });

    Future<ActivityEntry> insertEntry({
      required String name,
      required String categoryKey,
      required int startedAt,
      required int endedAt,
      required String dateKey,
      bool isDeleted = false,
      String? note,
      List<String>? photoPaths,
      String? mood,
      List<String>? obstacles,
      String? nextExperiment,
    }) async {
      final entry = ActivityEntry()
        ..syncId = 'sync-$startedAt'
        ..updatedAt = startedAt
        ..name = name
        ..categoryKey = categoryKey
        ..startedAt = startedAt
        ..endedAt = endedAt
        ..durationSeconds = ((endedAt - startedAt) / 1000).floor()
        ..dateKey = dateKey
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

    test(
      'getEntriesByDate возвращает только записи за запрошенный день',
      () async {
        await insertEntry(
          name: 'День 1',
          categoryKey: 'work',
          startedAt: 1000,
          endedAt: 2000,
          dateKey: '2026-08-21',
        );
        await insertEntry(
          name: 'День 2',
          categoryKey: 'rest',
          startedAt: 3000,
          endedAt: 4000,
          dateKey: '2026-08-22',
        );

        final entries = await repository.getEntriesByDate('2026-08-21');
        expect(entries.length, equals(1));
        expect(entries.first.name, equals('День 1'));
      },
    );

    test(
      'getEntriesByDate сортирует записи по времени начала (startedAt)',
      () async {
        await insertEntry(
          name: 'Вторая активность',
          categoryKey: 'work',
          startedAt: 5000,
          endedAt: 6000,
          dateKey: '2026-08-21',
        );
        await insertEntry(
          name: 'Первая активность',
          categoryKey: 'sport',
          startedAt: 1000,
          endedAt: 2000,
          dateKey: '2026-08-21',
        );

        final entries = await repository.getEntriesByDate('2026-08-21');
        expect(entries.length, equals(2));
        expect(entries[0].name, equals('Первая активность'));
        expect(entries[1].name, equals('Вторая активность'));
      },
    );

    test('getEntriesByDate исключает мягко удалённые записи', () async {
      await insertEntry(
        name: 'Активная',
        categoryKey: 'work',
        startedAt: 1000,
        endedAt: 2000,
        dateKey: '2026-08-21',
        isDeleted: false,
      );
      await insertEntry(
        name: 'Удалённая',
        categoryKey: 'rest',
        startedAt: 3000,
        endedAt: 4000,
        dateKey: '2026-08-21',
        isDeleted: true,
      );

      final entries = await repository.getEntriesByDate('2026-08-21');
      expect(entries.length, equals(1));
      expect(entries.first.name, equals('Активная'));
    });

    test(
      'getEarliestStartedAt возвращает самое раннее время начала среди неудалённых записей',
      () async {
        expect(await repository.getEarliestStartedAt(), isNull);

        await insertEntry(
          name: 'Удалённая самая ранняя',
          categoryKey: 'work',
          startedAt: 500,
          endedAt: 1000,
          dateKey: '2026-08-20',
          isDeleted: true,
        );
        await insertEntry(
          name: 'Первая активная',
          categoryKey: 'sport',
          startedAt: 2000,
          endedAt: 3000,
          dateKey: '2026-08-21',
        );
        await insertEntry(
          name: 'Вторая активная',
          categoryKey: 'growth',
          startedAt: 5000,
          endedAt: 6000,
          dateKey: '2026-08-21',
        );

        final earliest = await repository.getEarliestStartedAt();
        expect(earliest, equals(2000));
      },
    );

    test(
      'updateEntry обновляет имя, категорию, заметки, mood, obstacles и nextExperiment',
      () async {
        final entry = await insertEntry(
          name: 'Старое имя',
          categoryKey: 'work',
          startedAt: 1000,
          endedAt: 2000,
          dateKey: '2026-08-21',
        );

        await repository.updateEntry(
          entry.id,
          name: 'Новое имя',
          categoryKey: 'growth',
          note: 'Новая заметка',
          mood: 'good',
          obstacles: ['scattered_thoughts'],
          nextExperiment: 'Фокусироваться на одной задаче',
        );

        final updated = (await isar.activityEntrys.get(entry.id))!;
        expect(updated.name, equals('Новое имя'));
        expect(updated.categoryKey, equals('growth'));
        expect(updated.note, equals('Новая заметка'));
        expect(updated.mood, equals('good'));
        expect(updated.obstacles, equals(['scattered_thoughts']));
        expect(
          updated.nextExperiment,
          equals('Фокусироваться на одной задаче'),
        );
        expect(updated.updatedAt, isPositive);
      },
    );

    test(
      'updateEntry не изменяет защищённые временные границы (startedAt, endedAt, durationSeconds)',
      () async {
        final entry = await insertEntry(
          name: 'Задача',
          categoryKey: 'work',
          startedAt: 10000,
          endedAt: 25000,
          dateKey: '2026-08-21',
        );

        await repository.updateEntry(
          entry.id,
          name: 'Изменённая задача',
          categoryKey: 'sport',
        );

        final updated = (await isar.activityEntrys.get(entry.id))!;
        expect(updated.startedAt, equals(10000));
        expect(updated.endedAt, equals(25000));
        expect(updated.durationSeconds, equals(15));
      },
    );

    test(
      'deleteEntry устанавливает isDeleted в true и обновляет updatedAt',
      () async {
        final entry = await insertEntry(
          name: 'К удалению',
          categoryKey: 'waste',
          startedAt: 1000,
          endedAt: 2000,
          dateKey: '2026-08-21',
        );

        await repository.deleteEntry(entry.id);

        final deleted = (await isar.activityEntrys.get(entry.id))!;
        expect(deleted.isDeleted, isTrue);
        expect(deleted.updatedAt, isPositive);
      },
    );

    test(
      'addPhoto и removePhoto корректно управляют списком путей к фото',
      () async {
        final entry = await insertEntry(
          name: 'С фото',
          categoryKey: 'family',
          startedAt: 1000,
          endedAt: 2000,
          dateKey: '2026-08-21',
        );

        await repository.addPhoto(entry.id, 'photo_1.jpg');
        await repository.addPhoto(entry.id, 'photo_2.jpg');

        var current = (await isar.activityEntrys.get(entry.id))!;
        expect(current.photoPaths, equals(['photo_1.jpg', 'photo_2.jpg']));

        await repository.removePhoto(entry.id, 'photo_1.jpg');

        current = (await isar.activityEntrys.get(entry.id))!;
        expect(current.photoPaths, equals(['photo_2.jpg']));
        expect(current.pendingPhotoDeleteUrls, isNull);
      },
    );

    test(
      'removePhoto ставит облачную ссылку в очередь физического удаления',
      () async {
        const remoteUrl =
            'https://example.supabase.co/storage/v1/object/public/activity_photos/user-a/photo.jpg';
        final entry = await insertEntry(
          name: 'Облачное фото',
          categoryKey: 'family',
          startedAt: 1000,
          endedAt: 2000,
          dateKey: '2026-08-21',
          photoPaths: [remoteUrl],
        );

        await repository.removePhoto(entry.id, remoteUrl);
        await repository.removePhoto(entry.id, remoteUrl);

        final current = (await isar.activityEntrys.get(entry.id))!;
        expect(current.photoPaths, isEmpty);
        expect(current.pendingPhotoDeleteUrls, [remoteUrl]);
      },
    );

    test(
      'getRandomEntryWithPhoto и getAllEntriesWithPhotos выбирают только неудалённые записи с фото',
      () async {
        expect(await repository.getRandomEntryWithPhoto(), isNull);
        expect(await repository.getAllEntriesWithPhotos(), isEmpty);

        await insertEntry(
          name: 'Без фото',
          categoryKey: 'work',
          startedAt: 1000,
          endedAt: 2000,
          dateKey: '2026-08-21',
        );
        await insertEntry(
          name: 'Удалённая с фото',
          categoryKey: 'rest',
          startedAt: 3000,
          endedAt: 4000,
          dateKey: '2026-08-21',
          isDeleted: true,
          photoPaths: ['deleted.jpg'],
        );
        final activeWithPhoto = await insertEntry(
          name: 'Активная с фото',
          categoryKey: 'family',
          startedAt: 5000,
          endedAt: 6000,
          dateKey: '2026-08-21',
          photoPaths: ['active.jpg'],
        );

        final random = await repository.getRandomEntryWithPhoto();
        expect(random, isNotNull);
        expect(random!.id, equals(activeWithPhoto.id));

        final allPhotos = await repository.getAllEntriesWithPhotos();
        expect(allPhotos.length, equals(1));
        expect(allPhotos.first.id, equals(activeWithPhoto.id));
      },
    );

    test(
      'getDayStoryGroups группирует максимум 2 записи на категорию в хронологическом порядке появления',
      () async {
        // 1-я категория за день: work (3 записи с фото)
        await insertEntry(
          name: 'Работа 1',
          categoryKey: 'work',
          startedAt: 1000,
          endedAt: 2000,
          dateKey: '2026-08-21',
          photoPaths: ['w1.jpg'],
        );
        await insertEntry(
          name: 'Работа 2',
          categoryKey: 'work',
          startedAt: 3000,
          endedAt: 4000,
          dateKey: '2026-08-21',
          photoPaths: ['w2.jpg'],
        );
        await insertEntry(
          name: 'Работа 3',
          categoryKey: 'work',
          startedAt: 5000,
          endedAt: 6000,
          dateKey: '2026-08-21',
          photoPaths: ['w3.jpg'],
        );

        // 2-я категория за день: sport (1 запись с фото)
        await insertEntry(
          name: 'Спорт 1',
          categoryKey: 'sport',
          startedAt: 7000,
          endedAt: 8000,
          dateKey: '2026-08-21',
          photoPaths: ['s1.jpg'],
        );

        final groups = await repository.getDayStoryGroups('2026-08-21');
        expect(groups.length, equals(2));

        // Порядок категорий: work, затем sport
        expect(groups[0].categoryKey, equals('work'));
        // Максимум 2 записи для категории
        expect(groups[0].entries.length, equals(2));
        expect(groups[0].entries[0].entryName, equals('Работа 1'));
        expect(groups[0].entries[1].entryName, equals('Работа 2'));

        expect(groups[1].categoryKey, equals('sport'));
        expect(groups[1].entries.length, equals(1));
        expect(groups[1].entries[0].entryName, equals('Спорт 1'));
      },
    );
  });
}
