import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_provider.dart';
import '../screens/journey_screen.dart';
import '../screens/records_screen.dart';

/// Две тизер-плитки рядом — "Рекорды" и "Мой путь". Только иконка и короткая
/// подпись, тап открывает соответствующий полный экран.
class TeaserTilesRow extends ConsumerWidget {
  const TeaserTilesRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordsAsync = ref.watch(personalRecordsProvider);
    final journeyAsync = ref.watch(lifetimeJourneyStatsProvider);

    final recordsCount = recordsAsync.valueOrNull == null
        ? 0
        : [
            recordsAsync.valueOrNull!.longestSessionSeconds != null,
            recordsAsync.valueOrNull!.bestDaySeconds != null,
            recordsAsync.valueOrNull!.longestOverallStreakDays > 0,
            recordsAsync.valueOrNull!.longestNoWasteStreakDays > 0,
          ].where((v) => v).length;

    final daysWithApp = journeyAsync.valueOrNull?.daysSinceStart ?? 0;

    return Row(
      children: [
        Expanded(
          child: _TeaserTile(
            emoji: '🏆',
            title: 'Личные рекорды',
            subtitle: recordsCount > 0
                ? '$recordsCount ${_achievementsWord(recordsCount)} →'
                : 'Смотреть →',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RecordsScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TeaserTile(
            emoji: '📖',
            title: 'Мой путь',
            subtitle: daysWithApp > 0
                ? '$daysWithApp ${_daysWord(daysWithApp)} с тобой →'
                : 'Смотреть →',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const JourneyScreen())),
          ),
        ),
      ],
    );
  }

  String _daysWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'дней';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'дней';
    }
    return 'дней';
  }

  String _achievementsWord(int n) {
    if (n % 10 == 1 && n % 100 != 11) return 'достижение';
    if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
      return 'достижения';
    }
    return 'достижений';
  }
}

class _TeaserTile extends StatelessWidget {
  const _TeaserTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 11.5, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
