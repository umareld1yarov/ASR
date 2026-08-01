import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart' as du;
import '../../../data/isar_service.dart';
import '../data/timer_repository.dart';
import '../domain/models/current_activity.dart';
import '../domain/models/activity_entry.dart';

/// Провайдер репозитория — единая точка доступа к данным таймера.
final timerRepositoryProvider = Provider<TimerRepository>((ref) {
  return TimerRepository(IsarService.instance);
});

/// Текущая активность — обновляется вручную после switchActivity()
/// через ref.invalidate(currentActivityProvider) (см. ниже).
final currentActivityProvider = FutureProvider<CurrentActivity?>((ref) async {
  final repo = ref.watch(timerRepositoryProvider);
  return repo.getCurrent();
});

/// Счётчик изменений записей — увеличивается при любом redit/delete/switch.
/// Работает как "сигнал сброса кэша" между фичами Timer и Feed.
final entriesChangedProvider = StateProvider<int>((ref) => 0);

/// Статистика по ЗАКРЫТЫМ записям за сегодня (секунды).
final closedStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(entriesChangedProvider); // пересчитать при любом изменении записей
  final repo = ref.watch(timerRepositoryProvider);
  final today = du.DateUtils.dateKeyFromMillis(
    DateTime.now().millisecondsSinceEpoch,
  );
  final entries = await repo.getEntriesByDate(today);

  final stats = <String, int>{
    'focus': 0,
    'religion': 0,
    'growth': 0,
    'sport': 0,
    'base': 0,
    'waste': 0,
  };
  for (final e in entries) {
    stats[e.categoryKey] = (stats[e.categoryKey] ?? 0) + e.durationSeconds;
  }
  return stats;
});

/// Тикающий таймер — сколько секунд прошло с начала текущей активности.
/// Аналог setInterval(..., 1000) из timer.js, но через Stream, без ручной очистки.
final elapsedSecondsProvider = StreamProvider<int>((ref) async* {
  final repo = ref.watch(timerRepositoryProvider);

  while (true) {
    final current = await repo.getCurrent();
    if (current == null) {
      yield 0;
    } else {
      final now = DateTime.now().millisecondsSinceEpoch;
      yield ((now - current.startedAt) / 1000).floor();
    }
    await Future.delayed(const Duration(seconds: 1));
  }
});

/// Контроллер действий — переключение активности + оповещение UI об обновлении.
class TimerController {
  TimerController(this._ref);

  final Ref _ref;

  TimerRepository get _repo => _ref.read(timerRepositoryProvider);

  Future<void> switchActivity({
    required String name,
    required String categoryKey,
  }) async {
    await _repo.switchActivity(name: name, categoryKey: categoryKey);

    // Оповещаем зависимые провайдеры, что данные изменились
    _ref.invalidate(currentActivityProvider);
    _ref.read(entriesChangedProvider.notifier).state++;
  }
}

final timerControllerProvider = Provider<TimerController>((ref) {
  return TimerController(ref);
});

/// Записи конкретной категории за сегодня — для экрана "детали категории".
/// family — параметризованный провайдер: один и тот же код работает
/// для любой категории, кэшируется отдельно на каждый categoryKey.
final categoryEntriesProvider =
    FutureProvider.family<List<ActivityEntry>, String>((
      ref,
      categoryKey,
    ) async {
      ref.watch(entriesChangedProvider);
      final repo = ref.watch(timerRepositoryProvider);
      final today = du.DateUtils.dateKeyFromMillis(
        DateTime.now().millisecondsSinceEpoch,
      );
      final entries = await repo.getEntriesByDate(today);
      return entries.where((e) => e.categoryKey == categoryKey).toList();
    });
