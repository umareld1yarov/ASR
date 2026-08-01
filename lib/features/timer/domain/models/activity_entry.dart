import 'package:isar_community/isar.dart';

part 'activity_entry.g.dart';

/// Завершённая активность — то, что попадает в Ленту.
/// Аналог таблицы `entries` из PWA-версии (storage.js).
@collection
class ActivityEntry {
  Id id = Isar.autoIncrement;

  /// Название активности, введённое пользователем (например "Пишу код")
  late String name;

  /// Категория хранится строкой — см. ActivityCategory.storageKey
  late String categoryKey;

  /// Начало активности (epoch millis)
  late int startedAt;

  /// Конец активности (epoch millis) — всегда заполнен, т.к. это уже закрытая запись
  late int endedAt;

  /// Длительность в секундах — считается один раз при закрытии, чтобы не пересчитывать на лету
  late int durationSeconds;

  /// Ключ дня в формате YYYY-MM-DD — нужен для быстрой выборки по дате (индекс)
  @Index()
  late String dateKey;

  /// Мягкое удаление — на будущее, если понадобится синхронизация
  bool isDeleted = false;
}
