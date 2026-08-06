import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../../core/utils/date_utils.dart' as du;
import '../../application/profile_provider.dart';
import '../screens/memories_screen.dart';

/// Широкая плитка-тизер "Воспоминания" — случайное старое фото с названием
/// и датой, тап открывает полный экран-галерею всех фото.
class MemoryCard extends ConsumerWidget {
  const MemoryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memoryAsync = ref.watch(memoryEntryProvider);

    return memoryAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (entry) {
        if (entry == null ||
            entry.photoPaths == null ||
            entry.photoPaths!.isEmpty) {
          return const SizedBox.shrink();
        }

        final category = ActivityCategory.fromStorageKey(entry.categoryKey);
        final dateLabel = du.DateUtils.formatShortRu(
          DateTime.fromMillisecondsSinceEpoch(entry.startedAt),
        );

        return GestureDetector(
          onTap: () => Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const MemoriesScreen())),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Stack(
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Image.file(
                    File(entry.photoPaths!.first),
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.4, 1.0],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 12,
                  child: Row(
                    children: [
                      Text(
                        category.emoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
