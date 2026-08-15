import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../application/profile_provider.dart';

class Milestone {
  const Milestone({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.currentProgress,
    required this.target,
    required this.unit,
  });

  final String id;
  final String emoji;
  final String title;
  final String description;
  final bool isUnlocked;
  final int currentProgress;
  final int target;
  final String unit;

  double get ratio => (currentProgress / target).clamp(0.0, 1.0);
}

final milestonesProvider = FutureProvider<List<Milestone>>((ref) async {
  final journeyStats = await ref.watch(lifetimeJourneyStatsProvider.future);
  final breakdown = await ref.watch(lifetimeBreakdownProvider.future);
  final records = await ref.watch(personalRecordsProvider.future);

  final growthHours =
      (breakdown[ActivityCategory.growth.storageKey] ?? 0) ~/ 3600;
  final workHours = (breakdown[ActivityCategory.work.storageKey] ?? 0) ~/ 3600;
  final sportHours =
      (breakdown[ActivityCategory.sport.storageKey] ?? 0) ~/ 3600;
  final religionHours =
      (breakdown[ActivityCategory.religion.storageKey] ?? 0) ~/ 3600;
  final restHours = (breakdown[ActivityCategory.rest.storageKey] ?? 0) ~/ 3600;
  final noWasteDays = records.longestNoWasteStreakDays;

  return [
    Milestone(
      id: 'first_step',
      emoji: '🌱',
      title: 'milestones.items.first_step_title'.tr(),
      description: 'milestones.items.first_step_desc'.tr(),
      isUnlocked: journeyStats.totalActivities > 0,
      currentProgress: journeyStats.totalActivities > 0 ? 1 : 0,
      target: 1,
      unit: 'milestones.units.session'.tr(),
    ),
    Milestone(
      id: 'growth_5h',
      emoji: '📖',
      title: 'milestones.items.growth_5h_title'.tr(),
      description: 'milestones.items.growth_5h_desc'.tr(),
      isUnlocked: growthHours >= 5,
      currentProgress: growthHours,
      target: 5,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'growth_25h',
      emoji: '📚',
      title: 'milestones.items.growth_25h_title'.tr(),
      description: 'milestones.items.growth_25h_desc'.tr(),
      isUnlocked: growthHours >= 25,
      currentProgress: growthHours,
      target: 25,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'growth_100h',
      emoji: '🎓',
      title: 'milestones.items.growth_100h_title'.tr(),
      description: 'milestones.items.growth_100h_desc'.tr(),
      isUnlocked: growthHours >= 100,
      currentProgress: growthHours,
      target: 100,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'work_20h',
      emoji: '🧭',
      title: 'milestones.items.work_20h_title'.tr(),
      description: 'milestones.items.work_20h_desc'.tr(),
      isUnlocked: workHours >= 20,
      currentProgress: workHours,
      target: 20,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'work_100h',
      emoji: '💼',
      title: 'milestones.items.work_100h_title'.tr(),
      description: 'milestones.items.work_100h_desc'.tr(),
      isUnlocked: workHours >= 100,
      currentProgress: workHours,
      target: 100,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'work_400h',
      emoji: '🏗️',
      title: 'milestones.items.work_400h_title'.tr(),
      description: 'milestones.items.work_400h_desc'.tr(),
      isUnlocked: workHours >= 400,
      currentProgress: workHours,
      target: 400,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'sport_5h',
      emoji: '🏃',
      title: 'milestones.items.sport_5h_title'.tr(),
      description: 'milestones.items.sport_5h_desc'.tr(),
      isUnlocked: sportHours >= 5,
      currentProgress: sportHours,
      target: 5,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'sport_20h',
      emoji: '💪',
      title: 'milestones.items.sport_20h_title'.tr(),
      description: 'milestones.items.sport_20h_desc'.tr(),
      isUnlocked: sportHours >= 20,
      currentProgress: sportHours,
      target: 20,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'sport_75h',
      emoji: '🏆',
      title: 'milestones.items.sport_75h_title'.tr(),
      description: 'milestones.items.sport_75h_desc'.tr(),
      isUnlocked: sportHours >= 75,
      currentProgress: sportHours,
      target: 75,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'religion_5h',
      emoji: '🕌',
      title: 'milestones.items.religion_5h_title'.tr(),
      description: 'milestones.items.religion_5h_desc'.tr(),
      isUnlocked: religionHours >= 5,
      currentProgress: religionHours,
      target: 5,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'religion_25h',
      emoji: '🌙',
      title: 'milestones.items.religion_25h_title'.tr(),
      description: 'milestones.items.religion_25h_desc'.tr(),
      isUnlocked: religionHours >= 25,
      currentProgress: religionHours,
      target: 25,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'religion_100h',
      emoji: '✨',
      title: 'milestones.items.religion_100h_title'.tr(),
      description: 'milestones.items.religion_100h_desc'.tr(),
      isUnlocked: religionHours >= 100,
      currentProgress: religionHours,
      target: 100,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'rest_master',
      emoji: '🌴',
      title: 'milestones.items.rest_master_title'.tr(),
      description: 'milestones.items.rest_master_desc'.tr(),
      isUnlocked: restHours >= 10,
      currentProgress: restHours,
      target: 10,
      unit: 'milestones.units.h'.tr(),
    ),
    Milestone(
      id: 'no_waste_guard',
      emoji: '🛡️',
      title: 'milestones.items.no_waste_guard_title'.tr(),
      description: 'milestones.items.no_waste_guard_desc'.tr(),
      isUnlocked: noWasteDays >= 7,
      currentProgress: noWasteDays,
      target: 7,
      unit: 'milestones.units.d'.tr(),
    ),
  ];
});

final timeMetaphorProvider = Provider.family<String, int>((ref, totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  if (hours < 1) {
    return 'metaphors.start'.tr();
  } else if (hours < 10) {
    final books = (hours * 0.5).toStringAsFixed(1);
    return 'metaphors.books_1'.tr(args: ['$hours', books]);
  } else if (hours < 50) {
    final books = (hours / 12 * 5).round();
    return 'metaphors.books_2'.tr(args: ['$hours', '$books']);
  } else if (hours < 200) {
    final km = hours * 70;
    return 'metaphors.road'.tr(args: ['$hours', '$km']);
  } else {
    final days = (hours / 24).toStringAsFixed(1);
    return 'metaphors.life'.tr(args: ['$hours', days]);
  }
});
