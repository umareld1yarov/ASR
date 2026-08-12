import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/community_provider.dart';
import '../../community_theme.dart';
import '../../domain/models/friendship.dart';
import 'friend_status_card.dart';

class FriendsActivitySection extends ConsumerWidget {
  const FriendsActivitySection({super.key, required this.friendships, required this.onFriendTap});

  final List<Friendship> friendships;
  final ValueChanged<Friendship> onFriendTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'ДРУЗЬЯ СЕЙЧАС',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        ...friendships.map((friendship) {
          final status = ref.watch(
            friendActivityStatusProvider(friendship.friend.id),
          );
          return FriendStatusCard(
            friendship: friendship,
            status: status.valueOrNull,
            onTap: () => onFriendTap(friendship),
          );
        }),
      ],
    );
  }
}
