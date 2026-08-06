import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/date_utils.dart' as du;
import '../../../data/isar_service.dart';
import '../../timer/application/timer_provider.dart';
import '../data/stats_repository.dart';
import 'insight_engine.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(IsarService.instance);
});

/// Тип периода, который сейчас смотрит пользователь.
enum StatsPeriodType { day, week, month, year }

/// Диапазон дат текущего периода — start/end как DateTime (полночь).
class StatsPeriodRange {
  const StatsPeriodRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  String get startKey => du.DateUtils.dateKey(start);
  String get endKey => du.DateUtils.dateKey(end);
}

// ── Внутренние хелперы вычисления периодов ──────────
//
// Важно: anchor всегда хранится как СТАРТ периода (понедельник недели,
// 1-е число месяца, 1 января года; для дня — сам день). Это делает
// листание и вычисление диапазона тривиальным.

DateTime _startOfPeriod(StatsPeriodType type, DateTime date) {
  switch (type) {
    case StatsPeriodType.day:
      return du.DateUtils.startOfDay(date);
    case StatsPeriodType.week:
      return du.DateUtils.startOfWeek(date);
    case StatsPeriodType.month:
      return du.DateUtils.startOfMonth(date);
    case StatsPeriodType.year:
      return du.DateUtils.startOfYear(date);
  }
}

DateTime _endOfPeriod(StatsPeriodType type, DateTime anchor) {
  switch (type) {
    case StatsPeriodType.day:
      return anchor;
    case StatsPeriodType.week:
      return du.DateUtils.endOfWeek(anchor);
    case StatsPeriodType.month:
      return du.DateUtils.endOfMonth(anchor);
    case StatsPeriodType.year:
      return du.DateUtils.endOfYear(anchor);
  }
}

StatsPeriodRange _computeRange(StatsPeriodType type, DateTime anchor) {
  return StatsPeriodRange(anchor, _endOfPeriod(type, anchor));
}

/// Сдвигает anchor на [steps] периодов вперёд (положительное) или назад.
DateTime _shiftAnchor(StatsPeriodType type, DateTime anchor, int steps) {
  switch (type) {
    case StatsPeriodType.day:
      return anchor.add(Duration(days: steps));
    case StatsPeriodType.week:
      return anchor.add(Duration(days: 7 * steps));
    case StatsPeriodType.month:
      return DateTime(anchor.year, anchor.month + steps, 1);
    case StatsPeriodType.year:
      return DateTime(anchor.year + steps, 1, 1);
  }
}

// ── Состояние: тип периода + якорная дата ───────────

final statsPeriodTypeProvider = StateProvider<StatsPeriodType>((ref) {
  return StatsPeriodType.week;
});

final statsAnchorDateProvider = StateProvider<DateTime>((ref) {
  return _startOfPeriod(StatsPeriodType.week, DateTime.now());
});

/// Вычисленный диапазон текущего периода.
final statsPeriodRangeProvider = Provider<StatsPeriodRange>((ref) {
  final type = ref.watch(statsPeriodTypeProvider);
  final anchor = ref.watch(statsAnchorDateProvider);
  return _computeRange(type, anchor);
});

/// Самая ранняя дата с записями — ограничивает листание назад.
final statsEarliestDateProvider = FutureProvider<DateTime?>((ref) async {
  final repo = ref.watch(statsRepositoryProvider);
  final millis = await repo.getEarliestStartedAt();
  if (millis == null) return null;
  return du.DateUtils.startOfDay(DateTime.fromMillisecondsSinceEpoch(millis));
});

// ── Данные периода ───────────────────────────────────

/// Секунды по категориям за текущий период — БЕЗ live-времени текущей
/// активности. Пересчитывается только при реальном изменении данных
/// (entriesChangedProvider) или смене периода — специально не тикает
/// каждую секунду, иначе весь экран мигал бы и сбрасывал скролл.
final categoryBreakdownProvider = FutureProvider<Map<String, int>>((ref) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(statsRepositoryProvider);
  final range = ref.watch(statsPeriodRangeProvider);

  return repo.getCategoryBreakdown(
    startDateKey: range.startKey,
    endDateKey: range.endKey,
  );
});

/// Входит ли сегодняшний день в выбранный период — дешёвая синхронная
/// проверка, чтобы не добавлять live-время, когда смотрим прошлое.
final isTodayInRangeProvider = Provider<bool>((ref) {
  final range = ref.watch(statsPeriodRangeProvider);
  final today = du.DateUtils.startOfDay(DateTime.now());
  return !today.isBefore(range.start) && !today.isAfter(range.end);
});

/// Живые секунды текущей активности для конкретной категории (0, если
/// сейчас идёт другая категория или сегодня не входит в период).
/// СИНХРОННЫЙ Provider.family — используется только в маленьких
/// Consumer-виджетах (донат, активная строка), а не на уровне всего
/// экрана, чтобы тикал только нужный кусочек UI, а не весь список.
final liveCategorySecondsProvider = Provider.family<int, String>((
  ref,
  categoryKey,
) {
  if (!ref.watch(isTodayInRangeProvider)) return 0;
  final current = ref.watch(currentActivityProvider).valueOrNull;
  if (current == null || current.categoryKey != categoryKey) return 0;
  return ref.watch(elapsedSecondsProvider).valueOrNull ?? 0;
});

/// Секунды по категориям И по дням одновременно — сырьё для стриков и просадок.
final categoryDailyTotalsProvider =
    FutureProvider<Map<String, Map<String, int>>>((ref) async {
      ref.watch(entriesChangedProvider);
      final repo = ref.watch(statsRepositoryProvider);
      final range = ref.watch(statsPeriodRangeProvider);
      return repo.getCategoryDailyTotals(
        startDateKey: range.startKey,
        endDateKey: range.endKey,
      );
    });

/// Breakdown за ПРЕДЫДУЩИЙ период той же длины — для сравнения в инсайтах.
/// Не включает live-время (прошлый период уже закрыт целиком).
final previousCategoryBreakdownProvider = FutureProvider<Map<String, int>>((
  ref,
) async {
  ref.watch(entriesChangedProvider);
  final repo = ref.watch(statsRepositoryProvider);
  final type = ref.watch(statsPeriodTypeProvider);
  final range = ref.watch(statsPeriodRangeProvider);

  final prevAnchor = _shiftAnchor(type, range.start, -1);
  final prevRange = _computeRange(type, prevAnchor);

  return repo.getCategoryBreakdown(
    startDateKey: prevRange.startKey,
    endDateKey: prevRange.endKey,
  );
});

// ── Контроллер навигации + переключения периода ─────

class StatsController {
  StatsController(this._ref);

  final Ref _ref;

  StatsRepository get _repo => _ref.read(statsRepositoryProvider);

  /// Меняет тип периода (день/неделя/месяц/год) и сбрасывает якорь на
  /// период, содержащий сегодняшний день.
  void setPeriodType(StatsPeriodType type) {
    _ref.read(statsPeriodTypeProvider.notifier).state = type;
    _ref.read(statsAnchorDateProvider.notifier).state = _startOfPeriod(
      type,
      DateTime.now(),
    );
  }

  Future<void> goToPrevious() async {
    final type = _ref.read(statsPeriodTypeProvider);
    final anchor = _ref.read(statsAnchorDateProvider);
    final prevAnchor = _shiftAnchor(type, anchor, -1);

    final earliestMillis = await _repo.getEarliestStartedAt();
    if (earliestMillis != null) {
      final earliestDay = du.DateUtils.startOfDay(
        DateTime.fromMillisecondsSinceEpoch(earliestMillis),
      );
      final prevRangeEnd = _endOfPeriod(type, prevAnchor);
      // Если конец предыдущего периода раньше самой ранней записи — некуда листать.
      if (prevRangeEnd.isBefore(earliestDay)) return;
    }

    _ref.read(statsAnchorDateProvider.notifier).state = prevAnchor;
  }

  void goToNext() {
    final type = _ref.read(statsPeriodTypeProvider);
    final anchor = _ref.read(statsAnchorDateProvider);
    final nextAnchor = _shiftAnchor(type, anchor, 1);

    final todayPeriodStart = _startOfPeriod(type, DateTime.now());
    // Не пускаем в периоды, которые целиком в будущем.
    if (nextAnchor.isAfter(todayPeriodStart)) return;

    _ref.read(statsAnchorDateProvider.notifier).state = nextAnchor;
  }
}

final statsControllerProvider = Provider<StatsController>((ref) {
  return StatsController(ref);
});

// ── Готовые инсайты для UI ───────────────────────────

final insightsProvider = FutureProvider<List<Insight>>((ref) async {
  final current = await ref.watch(categoryBreakdownProvider.future);
  final previous = await ref.watch(previousCategoryBreakdownProvider.future);
  final daily = await ref.watch(categoryDailyTotalsProvider.future);
  final range = ref.watch(statsPeriodRangeProvider);

  final periodDaysCount = range.end.difference(range.start).inDays + 1;

  return buildInsights(
    current: current,
    previous: previous,
    dailyByCategory: daily,
    periodDaysCount: periodDaysCount,
  );
});

// ── Можно ли листать дальше ──────────────────────────

final canGoNextProvider = Provider<bool>((ref) {
  final type = ref.watch(statsPeriodTypeProvider);
  final anchor = ref.watch(statsAnchorDateProvider);
  final nextAnchor = _shiftAnchor(type, anchor, 1);
  final todayStart = _startOfPeriod(type, DateTime.now());
  return !nextAnchor.isAfter(todayStart);
});

final canGoPreviousProvider = Provider<bool>((ref) {
  final type = ref.watch(statsPeriodTypeProvider);
  final anchor = ref.watch(statsAnchorDateProvider);
  final earliest = ref.watch(statsEarliestDateProvider).valueOrNull;
  if (earliest == null) return true; // пока не знаем границу — не блокируем
  final prevAnchor = _shiftAnchor(type, anchor, -1);
  final prevRangeEnd = _endOfPeriod(type, prevAnchor);
  return !prevRangeEnd.isBefore(earliest);
});

// ── Подпись периода для UI ───────────────────────────

const _monthsGenitive = [
  'января',
  'февраля',
  'марта',
  'апреля',
  'мая',
  'июня',
  'июля',
  'августа',
  'сентября',
  'октября',
  'ноября',
  'декабря',
];
const _monthsNominative = [
  'Январь',
  'Февраль',
  'Март',
  'Апрель',
  'Май',
  'Июнь',
  'Июль',
  'Август',
  'Сентябрь',
  'Октябрь',
  'Ноябрь',
  'Декабрь',
];

String formatPeriodLabel(StatsPeriodType type, StatsPeriodRange range) {
  final isCurrent = range.start == _startOfPeriod(type, DateTime.now());

  switch (type) {
    case StatsPeriodType.day:
      if (isCurrent) return 'Сегодня';
      final d = range.start;
      return '${d.day} ${_monthsGenitive[d.month - 1]} ${d.year}';

    case StatsPeriodType.week:
      if (isCurrent) return 'Эта неделя';
      final s = range.start;
      final e = range.end;
      if (s.month == e.month) {
        return '${s.day}–${e.day} ${_monthsGenitive[s.month - 1]}';
      } else if (s.year == e.year) {
        return '${s.day} ${_monthsGenitive[s.month - 1]} – '
            '${e.day} ${_monthsGenitive[e.month - 1]}';
      }
      return '${s.day} ${_monthsGenitive[s.month - 1]} ${s.year} – '
          '${e.day} ${_monthsGenitive[e.month - 1]} ${e.year}';

    case StatsPeriodType.month:
      if (isCurrent) return 'Этот месяц';
      return '${_monthsNominative[range.start.month - 1]} ${range.start.year}';

    case StatsPeriodType.year:
      if (isCurrent) return 'Этот год';
      return '${range.start.year}';
  }
}
