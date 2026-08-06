import '../../../core/constants/activity_category.dart';

/// Тон инсайта — влияет на цвет/иконку в UI.
enum InsightTone { positive, warning, neutral }

class Insight {
  const Insight({required this.emoji, required this.text, required this.tone});

  final String emoji;
  final String text;
  final InsightTone tone;
}

/// Категории, которые считаются "продуктивными" при расчёте баланса.
const _productiveKeys = {
  'religion',
  'work',
  'growth',
  'finance',
  'sport',
  'family',
};

const _wasteKey = 'waste';

/// Минимальный порог в секундах, ниже которого разницу/долю не считаем
/// значимой — чтобы не генерировать инсайты из шума в 2 минуты.
const _noiseThresholdSeconds = 600; // 10 минут

String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}ч ${m}м';
  return '${m}м';
}

String _categoryLabel(String key) {
  return ActivityCategory.fromStorageKey(key).label;
}

/// Главная функция движка. Принимает агрегированные данные периода и
/// возвращает готовые фразы-инсайты, отсортированные по важности.
///
/// [current] — секунды по категориям за текущий период (включая live-время).
/// [previous] — секунды по категориям за предыдущий период той же длины.
/// [dailyByCategory] — секунды по дням+категориям текущего периода (для стриков).
/// [periodDaysCount] — сколько дней в периоде (для расчёта просадок по среднему).
List<Insight> buildInsights({
  required Map<String, int> current,
  required Map<String, int> previous,
  required Map<String, Map<String, int>> dailyByCategory,
  required int periodDaysCount,
}) {
  final candidates = <Insight>[];

  _addBalanceInsight(candidates, current);
  _addDeltaInsights(candidates, current, previous);
  _addStreakInsight(candidates, dailyByCategory);
  _addDropOffInsight(candidates, current, previous, periodDaysCount);

  // Не перегружаем UI — максимум 3 самых значимых.
  return candidates.take(3).toList();
}

// ── Баланс продуктив/потери ──────────────────────────

void _addBalanceInsight(List<Insight> out, Map<String, int> current) {
  final trackedTotal = current.values.fold(0, (a, b) => a + b);
  if (trackedTotal == 0) return;

  final wasteTotal = current[_wasteKey] ?? 0;
  final wasteShare = wasteTotal / trackedTotal;

  if (wasteTotal >= _noiseThresholdSeconds && wasteShare >= 0.3) {
    final percent = (wasteShare * 100).round();
    out.add(
      Insight(
        emoji: '⏳',
        text:
            '$percent% времени ушло в Потери — это ${_formatDuration(wasteTotal)}. '
            'В следующий раз попробуй поймать этот момент и переключиться.',
        tone: InsightTone.warning,
      ),
    );
  } else if (trackedTotal >= _noiseThresholdSeconds && wasteShare < 0.15) {
    final percent = (wasteShare * 100).round();
    out.add(
      Insight(
        emoji: '🔥',
        text: 'Отличный баланс — на Потери ушло всего $percent%. Так держать!',
        tone: InsightTone.positive,
      ),
    );
  }
}

// ── Сравнение с прошлым периодом ─────────────────────

void _addDeltaInsights(
  List<Insight> out,
  Map<String, int> current,
  Map<String, int> previous,
) {
  // Ищем категорию с наибольшим ростом среди продуктивных.
  String? bestKey;
  int bestDelta = 0;
  for (final key in _productiveKeys) {
    final delta = (current[key] ?? 0) - (previous[key] ?? 0);
    if (delta > bestDelta) {
      bestDelta = delta;
      bestKey = key;
    }
  }

  if (bestKey != null && bestDelta >= _noiseThresholdSeconds) {
    final prevValue = previous[bestKey] ?? 0;
    if (prevValue > 0) {
      final percent = ((bestDelta / prevValue) * 100).round();
      out.add(
        Insight(
          emoji: '📈',
          text:
              '${_categoryLabel(bestKey)} выросл${_genderSuffix(bestKey)} на $percent% '
              'по сравнению с прошлым периодом.',
          tone: InsightTone.positive,
        ),
      );
    } else {
      out.add(
        Insight(
          emoji: '✨',
          text:
              '${_categoryLabel(bestKey)} впервые появил${_genderSuffix(bestKey)}сь '
              'в этом периоде — ${_formatDuration(current[bestKey] ?? 0)}.',
          tone: InsightTone.positive,
        ),
      );
    }
  }

  // Рост потерь — отдельно и всегда как предупреждение.
  final wasteDelta = (current[_wasteKey] ?? 0) - (previous[_wasteKey] ?? 0);
  if (wasteDelta >= _noiseThresholdSeconds) {
    final prevWaste = previous[_wasteKey] ?? 0;
    if (prevWaste > 0) {
      final percent = ((wasteDelta / prevWaste) * 100).round();
      out.add(
        Insight(
          emoji: '⚠️',
          text: 'Потери выросли на $percent% по сравнению с прошлым периодом.',
          tone: InsightTone.warning,
        ),
      );
    }
  }
}

/// Грубое согласование рода для глагола ("вырос"/"выросла") — по последней
/// букве label. Не идеально лингвистически, но покрывает все 9 категорий верно.
String _genderSuffix(String key) {
  final label = _categoryLabel(key);
  return label.endsWith('а') || label.endsWith('я') ? 'а' : '';
}

// ── Стрики ────────────────────────────────────────────

void _addStreakInsight(
  List<Insight> out,
  Map<String, Map<String, int>> dailyByCategory,
) {
  if (dailyByCategory.length < 3) return; // стрик короче 3 дней не считаем

  final sortedDays = dailyByCategory.keys.toList()..sort();

  String? bestKey;
  int bestStreak = 0;

  for (final category in _productiveKeys) {
    int streak = 0;
    // Идём от самого свежего дня назад, пока категория присутствует.
    for (var i = sortedDays.length - 1; i >= 0; i--) {
      final seconds = dailyByCategory[sortedDays[i]]?[category] ?? 0;
      if (seconds >= 60) {
        streak++;
      } else {
        break;
      }
    }
    if (streak > bestStreak) {
      bestStreak = streak;
      bestKey = category;
    }
  }

  if (bestKey != null && bestStreak >= 3) {
    out.add(
      Insight(
        emoji: '🔥',
        text:
            '${_categoryLabel(bestKey)} — $bestStreak ${_daysWord(bestStreak)} подряд. Не останавливайся!',
        tone: InsightTone.positive,
      ),
    );
  }
}

String _daysWord(int n) {
  if (n % 10 == 1 && n % 100 != 11) return 'день';
  if ([2, 3, 4].contains(n % 10) && ![12, 13, 14].contains(n % 100)) {
    return 'дня';
  }
  return 'дней';
}

// ── Просадки ──────────────────────────────────────────

void _addDropOffInsight(
  List<Insight> out,
  Map<String, int> current,
  Map<String, int> previous,
  int periodDaysCount,
) {
  if (periodDaysCount == 0) return;

  String? bestKey;
  int bestAvgPrev = 0;

  for (final category in _productiveKeys) {
    final avgPrev = (previous[category] ?? 0) ~/ periodDaysCount;
    final avgCurr = (current[category] ?? 0) ~/ periodDaysCount;

    final significantBefore = avgPrev >= 600; // было ≥10 мин/день в среднем
    final droppedHard = avgCurr <= avgPrev * 0.3; // упало на 70%+

    if (significantBefore && droppedHard && avgPrev > bestAvgPrev) {
      bestAvgPrev = avgPrev;
      bestKey = category;
    }
  }

  if (bestKey != null) {
    out.add(
      Insight(
        emoji: '📉',
        text:
            '${_categoryLabel(bestKey)} почти пропал${_genderSuffix(bestKey)} в этом периоде — '
            'раньше было в среднем ${_formatDuration(bestAvgPrev)}/день.',
        tone: InsightTone.warning,
      ),
    );
  }
}
