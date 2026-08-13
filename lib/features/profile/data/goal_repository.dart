import 'package:isar_community/isar.dart';

import '../domain/models/goal.dart';

/// Репозиторий целей — CRUD + архивирование. Прогресс НЕ считается здесь,
/// это делает GoalsController в связке со StatsRepository.
class GoalRepository {
  GoalRepository(this._isar);

  final Isar _isar;

  /// Только активные (неархивированные) цели.
  Future<List<Goal>> getAllGoals() {
    return _isar.goals
        .filter()
        .isArchivedEqualTo(false)
        .sortByCreatedAt()
        .findAll();
  }

  Future<void> addGoal({
    required String categoryKey,
    String? activityName,
    required int targetSeconds,
    required String periodType,
  }) async {
    final goal = Goal()
      ..categoryKey = categoryKey
      ..activityName = (activityName != null && activityName.trim().isNotEmpty)
          ? activityName.trim()
          : null
      ..targetSeconds = targetSeconds
      ..periodType = periodType
      ..createdAt = DateTime.now().millisecondsSinceEpoch;

    await _isar.writeTxn(() async {
      await _isar.goals.put(goal);
    });
  }

  /// Архивирует цель (отмечена выполненной) — остаётся в базе, но скрыта
  /// из активных списков.
  Future<void> archiveGoal(int id) async {
    await _isar.writeTxn(() async {
      final goal = await _isar.goals.get(id);
      if (goal == null) return;
      goal.isArchived = true;
      await _isar.goals.put(goal);
    });
  }

  Future<void> deleteGoal(int id) async {
    await _isar.writeTxn(() async {
      await _isar.goals.delete(id);
    });
  }
}
