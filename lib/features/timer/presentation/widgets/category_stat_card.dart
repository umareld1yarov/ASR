import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';

/// Одна карточка статистики категории — эмодзи, название, время за сегодня.
class CategoryStatCard extends StatelessWidget {
  const CategoryStatCard({
    super.key,
    required this.category,
    required this.seconds,
    required this.isActive,
    this.onTap,
  });

  final ActivityCategory category;
  final int seconds;
  final bool isActive;
  final VoidCallback? onTap;

  String _formatShort(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}ч ${m}м';
    return '${m}м';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: isActive ? 0.28 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: category.color.withValues(alpha: isActive ? 1.0 : 0.35),
            width: isActive ? 2 : 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: category.color.withValues(alpha: 0.55),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(category.emoji, style: const TextStyle(fontSize: 19)),
            const SizedBox(height: 1),
            Text(
              category.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 0),
            Text(
              _formatShort(seconds),
              style: const TextStyle(fontSize: 10.5, color: Colors.white54),
            ),
          ],
        ),
      ),
    );
  }
}
