import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/community_provider.dart';
import '../../community_theme.dart';
import '../../domain/models/friendship.dart';
import '../../domain/models/sharing_permission.dart';
import '../widgets/community_header.dart';
import '../widgets/empty_friends_state.dart';
import '../widgets/friends_activity_section.dart';
import '../widgets/friend_access_sheet.dart';
import '../widgets/my_activity_preview_card.dart';
import 'find_friends_screen.dart';
import 'friend_profile_screen.dart';
import 'friend_requests_screen.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friends = ref.watch(friendsProvider);
    final incomingRequests = ref.watch(incomingRequestsProvider);

    void openAddFriend() => Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FindFriendsScreen()),
    );

    void openFriend(Friendship friendship) => Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FriendProfileScreen(friendship: friendship),
      ),
    );

    void openVisibleFriends(List<Friendship> friendships) {
      showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF1A1919),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (sheetContext) => FriendAccessSheet(
          friendships: friendships,
          onFriendTap: (friendship) {
            Navigator.of(sheetContext).pop();
            openFriend(friendship);
          },
        ),
      );
    }

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            CommunityHeader(
              incomingRequestsCount: incomingRequests.valueOrNull?.length ?? 0,
              onRequestsTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
              ),
              onAddFriendTap: openAddFriend,
            ),
            Expanded(
              child: friends.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: CommunityTheme.accentColor,
                  ),
                ),
                error: (_, _) => Center(
                  child: Text(
                    'Не удалось загрузить друзей',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
                data: (friendships) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  children: [
                    MyActivityPreviewCard(
                      visibleFriendsCount: friendships
                          .where(
                            (friendship) =>
                                friendship.myPermissionForFriend.scope !=
                                SharingScope.none,
                          )
                          .length,
                      onVisibleFriendsTap: () => openVisibleFriends(friendships),
                    ),
                    const SizedBox(height: 20),
                    if (friendships.isEmpty)
                      EmptyFriendsState(onAddFriendTap: openAddFriend)
                    else
                      FriendsActivitySection(
                        friendships: friendships,
                        onFriendTap: openFriend,
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
