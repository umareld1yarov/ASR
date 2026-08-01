import 'package:isar_community/isar.dart';

part 'current_activity.g.dart';

/// Текущая незавершённая активность — ровно одна запись в базе.
/// Аналог current_activity из settings в PWA (storage.js: getCurrent/setCurrent).
@collection
class CurrentActivity {
  /// Фиксированный id — гарантирует, что в базе всегда только одна запись.
  Id id = 0;

  late String name;
  late String categoryKey;

  /// Момент старта текущей активности (epoch millis)
  late int startedAt;
}
