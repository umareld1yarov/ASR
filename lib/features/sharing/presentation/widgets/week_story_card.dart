import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/day_story_provider.dart';

/// Виджет Сторис (9:16) для итогов Недели.
class WeekStoryCard extends StatelessWidget {
  const WeekStoryCard({
    super.key,
    required this.data,
  });

  final PeriodStoryData data;

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч ${m > 0 ? "$mм" : ""}';
    return '$mм';
  }

  @override
  Widget build(BuildContext context) {
    final totalSec = data.totalDurationSeconds;
    final topActivity = data.topActivities.isNotEmpty ? data.topActivities.first : null;

    final sortedCategories = ActivityCategory.values.toList()
      ..sort((a, b) => (data.categoryDurations[b.storageKey] ?? 0)
          .compareTo(data.categoryDurations[a.storageKey] ?? 0));

    final activeCategories = sortedCategories
        .where((cat) => (data.categoryDurations[cat.storageKey] ?? 0) > 0)
        .toList();

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF0F172A),
              Color(0xFF020617),
              Color(0xFF090D16),
            ],
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Верхняя шапка
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.auto_awesome, size: 12, color: Color(0xFF06B6D4)),
                      SizedBox(width: 4),
                      Text(
                        'ИТОГИ НЕДЕЛИ',
                        style: TextStyle(
                          color: Color(0xFF06B6D4),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'ASR FOCUS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.35),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Главный счетчик недели
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
            const Text(
              'время в зачёте за неделю',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.white54,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),

            // Главное занятие недели (если есть)
            if (topActivity != null) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                      ),
                      child: const Text('🥇', style: TextStyle(fontSize: 16)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Главное дело недели',
                            style: TextStyle(fontSize: 10.5, color: Colors.white54),
                          ),
                          Text(
                            topActivity.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      _formatDuration(topActivity.seconds),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFFACC15),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Раскладка по категориям
            const Text(
              'Распределение по категориям',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: activeCategories.isEmpty
                  ? const Center(
                      child: Text(
                        'Нет данных за эту неделю',
                        style: TextStyle(color: Colors.white38, fontSize: 12),
                      ),
                    )
                  : ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: activeCategories.length,
                      itemBuilder: (context, index) {
                        final cat = activeCategories[index];
                        final catSec = data.categoryDurations[cat.storageKey] ?? 0;
                        final percent = totalSec > 0 ? catSec / totalSec : 0.0;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                                      const SizedBox(width: 6),
                                      Text(
                                        cat.label,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Text(
                                    '${_formatDuration(catSec)} · ${(percent * 100).round()}%',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white60,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent.clamp(0.0, 1.0),
                                  minHeight: 5,
                                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                                  valueColor: AlwaysStoppedAnimation(cat.color),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),

            // Водяной знак
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
