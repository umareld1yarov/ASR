import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../feed/data/feed_repository.dart';
import '../../feed/application/feed_provider.dart';

/// Группы фото дня для "Дневника дня" — данные не меняются в рамках
/// одного открытия экрана превью, поэтому autoDispose: при выходе с экрана
/// провайдер сбрасывается, при следующем открытии данные читаются заново.
final dayStoryGroupsProvider = FutureProvider.autoDispose
    .family<List<DayStoryCategoryGroup>, String>((ref, dateKey) async {
      final repo = ref.watch(feedRepositoryProvider);
      return repo.getDayStoryGroups(dateKey);
    });

/// Состояние выбора пользователя на экране превью: какое фото выбрано
/// для каждой записи (по умолчанию — первое, индекс 0) и какие подписи
/// (заметки) скрыты от финального шера.
class DayStorySelection {
  const DayStorySelection({
    required this.photoIndexByEntry,
    required this.hiddenCaptionEntryIds,
  });

  final Map<int, int> photoIndexByEntry;
  final Set<int> hiddenCaptionEntryIds;
}

class DayStorySelectionController extends StateNotifier<DayStorySelection> {
  DayStorySelectionController()
    : super(
        const DayStorySelection(
          photoIndexByEntry: {},
          hiddenCaptionEntryIds: {},
        ),
      );

  int photoIndexFor(int entryId) => state.photoIndexByEntry[entryId] ?? 0;

  bool isCaptionHidden(int entryId) =>
      state.hiddenCaptionEntryIds.contains(entryId);

  void selectPhoto(int entryId, int index) {
    final updated = Map<int, int>.from(state.photoIndexByEntry);
    updated[entryId] = index;
    state = DayStorySelection(
      photoIndexByEntry: updated,
      hiddenCaptionEntryIds: state.hiddenCaptionEntryIds,
    );
  }

  void toggleCaptionHidden(int entryId) {
    final updated = Set<int>.from(state.hiddenCaptionEntryIds);
    if (updated.contains(entryId)) {
      updated.remove(entryId);
    } else {
      updated.add(entryId);
    }
    state = DayStorySelection(
      photoIndexByEntry: state.photoIndexByEntry,
      hiddenCaptionEntryIds: updated,
    );
  }
}

/// autoDispose — состояние выбора всегда стартует "с чистого листа" при
/// каждом новом открытии экрана превью (заметки видны по умолчанию,
/// выбрано первое фото каждой записи).
final dayStorySelectionProvider =
    StateNotifierProvider.autoDispose<
      DayStorySelectionController,
      DayStorySelection
    >((ref) {
      return DayStorySelectionController();
    });
