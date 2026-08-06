import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/profile_provider.dart';
import '../../domain/models/goal.dart';

/// Компактная карточка цели для превью на главном экране Профиля —
/// только название категории и прогресс-бар, без действий (удалить/архив).
class GoalMiniCard extends ConsumerWidget {
  const GoalMiniCard({super.key, required this.goal});

  final Goal goal;

  String _periodLabel(String type) {
    switch (type) {
      case 'week':
        return 'неделя';
      case 'month':
        return 'месяц';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final category = ActivityCategory.fromStorageKey(goal.categoryKey);
    final progressAsync = ref.watch(goalProgressProvider(goal));

    return progressAsync.when(
      data: (currentSeconds) {
        final ratio = (currentSeconds / goal.targetSeconds).clamp(0.0, 1.0);

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            color: category.color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: category.color.withValues(alpha: 0.18)),
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
                      '${category.label} · ${_periodLabel(goal.periodType)}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Text(
                    '${_formatHours(currentSeconds)}/${_formatHours(goal.targetSeconds)}',
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: Colors.white54,
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
                  color: category.color,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox(height: 60),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
