import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/stats_provider.dart';

/// Стрелки ← → + подпись текущего периода. Аналог day_navigator_bar,
/// но шаг — целый период (день/неделя/месяц/год), а не один день.
class PeriodNavigatorBar extends ConsumerWidget {
  const PeriodNavigatorBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final langCode = context.locale.languageCode;
    final type = ref.watch(statsPeriodTypeProvider);
    final range = ref.watch(statsPeriodRangeProvider);
    final canGoPrev = ref.watch(canGoPreviousProvider);
    final canGoNext = ref.watch(canGoNextProvider);
    final controller = ref.read(statsControllerProvider);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: canGoPrev ? controller.goToPrevious : null,
          icon: const Icon(Icons.chevron_left),
          color: canGoPrev ? Colors.white : Colors.white24,
        ),
        Text(
          formatPeriodLabel(type, range, langCode),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        IconButton(
          onPressed: canGoNext ? controller.goToNext : null,
          icon: const Icon(Icons.chevron_right),
          color: canGoNext ? Colors.white : Colors.white24,
        ),
      ],
    );
  }
}
