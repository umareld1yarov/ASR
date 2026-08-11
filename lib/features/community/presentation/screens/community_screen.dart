import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/community_provider.dart';
import '../../domain/models/community_user.dart';
import '../widgets/friend_status_card.dart';
import '../widgets/my_activity_preview_card.dart';
import 'find_friends_screen.dart';
import 'friend_profile_screen.dart';
import 'friend_requests_screen.dart';
import '../../community_theme.dart';

/// Главный экран вкладки "Сообщества": превью моей активности сверху,
/// список друзей на всю ширину, сворачиваемый блок рекомендаций внизу.
class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  bool _suggestionsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendsProvider);
    final incomingAsync = ref.watch(incomingRequestsProvider);

    return AppBackground(
      child: SafeArea(
        child: Column(
          children: [
            _Header(incomingCount: incomingAsync.valueOrNull?.length ?? 0),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                children: [
                  const MyActivityPreviewCard(),
                  const SizedBox(height: 20),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'друзья сейчас',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  friendsAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.symmetric(vertical: 20),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: CommunityTheme.accentColor,
                        ),
                      ),
                    ),
                    error: (e, _) => Text(
                      'Не удалось загрузить друзей',
                      style: TextStyle(color: Colors.white.withOpacity(0.5)),
                    ),
                    data: (friendships) {
                      if (friendships.isEmpty) {
                        return const _EmptyFriendsHint();
                      }
                      return Column(
                        children: friendships.map((friendship) {
                          final statusAsync = ref.watch(
                            friendActivityStatusProvider(friendship.friend.id),
                          );
                          return FriendStatusCard(
                            friendship: friendship,
                            status: statusAsync.valueOrNull,
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => FriendProfileScreen(
                                    friendship: friendship,
                                  ),
                                ),
                              );
                            },
                          );
                        }).toList(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SuggestionsSection(
                    expanded: _suggestionsExpanded,
                    onToggle: () => setState(
                      () => _suggestionsExpanded = !_suggestionsExpanded,
                    ),
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

class _SuggestionsSection extends ConsumerWidget {
  const _SuggestionsSection({required this.expanded, required this.onToggle});

  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        GestureDetector(
          onTap: onToggle,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.05),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.group_add_outlined,
                  color: Colors.white.withOpacity(0.7),
                  size: 18,
                ),
                const SizedBox(width: 8),
                Text(
                  'найти единомышленников',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13.5,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: Colors.white.withOpacity(0.5),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
        if (expanded) ...[const SizedBox(height: 10), _SuggestionsList()],
      ],
    );
  }
}

class _SuggestionsList extends ConsumerWidget {
  const _SuggestionsList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestedAsync = ref.watch(suggestedUsersProvider);
    final controller = ref.read(communityControllerProvider);

    return suggestedAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Colors.white38,
          ),
        ),
      ),
      error: (e, _) => Text(
        'Ошибка загрузки',
        style: TextStyle(color: Colors.white.withOpacity(0.4)),
      ),
      data: (users) {
        if (users.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'Пока нет новых рекомендаций',
              style: TextStyle(
                color: Colors.white.withOpacity(0.35),
                fontSize: 13,
              ),
            ),
          );
        }
        return Column(
          children: users
              .map(
                (user) => _SuggestedUserTile(
                  user: user,
                  onAdd: () async {
                    await controller.sendFriendRequest(user.id);
                  },
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SuggestedUserTile extends StatelessWidget {
  const _SuggestedUserTile({required this.user, required this.onAdd});

  final CommunityUser user;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Colors.white.withOpacity(0.1),
            child: Text(
              user.displayName.isNotEmpty
                  ? user.displayName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              backgroundColor: CommunityTheme.accentColor.withOpacity(0.15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Добавить',
              style: TextStyle(
                color: CommunityTheme.accentColor,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.incomingCount});

  final int incomingCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          const Text(
            'Сообщества',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _IconButtonWithBadge(
            icon: Icons.person_add_alt_1_outlined,
            badgeCount: incomingCount,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          _IconButtonWithBadge(
            icon: Icons.search,
            badgeCount: 0,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const FindFriendsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _IconButtonWithBadge extends StatelessWidget {
  const _IconButtonWithBadge({
    required this.icon,
    required this.badgeCount,
    required this.onTap,
  });

  final IconData icon;
  final int badgeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          shape: BoxShape.circle,
        ),
        child: Stack(
          children: [
            Center(child: Icon(icon, color: Colors.white70, size: 20)),
            if (badgeCount > 0)
              Positioned(
                right: 4,
                top: 4,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: CommunityTheme.accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyFriendsHint extends StatelessWidget {
  const _EmptyFriendsHint();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Text(
        'Пока нет друзей — загляни в блок ниже',
        style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13),
      ),
    );
  }
}
