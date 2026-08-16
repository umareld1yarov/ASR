import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/duration_formatter.dart';
import '../../application/day_story_provider.dart';

/// Виджет Сторис (9:16) для итогов Месяца.
class MonthStoryCard extends StatelessWidget {
  const MonthStoryCard({
    super.key,
    required this.data,
  });

  final PeriodStoryData data;

  String _formatDuration(int seconds) {
    return formatDuration(seconds);
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = data.totalDurationSeconds;
    final topActivities = data.topActivities;

    final sortedCategories = ActivityCategory.values.toList()
      ..sort((a, b) => (data.categoryDurations[b.storageKey] ?? 0)
          .compareTo(data.categoryDurations[a.storageKey] ?? 0));

    final activeCategories = sortedCategories
        .where((cat) => (data.categoryDurations[cat.storageKey] ?? 0) > 0)
        .take(4)
        .toList();

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E1B4B),
              Color(0xFF0F172A),
              Color(0xFF090D16),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text('🗓️ ', style: TextStyle(fontSize: 10)),
                      Text(
                        'sharing.month_summary_title'.tr(),
                        style: const TextStyle(
                          color: Color(0xFFA5B4FC),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'ASR JOURNAL',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              _formatDuration(totalSec),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 44,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -1.0,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'sharing.month_accumulated_time'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),

            if (topActivities.isNotEmpty) ...[
              Text(
                'sharing.top_3_month'.tr(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  children: [
                    for (int i = 0; i < topActivities.length; i++) ...[
                      if (i > 0) const Divider(color: Colors.white10, height: 12),
                      Row(
                        children: [
                          Text(
                            i == 0
                                ? '🥇'
                                : i == 1
                                    ? '🥈'
                                    : '🥉',
                            style: const TextStyle(fontSize: 15),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              topActivities[i].name,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            _formatDuration(topActivities[i].seconds),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: i == 0
                                  ? const Color(0xFFFACC15)
                                  : Colors.white70,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            if (data.bestDaySeconds != null && data.bestDaySeconds! > 0) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFF22C55E), size: 16),
                        const SizedBox(width: 6),
                        Text(
                          'sharing.peak_day_month'.tr(),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _formatDuration(data.bestDaySeconds!),
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF22C55E),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            Expanded(
              child: ListView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: activeCategories.length,
                itemBuilder: (context, index) {
                  final cat = activeCategories[index];
                  final catSec = data.categoryDurations[cat.storageKey] ?? 0;
                  final percent = totalSec > 0 ? catSec / totalSec : 0.0;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            cat.label,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '${_formatDuration(catSec)} · ${(percent * 100).round()}%',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white54,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            const Center(
              child: Text(
                'ASR · Focus & Life Journal',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.white38,
                  letterSpacing: 1.0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
