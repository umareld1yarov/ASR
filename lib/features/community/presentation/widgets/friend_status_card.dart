import 'package:flutter/material.dart';

import '../../domain/models/friendship.dart';
import '../../data/community_repository.dart';
import '../../community_theme.dart';
import '../../../../core/constants/activity_category.dart';
import 'community_avatar.dart';
import 'activity_status_pill.dart';

/// Карточка одного друга в списке Сообщества.
/// Показывает: аватар + имя + "прямо сейчас"/"не в сети", затем (если есть
/// live-статус) зелёную пилюлю с названием активности и временем, и
/// отдельным серым тегом — категорию (видна всегда, когда известна,
/// независимо от того, показано ли название активности).
class FriendStatusCard extends StatelessWidget {
  const FriendStatusCard({
    super.key,
    required this.friendship,
    required this.status,
    required this.onTap,
  });

  final Friendship friendship;

  /// null — если друг не поделился ничем текущим (оффлайн/скрыто).
  final FriendActivityStatus? status;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final friend = friendship.friend;
    final currentStatus = status;
    final isLive = currentStatus != null;
    final category = isLive && currentStatus.categoryKey != null
        ? ActivityCategory.fromStorageKey(currentStatus.categoryKey!)
        : null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: category?.color.withValues(alpha: 0.13) ??
              Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: category != null
              ? Border.all(color: category.color.withValues(alpha: 0.45))
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CommunityAvatar(
                  name: friend.displayName,
                  radius: 20,
                  showOnlineDot: true,
                  isOnline: isLive,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.displayName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        isLive
                            ? 'Прямо сейчас'
                            : 'Сейчас не делится активностью',
                        style: TextStyle(
                          color: isLive
                              ? category?.color ?? CommunityTheme.liveColor
                              : Colors.white.withValues(alpha: 0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.25),
                  size: 18,
                ),
              ],
            ),
            if (isLive) ...[
              const SizedBox(height: 12),
              ActivityStatusPill(
                activityName: currentStatus.activityName,
                categoryKey: currentStatus.categoryKey,
                startedAt: currentStatus.startedAt,
                embedded: true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
