import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/activity_category.dart';

/// Тон инсайта — влияет на цвет/иконку в UI.
enum InsightTone { positive, warning, neutral }

class Insight {
  const Insight({required this.emoji, required this.text, required this.tone});

  final String emoji;
  final String text;
  final InsightTone tone;
}

const _productiveKeys = {
  'religion',
  'work',
  'growth',
  'finance',
  'sport',
  'family',
};

const _wasteKey = 'waste';
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

List<Insight> buildInsights({
  required Map<String, int> current,
  required Map<String, int> previous,
  required Map<String, Map<String, int>> dailyByCategory,
  required int periodDaysCount,
}) {
  final candidates = <Insight>[];

  if (periodDaysCount <= 1) {
    _addDaySpecificInsights(candidates, current);
    return candidates.take(2).toList();
  }

  _addBalanceInsight(candidates, current);
  _addDeltaInsights(candidates, current, previous);
  _addStreakInsight(candidates, dailyByCategory);
  _addDropOffInsight(candidates, current, previous, periodDaysCount);

  return candidates.take(3).toList();
}

void _addDaySpecificInsights(List<Insight> out, Map<String, int> current) {
  final totalSec = current.values.fold(0, (a, b) => a + b);
  if (totalSec == 0) return;

  final wasteTotal = current[_wasteKey] ?? 0;

  if (wasteTotal == 0 && totalSec >= 1800) {
    out.add(
      Insight(
        emoji: '🌿',
        text: 'insights.clean_day'.tr(),
        tone: InsightTone.positive,
      ),
    );
  } else if (wasteTotal >= 1800) {
    out.add(
      Insight(
        emoji: '⏳',
        text: 'insights.waste_warning'.tr(args: [_formatDuration(wasteTotal)]),
        tone: InsightTone.warning,
      ),
    );
  }

  int productiveSec = 0;
  for (final k in _productiveKeys) {
    productiveSec += current[k] ?? 0;
  }

  if (productiveSec >= 10800) {
    out.add(
      Insight(
        emoji: '⚡',
        text: 'insights.high_productive_day'.tr(args: [_formatDuration(productiveSec)]),
        tone: InsightTone.positive,
      ),
    );
  }
}

void _addBalanceInsight(List<Insight> out, Map<String, int> current) {
  final trackedTotal = current.values.fold(0, (a, b) => a + b);
  if (trackedTotal == 0) return;

  final wasteTotal = current[_wasteKey] ?? 0;
  final wasteShare = wasteTotal / trackedTotal;

  if (wasteTotal >= _noiseThresholdSeconds && wasteShare >= 0.25) {
    out.add(
      Insight(
        emoji: '⏳',
        text: 'insights.waste_warning'.tr(args: [_formatDuration(wasteTotal)]),
        tone: InsightTone.warning,
      ),
    );
  } else if (trackedTotal >= 3600 && wasteShare < 0.10) {
    out.add(
      Insight(
        emoji: '🔥',
        text: 'insights.discipline_high'.tr(),
        tone: InsightTone.positive,
      ),
    );
  }
}

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

  if (bestKey != null && bestDelta >= 1800) {
    final prevValue = previous[bestKey] ?? 0;
    if (prevValue > 0) {
      final percent = ((bestDelta / prevValue) * 100).round();
      out.add(
        Insight(
          emoji: '📈',
          text: 'insights.category_growth'.tr(args: [
            _categoryLabel(bestKey),
            '$percent',
            _formatDuration(bestDelta),
          ]),
          tone: InsightTone.positive,
        ),
      );
    }
  }
}

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
      if (seconds >= 600) {
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
        text: 'insights.streak_active'.tr(args: [
          _categoryLabel(bestKey),
          '$bestStreak',
        ]),
        tone: InsightTone.positive,
      ),
    );
  }
}

void _addDropOffInsight(
  List<Insight> out,
  Map<String, int> current,
  Map<String, int> previous,
  int periodDaysCount,
) {
  if (periodDaysCount <= 3) return;

  String? bestKey;
  int bestAvgPrev = 0;

  for (final category in _productiveKeys) {
    final avgPrev = (previous[category] ?? 0) ~/ periodDaysCount;
    final avgCurr = (current[category] ?? 0) ~/ periodDaysCount;

    final significantBefore = avgPrev >= 1200;
    final droppedHard = avgCurr <= avgPrev * 0.25;

    if (significantBefore && droppedHard && avgPrev > bestAvgPrev) {
      bestAvgPrev = avgPrev;
      bestKey = category;
    }
  }

  if (bestKey != null) {
    out.add(
      Insight(
        emoji: '📉',
        text: 'insights.drop_off'.tr(args: [_categoryLabel(bestKey)]),
        tone: InsightTone.warning,
      ),
    );
  }
}
