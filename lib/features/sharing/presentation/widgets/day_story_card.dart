import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../feed/data/feed_repository.dart';
import '../../application/day_story_provider.dart';

/// Карточка "Дневник дня" — фиксированный формат 9:16 (360×640).
/// Поддерживает 3 премиальных шаблона:
/// 1. Journal (Полароидный коллаж)
/// 2. DarkFocus (Тёмный фокус с инфографикой и временем)
/// 3. MinimalQuote (Эстетичная типографика с мыслью дня)
class DayStoryCard extends ConsumerWidget {
  const DayStoryCard({super.key, required this.dateKey});

  final String dateKey;

  static const double width = 360;
  static const double height = 640;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(dayStoryDataProvider(dateKey));
    final selection = ref.watch(dayStorySelectionProvider);

    return SizedBox(
      width: width,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: dataAsync.when(
          loading: () => Container(
            color: const Color(0xFF141414),
            child: const Center(
              child: CircularProgressIndicator(color: Colors.white54),
            ),
          ),
          error: (e, _) => Container(
            color: const Color(0xFF141414),
            child: const Center(
              child: Text('Ошибка', style: TextStyle(color: Colors.white54)),
            ),
          ),
          data: (data) {
            switch (selection.theme) {
              case DayStoryTheme.journal:
                return _JournalThemeCard(data: data, selection: selection);
              case DayStoryTheme.darkFocus:
                return _DarkFocusThemeCard(data: data, selection: selection);
              case DayStoryTheme.minimalQuote:
                return _MinimalQuoteThemeCard(data: data, selection: selection);
            }
          },
        ),
      ),
    );
  }
}

/// 1. ШАБЛОН: Journal (Эстетичный коллаж-дневник с полароидами)
class _JournalThemeCard extends ConsumerWidget {
  const _JournalThemeCard({required this.data, required this.selection});

  final DayStoryData data;
  final DayStorySelection selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final slots = <DayStoryEntry>[
      for (final group in data.categoryGroups) ...group.entries,
    ];

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF2C2B30), Color(0xFF0F0F12)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
      child: Column(
        children: [
          // Шапка карточки
          _StoryHeader(dateKey: data.dateKey, themeLabel: 'ЖУРНАЛ ДНЯ'),
          const SizedBox(height: 12),

          // Статистика (если включена)
          if (selection.showStats && data.totalDurationSeconds > 0) ...[
            _MiniStatsBar(
              totalSeconds: data.totalDurationSeconds,
              durations: data.categoryDurations,
            ),
            const SizedBox(height: 12),
          ],

          // Сетка фото или пустое состояние
          Expanded(
            child: slots.isEmpty
                ? _NoPhotosPlaceholder(data: data, selection: selection)
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const columns = 2;
                      const spacing = 8.0;
                      final rows = (slots.length / columns).ceil();

                      final tileWidth =
                          (constraints.maxWidth - spacing * (columns - 1)) /
                          columns;
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
                              selection: selection,
                            ),
                        ],
                      );
                    },
                  ),
          ),

          const SizedBox(height: 12),
          // Нижний тихий логотип
          const _Watermark(),
        ],
      ),
    );
  }
}

/// 2. ШАБЛОН: DarkFocus (Тёмная инфографика с акцентным временем)
class _DarkFocusThemeCard extends ConsumerWidget {
  const _DarkFocusThemeCard({required this.data, required this.selection});

  final DayStoryData data;
  final DayStorySelection selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final photoEntries = data.entries
        .where((e) => e.photoPaths != null && e.photoPaths!.isNotEmpty)
        .toList();
    final firstPhoto = photoEntries.isNotEmpty ? photoEntries.first.photoPaths!.first : null;
    final notes = data.entries.where((e) => (e.note ?? '').trim().isNotEmpty).toList();

    final hours = data.totalDurationSeconds ~/ 3600;
    final minutes = (data.totalDurationSeconds % 3600) ~/ 60;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF18191E), Color(0xFF090A0C)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoryHeader(dateKey: data.dateKey, themeLabel: 'FOCUS & LIFE'),
          const SizedBox(height: 20),

          // Крупное время фокуса
          if (selection.showStats) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  hours > 0 ? '$hoursч $minutes' : '$minutes',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -1,
                  ),
                ),
                Text(
                  hours > 0 ? 'мин' : 'минут',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            Text(
              'общего осознанного времени',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.4),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),

            // Категории дня
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final entry in data.categoryDurations.entries)
                  if (entry.value > 0)
                    _CategoryPill(
                      category: ActivityCategory.fromStorageKey(entry.key),
                      durationSeconds: entry.value,
                    ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Главное фото дня (если есть)
          Expanded(
            child: firstPhoto != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(File(firstPhoto), fit: BoxFit.cover),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.75),
                              ],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                        if (selection.showNotes && notes.isNotEmpty)
                          Positioned(
                            left: 14,
                            right: 14,
                            bottom: 14,
                            child: Text(
                              '«${notes.first.note!.trim()}»',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                              ),
                            ),
                          ),
                      ],
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.bolt, color: Color(0xFF06B6D4), size: 36),
                        const SizedBox(height: 10),
                        if (selection.showNotes && notes.isNotEmpty)
                          Text(
                            '«${notes.first.note!.trim()}»',
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          )
                        else
                          Text(
                            'День наполнен продуктивностью и движением вперед.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                      ],
                    ),
                  ),
          ),

          const SizedBox(height: 14),
          const _Watermark(),
        ],
      ),
    );
  }
}

/// 3. ШАБЛОН: MinimalQuote (Минималистичный цитатник с мыслью дня)
class _MinimalQuoteThemeCard extends ConsumerWidget {
  const _MinimalQuoteThemeCard({required this.data, required this.selection});

  final DayStoryData data;
  final DayStorySelection selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notes = data.entries.where((e) => (e.note ?? '').trim().isNotEmpty).toList();
    final mainNote = notes.isNotEmpty ? notes.first.note!.trim() : 'День прошёл в балансе и фокусе.';

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D0E11),
      ),
      padding: const EdgeInsets.fromLTRB(26, 32, 26, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StoryHeader(dateKey: data.dateKey, themeLabel: 'THOUGHT OF THE DAY'),
          const Spacer(),

          const Text(
            '“',
            style: TextStyle(
              color: Color(0xFF06B6D4),
              fontSize: 64,
              fontFamily: 'Serif',
              height: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            mainNote,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w500,
              height: 1.4,
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 16),
          if (notes.isNotEmpty)
            Text(
              '— ${notes.first.name}',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),

          const Spacer(),

          if (selection.showStats && data.totalDurationSeconds > 0) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined, color: Colors.white70, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Фокус дня: ${_formatDuration(data.totalDurationSeconds)}',
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                  ),
                  const Spacer(),
                  Text(
                    '${data.entries.length} записей',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.4), fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          const _Watermark(),
        ],
      ),
    );
  }

  String _formatDuration(int totalSec) {
    final h = totalSec ~/ 3600;
    final m = (totalSec % 3600) ~/ 60;
    if (h > 0) return '$hч $m мин';
    return '$m мин';
  }
}

// ================= ВСПОМОГАТЕЛЬНЫЕ КОМПОНЕНТЫ =================

class _StoryHeader extends StatelessWidget {
  const _StoryHeader({required this.dateKey, required this.themeLabel});
  final String dateKey;
  final String themeLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          themeLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            dateKey,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStatsBar extends StatelessWidget {
  const _MiniStatsBar({
    required this.totalSeconds,
    required this.durations,
  });

  final int totalSeconds;
  final Map<String, int> durations;

  @override
  Widget build(BuildContext context) {
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            hours > 0 ? '$hoursч $mins мин' : '$mins мин',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final e in durations.entries)
                    if (e.value > 0)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          ActivityCategory.fromStorageKey(e.key).emoji,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.category, required this.durationSeconds});

  final ActivityCategory category;
  final int durationSeconds;

  @override
  Widget build(BuildContext context) {
    final mins = durationSeconds ~/ 60;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: category.color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(category.emoji, style: const TextStyle(fontSize: 11)),
          const SizedBox(width: 4),
          Text(
            '${category.label} · $minsм',
            style: TextStyle(
              color: category.color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NoPhotosPlaceholder extends StatelessWidget {
  const _NoPhotosPlaceholder({required this.data, required this.selection});
  final DayStoryData data;
  final DayStorySelection selection;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.photo_library_outlined, color: Colors.white.withValues(alpha: 0.3), size: 40),
            const SizedBox(height: 12),
            Text(
              'За этот день нет фотографий',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
            const SizedBox(height: 4),
            Text(
              'Переключите шаблон на «Тёмный фокус» или «Минимализм» для идеального вида!',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.35), fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _Watermark extends StatelessWidget {
  const _Watermark();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: const BoxDecoration(
            color: Color(0xFF06B6D4),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          'ASR · Focus & Life Journal',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.35),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.8,
          ),
        ),
      ],
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
    required this.selection,
  });

  final DayStoryEntry entry;
  final ActivityCategory category;
  final double width;
  final double height;
  final double rotationDegrees;
  final DayStorySelection selection;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(dayStorySelectionProvider.notifier);

    final photoIndex = selection.photoIndexByEntry[entry.entryId] ?? 0;
    final photoPath =
        entry.photoPaths[photoIndex.clamp(0, entry.photoPaths.length - 1)];
    final hasMultiplePhotos = entry.photoPaths.length > 1;
    final hasNote = (entry.note ?? '').trim().isNotEmpty;
    final captionHidden = selection.hiddenCaptionEntryIds.contains(entry.entryId);

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
                    Positioned(
                      left: 5,
                      right: 5,
                      bottom: (hasNote && selection.showNotes) ? 14 : 5,
                      child: Row(
                        children: [
                          Text(category.emoji, style: const TextStyle(fontSize: 9)),
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
                    if (hasNote && selection.showNotes)
                      Positioned(
                        left: 5,
                        right: 5,
                        bottom: 3,
                        child: GestureDetector(
                          onTap: () => controller.toggleCaptionHidden(entry.entryId),
                          child: Text(
                            captionHidden ? 'Скрыто' : '«${entry.note!.trim()}»',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 7.5,
                              fontStyle: FontStyle.italic,
                              color: captionHidden ? Colors.white38 : Colors.white70,
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
