import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../application/profile_provider.dart';

/// Модель вехи (достижения пути).
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

/// Провайдер вычисления достижений (вех развития) на основе всей истории.
final milestonesProvider = FutureProvider<List<Milestone>>((ref) async {
  final journeyStats = await ref.watch(lifetimeJourneyStatsProvider.future);
  final breakdown = await ref.watch(lifetimeBreakdownProvider.future);
  final records = await ref.watch(personalRecordsProvider.future);

  // Категории продуктивного фокуса (созидание на 100%): Работа, Развитие, Религия, Спорт, Финансы
  final productiveFocusSec = (breakdown[ActivityCategory.work.storageKey] ?? 0) +
      (breakdown[ActivityCategory.growth.storageKey] ?? 0) +
      (breakdown[ActivityCategory.religion.storageKey] ?? 0) +
      (breakdown[ActivityCategory.sport.storageKey] ?? 0) +
      (breakdown[ActivityCategory.finance.storageKey] ?? 0);

  final productiveFocusHours = productiveFocusSec ~/ 3600;

  final growthHours = (breakdown[ActivityCategory.growth.storageKey] ?? 0) ~/ 3600;
  final workHours = (breakdown[ActivityCategory.work.storageKey] ?? 0) ~/ 3600;
  final sportHours = (breakdown[ActivityCategory.sport.storageKey] ?? 0) ~/ 3600;
  final religionHours = (breakdown[ActivityCategory.religion.storageKey] ?? 0) ~/ 3600;
  final restHours = (breakdown[ActivityCategory.rest.storageKey] ?? 0) ~/ 3600;
  final noWasteDays = records.longestNoWasteStreakDays;

  return [
    Milestone(
      id: 'first_step',
      emoji: '🌱',
      title: 'Первый шаг',
      description: 'Завершить свою самую первую сессию',
      isUnlocked: journeyStats.totalActivities > 0,
      currentProgress: journeyStats.totalActivities > 0 ? 1 : 0,
      target: 1,
      unit: 'сессия',
    ),
    Milestone(
      id: 'focus_10h',
      emoji: '⚡',
      title: 'Инициация',
      description: 'Накопить 10 часов Продуктивного фокуса (работа, учёба, спорт, духовность)',
      isUnlocked: productiveFocusHours >= 10,
      currentProgress: productiveFocusHours,
      target: 10,
      unit: 'ч фокуса',
    ),
    Milestone(
      id: 'focus_50h',
      emoji: '🔥',
      title: 'Глубокое погружение',
      description: 'Накопить 50 часов Продуктивного фокуса',
      isUnlocked: productiveFocusHours >= 50,
      currentProgress: productiveFocusHours,
      target: 50,
      unit: 'ч фокуса',
    ),
    Milestone(
      id: 'focus_100h',
      emoji: '🥇',
      title: '100 часов Мастерства',
      description: 'Достичь 100 часов Продуктивного фокуса в жизни',
      isUnlocked: productiveFocusHours >= 100,
      currentProgress: productiveFocusHours,
      target: 100,
      unit: 'ч фокуса',
    ),
    Milestone(
      id: 'focus_500h',
      emoji: '👑',
      title: 'Легенда дисциплины',
      description: 'Достичь 500 часов Продуктивного фокуса',
      isUnlocked: productiveFocusHours >= 500,
      currentProgress: productiveFocusHours,
      target: 500,
      unit: 'ч фокуса',
    ),
    Milestone(
      id: 'growth_master',
      emoji: '📚',
      title: 'Жажда знаний',
      description: 'Посвятить 10 часов категории «Развитие»',
      isUnlocked: growthHours >= 10,
      currentProgress: growthHours,
      target: 10,
      unit: 'ч',
    ),
    Milestone(
      id: 'work_master',
      emoji: '💼',
      title: 'Архитектор проектов',
      description: 'Посвятить 20 часов категории «Работа»',
      isUnlocked: workHours >= 20,
      currentProgress: workHours,
      target: 20,
      unit: 'ч',
    ),
    Milestone(
      id: 'sport_master',
      emoji: '💪',
      title: 'Железная воля',
      description: 'Посвятить 10 часов категории «Спорт»',
      isUnlocked: sportHours >= 10,
      currentProgress: sportHours,
      target: 10,
      unit: 'ч',
    ),
    Milestone(
      id: 'religion_master',
      emoji: '🕌',
      title: 'Духовный рост',
      description: 'Посвятить 10 часов категории «Религия»',
      isUnlocked: religionHours >= 10,
      currentProgress: religionHours,
      target: 10,
      unit: 'ч',
    ),
    Milestone(
      id: 'rest_master',
      emoji: '🌴',
      title: 'Осознанный отдых',
      description: 'Посвятить 10 часов категории «Отдых»',
      isUnlocked: restHours >= 10,
      currentProgress: restHours,
      target: 10,
      unit: 'ч',
    ),
    Milestone(
      id: 'no_waste_guard',
      emoji: '🛡️',
      title: 'Страж времени',
      description: '7 дней подряд без единой записи в «Потери»',
      isUnlocked: noWasteDays >= 7,
      currentProgress: noWasteDays,
      target: 7,
      unit: 'дн',
    ),
  ];
});

/// Провайдер расчета вдохновляющей метафоры времени.
final timeMetaphorProvider = Provider.family<String, int>((ref, totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  if (hours < 1) {
    return 'Вы только начинаете свой путь — каждая сессия созидания приближает к высоким целям!';
  } else if (hours < 10) {
    final books = (hours * 0.5).toStringAsFixed(1);
    return 'У Вас уже $hours ч Продуктивного фокуса — это равноценно прочтению около $books книг!';
  } else if (hours < 50) {
    final books = (hours / 12 * 5).round();
    return 'Вы отдали делу $hours ч Продуктивного фокуса — это как прочитать $books книг по 300 страниц!';
  } else if (hours < 200) {
    final km = hours * 70;
    return 'Ваш результат $hours ч Продуктивного фокуса — это как проехать $km км навстречу своей мечте!';
  } else {
    final days = (hours / 24).toStringAsFixed(1);
    return 'Потрясающе! $hours ч Продуктивного фокуса — это $days дней чистого созидания и работы на 100%!';
  }
});
