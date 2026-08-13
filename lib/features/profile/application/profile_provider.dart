import 'package:asr/features/stats/application/insight_engine.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart' as du;
import '../../../data/isar_service.dart';
import '../../stats/application/stats_provider.dart';
import '../../timer/application/timer_provider.dart';
import '../data/goal_repository.dart';
import '../data/profile_repository.dart';
import '../domain/models/goal.dart';
import '../domain/models/user_profile.dart';
import '../../stats/data/stats_repository.dart';
import '../../feed/application/feed_provider.dart';
import '../../timer/domain/models/activity_entry.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(IsarService.instance);
});

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(IsarService.instance);
});

// ── Профиль (аватар/имя) ─────────────────────────────

final userProfileProvider = FutureProvider<UserProfile>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);
  return repo.getProfile();
});

class ProfileController {
  ProfileController(this._ref);

  final Ref _ref;

  Future<void> updateProfile({
    String? name,
    String? avatarPath,
    String? missionStatement,
  }) async {
    await _ref
        .read(profileRepositoryProvider)
        .updateProfile(
          name: name,
          avatarPath: avatarPath,
          missionStatement: missionStatement,
        );
    _ref.invalidate(userProfileProvider);
  }
}

final profileControllerProvider = Provider<ProfileController>((ref) {
  return ProfileController(ref);
});

// ── Общий стрик приложения ───────────────────────────

final overallStreakProvider = FutureProvider<int>((ref) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getOverallStreak();
});

// ── Пожизненная статистика по категориям ────────────

final lifetimeBreakdownProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(statsRepositoryProvider);
  final todayKey = du.DateUtils.dateKey(DateTime.now());

  return repo.getCategoryBreakdown(startDateKey: null, endDateKey: todayKey);
});

// ── Цели и их прогресс ───────────────────────────────

final goalsProvider = FutureProvider<List<Goal>>((ref) async {
  final repo = ref.watch(goalRepositoryProvider);
  return repo.getAllGoals();
});

/// Прогресс одной цели: секунды, накопленные за её период (неделя/месяц).
final goalProgressProvider = FutureProvider.family<int, Goal>((
  ref,
  goal,
) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(statsRepositoryProvider);
  final now = DateTime.now();

  String startKey;
  final endKey = du.DateUtils.dateKey(now);

  switch (goal.periodType) {
    case 'week':
      startKey = du.DateUtils.dateKey(du.DateUtils.startOfWeek(now));
      break;
    case 'month':
    default:
      startKey = du.DateUtils.dateKey(du.DateUtils.startOfMonth(now));
      break;
  }

  if (goal.activityName != null && goal.activityName!.trim().isNotEmpty) {
    final targetName = goal.activityName!.trim().toLowerCase();
    final rangeEntries = await repo.getEntriesInRange(
      startDateKey: startKey,
      endDateKey: endKey,
    );

    int totalSec = 0;
    for (final e in rangeEntries) {
      if (e.categoryKey == goal.categoryKey &&
          e.name.trim().toLowerCase() == targetName) {
        totalSec += e.durationSeconds;
      }
    }
    return totalSec;
  }

  final breakdown = await repo.getCategoryBreakdown(
    startDateKey: startKey,
    endDateKey: endKey,
  );
  return breakdown[goal.categoryKey] ?? 0;
});

class GoalsController {
  GoalsController(this._ref);

  final Ref _ref;

  Future<void> addGoal({
    required String categoryKey,
    String? activityName,
    required int targetSeconds,
    required String periodType,
  }) async {
    await _ref
        .read(goalRepositoryProvider)
        .addGoal(
          categoryKey: categoryKey,
          activityName: activityName,
          targetSeconds: targetSeconds,
          periodType: periodType,
        );
    _ref.invalidate(goalsProvider);
  }

  Future<void> archiveGoal(int id) async {
    await _ref.read(goalRepositoryProvider).archiveGoal(id);
    _ref.invalidate(goalsProvider);
  }

  Future<void> deleteGoal(int id) async {
    await _ref.read(goalRepositoryProvider).deleteGoal(id);
    _ref.invalidate(goalsProvider);
  }
}

final goalsControllerProvider = Provider<GoalsController>((ref) {
  return GoalsController(ref);
});

// ── "Мой путь" — пожизненная статистика пути ─────────

final lifetimeJourneyStatsProvider = FutureProvider<LifetimeJourneyStats>((
  ref,
) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getLifetimeJourneyStats();
});

// ── Личные рекорды ────────────────────────────────────

final personalRecordsProvider = FutureProvider<PersonalRecords>((ref) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(statsRepositoryProvider);
  return repo.getPersonalRecords();
});

// ── "Что ASR заметил" — переиспользуем insight-движок Статистики ────

/// Один самый значимый инсайт за последние 30 дней (в сравнении
/// с предыдущими 30 днями) — та же логика, что в Статистике, просто
/// с более длинным окном и без привязки к выбранному пользователем периоду.
final profileInsightProvider = FutureProvider<Insight?>((ref) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(statsRepositoryProvider);

  final today = du.DateUtils.startOfDay(DateTime.now());
  final currentStart = today.subtract(const Duration(days: 29));
  final previousEnd = currentStart.subtract(const Duration(days: 1));
  final previousStart = previousEnd.subtract(const Duration(days: 29));

  final currentKey = du.DateUtils.dateKey(today);
  final currentStartKey = du.DateUtils.dateKey(currentStart);
  final previousStartKey = du.DateUtils.dateKey(previousStart);
  final previousEndKey = du.DateUtils.dateKey(previousEnd);

  final current = await repo.getCategoryBreakdown(
    startDateKey: currentStartKey,
    endDateKey: currentKey,
  );
  final previous = await repo.getCategoryBreakdown(
    startDateKey: previousStartKey,
    endDateKey: previousEndKey,
  );
  final daily = await repo.getCategoryDailyTotals(
    startDateKey: currentStartKey,
    endDateKey: currentKey,
  );

  final insights = buildInsights(
    current: current,
    previous: previous,
    dailyByCategory: daily,
    periodDaysCount: 30,
  );

  return insights.isNotEmpty ? insights.first : null;
});

// ── Воспоминания — случайная запись с фото ───────────

/// autoDispose — чтобы при каждом новом заходе на экран Профиля выбиралась
/// новая случайная запись, а не одна и та же закэшированная.
final memoryEntryProvider = FutureProvider.autoDispose<ActivityEntry?>((
  ref,
) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(feedRepositoryProvider);
  return repo.getRandomEntryWithPhoto();
});

/// Все записи с фото — для полного экрана-галереи "Воспоминания".
final allMemoriesProvider = FutureProvider<List<ActivityEntry>>((ref) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(feedRepositoryProvider);
  return repo.getAllEntriesWithPhotos();
});
