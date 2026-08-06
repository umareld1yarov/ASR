import 'package:isar_community/isar.dart';

part 'goal.g.dart';

/// Цель, привязанная к категории — например "20 часов испанского в месяц".
/// Прогресс НЕ хранится здесь — считается на лету из ActivityEntry
/// за текущий период (неделя/месяц/всё время).
@collection
class Goal {
  Id id = Isar.autoIncrement;

  late String categoryKey;

  /// Целевая длительность в секундах.
  late int targetSeconds;

  /// 'week' | 'month' | 'all' — период, за который считается прогресс.
  late String periodType;

  late int createdAt;

  /// Архивирована (отмечена выполненной) — скрыта из активных списков,
  /// но остаётся в базе. Не удаляется физически.
  bool isArchived = false;
}
