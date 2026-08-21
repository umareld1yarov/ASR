import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/milestones_provider.dart';
import '../../application/profile_provider.dart';
import '../screens/journey_screen.dart';

class TeaserTilesRow extends ConsumerWidget {
  const TeaserTilesRow({super.key});

  String _daysWord(int n) {
    return 'profile.day_count'.plural(n);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = context.locale;
    final journeyAsync = ref.watch(lifetimeJourneyStatsProvider);
    final milestonesAsync = ref.watch(milestonesProvider);

    final daysWithApp = journeyAsync.valueOrNull?.daysSinceStart ?? 0;
    final totalHours = (journeyAsync.valueOrNull?.totalSeconds ?? 0) ~/ 3600;
    final unlockedCount =
        milestonesAsync.valueOrNull?.where((m) => m.isUnlocked).length ?? 0;

    return InkWell(
      onTap: () => JourneyScreen.show(context),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF06B6D4).withValues(alpha: 0.15),
              const Color(0xFFEAB308).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308).withValues(alpha: 0.2),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFEAB308)),
              ),
              alignment: Alignment.center,
              child: const Text('🏆', style: TextStyle(fontSize: 22)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'profile.my_journey'.tr(),
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    daysWithApp > 0
                        ? 'profile.journey_subtitle'.tr(
                            args: [_daysWord(daysWithApp), '$totalHours'],
                          )
                        : 'profile.journey_desc'.tr(),
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Text(
                    'profile.milestones_count'.tr(args: ['$unlockedCount']),
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFEAB308),
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.chevron_right,
                    size: 16,
                    color: Colors.white54,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
