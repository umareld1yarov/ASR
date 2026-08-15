import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_provider.dart';
import '../screens/journey_screen.dart';
import '../screens/records_screen.dart';

class TeaserTilesRow extends ConsumerWidget {
  const TeaserTilesRow({super.key});

  String _daysWord(int n) {
    return 'profile.day_count'.plural(n);
  }

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
            title: 'profile.longest_streak'.tr(),
            subtitle: recordsCount > 0
                ? 'profile.achievements_count'.plural(recordsCount, args: ['$recordsCount'])
                : 'profile.watch_arrow'.tr(),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const RecordsScreen())),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TeaserTile(
            emoji: '📖',
            title: 'profile.my_journey'.tr(),
            subtitle: daysWithApp > 0
                ? 'profile.with_you_arrow'.tr(args: ['$daysWithApp', _daysWord(daysWithApp)])
                : 'profile.watch_arrow'.tr(),
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const JourneyScreen())),
          ),
        ),
      ],
    );
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
