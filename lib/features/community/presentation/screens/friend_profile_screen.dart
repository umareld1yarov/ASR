import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../shared/widgets/app_background.dart';
import '../../application/community_provider.dart';
import '../../domain/models/friendship.dart';
import 'sharing_settings_screen.dart';

/// Профиль друга: показывает live-статус (если он разрешил) и даёт доступ
/// к настройке того, что Я разрешаю видеть ЕМУ.
/// Важно: то, что видно НА этом экране (статус друга) — это ЕГО permission
/// для меня. Кнопка "Настроить доступ" ведёт к МОЕМУ permission для него.
/// Это две разные вещи, и путать их нельзя.
class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({super.key, required this.friendship});

  final Friendship friendship;

  static const _accentColor = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(
      friendActivityStatusProvider(friendship.friend.id),
    );

    return AppBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  Text(
                    friendship.friend.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.white.withOpacity(0.1),
                    child: Text(
                      friendship.friend.displayName.isNotEmpty
                          ? friendship.friend.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 28,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (statusAsync.valueOrNull != null)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: const Color(0xFF22C55E),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF0A0A0A),
                            width: 3,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                '@${friendship.friend.username}',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.4),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: statusAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: _accentColor),
                ),
                error: (e, _) => _InfoCard(
                  text: 'Не удалось загрузить статус',
                  color: Colors.white38,
                ),
                data: (status) {
                  if (status == null) {
                    return const _InfoCard(
                      text: 'Сейчас не делится тем, чем занят',
                      color: Colors.white38,
                    );
                  }
                  final categoryLabel = status.categoryKey != null
                      ? ActivityCategory.fromStorageKey(
                          status.categoryKey!,
                        ).label
                      : '—';
                  final activityText =
                      status.activityName ?? 'Занят: $categoryLabel';
                  return _InfoCard(text: activityText, color: _accentColor);
                },
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            SharingSettingsScreen(friendship: friendship),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune, color: _accentColor, size: 18),
                  label: const Text(
                    'Настроить, что видит он',
                    style: TextStyle(color: _accentColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: _accentColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
