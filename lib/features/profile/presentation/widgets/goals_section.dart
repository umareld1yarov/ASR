import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_provider.dart';
import 'add_goal_sheet.dart';
import 'goal_card.dart';

class GoalsSection extends ConsumerWidget {
  const GoalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(goalsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'profile.goals_title'.tr(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline, color: Colors.white70),
              onPressed: () => AddGoalSheet.show(context),
            ),
          ],
        ),
        const SizedBox(height: 8),
        goalsAsync.when(
          data: (goals) {
            if (goals.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'profile.no_goals'.tr(),
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              );
            }
            return Column(
              children: goals.map((goal) => GoalCard(goal: goal)).toList(),
            );
          },
          loading: () => const SizedBox(height: 60),
          error: (e, _) => Text('${"common.error".tr()}: $e'),
        ),
      ],
    );
  }
}
