import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/profile_provider.dart';
import '../../domain/models/goal.dart';

/// Карточка одной цели — прогресс-бар, заполняемый реальным трекнутым
/// временем в категории за выбранный период (неделя/месяц/всё время).
class GoalCard extends ConsumerWidget {
  const GoalCard({super.key, required this.goal});

  final Goal goal;

  String _periodLabel(String type) {
    switch (type) {
      case 'week':
        return 'эту неделю';
      case 'month':
        return 'этот месяц';
      default:
        return 'всё время';
    }
  }

  String _formatHours(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}ч ${m}м';
    return '${m}м';
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text('Удалить цель?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
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

    return progressAsync.when(
      data: (currentSeconds) {
        final ratio = (currentSeconds / goal.targetSeconds).clamp(0.0, 1.0);
        final isDone = currentSeconds >= goal.targetSeconds;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: category.color.withValues(alpha: 0.18)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${category.label} · ${_periodLabel(goal.periodType)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () =>
                        ref.read(goalsControllerProvider).archiveGoal(goal.id),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: isDone
                            ? const Color(0xFF22C55E)
                            : Colors.white38,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _confirmDelete(context, ref),
                    child: const Padding(
                      padding: EdgeInsets.only(left: 8),
                      child: Icon(Icons.close, size: 16, color: Colors.white38),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: category.color,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${_formatHours(currentSeconds)} / ${_formatHours(goal.targetSeconds)}',
                style: const TextStyle(fontSize: 12, color: Colors.white54),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 80),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
