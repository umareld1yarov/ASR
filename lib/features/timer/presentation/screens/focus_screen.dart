import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_background.dart';
import '../widgets/category_stats_grid.dart';
import '../widgets/switch_activity_button.dart';
import '../widgets/timer_display.dart';

/// Флагманский экран Фокуса (Главный экран).
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                'timer.what_are_you_doing'.tr(),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 12),
              const TimerDisplay(),

              const SizedBox(height: 16),
              const SwitchActivityButton(),

              const SizedBox(height: 24),
              const Expanded(child: CategoryStatsGrid()),
            ],
          ),
        ),
      ),
    );
  }
}
