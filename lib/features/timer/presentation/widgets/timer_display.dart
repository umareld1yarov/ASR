import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/timer_provider.dart';

/// Большой таймер + название текущей активности.
/// Аналог блока .current-block из index.html (PWA).
class TimerDisplay extends ConsumerWidget {
  const TimerDisplay({super.key});

  String _formatHMS(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(currentActivityProvider);
    final elapsedAsync = ref.watch(elapsedSecondsProvider);

    return currentAsync.when(
      data: (current) {
        if (current == null) {
          return const Column(
            children: [
              Text('—', style: TextStyle(fontSize: 14, color: Colors.grey)),
              SizedBox(height: 8),
              Text(
                'Нажми «Старт»',
                style: TextStyle(fontSize: 18, color: Colors.white70),
              ),
              SizedBox(height: 12),
              Text(
                '00:00:00',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.w300,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ],
          );
        }

        final category = ActivityCategory.fromStorageKey(current.categoryKey);
        final elapsed = elapsedAsync.maybeWhen(data: (s) => s, orElse: () => 0);

        return Column(
          children: [
            Text(
              category.label,
              style: TextStyle(
                fontSize: 14,
                color: category.color,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              current.name,
              style: const TextStyle(fontSize: 18, color: Colors.white70),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _formatHMS(elapsed),
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w300,
                color: category.color,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (e, _) => Text('Ошибка: $e'),
    );
  }
}
