import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../timer/domain/models/activity_entry.dart';

/// Карточка одной записи в таймлайне Ленты — цветная подложка по категории,
/// время + длительность, название, заметка (зелёная), миниатюры фото.
class LogItemTile extends StatelessWidget {
  const LogItemTile({super.key, required this.entry, this.onTap});

  final ActivityEntry entry;
  final VoidCallback? onTap;

  static const _noteColor = Color(0xFF22C55E);

  String _time(int millis) {
    final d = DateTime.fromMillisecondsSinceEpoch(millis);
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  String _formatShort(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}ч ${m}м';
    return '${m}м';
  }

  @override
  Widget build(BuildContext context) {
    final category = ActivityCategory.fromStorageKey(entry.categoryKey);
    final photos = entry.photoPaths ?? [];
    final note = entry.note?.trim();
    final hasNote = note != null && note.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          color: category.color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: category.color.withValues(alpha: 0.15)),
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_time(entry.startedAt)} – ${_time(entry.endedAt)} · ${_formatShort(entry.durationSeconds)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.55),
                      ),
                    ),
                    Text(
                      category.label.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: category.color,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  entry.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                if (hasNote) ...[
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.notes_rounded,
                        size: 14,
                        color: _noteColor,
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: _noteColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (photos.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Row(
                    children: photos.take(4).map((path) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.file(
                            File(path),
                            width: 44,
                            height: 44,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 44,
                                height: 44,
                                color: const Color(0xFF1F1F1F),
                                child: const Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white24,
                                  size: 16,
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
            if (photos.isEmpty)
              Positioned(
                bottom: 0,
                right: 0,
                child: Icon(
                  Icons.camera_alt_outlined,
                  size: 15,
                  color: Colors.white.withValues(alpha: 0.22),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
