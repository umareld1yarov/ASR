import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../timer/domain/models/activity_entry.dart';

/// Одна строка записи в Ленте.
/// Аналог .log-item из index.html (PWA).
class LogItemTile extends StatelessWidget {
  const LogItemTile({super.key, required this.entry, this.onTap});

  final ActivityEntry entry;
  final VoidCallback? onTap;

  String _time(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatShort(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч $mм';
    return '$mм';
  }

  @override
  Widget build(BuildContext context) {
    final category = ActivityCategory.fromStorageKey(entry.categoryKey);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
        ),
        child: Row(
          children: [
            // Цветная полоска категории слева
            Container(
              width: 3,
              height: 36,
              decoration: BoxDecoration(
                color: category.color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Название + время + категория
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_time(entry.startedAt)} – ${_time(entry.endedAt)} · ${category.label}',
                    style: const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              ),
            ),

            // Длительность
            Text(
              _formatShort(entry.durationSeconds),
              style: const TextStyle(
                fontSize: 14,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
