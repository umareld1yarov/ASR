import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../community_theme.dart';

class CommunityHeader extends StatelessWidget {
  const CommunityHeader({
    super.key,
    required this.incomingRequestsCount,
    required this.onRequestsTap,
    required this.onAddFriendTap,
  });

  final int incomingRequestsCount;
  final VoidCallback onRequestsTap;
  final VoidCallback onAddFriendTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          Text(
            'community.title'.tr(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const Spacer(),
          _HeaderAction(
            icon: Icons.group_outlined,
            badgeCount: incomingRequestsCount,
            tooltip: 'community.friend_requests'.tr(),
            onTap: onRequestsTap,
          ),
          const SizedBox(width: 8),
          _HeaderAction(
            icon: Icons.person_add_alt_1_outlined,
            tooltip: 'community.add_friend'.tr(),
            onTap: onAddFriendTap,
          ),
        ],
      ),
    );
  }
}

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Ink(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.06),
              shape: BoxShape.circle,
            ),
            child: Stack(
              children: [
                Center(child: Icon(icon, color: Colors.white70, size: 20)),
                if (badgeCount > 0)
                  Positioned(
                    top: 5,
                    right: 5,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 16),
                      height: 16,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: const BoxDecoration(
                        color: CommunityTheme.accentColor,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
