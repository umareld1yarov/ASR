import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../../sharing/presentation/screens/day_story_preview_screen.dart';
import '../../application/stats_provider.dart';
import '../widgets/category_stat_row.dart';
import '../widgets/donut_chart.dart';
import '../widgets/insight_card.dart';
import '../widgets/period_navigator_bar.dart';
import '../widgets/period_switcher.dart';

/// Флагманский экран Статистики.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(categoryBreakdownProvider);
    final insightsAsync = ref.watch(insightsProvider);
    final periodType = ref.watch(statsPeriodTypeProvider);

    final isLongPeriod = periodType == StatsPeriodType.month || periodType == StatsPeriodType.year;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: statsAsync.when(
            skipLoadingOnReload: true,
            skipLoadingOnRefresh: true,
            loading: () => const Center(
              child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
            ),
            error: (e, _) => Center(
              child: Text(
                '${"common.error".tr()}: $e',
                style: const TextStyle(color: Colors.white54),
              ),
            ),
            data: (stats) {
              final total = stats.values.fold(0, (a, b) => a + b);
              final sortedCategories = ActivityCategory.values.toList()
                ..sort(
                  (a, b) => (stats[b.storageKey] ?? 0).compareTo(
                    stats[a.storageKey] ?? 0,
                  ),
                );

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Переключатель периодов (День / Неделя / Месяц / Год)
                    const PeriodSwitcher(),
                    const SizedBox(height: 12),
                    const PeriodNavigatorBar(),
                    const SizedBox(height: 16),

                    // Кнопки экспорта (В Stories 9:16 и Аудит текстом / Файлом)
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              final pType = ref.read(statsPeriodTypeProvider);
                              final range = ref.read(statsPeriodRangeProvider);
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => DayStoryPreviewScreen(
                                    dateKey: range.endKey,
                                    periodType: pType,
                                    range: range,
                                  ),
                                ),
                              );
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF06B6D4).withValues(
                                  alpha: 0.12,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: const Color(0xFF06B6D4).withValues(
                                    alpha: 0.3,
                                  ),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.auto_awesome,
                                    size: 15,
                                    color: Color(0xFF06B6D4),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'stats.export_story'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () async {
                              final pType = ref.read(statsPeriodTypeProvider);
                              final range = ref.read(statsPeriodRangeProvider);
                              final repo = ref.read(statsRepositoryProvider);
                              final label = formatPeriodLabel(pType, range);

                              if (pType == StatsPeriodType.day) {
                                final auditText = await repo.generateDayAuditText(
                                  range.startKey,
                                );
                                await Clipboard.setData(
                                  ClipboardData(text: auditText),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF22C55E),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('stats.audit_copied_toast'.tr()),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF1F1F1F),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else if (pType == StatsPeriodType.week) {
                                final auditText = await repo.generatePeriodAuditText(
                                  startDateKey: range.startKey,
                                  endDateKey: range.endKey,
                                  periodLabel: label,
                                );
                                await Clipboard.setData(
                                  ClipboardData(text: auditText),
                                );
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          const Icon(
                                            Icons.check_circle,
                                            color: Color(0xFF22C55E),
                                            size: 18,
                                          ),
                                          const SizedBox(width: 8),
                                          Text('stats.audit_copied_toast'.tr()),
                                        ],
                                      ),
                                      backgroundColor: const Color(0xFF1F1F1F),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              } else {
                                final auditText = await repo.generatePeriodAuditText(
                                  startDateKey: range.startKey,
                                  endDateKey: range.endKey,
                                  periodLabel: label,
                                );
                                final tempDir = await getTemporaryDirectory();
                                final file = File(
                                  '${tempDir.path}/ASR_Audit_${range.startKey}_to_${range.endKey}.txt',
                                );
                                await file.writeAsString(auditText);

                                if (context.mounted) {
                                  await SharePlus.instance.share(
                                    ShareParams(files: [XFile(file.path)]),
                                  );
                                }
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isLongPeriod ? Icons.description_outlined : Icons.copy,
                                    size: 15,
                                    color: Colors.white70,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    isLongPeriod ? 'stats.export_txt'.tr() : 'stats.copy_log'.tr(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Интерактивная Донат-Диаграмма
                    Center(child: DonutChart(stats: stats)),
                    const SizedBox(height: 20),

                    // Умные инсайты
                    insightsAsync.when(
                      skipLoadingOnReload: true,
                      skipLoadingOnRefresh: true,
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
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

                    // Секция деталей по категориям и делам
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'stats.activities_breakdown'.tr(),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

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
