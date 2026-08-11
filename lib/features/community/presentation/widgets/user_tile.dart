import 'package:flutter/material.dart';

import '../../domain/models/community_user.dart';
import 'community_avatar.dart';

/// Единая карточка пользователя: аватар + имя + @username + действие справа.
/// Используется и в поиске (find_friends_screen), и в блоке рекомендаций
/// (community_screen) — раньше это были два почти одинаковых виджета.
class UserTile extends StatelessWidget {
  const UserTile({super.key, required this.user, required this.trailing});

  final CommunityUser user;

  /// Виджет действия справа — разный в разных местах использования
  /// (иконка в поиске, текстовая кнопка в рекомендациях), поэтому
  /// принимается снаружи, а не жёстко фиксируется внутри тайла.
  final Widget trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          CommunityAvatar(name: user.displayName, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                ),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.4),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
