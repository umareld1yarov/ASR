import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../application/profile_provider.dart';

class Milestone {
  const Milestone({
    required this.id,
    required this.emoji,
    required this.titleKey,
    required this.descriptionKey,
    required this.isUnlocked,
    required this.currentProgress,
    required this.target,
    required this.unitKey,
  });

  final String id;
  final String emoji;
  final String titleKey;
  final String descriptionKey;
  final bool isUnlocked;
  final int currentProgress;
  final int target;
  final String unitKey;

  String get title => titleKey.tr();
  String get description => descriptionKey.tr();
  String get unit => unitKey.tr();

  double get ratio => (currentProgress / target).clamp(0.0, 1.0);
}

final milestonesProvider = FutureProvider<List<Milestone>>((ref) async {
  final journeyStats = await ref.watch(lifetimeJourneyStatsProvider.future);
  final breakdown = await ref.watch(lifetimeBreakdownProvider.future);

  final growthHours =
      (breakdown[ActivityCategory.growth.storageKey] ?? 0) ~/ 3600;
  final workHours = (breakdown[ActivityCategory.work.storageKey] ?? 0) ~/ 3600;
  final sportHours =
      (breakdown[ActivityCategory.sport.storageKey] ?? 0) ~/ 3600;
  final religionHours =
      (breakdown[ActivityCategory.religion.storageKey] ?? 0) ~/ 3600;
  final restHours = (breakdown[ActivityCategory.rest.storageKey] ?? 0) ~/ 3600;

  return [
    Milestone(
      id: 'first_step',
      emoji: '🌱',
      titleKey: 'milestones.items.first_step_title',
      descriptionKey: 'milestones.items.first_step_desc',
      isUnlocked: journeyStats.totalActivities > 0,
      currentProgress: journeyStats.totalActivities > 0 ? 1 : 0,
      target: 1,
      unitKey: 'milestones.units.session',
    ),
    Milestone(
      id: 'growth_5h',
      emoji: '📖',
      titleKey: 'milestones.items.growth_5h_title',
      descriptionKey: 'milestones.items.growth_5h_desc',
      isUnlocked: growthHours >= 5,
      currentProgress: growthHours,
      target: 5,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'growth_25h',
      emoji: '📚',
      titleKey: 'milestones.items.growth_25h_title',
      descriptionKey: 'milestones.items.growth_25h_desc',
      isUnlocked: growthHours >= 25,
      currentProgress: growthHours,
      target: 25,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'growth_100h',
      emoji: '🎓',
      titleKey: 'milestones.items.growth_100h_title',
      descriptionKey: 'milestones.items.growth_100h_desc',
      isUnlocked: growthHours >= 100,
      currentProgress: growthHours,
      target: 100,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'work_20h',
      emoji: '🧭',
      titleKey: 'milestones.items.work_20h_title',
      descriptionKey: 'milestones.items.work_20h_desc',
      isUnlocked: workHours >= 20,
      currentProgress: workHours,
      target: 20,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'work_100h',
      emoji: '💼',
      titleKey: 'milestones.items.work_100h_title',
      descriptionKey: 'milestones.items.work_100h_desc',
      isUnlocked: workHours >= 100,
      currentProgress: workHours,
      target: 100,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'work_400h',
      emoji: '🏗️',
      titleKey: 'milestones.items.work_400h_title',
      descriptionKey: 'milestones.items.work_400h_desc',
      isUnlocked: workHours >= 400,
      currentProgress: workHours,
      target: 400,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'sport_5h',
      emoji: '🏃',
      titleKey: 'milestones.items.sport_5h_title',
      descriptionKey: 'milestones.items.sport_5h_desc',
      isUnlocked: sportHours >= 5,
      currentProgress: sportHours,
      target: 5,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'sport_20h',
      emoji: '💪',
      titleKey: 'milestones.items.sport_20h_title',
      descriptionKey: 'milestones.items.sport_20h_desc',
      isUnlocked: sportHours >= 20,
      currentProgress: sportHours,
      target: 20,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'sport_75h',
      emoji: '🏆',
      titleKey: 'milestones.items.sport_75h_title',
      descriptionKey: 'milestones.items.sport_75h_desc',
      isUnlocked: sportHours >= 75,
      currentProgress: sportHours,
      target: 75,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'religion_5h',
      emoji: '🕌',
      titleKey: 'milestones.items.religion_5h_title',
      descriptionKey: 'milestones.items.religion_5h_desc',
      isUnlocked: religionHours >= 5,
      currentProgress: religionHours,
      target: 5,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'religion_25h',
      emoji: '🌙',
      titleKey: 'milestones.items.religion_25h_title',
      descriptionKey: 'milestones.items.religion_25h_desc',
      isUnlocked: religionHours >= 25,
      currentProgress: religionHours,
      target: 25,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'religion_100h',
      emoji: '✨',
      titleKey: 'milestones.items.religion_100h_title',
      descriptionKey: 'milestones.items.religion_100h_desc',
      isUnlocked: religionHours >= 100,
      currentProgress: religionHours,
      target: 100,
      unitKey: 'milestones.units.h',
    ),
    Milestone(
      id: 'rest_master',
      emoji: '🌴',
      titleKey: 'milestones.items.rest_master_title',
      descriptionKey: 'milestones.items.rest_master_desc',
      isUnlocked: restHours >= 10,
      currentProgress: restHours,
      target: 10,
      unitKey: 'milestones.units.h',
    ),
  ];
});
