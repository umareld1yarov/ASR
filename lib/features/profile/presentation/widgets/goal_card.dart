import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/profile_provider.dart';
import '../../domain/models/goal.dart';

/// Эстетичная карточка цели с процентом, оставшимися днями и бейджем выполнения.
class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal});

  final Goal goal;

  String _periodLabel(String type) {
    switch (type) {
      case 'week':
        return 'Неделя';
      case 'month':
      default:
        return 'Месяц';
    }
  }

  String _remainingDaysLabel(String type) {
    final now = DateTime.now();
    if (type == 'week') {
      final daysUntilSunday = 7 - now.weekday;
      if (daysUntilSunday == 0) return 'Последний день';
      return 'Осталось $daysUntilSunday ${daysUntilSunday == 1 ? "день" : "дня"}';
    } else {
      final lastDayOfMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysLeft = lastDayOfMonth - now.day;
      if (daysLeft == 0) return 'Последний день';
      return 'Осталось $daysLeft ${daysLeft == 1 ? "день" : "дней"}';
    }
  }

  String _formatHours(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч ${m > 0 ? "$mм" : ""}';
    return '$mм';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Удалить цель?'),
        content: const Text(
          'Цель будет полностью удалена.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(goalsControllerProvider).deleteGoal(goal.id);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ActivityCategory.fromStorageKey(goal.categoryKey);
    final progressAsync = ref.watch(goalProgressProvider(goal));

    final titleText = goal.activityName != null && goal.activityName!.isNotEmpty
        ? '${category.label} · ${goal.activityName}'
        : category.label;

    return progressAsync.when(
      data: (currentSeconds) {
        final ratio = (currentSeconds / goal.targetSeconds).clamp(0.0, 1.0);
        final percent = (ratio * 100).round();
        final isDone = currentSeconds >= goal.targetSeconds;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                  : category.color.withValues(alpha: 0.25),
              width: isDone ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          titleText,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_periodLabel(goal.periodType)} · ${_remainingDaysLabel(goal.periodType)}',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Colors.white.withValues(alpha: 0.45),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isDone)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF22C55E)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.stars, color: Color(0xFF22C55E), size: 14),
                          SizedBox(width: 4),
                          Text(
                            'Выполнено!',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  IconButton(
                    onPressed: () => _confirmDelete(context, ref),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: isDone ? const Color(0xFF22C55E) : category.color,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_formatHours(currentSeconds)} из ${_formatHours(goal.targetSeconds)}',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                  Text(
                    '$percent%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: isDone ? const Color(0xFF22C55E) : category.color,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 80),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
