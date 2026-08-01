import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';

/// Одна карточка статистики категории — время за сегодня.
/// Аналог .stat-card из index.html (PWA).
class CategoryStatCard extends StatelessWidget {
  const CategoryStatCard({
    super.key,
    required this.category,
    required this.seconds,
    this.onTap,
  });

  final ActivityCategory category;
  final int seconds;
  final VoidCallback? onTap;

  String _formatShort(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч $mм';
    return '$mм';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(12),
          border: Border(left: BorderSide(color: category.color, width: 3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatShort(seconds),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.label,
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
