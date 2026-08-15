import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/community_provider.dart';
import '../../domain/models/friendship.dart';
import 'community_avatar.dart';

/// Горизонтальная карусель "Друзья в фокусе прямо сейчас".
class LiveFocusBar extends ConsumerWidget {
  const LiveFocusBar({
    super.key,
    required this.friendships,
    required this.onFriendTap,
  });

  final List<Friendship> friendships;
  final ValueChanged<Friendship> onFriendTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final liveFriends = friendships.where((f) {
      final status = ref.watch(friendActivityStatusProvider(f.friend.id));
      return status.valueOrNull != null;
    }).toList();

    if (liveFriends.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFF22C55E),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'community.live_stream'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 82,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: liveFriends.length,
            itemBuilder: (context, index) {
              final friendship = liveFriends[index];
              final status = ref.watch(
                friendActivityStatusProvider(friendship.friend.id),
              ).valueOrNull;

              final category = status?.categoryKey != null
                  ? ActivityCategory.fromStorageKey(status!.categoryKey!)
                  : null;

              return Padding(
                padding: const EdgeInsets.only(right: 14),
                child: GestureDetector(
                  onTap: () => onFriendTap(friendship),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2.5),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: category?.color ?? const Color(0xFF22C55E),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (category?.color ?? const Color(0xFF22C55E))
                                      .withValues(alpha: 0.35),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: CommunityAvatar(
                              name: friendship.friend.displayName,
                              radius: 22,
                            ),
                          ),
                          if (category != null)
                            Positioned(
                              right: -2,
                              bottom: -2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Color(0xFF141414),
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  category.emoji,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 58,
                        child: Text(
                          friendship.friend.displayName.split(' ').first,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
