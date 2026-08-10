import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../application/profile_provider.dart';

/// Личные рекорды — 4 карточки 2×2: самая длинная сессия, лучший день,
/// рекордный стрик, рекордная серия без "Потерь". Не про категории/проценты
/// (это Статистика) — здесь про пиковые моменты пути.
class PersonalRecordsSection extends ConsumerWidget {
  const PersonalRecordsSection({super.key});

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч $mм';
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
    final recordsAsync = ref.watch(personalRecordsProvider);

    return recordsAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('Ошибка: $e'),
      data: (records) {
        final hasAnyRecord =
            records.longestSessionSeconds != null ||
            records.longestOverallStreakDays > 0;
        if (!hasAnyRecord) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Личные рекорды',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.5,
              children: [
                _RecordCard(
                  emoji: '⚡',
                  title: 'Самая длинная сессия',
                  value: records.longestSessionSeconds != null
                      ? _formatDuration(records.longestSessionSeconds!)
                      : '—',
                  subtitle: records.longestSessionName,
                  accentColor: records.longestSessionCategoryKey != null
                      ? ActivityCategory.fromStorageKey(
                          records.longestSessionCategoryKey!,
                        ).color
                      : Colors.white38,
                ),
                _RecordCard(
                  emoji: '🏆',
                  title: 'Лучший день',
                  value: records.bestDaySeconds != null
                      ? _formatDuration(records.bestDaySeconds!)
                      : '—',
                  subtitle: records.bestDayDateKey != null
                      ? du.DateUtils.formatShortRu(
                          du.DateUtils.dateKeyToDate(records.bestDayDateKey!),
                        )
                      : null,
                  accentColor: records.bestCategoryKeyOfBestDay != null
                      ? ActivityCategory.fromStorageKey(
                          records.bestCategoryKeyOfBestDay!,
                        ).color
                      : Colors.white38,
                ),
                _RecordCard(
                  emoji: '🔥',
                  title: 'Рекордный стрик',
                  value: '${records.longestOverallStreakDays}',
                  subtitle: _daysWord(records.longestOverallStreakDays),
                  accentColor: const Color(0xFF22C55E),
                ),
                _RecordCard(
                  emoji: '✨',
                  title: 'Без Потерь подряд',
                  value: '${records.longestNoWasteStreakDays}',
                  subtitle: _daysWord(records.longestNoWasteStreakDays),
                  accentColor: const Color(0xFF06B6D4),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.emoji,
    required this.title,
    required this.value,
    required this.accentColor,
    this.subtitle,
  });

  final String emoji;
  final String title;
  final String value;
  final String? subtitle;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accentColor.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(fontSize: 10.5, color: Colors.white54),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          if (subtitle != null && subtitle!.isNotEmpty)
            Text(
              subtitle!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10.5, color: Colors.white38),
            ),
        ],
      ),
    );
  }
}
