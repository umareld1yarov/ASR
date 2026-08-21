import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/profile_provider.dart';

class LifetimeStatsSection extends ConsumerWidget {
  const LifetimeStatsSection({super.key});

  String _daysWord(int n) {
    return 'profile.day_count'.plural(n);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(lifetimeJourneyStatsProvider);

    return statsAsync.when(
      skipLoadingOnReload: true,
      skipLoadingOnRefresh: true,
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text('${"common.error".tr()}: $e'),
      data: (stats) {
        if (stats.totalActivities == 0) return const SizedBox.shrink();

        final hours = stats.totalSeconds ~/ 3600;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'profile.days_with_asr'.tr(
                args: [_daysWord(stats.daysSinceStart)],
              ),
              textAlign: TextAlign.center,
              style: const TextStyle(
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
              childAspectRatio: 1.7,
              children: [
                _JourneyStatCard(
                  emoji: '⏱️',
                  value: '$hours',
                  label: 'common.time'.tr(),
                ),
                _JourneyStatCard(
                  emoji: '📋',
                  value: '${stats.totalActivities}',
                  label: 'common.sessions'.tr(),
                ),
                _JourneyStatCard(
                  emoji: '📝',
                  value: '${stats.totalNotes}',
                  label: 'feed.note'.tr(),
                ),
                _JourneyStatCard(
                  emoji: '📷',
                  value: '${stats.totalPhotos}',
                  label: 'common.photos'.tr(),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _JourneyStatCard extends StatelessWidget {
  const _JourneyStatCard({
    required this.emoji,
    required this.value,
    required this.label,
  });

  final String emoji;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11.5, color: Colors.white54),
          ),
        ],
      ),
    );
  }
}
