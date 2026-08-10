import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';
import '../../domain/models/friendship.dart';
import '../../data/community_repository.dart';

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

  static const _liveColor = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final friend = friendship.friend;
    final isLive = status != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _Avatar(name: friend.displayName, isLive: isLive),
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
                        isLive ? 'Прямо сейчас' : 'Не в сети',
                        style: TextStyle(
                          color: isLive
                              ? _liveColor
                              : Colors.white.withOpacity(0.35),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: Colors.white.withOpacity(0.25),
                  size: 18,
                ),
              ],
            ),
            if (isLive) ...[
              const SizedBox(height: 10),
              _LivePill(status: status!),
            ],
          ],
        ),
      ),
    );
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill({required this.status});

  final FriendActivityStatus status;

  static const _liveColor = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final category = status.categoryKey != null
        ? ActivityCategory.fromStorageKey(status.categoryKey!)
        : null;
    final hasName = status.activityName != null;
    final label = status.activityName ?? category?.label ?? '—';
    final elapsed = status.startedAt != null
        ? _formatElapsed(
            ((DateTime.now().millisecondsSinceEpoch - status.startedAt!) / 1000)
                .floor(),
          )
        : null;

    return Wrap(
      spacing: 8,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _liveColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _liveColor.withOpacity(0.4)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  color: _liveColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                elapsed != null ? '$label · $elapsed' : label,
                style: const TextStyle(
                  color: _liveColor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (hasName && category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              category.label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  static String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    if (h > 0) return '$h ч $m мин';
    return '$m мин';
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.isLive});

  final String name;
  final bool isLive;

  static const _liveColor = Color(0xFF22C55E);

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Stack(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: Colors.white.withOpacity(0.1),
          child: Text(
            initial,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
        if (isLive)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(
                color: _liveColor,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF0A0A0A), width: 2),
              ),
            ),
          ),
      ],
    );
  }
}
