import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_provider.dart';
import '../screens/goals_screen.dart';
import 'goal_mini_card.dart';

class GoalsPreviewSection extends ConsumerWidget {
  const GoalsPreviewSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = context.locale;
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
            GestureDetector(
              onTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
              child: Text(
                'profile.all_arrow'.tr(),
                style: const TextStyle(fontSize: 13, color: Colors.white54),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        goalsAsync.when(
          skipLoadingOnReload: true,
          skipLoadingOnRefresh: true,
          loading: () => const SizedBox(height: 60),
          error: (e, _) => Text('${"common.error".tr()}: $e'),
          data: (goals) {
            if (goals.isEmpty) {
              return GestureDetector(
                onTap: () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const GoalsScreen())),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'profile.no_goals'.tr(),
                    style: const TextStyle(color: Colors.white38, fontSize: 13),
                  ),
                ),
              );
            }
            final preview = goals.take(3).toList();
            return Column(
              children: [for (final goal in preview) GoalMiniCard(goal: goal)],
            );
          },
        ),
      ],
    );
  }
}
