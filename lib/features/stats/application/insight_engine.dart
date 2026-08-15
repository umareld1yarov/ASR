import '../../../core/constants/activity_category.dart';

/// Тон инсайта — влияет на цвет/иконку в UI.
enum InsightTone { positive, warning, neutral }

class Insight {
  const Insight({required this.emoji, required this.text, required this.tone});

  final String emoji;
  final String text;
  final InsightTone tone;
}

/// Категории, которые считаются "созидательными/продуктивными".
const _productiveKeys = {
  'religion',
  'work',
  'growth',
  'finance',
  'sport',
  'family',
};

const _wasteKey = 'waste';

/// Минимальный порог в секундах (10 минут)
const _noiseThresholdSeconds = 600;

String _formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '$hч ${m > 0 ? "$mм" : ""}';
  return '$mм';
}

String _categoryLabel(String key) {
  return ActivityCategory.fromStorageKey(key).label;
}

/// Умный движок инсайтов. Генерирует НЕ очевидные факты (которые и так видны
/// на экране), а глубокие тренды, длинные стрики и скрытую динамику.
List<Insight> buildInsights({
  required Map<String, int> current,
  required Map<String, int> previous,
  required Map<String, Map<String, int>> dailyByCategory,
  required int periodDaysCount,
}) {
  final candidates = <Insight>[];

  // 1. Однодневный режим (День)
  if (periodDaysCount <= 1) {
    _addDaySpecificInsights(candidates, current);
    return candidates.take(2).toList();
  }

  // 2. Длинные периоды (Неделя, Месяц, Год)
  _addBalanceInsight(candidates, current);
  _addDeltaInsights(candidates, current, previous);
  _addStreakInsight(candidates, dailyByCategory);
  _addDropOffInsight(candidates, current, previous, periodDaysCount);

  return candidates.take(3).toList();
}

// ── Специальные инсайты для ДНЯ (без ложных тревог) ──

void _addDaySpecificInsights(List<Insight> out, Map<String, int> current) {
  final totalSec = current.values.fold(0, (a, b) => a + b);
  if (totalSec == 0) return;

  final wasteTotal = current[_wasteKey] ?? 0;

  // 1. Нуль потерь за день
  if (wasteTotal == 0 && totalSec >= 1800) {
    out.add(
      const Insight(
        emoji: '🌿',
        text: 'Чистый день без единой минуты в «Потери». Отличный самоконтроль!',
        tone: InsightTone.positive,
      ),
    );
  } else if (wasteTotal >= 1800) {
    // Высокие потери
    out.add(
      Insight(
        emoji: '⏳',
        text: 'На Потери ушло ${_formatDuration(wasteTotal)}. Попробуйте сделать осознанную паузу.',
        tone: InsightTone.warning,
      ),
    );
  }

  // 2. Выдающийся продуктивный объем
  int productiveSec = 0;
  for (final k in _productiveKeys) {
    productiveSec += current[k] ?? 0;
  }

  if (productiveSec >= 10800) { // ≥ 3 часов
    out.add(
      Insight(
        emoji: '⚡',
        text: 'Высокий день созидания: ${_formatDuration(productiveSec)} продуктивной работы!',
        tone: InsightTone.positive,
      ),
    );
  }
}

// ── Баланс продуктив/потери для НЕДЕЛИ/МЕСЯЦА ──────────

void _addBalanceInsight(List<Insight> out, Map<String, int> current) {
  final trackedTotal = current.values.fold(0, (a, b) => a + b);
  if (trackedTotal == 0) return;

  final wasteTotal = current[_wasteKey] ?? 0;
  final wasteShare = wasteTotal / trackedTotal;

  if (wasteTotal >= _noiseThresholdSeconds && wasteShare >= 0.25) {
    final percent = (wasteShare * 100).round();
    out.add(
      Insight(
        emoji: '⏳',
        text:
            '$percent% времени периода ушло в Потери (${_formatDuration(wasteTotal)}). '
            'Попробуйте проанализировать эти моменты.',
        tone: InsightTone.warning,
      ),
    );
  } else if (trackedTotal >= 3600 && wasteShare < 0.10) {
    out.add(
      const Insight(
        emoji: '🔥',
        text: 'Высокая дисциплина периода — Потери составляют менее 10% времени!',
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
  String? bestKey;
  int bestDelta = 0;
  for (final key in _productiveKeys) {
    final delta = (current[key] ?? 0) - (previous[key] ?? 0);
    if (delta > bestDelta) {
      bestDelta = delta;
      bestKey = key;
    }
  }

  if (bestKey != null && bestDelta >= 1800) { // хотя бы +30 мин роста
    final prevValue = previous[bestKey] ?? 0;
    if (prevValue > 0) {
      final percent = ((bestDelta / prevValue) * 100).round();
      out.add(
        Insight(
          emoji: '📈',
          text:
              'Сфера «${_categoryLabel(bestKey)}» выросла на $percent% '
              '(+${_formatDuration(bestDelta)}) к прошлому периоду.',
          tone: InsightTone.positive,
        ),
      );
    }
  }
}

// ── Стрики и серии ────────────────────────────────────

void _addStreakInsight(
  List<Insight> out,
  Map<String, Map<String, int>> dailyByCategory,
) {
  if (dailyByCategory.length < 3) return;

  final sortedDays = dailyByCategory.keys.toList()..sort();

  String? bestKey;
  int bestStreak = 0;

  for (final category in _productiveKeys) {
    int streak = 0;
    for (var i = sortedDays.length - 1; i >= 0; i--) {
      final seconds = dailyByCategory[sortedDays[i]]?[category] ?? 0;
      if (seconds >= 600) { // хотя бы 10 минут в день
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
            'Серия «${_categoryLabel(bestKey)}»: $bestStreak ${_daysWord(bestStreak)} подряд!',
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

// ── Заметные просадки (только для долгосрока) ─────────

void _addDropOffInsight(
  List<Insight> out,
  Map<String, int> current,
  Map<String, int> previous,
  int periodDaysCount,
) {
  // На коротких отрезках (≤ 3 дней) просадки не считаем — это естественный отдых
  if (periodDaysCount <= 3) return;

  String? bestKey;
  int bestAvgPrev = 0;

  for (final category in _productiveKeys) {
    final avgPrev = (previous[category] ?? 0) ~/ periodDaysCount;
    final avgCurr = (current[category] ?? 0) ~/ periodDaysCount;

    final significantBefore = avgPrev >= 1200; // было ≥20 мин/день
    final droppedHard = avgCurr <= avgPrev * 0.25; // упало на 75%+

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
            'Категория «${_categoryLabel(bestKey)}» просела за этот период. '
            'В прошлом было в среднем ${_formatDuration(bestAvgPrev)}/день.',
        tone: InsightTone.warning,
      ),
    );
  }
}
