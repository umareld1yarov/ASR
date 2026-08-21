import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:asr/features/profile/data/goal_repository.dart';
import 'package:asr/features/profile/domain/models/goal.dart';
import '../helpers/test_db_helper.dart';

void main() {
  setUpAll(() async {
    await initTestIsarCore();
  });

  group('GoalRepository', () {
    late TestDbHandle dbHandle;
    late Isar isar;
    late GoalRepository repository;

    setUp(() async {
      dbHandle = await createTestIsar(prefix: 'goal_repo_test');
      isar = dbHandle.isar;
      repository = GoalRepository(isar);
    });

    tearDown(() async {
      await dbHandle.dispose();
    });

    test('addGoal создаёт цель с корректными полями', () async {
      await repository.addGoal(
        categoryKey: 'growth',
        activityName: '  Чтение книг  ',
        targetSeconds: 36000,
        periodType: 'month',
      );

      final goals = await repository.getAllGoals();
      expect(goals.length, equals(1));

      final goal = goals.first;
      expect(goal.categoryKey, equals('growth'));
      expect(goal.activityName, equals('Чтение книг'));
      expect(goal.targetSeconds, equals(36000));
      expect(goal.periodType, equals('month'));
      expect(goal.isArchived, isFalse);
      expect(goal.createdAt, isPositive);
    });

    test('getAllGoals возвращает только неархивированные цели', () async {
      await repository.addGoal(
        categoryKey: 'sport',
        targetSeconds: 7200,
        periodType: 'week',
      );
      await repository.addGoal(
        categoryKey: 'work',
        targetSeconds: 144000,
        periodType: 'month',
      );

      var goals = await repository.getAllGoals();
      expect(goals.length, equals(2));

      // Архивируем первую цель
      await repository.archiveGoal(goals.first.id);

      goals = await repository.getAllGoals();
      expect(goals.length, equals(1));
      expect(goals.first.categoryKey, equals('work'));

      // Проверяем, что в самой БД архивированная цель сохранилась
      final allDbGoals = await isar.goals.where().findAll();
      expect(allDbGoals.length, equals(2));
      expect(allDbGoals.any((g) => g.isArchived), isTrue);
    });

    test('deleteGoal удаляет цель из базы данных полностью', () async {
      await repository.addGoal(
        categoryKey: 'religion',
        targetSeconds: 18000,
        periodType: 'week',
      );

      final goals = await repository.getAllGoals();
      expect(goals.length, equals(1));

      await repository.deleteGoal(goals.first.id);

      final remaining = await isar.goals.where().findAll();
      expect(remaining, isEmpty);
    });
  });
}
