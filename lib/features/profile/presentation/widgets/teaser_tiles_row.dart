import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/milestones_provider.dart';
import '../../application/profile_provider.dart';
import '../screens/journey_records_screen.dart';

/// Единый премиум-баннер "Мой путь & Личные рекорды" на экране Профиля.
class TeaserTilesRow extends ConsumerWidget {
  const TeaserTilesRow({super.key});

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
    final milestonesAsync = ref.watch(milestonesProvider);

    final daysWithApp = journeyAsync.valueOrNull?.daysSinceStart ?? 0;
    final totalHours = (journeyAsync.valueOrNull?.totalSeconds ?? 0) ~/ 3600;
    final unlockedCount = milestonesAsync.valueOrNull
            ?.where((m) => m.isUnlocked)
            .length ??
        0;

    return InkWell(
      onTap: () => JourneyRecordsScreen.show(context),
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
                  const Text(
                    'Мой путь & Рекорды',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    daysWithApp > 0
                        ? 'ASR с Вами $daysWithApp ${_daysWord(daysWithApp)} · $totalHoursч фокуса'
                        : 'Статистика Вашего пути и рекорды',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
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
                    '$unlockedCount вех',
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
