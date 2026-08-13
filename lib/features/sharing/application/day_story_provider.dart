import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/application/feed_provider.dart';
import '../../feed/data/feed_repository.dart';
import '../../timer/domain/models/activity_entry.dart';

enum DayStoryTheme {
  journal, // Стильный дневник с полароидами
  darkFocus, // Тёмный техно-фитнес/фокус с инфографикой
  minimalQuote, // Лаконичная типографика и главная мысль
}

/// Все данные дня для рендеринга сторис
class DayStoryData {
  const DayStoryData({
    required this.dateKey,
    required this.entries,
    required this.categoryGroups,
    required this.totalDurationSeconds,
    required this.categoryDurations,
  });

  final String dateKey;
  final List<ActivityEntry> entries;
  final List<DayStoryCategoryGroup> categoryGroups;
  final int totalDurationSeconds;
  final Map<String, int> categoryDurations;
}

final dayStoryDataProvider = FutureProvider.autoDispose
    .family<DayStoryData, String>((ref, dateKey) async {
      final repo = ref.watch(feedRepositoryProvider);
      final entries = await repo.getEntriesByDate(dateKey);
      final groups = await repo.getDayStoryGroups(dateKey);

      int totalSec = 0;
      final durations = <String, int>{};
      for (final e in entries) {
        totalSec += e.durationSeconds;
        durations[e.categoryKey] =
            (durations[e.categoryKey] ?? 0) + e.durationSeconds;
      }

      return DayStoryData(
        dateKey: dateKey,
        entries: entries,
        categoryGroups: groups,
        totalDurationSeconds: totalSec,
        categoryDurations: durations,
      );
    });

/// Состояние выбора пользователя на экране превью
class DayStorySelection {
  const DayStorySelection({
    required this.theme,
    required this.showStats,
    required this.showNotes,
    required this.photoIndexByEntry,
    required this.hiddenCaptionEntryIds,
  });

  final DayStoryTheme theme;
  final bool showStats;
  final bool showNotes;
  final Map<int, int> photoIndexByEntry;
  final Set<int> hiddenCaptionEntryIds;

  DayStorySelection copyWith({
    DayStoryTheme? theme,
    bool? showStats,
    bool? showNotes,
    Map<int, int>? photoIndexByEntry,
    Set<int>? hiddenCaptionEntryIds,
  }) {
    return DayStorySelection(
      theme: theme ?? this.theme,
      showStats: showStats ?? this.showStats,
      showNotes: showNotes ?? this.showNotes,
      photoIndexByEntry: photoIndexByEntry ?? this.photoIndexByEntry,
      hiddenCaptionEntryIds:
          hiddenCaptionEntryIds ?? this.hiddenCaptionEntryIds,
    );
  }
}

class DayStorySelectionController extends StateNotifier<DayStorySelection> {
  DayStorySelectionController()
    : super(
        const DayStorySelection(
          theme: DayStoryTheme.journal,
          showStats: true,
          showNotes: true,
          photoIndexByEntry: {},
          hiddenCaptionEntryIds: {},
        ),
      );

  void setTheme(DayStoryTheme theme) {
    state = state.copyWith(theme: theme);
  }

  void toggleShowStats() {
    state = state.copyWith(showStats: !state.showStats);
  }

  void toggleShowNotes() {
    state = state.copyWith(showNotes: !state.showNotes);
  }

  void selectPhoto(int entryId, int index) {
    final updated = Map<int, int>.from(state.photoIndexByEntry);
    updated[entryId] = index;
    state = state.copyWith(photoIndexByEntry: updated);
  }

  void toggleCaptionHidden(int entryId) {
    final updated = Set<int>.from(state.hiddenCaptionEntryIds);
    if (updated.contains(entryId)) {
      updated.remove(entryId);
    } else {
      updated.add(entryId);
    }
    state = state.copyWith(hiddenCaptionEntryIds: updated);
  }
}

final dayStorySelectionProvider =
    StateNotifierProvider.autoDispose<
      DayStorySelectionController,
      DayStorySelection
    >((ref) {
      return DayStorySelectionController();
    });
