import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/timer_provider.dart';
import '../screens/category_detail_screen.dart';
import 'category_stat_card.dart';

class CategoryStatsGrid extends ConsumerWidget {
  const CategoryStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final closedAsync = ref.watch(closedStatsProvider);
    final current = ref.watch(currentActivityProvider).valueOrNull;
    final elapsed = ref.watch(elapsedSecondsProvider).valueOrNull ?? 0;

    return closedAsync.when(
      data: (closedStats) {
        final stats = Map<String, int>.from(closedStats);
        if (current != null) {
          stats[current.categoryKey] =
              (stats[current.categoryKey] ?? 0) + elapsed;
        }

        return GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 6,
          crossAxisSpacing: 6,
          childAspectRatio: 1.55,
          children: ActivityCategory.values.map((category) {
            final seconds = stats[category.storageKey] ?? 0;
            return CategoryStatCard(
              category: category,
              seconds: seconds,
              isActive: current?.categoryKey == category.storageKey,
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => CategoryDetailScreen(category: category),
                ),
              ),
            );
          }).toList(),
        );
      },
      loading: () => const SizedBox(
        height: 100,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Ошибка: $e'),
    );
  }
}
