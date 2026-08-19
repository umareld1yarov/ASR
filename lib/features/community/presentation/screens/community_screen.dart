import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../../auth/application/auth_controller.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../application/community_provider.dart';
import '../../community_theme.dart';
import '../../domain/models/friendship.dart';
import '../../domain/models/sharing_permission.dart';
import '../widgets/community_header.dart';
import '../widgets/empty_friends_state.dart';
import '../widgets/friends_activity_section.dart';
import '../widgets/friend_access_sheet.dart';
import '../widgets/live_focus_bar.dart';
import '../widgets/my_activity_preview_card.dart';
import 'find_friends_screen.dart';
import 'friend_profile_screen.dart';
import 'friend_requests_screen.dart';

class CommunityScreen extends ConsumerWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = context.locale;
    final authState = ref.watch(authControllerProvider);

    // Если пользователь еще не авторизован — показываем приветственный экран
    if (!authState.isAuthenticated) {
      return AppBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.people_alt_outlined,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'auth.community_guest_title'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'auth.community_guest_desc'.tr(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white60,
                    height: 1.4,
                  ),
                ),
                const Spacer(),
                SizedBox(
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    },
                    icon: const Icon(Icons.login, size: 20),
                    label: Text(
                      'auth.login_or_register'.tr(),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      );
    }

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
                    'common.error'.tr(),
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                  ),
                ),
                data: (friendships) => ListView(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                  children: [
                    LiveFocusBar(
                      friendships: friendships,
                      onFriendTap: openFriend,
                    ),
                    const SizedBox(height: 12),

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
                    const SizedBox(height: 18),

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
