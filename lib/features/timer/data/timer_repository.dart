import 'package:isar_community/isar.dart';

import '../../../core/utils/date_utils.dart' as du;
import '../domain/models/activity_entry.dart';
import '../domain/models/activity_suggestion.dart';
import '../domain/models/current_activity.dart';

/// Репозиторий таймера: работа с текущей активностью и завершёнными записями.
/// Логика нарезки по полуночи — прямой перенос _ensureSliced из timer.js.
class TimerRepository {
  TimerRepository(this._isar);

  final Isar _isar;

  static const int _minDurationSeconds = 5;

  // ── Текущая активность ──────────────────────

  Future<CurrentActivity?> getCurrent() {
    return _isar.currentActivitys.get(0);
  }

  Future<void> _setCurrent(CurrentActivity activity) async {
    await _isar.writeTxn(() async {
      await _isar.currentActivitys.put(activity);
    });
  }

  Future<void> _clearCurrent() async {
    await _isar.writeTxn(() async {
      await _isar.currentActivitys.delete(0);
    });
  }

  // ── Завершённые записи ──────────────────────

  Future<void> _addEntry(ActivityEntry entry) async {
    await _isar.writeTxn(() async {
      await _isar.activityEntrys.put(entry);
    });
  }

  Future<List<ActivityEntry>> getEntriesByDate(String dateKey) {
    return _isar.activityEntrys
        .filter()
        .dateKeyEqualTo(dateKey)
        .isDeletedEqualTo(false)
        .sortByStartedAt()
        .findAll();
  }

  /// Returns every distinct activity ever completed in [categoryKey]. Names are
  /// normalized for comparison, while the spelling from the most recent entry
  /// is retained for display.
  Future<List<ActivitySuggestion>> getActivitySuggestions(
    String categoryKey,
  ) async {
    final entries = await _isar.activityEntrys
        .filter()
        .categoryKeyEqualTo(categoryKey)
        .isDeletedEqualTo(false)
        .findAll();

    final grouped = <String, _SuggestionAccumulator>{};

    void addName(String name, int usedAt) {
      final displayName = name.trim();
      if (displayName.isEmpty) return;
      final normalizedName = displayName.toLowerCase();
      final current = grouped[normalizedName];
      if (current == null) {
        grouped[normalizedName] = _SuggestionAccumulator(
          displayName: displayName,
          usesCount: 1,
          lastUsedAt: usedAt,
        );
      } else {
        current.usesCount++;
        if (usedAt > current.lastUsedAt) {
          current.displayName = displayName;
          current.lastUsedAt = usedAt;
        }
      }
    }

    for (final entry in entries) {
      addName(entry.name, entry.startedAt);
    }

    // A just-started activity has not become a completed entry yet, but it
    // should already be reusable if the user opens the picker again.
    final currentActivity = await getCurrent();
    if (currentActivity?.categoryKey == categoryKey) {
      addName(currentActivity!.name, currentActivity.startedAt);
    }

    final suggestions = grouped.values
        .map(
          (item) => ActivitySuggestion(
            name: item.displayName,
            usesCount: item.usesCount,
            lastUsedAt: item.lastUsedAt,
          ),
        )
        .toList();
    suggestions.sort((a, b) {
      final byUses = b.usesCount.compareTo(a.usesCount);
      return byUses != 0 ? byUses : b.lastUsedAt.compareTo(a.lastUsedAt);
    });
    return suggestions;
  }

  // ── Нарезка по полуночи ──────────────────────
  //
  // Принимает "черновик" активности (name/categoryKey/startedAt) и момент
  // окончания endMillis. Если между startedAt и endMillis есть одна или
  // несколько полуночей — сохраняет промежуточные куски как отдельные
  // ActivityEntry и возвращает startedAt последнего (незакрытого) куска —
  // именно его вызывающий код должен закрыть/сохранить сам.
  //
  // Если полночей между start и end нет — просто возвращает исходный startedAt.

  Future<int> _ensureSliced({
    required String name,
    required String categoryKey,
    required int startedAt,
    required int endMillis,
  }) async {
    int currentStart = startedAt;

    while (du.DateUtils.dateKeyFromMillis(currentStart) !=
        du.DateUtils.dateKeyFromMillis(endMillis)) {
      final midnight = du.DateUtils.nextMidnight(
        DateTime.fromMillisecondsSinceEpoch(currentStart),
      );
      final midnightMillis = midnight.millisecondsSinceEpoch;

      final durationSeconds = ((midnightMillis - currentStart) / 1000).floor();

      final chunk = ActivityEntry()
        ..name = name
        ..categoryKey = categoryKey
        ..startedAt = currentStart
        ..endedAt = midnightMillis
        ..durationSeconds = durationSeconds
        ..dateKey = du.DateUtils.dateKeyFromMillis(currentStart);

      await _addEntry(chunk);

      currentStart = midnightMillis;
    }

    return currentStart;
  }

  // ── Инициализация при старте приложения ─────
  //
  // Если текущая активность началась не сегодня (телефон лежал всю ночь) —
  // нарезаем прошедшие сутки и обновляем CurrentActivity на "сегодняшний кусок".
  // Аналог Timer.init() из timer.js.

  Future<void> initializeOnStart() async {
    final current = await getCurrent();
    if (current == null) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final today = du.DateUtils.dateKeyFromMillis(now);

    if (du.DateUtils.dateKeyFromMillis(current.startedAt) != today) {
      final todayStart = await _ensureSliced(
        name: current.name,
        categoryKey: current.categoryKey,
        startedAt: current.startedAt,
        endMillis: now,
      );

      final updated = CurrentActivity()
        ..name = current.name
        ..categoryKey = current.categoryKey
        ..startedAt = todayStart;

      await _setCurrent(updated);
    }
  }

  // ── Переключение активности ──────────────────
  //
  // Закрывает предыдущую активность (с нарезкой по полуночи если нужно)
  // и запускает новую. Аналог Timer.switchActivity() из timer.js.

  Future<void> switchActivity({
    required String name,
    required String categoryKey,
    String? reviewMood,
    List<String>? reviewObstacles,
    String? reviewNextExperiment,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;

    final prev = await getCurrent();
    if (prev != null) {
      final totalDuration = ((now - prev.startedAt) / 1000).floor();

      if (totalDuration >= _minDurationSeconds) {
        final lastChunkStart = await _ensureSliced(
          name: prev.name,
          categoryKey: prev.categoryKey,
          startedAt: prev.startedAt,
          endMillis: now,
        );

        final durationSeconds = ((now - lastChunkStart) / 1000).floor();

        final finalEntry = ActivityEntry()
          ..name = prev.name
          ..categoryKey = prev.categoryKey
          ..startedAt = lastChunkStart
          ..endedAt = now
          ..durationSeconds = durationSeconds
          ..dateKey = du.DateUtils.dateKeyFromMillis(lastChunkStart)
          ..mood = reviewMood
          ..obstacles = reviewObstacles
          ..nextExperiment = reviewNextExperiment;

        await _addEntry(finalEntry);
      }
    }

    final newCurrent = CurrentActivity()
      ..name = name.trim()
      ..categoryKey = categoryKey
      ..startedAt = now;

    await _setCurrent(newCurrent);
  }

  // ── Статистика дня ───────────────────────────
  //
  // Возвращает секунды по каждой категории за сегодня, включая
  // текущую незакрытую активность в реальном времени.
  // Аналог Timer.getTodayStats() из timer.js.

  Future<Map<String, int>> getTodayStats() async {
    final today = du.DateUtils.dateKeyFromMillis(
      DateTime.now().millisecondsSinceEpoch,
    );

    final entries = await getEntriesByDate(today);

    final stats = <String, int>{
      'religion': 0,
      'work': 0,
      'growth': 0,
      'finance': 0,
      'sport': 0,
      'family': 0,
      'rest': 0,
      'waste': 0,
      'base': 0,
    };

    for (final e in entries) {
      stats[e.categoryKey] = (stats[e.categoryKey] ?? 0) + e.durationSeconds;
    }

    final current = await getCurrent();
    if (current != null) {
      final now = DateTime.now().millisecondsSinceEpoch;

      if (du.DateUtils.dateKeyFromMillis(current.startedAt) == today) {
        final elapsed = ((now - current.startedAt) / 1000).floor();
        stats[current.categoryKey] =
            (stats[current.categoryKey] ?? 0) + elapsed;
      } else {
        final todayMidnight = DateTime.now();
        final midnightMillis = DateTime(
          todayMidnight.year,
          todayMidnight.month,
          todayMidnight.day,
        ).millisecondsSinceEpoch;
        final elapsedToday = ((now - midnightMillis) / 1000).floor();
        stats[current.categoryKey] =
            (stats[current.categoryKey] ?? 0) + elapsedToday;
      }
    }

    return stats;
  }

  // ── Редактирование / удаление записи (для Ленты) ──

  Future<void> updateEntry(int id, {String? name, String? categoryKey}) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.activityEntrys.get(id);
      if (entry == null) return;
      if (name != null) entry.name = name;
      if (categoryKey != null) entry.categoryKey = categoryKey;
      await _isar.activityEntrys.put(entry);
    });
  }

  Future<void> deleteEntry(int id) async {
    await _isar.writeTxn(() async {
      final entry = await _isar.activityEntrys.get(id);
      if (entry == null) return;
      entry.isDeleted = true;
      await _isar.activityEntrys.put(entry);
    });
  }
}

class _SuggestionAccumulator {
  _SuggestionAccumulator({
    required this.displayName,
    required this.usesCount,
    required this.lastUsedAt,
  });

  String displayName;
  int usesCount;
  int lastUsedAt;
}
