import 'package:isar_community/isar.dart';

import '../../timer/domain/models/activity_entry.dart';
import 'dart:math';
import 'package:uuid/uuid.dart';

/// Одна запись-кандидат для карточки "Дневник дня" — со ВСЕМИ её фото
/// (до 4 штук). Какое именно фото показать — выбирает пользователь на
/// экране превью, репозиторий сам ничего не решает за него.
class DayStoryEntry {
  const DayStoryEntry({
    required this.entryId,
    required this.entryName,
    required this.note,
    required this.categoryKey,
    required this.startedAt,
    required this.photoPaths,
  });

  final int entryId;
  final String entryName;
  final String? note;
  final String categoryKey;
  final int startedAt;

  /// Все фото этой записи (1–4 шт.) — выбор конкретного делается в UI.
  final List<String> photoPaths;
}

/// Группа записей одной категории за день (максимум 2 записи) — для сборки
/// "разбросанного полароида" в порядке, в котором категории происходили за день.
class DayStoryCategoryGroup {
  const DayStoryCategoryGroup({
    required this.categoryKey,
    required this.entries,
  });

  final String categoryKey;
  final List<DayStoryEntry> entries;
}

/// Репозиторий Ленты: чтение записей по дате, редактирование, удаление,
/// определение границ доступных дат для навигации ← / →.
class FeedRepository {
  FeedRepository(this._isar);

  final Isar _isar;
  static const _uuid = Uuid();

  /// Записи за конкретный день, отсортированные по времени начала.
  Future<List<ActivityEntry>> getEntriesByDate(String dateKey) {
    return _isar.activityEntrys
        .filter()
        .dateKeyEqualTo(dateKey)
        .isDeletedEqualTo(false)
        .sortByStartedAt()
        .findAll();
  }

  /// Самая ранняя запись в базе — нужна, чтобы ограничить кнопку "←"
  /// (не даём листать в дни, когда ещё не было записей).
  /// Аналог проверки firstDate в app.js (btn-prev-day).
  Future<int?> getEarliestStartedAt() async {
    final earliest = await _isar.activityEntrys
        .filter()
        .isDeletedEqualTo(false)
        .sortByStartedAt()
        .findFirst();
    return earliest?.startedAt;
  }

  Future<void> updateEntry(
    int id, {
    String? name,
    String? categoryKey,
    String? note,
    String? mood,
    List<String>? obstacles,
    String? nextExperiment,
  }) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.activityEntrys.get(id);
      if (entry == null) return;
      if (name != null) entry.name = name;
      if (categoryKey != null) entry.categoryKey = categoryKey;
      if (note != null) entry.note = note;
      if (mood != null) entry.mood = mood;
      if (obstacles != null) entry.obstacles = obstacles;
      if (nextExperiment != null) entry.nextExperiment = nextExperiment;
      entry.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _isar.activityEntrys.put(entry);
    });
  }

  /// Случайная запись с хотя бы одним фото — для секции "Воспоминания"
  /// в Профиле. Полностью случайная при каждом вызове (не стабильная).
  Future<ActivityEntry?> getRandomEntryWithPhoto() async {
    final entries = await _isar.activityEntrys
        .filter()
        .isDeletedEqualTo(false)
        .photoPathsIsNotEmpty()
        .findAll();

    if (entries.isEmpty) return null;

    final random = Random();
    return entries[random.nextInt(entries.length)];
  }

  /// Добавляет путь к фото в список записи (до 4 штук — проверка на UI-стороне).
  Future<void> addPhoto(int id, String photoPath) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.activityEntrys.get(id);
      if (entry == null) return;
      final photos = List<String>.from(entry.photoPaths ?? []);
      photos.add(photoPath);
      entry.photoPaths = photos;
      entry.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _isar.activityEntrys.put(entry);
    });
  }

  /// Убирает путь к фото из списка записи (сам файл на диске удаляется отдельно).
  Future<void> removePhoto(int id, String photoPath) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.activityEntrys.get(id);
      if (entry == null) return;
      final photos = List<String>.from(entry.photoPaths ?? []);
      photos.remove(photoPath);
      entry.photoPaths = photos;
      entry.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _isar.activityEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(int id) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.activityEntrys.get(id);
      if (entry == null) return;
      entry.isDeleted = true;
      entry.updatedAt = DateTime.now().millisecondsSinceEpoch;
      await _isar.activityEntrys.put(entry);
    });
  }

  /// Делит завершённую запись на две непрерывные части, не позволяя изменить
  /// внешние границы исходного интервала.
  Future<ActivityEntry> splitEntry(
    int id, {
    required int splitAt,
    required String firstName,
    required String firstCategoryKey,
    required String secondName,
    required String secondCategoryKey,
  }) async {
    late ActivityEntry second;
    await _isar.writeTxn(() async {
      final original = await _isar.activityEntrys.get(id);
      if (original == null || original.isDeleted) {
        throw StateError('Activity entry not found');
      }
      const minPartMillis = Duration.millisecondsPerMinute;
      if (splitAt - original.startedAt < minPartMillis ||
          original.endedAt - splitAt < minPartMillis) {
        throw ArgumentError('Each split part must be at least one minute');
      }

      final now = DateTime.now().millisecondsSinceEpoch;
      final originalEnd = original.endedAt;
      final totalDurationSeconds = ((originalEnd - original.startedAt) / 1000)
          .floor();
      final firstDurationSeconds = ((splitAt - original.startedAt) / 1000)
          .floor();
      original
        ..name = firstName.trim()
        ..categoryKey = firstCategoryKey
        ..endedAt = splitAt
        ..durationSeconds = firstDurationSeconds
        ..updatedAt = now;

      second = ActivityEntry()
        ..syncId = _uuid.v4()
        ..updatedAt = now
        ..name = secondName.trim()
        ..categoryKey = secondCategoryKey
        ..startedAt = splitAt
        ..endedAt = originalEnd
        ..durationSeconds = totalDurationSeconds - firstDurationSeconds
        ..dateKey = original.dateKey;

      await _isar.activityEntrys.put(original);
      await _isar.activityEntrys.put(second);
    });
    return second;
  }

  /// Все записи с фото, для полного экрана "Воспоминания" — от новых к старым.
  Future<List<ActivityEntry>> getAllEntriesWithPhotos() {
    return _isar.activityEntrys
        .filter()
        .isDeletedEqualTo(false)
        .photoPathsIsNotEmpty()
        .sortByStartedAtDesc()
        .findAll();
  }

  /// Фото дня для "Дневника дня" — сгруппированы по категории (максимум
  /// 2 фото на категорию, из первых по времени записей), категории идут
  /// в порядке первого появления за день (утренняя активность — первая).
  Future<List<DayStoryCategoryGroup>> getDayStoryGroups(String dateKey) async {
    final photoEntries = await _isar.activityEntrys
        .filter()
        .dateKeyEqualTo(dateKey)
        .isDeletedEqualTo(false)
        .photoPathsIsNotEmpty()
        .sortByStartedAt()
        .findAll();

    // Map в Dart сохраняет порядок вставки — благодаря сортировке записей
    // по startedAt выше, первая встреченная запись каждой категории и
    // определяет порядок категорий на карточке.
    final grouped = <String, List<ActivityEntry>>{};
    for (final e in photoEntries) {
      final list = grouped.putIfAbsent(e.categoryKey, () => []);
      if (list.length < 2) list.add(e);
    }

    return [
      for (final group in grouped.entries)
        DayStoryCategoryGroup(
          categoryKey: group.key,
          entries: [
            for (final e in group.value)
              DayStoryEntry(
                entryId: e.id,
                entryName: e.name,
                note: e.note,
                categoryKey: e.categoryKey,
                startedAt: e.startedAt,
                photoPaths: e.photoPaths ?? [],
              ),
          ],
        ),
    ];
  }
}
