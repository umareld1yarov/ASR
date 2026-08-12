import 'package:flutter/material.dart';

import '../../community_theme.dart';

class EmptyFriendsState extends StatelessWidget {
  const EmptyFriendsState({super.key, required this.onAddFriendTap});

  final VoidCallback onAddFriendTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Icon(
            Icons.people_outline,
            size: 30,
            color: Colors.white.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          const Text(
            'Пока нет друзей',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Добавьте друга по username, чтобы видеть, чем он занят сейчас.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withValues(alpha: 0.45)),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: onAddFriendTap,
            icon: const Icon(Icons.person_add_alt_1, size: 18),
            label: const Text('Добавить друга'),
            style: TextButton.styleFrom(
              foregroundColor: CommunityTheme.accentColor,
            ),
          ),
        ],
      ),
    );
  }
}
