import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../timer/application/timer_provider.dart';
import '../../../../core/constants/activity_category.dart';
import 'activity_status_pill.dart';
import 'community_avatar.dart';

/// Превью того, как МОЯ текущая активность выглядит для друзей —
/// показывается сверху вкладки "Сообщества". Использует тот же
/// ActivityStatusPill/CommunityAvatar, что и карточки друзей —
/// визуально идентична FriendStatusCard, просто про "себя".
class MyActivityPreviewCard extends ConsumerWidget {
  const MyActivityPreviewCard({
    super.key,
    required this.visibleFriendsCount,
    required this.onVisibleFriendsTap,
  });

  final int visibleFriendsCount;
  final VoidCallback onVisibleFriendsTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(currentActivityProvider);

    return currentAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (current) {
        final isLive = current != null;
        final category = isLive
            ? ActivityCategory.fromStorageKey(current.categoryKey)
            : null;
        return Container(
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
          Text(
            'так тебя видят друзья',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.35),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
          Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CommunityAvatar(
                    name: 'Я',
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
                          isLive ? 'Прямо сейчас' : 'Не в сети',
                          style: TextStyle(
                            color: isLive
                                ? category?.color ?? const Color(0xFF22C55E)
                                : Colors.white.withValues(alpha: 0.35),
                            fontWeight: FontWeight.w600,
                            fontSize: 14.5,
                          ),
                        ),
                        if (isLive) ...[
                          const SizedBox(height: 10),
                          ActivityStatusPill(
                            activityName: current.name,
                            categoryKey: current.categoryKey,
                            startedAt: current.startedAt,
                            embedded: true,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
          ),
          const SizedBox(height: 10),
          TextButton.icon(
            onPressed: onVisibleFriendsTap,
            icon: const Icon(Icons.visibility_outlined, size: 17),
            label: Text('Видят вашу активность: $visibleFriendsCount'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white.withValues(alpha: 0.72),
              padding: EdgeInsets.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
          ),
        );
      },
    );
  }
}
