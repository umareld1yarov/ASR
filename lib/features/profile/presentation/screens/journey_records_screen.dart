import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../../../shared/widgets/app_background.dart';
import '../../application/milestones_provider.dart';
import '../../application/profile_provider.dart';

/// Флагманский экран «Мой путь & Личные рекорды» — интеграция личной
/// хронологии, рекордов с возможностью экспорта в Сторис и вех развития.
class JourneyRecordsScreen extends ConsumerWidget {
  const JourneyRecordsScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const JourneyRecordsScreen()));
  }

  String _formatHours(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч ${m > 0 ? "$mм" : ""}';
    return '$mм';
  }

  String _daysWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'день';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'дня';
    }
    return 'дней';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final journeyAsync = ref.watch(lifetimeJourneyStatsProvider);
    final recordsAsync = ref.watch(personalRecordsProvider);
    final milestonesAsync = ref.watch(milestonesProvider);

    final unlockedCount =
        milestonesAsync.valueOrNull?.where((m) => m.isUnlocked).length ?? 0;
    final totalMilestones = milestonesAsync.valueOrNull?.length ?? 10;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Навигационная панель
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 16, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Мой путь & Рекорды',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAB308).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFEAB308).withValues(alpha: 0.5),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text('🏆 ', style: TextStyle(fontSize: 12)),
                          Text(
                            '$unlockedCount/$totalMilestones',
                            style: const TextStyle(
                              color: Color(0xFFEAB308),
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── СЕКЦИЯ 1: МАШТАБ ПУТИ ─────────────────────────────
                      journeyAsync.when(
                        data: (stats) {
                          final hours = stats.totalSeconds ~/ 3600;
                          final metaphor = ref.watch(
                            timeMetaphorProvider(stats.totalSeconds),
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'ASR с Вами ${stats.daysSinceStart} ${_daysWord(stats.daysSinceStart)}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Row(
                                      children: [
                                        _StatPill(
                                          emoji: '⏱️',
                                          value: '$hoursч',
                                          label: 'времени',
                                        ),
                                        const SizedBox(width: 8),
                                        _StatPill(
                                          emoji: '📋',
                                          value: '${stats.totalActivities}',
                                          label: 'сессий',
                                        ),
                                        const SizedBox(width: 8),
                                        _StatPill(
                                          emoji: '📝',
                                          value: '${stats.totalNotes}',
                                          label: 'заметок',
                                        ),
                                        const SizedBox(width: 8),
                                        _StatPill(
                                          emoji: '📷',
                                          value: '${stats.totalPhotos}',
                                          label: 'фото',
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              // Метафора времени
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF06B6D4,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: const Color(
                                      0xFF06B6D4,
                                    ).withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Text(
                                      '💡 ',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Expanded(
                                      child: Text(
                                        metaphor,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox(height: 120),
                        error: (_, _) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 24),

                      // ── СЕКЦИЯ 2: 🏆 ЛИЧНЫЕ РЕКОРДЫ С КНОПКОЙ ШЕРИНГА ─────
                      Row(
                        children: [
                          Text(
                            'profile.journey_records'.tr(),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      recordsAsync.when(
                        data: (records) {
                          return GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.25,
                            children: [
                              _RecordShareCard(
                                emoji: '⚡',
                                title: 'profile.longest_session'.tr(),
                                value: records.longestSessionSeconds != null
                                    ? _formatHours(
                                        records.longestSessionSeconds!,
                                      )
                                    : '—',
                                subtitle:
                                    records.longestSessionName ?? '—',
                                accentColor:
                                    records.longestSessionCategoryKey != null
                                    ? ActivityCategory.fromStorageKey(
                                        records.longestSessionCategoryKey!,
                                      ).color
                                    : const Color(0xFF06B6D4),
                              ),
                              _RecordShareCard(
                                emoji: '🏆',
                                title: 'profile.best_day'.tr(),
                                value: records.bestDaySeconds != null
                                    ? _formatHours(records.bestDaySeconds!)
                                    : '—',
                                subtitle: records.bestDayDateKey != null
                                    ? du.DateUtils.formatShortRu(
                                        du.DateUtils.dateKeyToDate(
                                          records.bestDayDateKey!,
                                        ),
                                      )
                                    : '—',
                                accentColor:
                                    records.bestCategoryKeyOfBestDay != null
                                    ? ActivityCategory.fromStorageKey(
                                        records.bestCategoryKeyOfBestDay!,
                                      ).color
                                    : const Color(0xFFEAB308),
                              ),
                              _RecordShareCard(
                                emoji: '🔥',
                                title: 'profile.longest_streak'.tr(),
                                value: '${records.longestOverallStreakDays}',
                                subtitle: _daysWord(
                                  records.longestOverallStreakDays,
                                ),
                                accentColor: const Color(0xFF22C55E),
                              ),
                              _RecordShareCard(
                                emoji: '✨',
                                title: 'profile.no_waste'.tr(),
                                value: '${records.longestNoWasteStreakDays}',
                                subtitle: _daysWord(
                                  records.longestNoWasteStreakDays,
                                ),
                                accentColor: const Color(0xFFA855F7),
                              ),
                            ],
                          );
                        },
                        loading: () => const SizedBox(height: 140),
                        error: (_, _) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 24),

                      // ── СЕКЦИЯ 3: 🏅 ВЕХИ РАЗВИТИЯ (MILESTONES) ─────────────
                      const Text(
                        '🏅 Вехи развития',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Достижения разблокируются автоматически по мере вашего продвижения',
                        style: TextStyle(fontSize: 12, color: Colors.white54),
                      ),
                      const SizedBox(height: 12),

                      milestonesAsync.when(
                        data: (milestones) {
                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: milestones.length,
                            itemBuilder: (context, index) {
                              final m = milestones[index];
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: m.isUnlocked
                                      ? const Color(
                                          0xFF22C55E,
                                        ).withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.04),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: m.isUnlocked
                                        ? const Color(
                                            0xFF22C55E,
                                          ).withValues(alpha: 0.35)
                                        : Colors.white.withValues(alpha: 0.08),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: m.isUnlocked
                                            ? const Color(
                                                0xFF22C55E,
                                              ).withValues(alpha: 0.15)
                                            : Colors.white.withValues(
                                                alpha: 0.05,
                                              ),
                                        shape: BoxShape.circle,
                                      ),
                                      alignment: Alignment.center,
                                      child: Text(
                                        m.emoji,
                                        style: const TextStyle(fontSize: 22),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  m.title,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w700,
                                                    color: m.isUnlocked
                                                        ? Colors.white
                                                        : Colors.white70,
                                                  ),
                                                ),
                                              ),
                                              Text(
                                                m.isUnlocked
                                                    ? '✅ Разблокировано'
                                                    : '${m.currentProgress}/${m.target} ${m.unit}',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  fontWeight: FontWeight.w600,
                                                  color: m.isUnlocked
                                                      ? const Color(0xFF22C55E)
                                                      : Colors.white38,
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            m.description,
                                            style: const TextStyle(
                                              fontSize: 11.5,
                                              color: Colors.white54,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                            child: LinearProgressIndicator(
                                              value: m.ratio,
                                              minHeight: 5,
                                              backgroundColor: Colors.white
                                                  .withValues(alpha: 0.06),
                                              color: m.isUnlocked
                                                  ? const Color(0xFF22C55E)
                                                  : const Color(0xFF06B6D4),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF06B6D4),
                          ),
                        ),
                        error: (e, _) => Text(
                          'Ошибка вех: $e',
                          style: const TextStyle(color: Colors.white54),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordShareCard extends StatelessWidget {
  const _RecordShareCard({
    required this.emoji,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.accentColor,
  });

  final String emoji;
  final String title;
  final String value;
  final String subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 11, color: Colors.white54),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.5,
                  color: accentColor.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
