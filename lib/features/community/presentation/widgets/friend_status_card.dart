import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/community_provider.dart';
import '../../data/community_repository.dart';
import '../../domain/models/friendship.dart';
import 'activity_status_pill.dart';
import 'community_avatar.dart';

/// Карточка одного друга в списке Сообщества.
class FriendStatusCard extends ConsumerStatefulWidget {
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
  ConsumerState<FriendStatusCard> createState() => _FriendStatusCardState();
}

class _FriendStatusCardState extends ConsumerState<FriendStatusCard> {
  static const _reactions = ['🔥', '🤲', '👏', '💪'];
  String? _selectedEmoji;

  void _toggleReaction(BuildContext context, String emoji) async {
    final repo = ref.read(communityRepositoryProvider);

    setState(() {
      if (_selectedEmoji == emoji) {
        _selectedEmoji = null;
      } else {
        _selectedEmoji = emoji;
      }
    });

    if (_selectedEmoji != null) {
      await repo.sendReaction(friendId: widget.friendship.friend.id, emoji: emoji);
      if (context.mounted) {
        final friendFirstName = widget.friendship.friend.displayName.split(' ').first;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text(emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text(
                  'community.respect_toast'.tr(args: [friendFirstName]),
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF1F1F1F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Регистрируем зависимость от локали для мгновенного обновления статуса друга
    final _ = context.locale;
    final friend = widget.friendship.friend;
    final currentStatus = widget.status;
    final isLive = currentStatus != null;
    final category = isLive && currentStatus.categoryKey != null
        ? ActivityCategory.fromStorageKey(currentStatus.categoryKey!)
        : null;

    final visibleReactions = _selectedEmoji != null ? [_selectedEmoji!] : _reactions;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: category?.color.withValues(alpha: 0.08) ??
            Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: category?.color.withValues(alpha: 0.25) ??
              Colors.white.withValues(alpha: 0.06),
        ),
      ),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CommunityAvatar(
                    name: friend.displayName,
                    radius: 18,
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
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          isLive
                              ? 'community.online_status'.tr()
                              : 'community.offline_status'.tr(),
                          style: TextStyle(
                            color: isLive
                                ? const Color(0xFF22C55E)
                                : Colors.white.withValues(alpha: 0.35),
                            fontSize: 11,
                            fontWeight: isLive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isLive)
                    Row(
                      children: visibleReactions.map((emoji) {
                        final isSelected = _selectedEmoji == emoji;
                        return Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: GestureDetector(
                            onTap: () => _toggleReaction(context, emoji),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFF06B6D4).withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFF06B6D4)
                                      : Colors.white.withValues(alpha: 0.08),
                                ),
                              ),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                ],
              ),

              if (isLive) ...[
                const SizedBox(height: 8),
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
      ),
    );
  }
}
