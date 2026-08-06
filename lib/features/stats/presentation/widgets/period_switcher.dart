import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/stats_provider.dart';

/// Переключатель периода: День / Неделя / Месяц / Год.
/// Стеклянная капсула с 4 сегментами, активный подсвечен.
class PeriodSwitcher extends ConsumerWidget {
  const PeriodSwitcher({super.key});

  static const _options = [
    (StatsPeriodType.day, 'День'),
    (StatsPeriodType.week, 'Неделя'),
    (StatsPeriodType.month, 'Месяц'),
    (StatsPeriodType.year, 'Год'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(statsPeriodTypeProvider);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: _options.map((option) {
          final (type, label) = option;
          final isSelected = type == selected;

          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  ref.read(statsControllerProvider).setPeriodType(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : Colors.white54,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
