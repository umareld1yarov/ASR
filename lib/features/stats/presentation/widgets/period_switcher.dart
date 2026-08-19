import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../premium/application/premium_controller.dart';
import '../../../premium/presentation/screens/paywall_screen.dart';
import '../../application/stats_provider.dart';

/// Переключатель периода: День / Неделя (Free) и Месяц / Год (PRO).
class PeriodSwitcher extends ConsumerWidget {
  const PeriodSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = context.locale;
    final selected = ref.watch(statsPeriodTypeProvider);
    final isPro = ref.watch(isProProvider);

    final options = [
      (StatsPeriodType.day, 'stats.day'.tr(), false),
      (StatsPeriodType.week, 'stats.week'.tr(), false),
      (StatsPeriodType.month, 'stats.month'.tr(), true),
      (StatsPeriodType.year, 'stats.year'.tr(), true),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: options.map((option) {
          final (type, label, isProOnly) = option;
          final isSelected = type == selected;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (isProOnly && !isPro) {
                  // Переход на Paywall при выборе PRO периода без подписки
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PaywallScreen()),
                  );
                } else {
                  ref.read(statsControllerProvider).setPeriodType(type);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : Colors.white54,
                      ),
                    ),
                    if (isProOnly && !isPro) ...[
                      const SizedBox(width: 3),
                      const Icon(
                        Icons.workspace_premium,
                        size: 13,
                        color: Color(0xFF06B6D4),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
