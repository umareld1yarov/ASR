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
/// Каждая веха привязана к ОДНОЙ конкретной категории — без агрегатов,
/// суммирующих разные категории в единый "балл продуктивности".
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
      title: 'Первый шаг',
      description: 'Завершить свою самую первую сессию',
      isUnlocked: journeyStats.totalActivities > 0,
      currentProgress: journeyStats.totalActivities > 0 ? 1 : 0,
      target: 1,
      unit: 'сессия',
    ),

    // ── Развитие: 5ч → 25ч → 100ч ──
    Milestone(
      id: 'growth_5h',
      emoji: '📖',
      title: 'Первые страницы',
      description: 'Посвятить 5 часов категории «Развитие»',
      isUnlocked: growthHours >= 5,
      currentProgress: growthHours,
      target: 5,
      unit: 'ч',
    ),
    Milestone(
      id: 'growth_25h',
      emoji: '📚',
      title: 'Жажда знаний',
      description: 'Посвятить 25 часов категории «Развитие»',
      isUnlocked: growthHours >= 25,
      currentProgress: growthHours,
      target: 25,
      unit: 'ч',
    ),
    Milestone(
      id: 'growth_100h',
      emoji: '🎓',
      title: 'Путь мастерства',
      description: 'Посвятить 100 часов категории «Развитие»',
      isUnlocked: growthHours >= 100,
      currentProgress: growthHours,
      target: 100,
      unit: 'ч',
    ),

    // ── Работа: 20ч → 100ч → 400ч ──
    Milestone(
      id: 'work_20h',
      emoji: '🧭',
      title: 'Первые шаги в деле',
      description: 'Посвятить 20 часов категории «Работа»',
      isUnlocked: workHours >= 20,
      currentProgress: workHours,
      target: 20,
      unit: 'ч',
    ),
    Milestone(
      id: 'work_100h',
      emoji: '💼',
      title: 'Архитектор проектов',
      description: 'Посвятить 100 часов категории «Работа»',
      isUnlocked: workHours >= 100,
      currentProgress: workHours,
      target: 100,
      unit: 'ч',
    ),
    Milestone(
      id: 'work_400h',
      emoji: '🏗️',
      title: 'Строитель наследия',
      description: 'Посвятить 400 часов категории «Работа»',
      isUnlocked: workHours >= 400,
      currentProgress: workHours,
      target: 400,
      unit: 'ч',
    ),

    // ── Спорт: 5ч → 20ч → 75ч ──
    Milestone(
      id: 'sport_5h',
      emoji: '🏃',
      title: 'Первый рывок',
      description: 'Посвятить 5 часов категории «Спорт»',
      isUnlocked: sportHours >= 5,
      currentProgress: sportHours,
      target: 5,
      unit: 'ч',
    ),
    Milestone(
      id: 'sport_20h',
      emoji: '💪',
      title: 'Железная воля',
      description: 'Посвятить 20 часов категории «Спорт»',
      isUnlocked: sportHours >= 20,
      currentProgress: sportHours,
      target: 20,
      unit: 'ч',
    ),
    Milestone(
      id: 'sport_75h',
      emoji: '🏆',
      title: 'Атлет дисциплины',
      description: 'Посвятить 75 часов категории «Спорт»',
      isUnlocked: sportHours >= 75,
      currentProgress: sportHours,
      target: 75,
      unit: 'ч',
    ),

    // ── Религия: 5ч → 25ч → 100ч ──
    Milestone(
      id: 'religion_5h',
      emoji: '🕌',
      title: 'Первые шаги веры',
      description: 'Посвятить 5 часов категории «Религия»',
      isUnlocked: religionHours >= 5,
      currentProgress: religionHours,
      target: 5,
      unit: 'ч',
    ),
    Milestone(
      id: 'religion_25h',
      emoji: '🌙',
      title: 'Духовный рост',
      description: 'Посвятить 25 часов категории «Религия»',
      isUnlocked: religionHours >= 25,
      currentProgress: religionHours,
      target: 25,
      unit: 'ч',
    ),
    Milestone(
      id: 'religion_100h',
      emoji: '✨',
      title: 'Постоянство в вере',
      description: 'Посвятить 100 часов категории «Религия»',
      isUnlocked: religionHours >= 100,
      currentProgress: religionHours,
      target: 100,
      unit: 'ч',
    ),

    // ── Отдых: один порог, это не про "достижение" в чистом виде ──
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

/// Провайдер расчёта вдохновляющей метафоры времени — теперь считает
/// от общего протрекано времени (все категории), без слова "фокус"
/// и без противопоставления "продуктивного" и "непродуктивного".
final timeMetaphorProvider = Provider.family<String, int>((ref, totalSeconds) {
  final hours = totalSeconds ~/ 3600;
  if (hours < 1) {
    return 'Вы только начинаете свой путь — каждая сессия приближает к вашим целям!';
  } else if (hours < 10) {
    final books = (hours * 0.5).toStringAsFixed(1);
    return 'У вас уже $hours ч осознанного времени — это равноценно прочтению около $books книг!';
  } else if (hours < 50) {
    final books = (hours / 12 * 5).round();
    return 'Вы отдали делу $hours ч — это как прочитать $books книг по 300 страниц!';
  } else if (hours < 200) {
    final km = hours * 70;
    return 'Ваш результат $hours ч — это как проехать $km км навстречу своей мечте!';
  } else {
    final days = (hours / 24).toStringAsFixed(1);
    return 'Потрясающе! $hours ч — это $days дней осознанной, наполненной смыслом жизни!';
  }
});
