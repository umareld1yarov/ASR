import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../application/stats_provider.dart';
import '../widgets/category_stat_row.dart';
import '../widgets/donut_chart.dart';
import '../widgets/insight_card.dart';
import '../widgets/period_navigator_bar.dart';
import '../widgets/period_switcher.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(categoryBreakdownProvider);
    final insightsAsync = ref.watch(insightsProvider);

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: statsAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Ошибка: $e')),
            data: (stats) {
              final total = stats.values.fold(0, (a, b) => a + b);
              final sortedCategories = ActivityCategory.values.toList()
                ..sort(
                  (a, b) => (stats[b.storageKey] ?? 0).compareTo(
                    stats[a.storageKey] ?? 0,
                  ),
                );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Статистика',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const PeriodSwitcher(),
                    const SizedBox(height: 14),
                    const PeriodNavigatorBar(),
                    const SizedBox(height: 20),
                    Center(child: DonutChart(stats: stats)),
                    const SizedBox(height: 20),

                    insightsAsync.when(
                      skipLoadingOnReload: true,
                      skipLoadingOnRefresh: true,
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (insights) {
                        if (insights.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final insight in insights) ...[
                              InsightCard(insight: insight),
                              const SizedBox(height: 8),
                            ],
                            const SizedBox(height: 8),
                          ],
                        );
                      },
                    ),

                    // ── Экспорт — подключим на следующем шаге ──
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: null, // TODO: экспорт картинки
                            icon: const Icon(Icons.auto_awesome_outlined),
                            label: const Text('В Stories'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: null, // TODO: экспорт текста
                            icon: const Icon(Icons.text_snippet_outlined),
                            label: const Text('Текстом'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    for (final category in sortedCategories)
                      CategoryStatRow(
                        category: category,
                        seconds: stats[category.storageKey] ?? 0,
                        totalSeconds: total,
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
