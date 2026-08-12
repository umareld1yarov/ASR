import 'package:flutter/material.dart';

import '../../community_theme.dart';
import '../../domain/models/friendship.dart';
import '../../domain/models/sharing_permission.dart';
import 'community_avatar.dart';

class FriendAccessSheet extends StatelessWidget {
  const FriendAccessSheet({
    super.key,
    required this.friendships,
    required this.onFriendTap,
  });

  final List<Friendship> friendships;
  final ValueChanged<Friendship> onFriendTap;

  @override
  Widget build(BuildContext context) {
    final visibleFriends = friendships
        .where((friendship) => friendship.myPermissionForFriend.scope != SharingScope.none)
        .toList();

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Кто видит вашу активность',
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Доступ действует, когда у вас запущена активность.',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
            ),
            const SizedBox(height: 14),
            if (visibleFriends.isEmpty)
              Text(
                'Никому не разрешено видеть вашу текущую активность.',
                style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
              )
            else
              ...visibleFriends.map(
                (friendship) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  onTap: () => onFriendTap(friendship),
                  leading: CommunityAvatar(
                    name: friendship.friend.displayName,
                    radius: 19,
                  ),
                  title: Text(
                    friendship.friend.displayName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    _scopeLabel(friendship.myPermissionForFriend.scope),
                    style: const TextStyle(
                      color: CommunityTheme.accentColor,
                      fontSize: 12,
                    ),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.white38,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _scopeLabel(SharingScope scope) {
    return switch (scope) {
      SharingScope.none => 'Нет доступа',
      SharingScope.category => 'Видит только категорию',
      SharingScope.fullActivity => 'Видит полную активность',
    };
  }
}
