import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/profile_provider.dart';
import '../../domain/models/goal.dart';

/// Компактная карточка цели для превью в Профиле.
class GoalMiniCard extends ConsumerWidget {
  const GoalMiniCard({super.key, required this.goal});

  final Goal goal;

  String _formatHours(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч ${m > 0 ? "$mм" : ""}';
    return '$mм';
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
        final isDone = currentSeconds >= goal.targetSeconds;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDone
                  ? const Color(0xFF22C55E).withValues(alpha: 0.5)
                  : category.color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text(category.emoji, style: const TextStyle(fontSize: 15)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      titleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${_formatHours(currentSeconds)} / ${_formatHours(goal.targetSeconds)}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
                      color: isDone ? const Color(0xFF22C55E) : Colors.white60,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 6,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  color: isDone ? const Color(0xFF22C55E) : category.color,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 54),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}
