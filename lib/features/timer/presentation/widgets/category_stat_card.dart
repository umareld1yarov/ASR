import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';

import '../../../../core/utils/duration_formatter.dart';

/// Одна карточка статистики категории — эмодзи, название, время за сегодня.
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
    return formatDuration(seconds);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 4),
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: category.color.withValues(alpha: 0.18),
            width: 1,
          ),
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
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              _formatShort(seconds),
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white70,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
