import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../timer/application/timer_provider.dart';
import 'activity_status_pill.dart';
import 'community_avatar.dart';

/// Плашка "Как вас видят друзья" — 100% реальное отражение собственного статуса.
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
    // Регистрируем зависимость от локали для перевода "Как вас видят друзья", "Доступ" и т.д.
    final _ = context.locale;
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: category?.color.withValues(alpha: 0.08) ??
                Colors.white.withValues(alpha: 0.03),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: category?.color.withValues(alpha: 0.25) ??
                  Colors.white.withValues(alpha: 0.06),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.visibility_outlined,
                        size: 13,
                        color: Colors.white.withValues(alpha: 0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'community.how_friends_see_you'.tr(),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: onVisibleFriendsTap,
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.shield_outlined,
                            size: 12,
                            color: Color(0xFF06B6D4),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'community.access_count'.tr(args: ['$visibleFriendsCount']),
                            style: const TextStyle(
                              color: Color(0xFF06B6D4),
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  CommunityAvatar(
                    name: 'community.you'.tr(),
                    radius: 16,
                    showOnlineDot: true,
                    isOnline: isLive,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      isLive
                          ? 'community.online_status'.tr()
                          : 'community.offline_status'.tr(),
                      style: TextStyle(
                        color: isLive
                            ? const Color(0xFF22C55E)
                            : Colors.white.withValues(alpha: 0.35),
                        fontWeight: isLive ? FontWeight.w600 : FontWeight.w400,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ],
              ),
              if (isLive) ...[
                const SizedBox(height: 8),
                ActivityStatusPill(
                  activityName: current.name,
                  categoryKey: current.categoryKey,
                  startedAt: current.startedAt,
                  embedded: true,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
