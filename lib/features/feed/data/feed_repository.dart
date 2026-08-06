import 'package:isar_community/isar.dart';

import '../../timer/domain/models/activity_entry.dart';
import 'dart:math';

/// Репозиторий Ленты: чтение записей по дате, редактирование, удаление,
/// определение границ доступных дат для навигации ← / →.
class FeedRepository {
  FeedRepository(this._isar);

  final Isar _isar;

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
      await _isar.activityEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(int id) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.activityEntrys.get(id);
      if (entry == null) return;
      entry.isDeleted = true;
      await _isar.activityEntrys.put(entry);
    });
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
}
