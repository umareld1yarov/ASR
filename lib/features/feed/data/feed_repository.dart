import 'package:isar_community/isar.dart';

import '../../timer/domain/models/activity_entry.dart';

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

  Future<void> updateEntry(int id, {String? name, String? categoryKey}) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.activityEntrys.get(id);
      if (entry == null) return;
      if (name != null) entry.name = name;
      if (categoryKey != null) entry.categoryKey = categoryKey;
      await _isar.activityEntrys.put(entry);
    });
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
}
