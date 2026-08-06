import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/stats_provider.dart';

/// Строка категории на всю ширину. Подмешивает live-время только если
/// это активная категория — остальные 8 строк не перерисовываются каждую
/// секунду (Provider.family не уведомляет виджеты с неизменным значением).
class CategoryStatRow extends ConsumerWidget {
  const CategoryStatRow({
    super.key,
    required this.category,
    required this.seconds,
    required this.totalSeconds,
    this.onTap,
  });

  final ActivityCategory category;
  final int seconds;
  final int totalSeconds;
  final VoidCallback? onTap;

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}ч ${m}м';
    return '${m}м';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final live = ref.watch(liveCategorySecondsProvider(category.storageKey));
    final displaySeconds = seconds + live;
    final displayTotal = totalSeconds + live;
    final percent = displayTotal > 0 ? displaySeconds / displayTotal : 0.0;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category.label,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${_formatDuration(displaySeconds)} · ${(percent * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0, 1),
                      minHeight: 6,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      valueColor: AlwaysStoppedAnimation(category.color),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
