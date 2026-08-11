import 'package:flutter/material.dart';

import '../../community_theme.dart';

/// Единый аватар пользователя Сообщества — кружок с первой буквой имени
/// (позже, с подключением Supabase Storage, сюда добавится показ
/// реального avatarUrl через NetworkImage, если он есть).
/// Опционально показывает индикатор "онлайн" в правом нижнем углу.
class CommunityAvatar extends StatelessWidget {
  const CommunityAvatar({
    super.key,
    required this.name,
    this.radius = 20,
    this.showOnlineDot = false,
    this.isOnline = false,
  });

  final String name;
  final double radius;

  /// Показывать ли индикатор онлайн-статуса вообще (некоторым местам,
  /// например списку рекомендаций, индикатор не нужен в принципе).
  final bool showOnlineDot;

  /// Сам статус — используется только если showOnlineDot == true.
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white.withValues(alpha: 0.1),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w600,
          fontSize: radius * 0.75,
        ),
      ),
    );

    if (!showOnlineDot) return avatar;

    final dotSize = radius * 0.55;

    return Stack(
      children: [
        avatar,
        if (isOnline)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: dotSize,
              height: dotSize,
              decoration: BoxDecoration(
                color: CommunityTheme.liveColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF0A0A0A),
                  width: radius * 0.15,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
