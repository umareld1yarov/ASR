import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart' as du;
import '../../../data/isar_service.dart';
import '../data/feed_repository.dart';
import '../../timer/application/timer_provider.dart';

final feedRepositoryProvider = Provider<FeedRepository>((ref) {
  return FeedRepository(IsarService.instance);
});

/// Выбранная дата в Ленте — ВСЕГДА нормализована к полуночи (00:00:00).
/// Это критично: если хранить DateTime.now() как есть, время суток
/// "прилипает" при листании и ломает сравнения "сегодня/не сегодня".
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

/// Записи за выбранную дату.
final feedEntriesProvider = FutureProvider((ref) async {
  ref.watch(entriesChangedProvider); // обновляться при любом изменении записей
  final repo = ref.watch(feedRepositoryProvider);
  final date = ref.watch(selectedDateProvider);
  final dateKey = du.DateUtils.dateKey(date);
  return repo.getEntriesByDate(dateKey);
});

/// Самая ранняя дата с записями (тоже нормализована к полуночи) —
/// ограничивает кнопку "←", чтобы нельзя было улистать в дни без записей.
final earliestDateProvider = FutureProvider<DateTime?>((ref) async {
  final repo = ref.watch(feedRepositoryProvider);
  final millis = await repo.getEarliestStartedAt();
  if (millis == null) return null;
  final d = DateTime.fromMillisecondsSinceEpoch(millis);
  return DateTime(d.year, d.month, d.day);
});

class FeedController {
  FeedController(this._ref);

  final Ref _ref;

  FeedRepository get _repo => _ref.read(feedRepositoryProvider);

  Future<void> goToPreviousDay() async {
    final current = _ref.read(selectedDateProvider);
    // .future гарантированно ждёт полного завершения запроса к базе,
    // а не берёт "текущее" (возможно ещё не готовое) значение
    final earliest = await _ref.read(earliestDateProvider.future);
    final prevDay = current.subtract(const Duration(days: 1));

    // Не пускаем раньше самой ранней даты с записями
    if (earliest != null && prevDay.isBefore(earliest)) return;

    _ref.read(selectedDateProvider.notifier).state = prevDay;
  }

  void goToNextDay() {
    final current = _ref.read(selectedDateProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextDay = current.add(const Duration(days: 1));

    // Сравниваем дату с датой (без времени) — вот тут и была ошибка
    if (nextDay.isAfter(today)) return;

    _ref.read(selectedDateProvider.notifier).state = nextDay;
  }

  Future<void> updateEntry(
    int id, {
    String? name,
    String? categoryKey,
    String? note,
    String? mood,
    List<String>? obstacles,
    String? nextExperiment,
  }) async {
    await _repo.updateEntry(
      id,
      name: name,
      categoryKey: categoryKey,
      note: note,
      mood: mood,
      obstacles: obstacles,
      nextExperiment: nextExperiment,
    );
    _ref.invalidate(feedEntriesProvider);
    _ref.read(entriesChangedProvider.notifier).state++;
  }

  Future<void> addPhoto(int id, String photoPath) async {
    await _repo.addPhoto(id, photoPath);
    _ref.invalidate(feedEntriesProvider);
    _ref.read(entriesChangedProvider.notifier).state++;
  }

  Future<void> removePhoto(int id, String photoPath) async {
    await _repo.removePhoto(id, photoPath);
    _ref.invalidate(feedEntriesProvider);
    _ref.read(entriesChangedProvider.notifier).state++;
  }

  Future<void> deleteEntry(int id) async {
    await _repo.deleteEntry(id);
    _ref.invalidate(feedEntriesProvider);
    _ref.read(entriesChangedProvider.notifier).state++;
  }
}

final feedControllerProvider = Provider<FeedController>((ref) {
  return FeedController(ref);
});
