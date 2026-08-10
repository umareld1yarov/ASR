import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../feed/data/feed_repository.dart';
import '../../application/day_story_provider.dart';

/// Карточка "Дневник дня" — фиксированный формат 9:16.
/// Раскладка — сетка 2 колонки с ВЫЧИСЛЕННЫМ размером плитки (через
/// LayoutBuilder), а не Expanded-доли по категориям. Это гарантирует, что
/// любое количество фото (хоть 2, хоть 10) всегда впишется в карточку без
/// переполнения — плитки просто становятся мельче, а не вылезают за рамки.
class DayStoryCard extends ConsumerWidget {
  const DayStoryCard({super.key, required this.dateKey});

  final String dateKey;

  static const double width = 360;
  static const double height = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(dayStoryGroupsProvider(dateKey));

    return SizedBox(
      width: width,
      height: height,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(255, 60, 58, 58),
              Color.fromARGB(255, 12, 12, 12),
            ],
          ),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: width * 0.06,
          vertical: height * 0.09,
        ),
        child: groupsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: Colors.white54),
          ),
          error: (e, _) => const Center(
            child: Text('Ошибка', style: TextStyle(color: Colors.white54)),
          ),
          data: (groups) {
            // Разворачиваем группы категорий в плоский список "слотов" —
            // по одному на запись, порядок сохраняется (хронология дня).
            final slots = <DayStoryEntry>[
              for (final group in groups) ...group.entries,
            ];

            if (slots.isEmpty) {
              return const Center(
                child: Text(
                  'За сегодня пока нет фото',
                  style: TextStyle(color: Colors.white38, fontSize: 13),
                  textAlign: TextAlign.center,
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                const columns = 2;
                const spacing = 8.0;
                final rows = (slots.length / columns).ceil();

                final tileWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                final tileHeight =
                    (constraints.maxHeight - spacing * (rows - 1)) / rows;

                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: [
                    for (var i = 0; i < slots.length; i++)
                      _PolaroidTile(
                        entry: slots[i],
                        category: ActivityCategory.fromStorageKey(
                          slots[i].categoryKey,
                        ),
                        width: tileWidth,
                        height: tileHeight,
                        rotationDegrees: i.isEven ? -2.5 : 2.0,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _PolaroidTile extends ConsumerWidget {
  const _PolaroidTile({
    required this.entry,
    required this.category,
    required this.width,
    required this.height,
    required this.rotationDegrees,
  });

  final DayStoryEntry entry;
  final ActivityCategory category;
  final double width;
  final double height;
  final double rotationDegrees;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(dayStorySelectionProvider.notifier);
    final selection = ref.watch(dayStorySelectionProvider);

    final photoIndex = selection.photoIndexByEntry[entry.entryId] ?? 0;
    final photoPath =
        entry.photoPaths[photoIndex.clamp(0, entry.photoPaths.length - 1)];
    final hasMultiplePhotos = entry.photoPaths.length > 1;
    final hasNote = (entry.note ?? '').trim().isNotEmpty;
    final captionHidden = selection.hiddenCaptionEntryIds.contains(
      entry.entryId,
    );

    // Небольшой отступ под рамку/тень, чтобы соседние повёрнутые плитки
    // не наезжали друг на друга при небольшом угле поворота.
    return Padding(
      padding: const EdgeInsets.all(3),
      child: Transform.rotate(
        angle: rotationDegrees * 3.14159 / 180,
        child: SizedBox(
          width: width - 6,
          height: height - 6,
          child: GestureDetector(
            onTap: hasMultiplePhotos
                ? () => controller.selectPhoto(
                    entry.entryId,
                    (photoIndex + 1) % entry.photoPaths.length,
                  )
                : null,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(File(photoPath), fit: BoxFit.cover),

                    // Затемнение снизу, чтобы текст поверх фото читался.
                    const Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black54],
                            stops: [0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    if (hasMultiplePhotos)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${photoIndex + 1}/${entry.photoPaths.length}',
                            style: const TextStyle(
                              fontSize: 8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                    // Подпись — категория + название, внутри кадра снизу.
                    Positioned(
                      left: 5,
                      right: 5,
                      bottom: hasNote ? 14 : 5,
                      child: Row(
                        children: [
                          Text(
                            category.emoji,
                            style: const TextStyle(fontSize: 9),
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              entry.entryName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    if (hasNote)
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: 3,
                        child: GestureDetector(
                          onTap: () =>
                              controller.toggleCaptionHidden(entry.entryId),
                          child: Text(
                            captionHidden
                                ? 'Скрыто'
                                : '«${entry.note!.trim()}»',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 7.5,
                              fontStyle: FontStyle.italic,
                              color: captionHidden
                                  ? Colors.white38
                                  : Colors.white70,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
