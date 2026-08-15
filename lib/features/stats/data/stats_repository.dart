import 'package:easy_localization/easy_localization.dart';
import 'package:isar_community/isar.dart';

import '../../../core/constants/activity_category.dart';
import '../../../core/utils/date_utils.dart' as du;
import '../../timer/domain/models/activity_entry.dart';

/// Пожизненная статистика пути пользователя — для секции "Мой путь"
/// в Профиле. Не про категории (это Статистика), а про масштаб пути.
class LifetimeJourneyStats {
  const LifetimeJourneyStats({
    required this.totalSeconds,
    required this.totalActivities,
    required this.totalNotes,
    required this.totalPhotos,
    required this.daysSinceStart,
  });

  final int totalSeconds;
  final int totalActivities;
  final int totalNotes;
  final int totalPhotos;
  final int daysSinceStart;
}

/// Личные рекорды пользователя — для секции "Личные рекорды" в Профиле.
class PersonalRecords {
  const PersonalRecords({
    this.longestSessionSeconds,
    this.longestSessionName,
    this.longestSessionCategoryKey,
    this.bestCategoryKeyOfBestDay,
    this.bestDaySeconds,
    this.bestDayDateKey,
    required this.longestOverallStreakDays,
    required this.longestNoWasteStreakDays,
  });

  final int? longestSessionSeconds;
  final String? longestSessionName;
  final String? longestSessionCategoryKey;

  final String? bestCategoryKeyOfBestDay;
  final int? bestDaySeconds;
  final String? bestDayDateKey;

  final int longestOverallStreakDays;
  final int longestNoWasteStreakDays;
}

/// Репозиторий статистики: читает ActivityEntry за диапазон дат и агрегирует
/// их несколькими способами — по категориям (пирог), по дням (тренд),
/// по дням+категориям (стрики и просадки).
class StatsRepository {
  StatsRepository(this._isar);

  final Isar _isar;

  /// Записи за диапазон дат включительно. Если [startDateKey] == null —
  /// диапазон не ограничен снизу (режим "всё время").
  /// Записи за диапазон дат включительно. Если [startDateKey] == null —
  /// диапазон не ограничен снизу (режим "всё время").
  Future<List<ActivityEntry>> getEntriesInRange({
    required String? startDateKey,
    required String endDateKey,
  }) {
    if (startDateKey == null) {
      return _isar.activityEntrys
          .filter()
          .isDeletedEqualTo(false)
          .sortByStartedAt()
          .findAll();
    }

    return _isar.activityEntrys
        .filter()
        .isDeletedEqualTo(false)
        .dateKeyBetween(startDateKey, endDateKey)
        .sortByStartedAt()
        .findAll();
  }

  /// Суммарные секунды по каждой категории за период.
  /// Возвращает словарь со всеми 9 категориями (даже если 0).
  Future<Map<String, int>> getCategoryBreakdown({
    required String? startDateKey,
    required String endDateKey,
  }) async {
    final entries = await getEntriesInRange(
      startDateKey: startDateKey,
      endDateKey: endDateKey,
    );

    final stats = <String, int>{
      for (final c in ActivityCategory.values) c.storageKey: 0,
    };

    for (final e in entries) {
      stats[e.categoryKey] = (stats[e.categoryKey] ?? 0) + e.durationSeconds;
    }

    return stats;
  }

  /// Раскладка по конкретным активностям (делам/тегам) для выбранной категории за период.
  /// Возвращает карту: название активности -> суммарные секунды, отсортированную по убыванию.
  Future<Map<String, int>> getActivityBreakdownForCategory({
    required String categoryKey,
    required String? startDateKey,
    required String endDateKey,
  }) async {
    final entries = await getEntriesInRange(
      startDateKey: startDateKey,
      endDateKey: endDateKey,
    );

    final grouped = <String, int>{};
    for (final e in entries) {
      if (e.categoryKey == categoryKey) {
        final name = e.name.trim();
        if (name.isEmpty) continue;
        grouped[name] = (grouped[name] ?? 0) + e.durationSeconds;
      }
    }

    final sortedEntries = grouped.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Map.fromEntries(sortedEntries);
  }

  /// Статистика по сессиям за период: всего сессий и средняя длительность сессии.
  Future<({int totalSessions, int averageSeconds})> getPeriodSessionSummary({
    required String? startDateKey,
    required String endDateKey,
  }) async {
    final entries = await getEntriesInRange(
      startDateKey: startDateKey,
      endDateKey: endDateKey,
    );

    if (entries.isEmpty) {
      return (totalSessions: 0, averageSeconds: 0);
    }

    int totalSec = 0;
    for (final e in entries) {
      totalSec += e.durationSeconds;
    }

    final avg = (totalSec / entries.length).round();
    return (totalSessions: entries.length, averageSeconds: avg);
  }

  /// Суммарные секунды по каждому дню за период (для тренда).
  /// Включает дни без единой записи (0 секунд), чтобы график/стрик-логика
  /// не "перепрыгивала" через пропуски.
  Future<List<MapEntry<String, int>>> getDailyTotals({
    required String startDateKey,
    required String endDateKey,
  }) async {
    final byCategory = await getCategoryDailyTotals(
      startDateKey: startDateKey,
      endDateKey: endDateKey,
    );

    return byCategory.entries
        .map((e) => MapEntry(e.key, e.value.values.fold(0, (a, b) => a + b)))
        .toList();
  }

  /// Секунды по каждой категории в разрезе КАЖДОГО дня периода.
  /// Ключ верхнего уровня — dateKey, значение — карта categoryKey→секунды.
  /// Основа для детекции стриков ("спорт 4 дня подряд") и просадок
  /// ("развитие пропало на этой неделе").
  Future<Map<String, Map<String, int>>> getCategoryDailyTotals({
    required String startDateKey,
    required String endDateKey,
  }) async {
    final entries = await getEntriesInRange(
      startDateKey: startDateKey,
      endDateKey: endDateKey,
    );

    final byDay = <String, Map<String, int>>{};

    // Заполняем все дни диапазона нулями — чтобы дни без записей не выпадали.
    var cursor = du.DateUtils.dateKeyToDate(startDateKey);
    final end = du.DateUtils.dateKeyToDate(endDateKey);
    while (!cursor.isAfter(end)) {
      final key = du.DateUtils.dateKey(cursor);
      byDay[key] = {for (final c in ActivityCategory.values) c.storageKey: 0};
      cursor = cursor.add(const Duration(days: 1));
    }

    for (final e in entries) {
      final dayMap = byDay[e.dateKey];
      if (dayMap == null) continue; // на всякий случай, не должно случаться
      dayMap[e.categoryKey] = (dayMap[e.categoryKey] ?? 0) + e.durationSeconds;
    }

    return byDay;
  }

  /// Самая ранняя запись в базе — ограничивает навигацию "назад" по периодам.
  Future<int?> getEarliestStartedAt() async {
    final earliest = await _isar.activityEntrys
        .filter()
        .isDeletedEqualTo(false)
        .sortByStartedAt()
        .findFirst();
    return earliest?.startedAt;
  }

  /// Общий стрик приложения — сколько дней подряд (включая сегодня, если
  /// уже есть активность) была хотя бы одна запись, независимо от категории.
  /// Считаем от сегодня назад, останавливаемся на первом пустом дне.
  Future<int> getOverallStreak() async {
    final allEntries = await _isar.activityEntrys
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    if (allEntries.isEmpty) return 0;

    final daysWithActivity = <String>{};
    for (final e in allEntries) {
      daysWithActivity.add(e.dateKey);
    }

    var streak = 0;
    var cursor = du.DateUtils.startOfDay(DateTime.now());

    while (daysWithActivity.contains(du.DateUtils.dateKey(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  /// Пожизненная статистика пути — один проход по всем записям.
  Future<LifetimeJourneyStats> getLifetimeJourneyStats() async {
    final entries = await _isar.activityEntrys
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    if (entries.isEmpty) {
      return const LifetimeJourneyStats(
        totalSeconds: 0,
        totalActivities: 0,
        totalNotes: 0,
        totalPhotos: 0,
        daysSinceStart: 0,
      );
    }

    var totalSeconds = 0;
    var totalNotes = 0;
    var totalPhotos = 0;

    for (final e in entries) {
      totalSeconds += e.durationSeconds;
      if ((e.note ?? '').trim().isNotEmpty) totalNotes++;
      totalPhotos += e.photoPaths?.length ?? 0;
    }

    final earliestMillis = await getEarliestStartedAt();
    var daysSinceStart = 0;
    if (earliestMillis != null) {
      final earliestDay = du.DateUtils.startOfDay(
        DateTime.fromMillisecondsSinceEpoch(earliestMillis),
      );
      final today = du.DateUtils.startOfDay(DateTime.now());
      daysSinceStart = today.difference(earliestDay).inDays + 1;
    }

    return LifetimeJourneyStats(
      totalSeconds: totalSeconds,
      totalActivities: entries.length,
      totalNotes: totalNotes,
      totalPhotos: totalPhotos,
      daysSinceStart: daysSinceStart,
    );
  }

  static const int _noWasteThresholdSeconds = 300; // 5 минут

  /// Личные рекорды — один проход по всем записям + проход по календарным
  /// дням от первой записи до сегодня (для стрика "без Потерь").
  Future<PersonalRecords> getPersonalRecords() async {
    final entries = await _isar.activityEntrys
        .filter()
        .isDeletedEqualTo(false)
        .findAll();

    if (entries.isEmpty) {
      return const PersonalRecords(
        longestOverallStreakDays: 0,
        longestNoWasteStreakDays: 0,
      );
    }

    // ── Самая длинная сессия ──
    var longestEntry = entries.first;
    for (final e in entries) {
      if (e.durationSeconds > longestEntry.durationSeconds) longestEntry = e;
    }

    // ── Лучший день по категории + карта день→категория→секунды ──
    final byDayCategory = <String, Map<String, int>>{};
    final wasteByDay = <String, int>{};
    final daysWithActivity = <String>{};

    for (final e in entries) {
      daysWithActivity.add(e.dateKey);
      final dayMap = byDayCategory.putIfAbsent(e.dateKey, () => {});
      dayMap[e.categoryKey] = (dayMap[e.categoryKey] ?? 0) + e.durationSeconds;
      if (e.categoryKey == 'waste') {
        wasteByDay[e.dateKey] =
            (wasteByDay[e.dateKey] ?? 0) + e.durationSeconds;
      }
    }

    String? bestDayKey;
    String? bestDayCategory;
    var bestDaySeconds = 0;
    for (final dayEntry in byDayCategory.entries) {
      for (final catEntry in dayEntry.value.entries) {
        if (catEntry.value > bestDaySeconds) {
          bestDaySeconds = catEntry.value;
          bestDayKey = dayEntry.key;
          bestDayCategory = catEntry.key;
        }
      }
    }

    // ── Рекордный стрик за всё время (любая активность) ──
    final sortedDays = daysWithActivity.toList()..sort();
    var longestOverallStreak = 0;
    var currentStreak = 0;
    DateTime? prevDate;
    for (final key in sortedDays) {
      final date = du.DateUtils.dateKeyToDate(key);
      if (prevDate != null && date.difference(prevDate).inDays == 1) {
        currentStreak++;
      } else {
        currentStreak = 1;
      }
      if (currentStreak > longestOverallStreak) {
        longestOverallStreak = currentStreak;
      }
      prevDate = date;
    }

    // ── Самый долгий период без "Потерь" ──
    // День без единой записи тоже прерывает стрик (решено осознанно).
    final earliestMillis = await getEarliestStartedAt();
    var longestNoWasteStreak = 0;
    if (earliestMillis != null) {
      var cursor = du.DateUtils.startOfDay(
        DateTime.fromMillisecondsSinceEpoch(earliestMillis),
      );
      final today = du.DateUtils.startOfDay(DateTime.now());
      var streak = 0;

      while (!cursor.isAfter(today)) {
        final key = du.DateUtils.dateKey(cursor);
        final hasActivity = daysWithActivity.contains(key);
        final waste = wasteByDay[key] ?? 0;

        if (hasActivity && waste < _noWasteThresholdSeconds) {
          streak++;
          if (streak > longestNoWasteStreak) longestNoWasteStreak = streak;
        } else {
          streak = 0;
        }

        cursor = cursor.add(const Duration(days: 1));
      }
    }

    return PersonalRecords(
      longestSessionSeconds: longestEntry.durationSeconds,
      longestSessionName: longestEntry.name,
      longestSessionCategoryKey: longestEntry.categoryKey,
      bestCategoryKeyOfBestDay: bestDayCategory,
      bestDaySeconds: bestDaySeconds > 0 ? bestDaySeconds : null,
      bestDayDateKey: bestDayKey,
      longestOverallStreakDays: longestOverallStreak,
      longestNoWasteStreakDays: longestNoWasteStreak,
    );
  }

  // ── Хронологический Аудит времени (Текстовый экспорт) ──

  String _formatTimeHHmm(int millisSinceEpoch) {
    final dt = DateTime.fromMillisecondsSinceEpoch(millisSinceEpoch);
    return DateFormat('HH:mm').format(dt);
  }

  String _formatDurationBrief(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч ${m > 0 ? "$mм" : ""}';
    return '$mм';
  }

  /// Генерирует подробный текстовый аудит за ОДИН ДЕНЬ.
  Future<String> generateDayAuditText(String dateKey) async {
    final entries = await getEntriesInRange(
      startDateKey: dateKey,
      endDateKey: dateKey,
    );

    final date = du.DateUtils.dateKeyToDate(dateKey);
    final dateStr = DateFormat('EEEE, dd.MM.yyyy (d MMMM yyyy)').format(date);

    final buffer = StringBuffer();
    buffer.writeln('stats.audit_header'.tr(namedArgs: {'date': dateStr}));
    buffer.writeln();

    if (entries.isEmpty) {
      buffer.writeln('stats.no_entries_period'.tr());
    } else {
      final categoryTotals = <String, int>{};

      for (final e in entries) {
        categoryTotals[e.categoryKey] = (categoryTotals[e.categoryKey] ?? 0) + e.durationSeconds;

        final startStr = _formatTimeHHmm(e.startedAt);
        final endStr = _formatTimeHHmm(e.endedAt);
        final cat = ActivityCategory.fromStorageKey(e.categoryKey);
        final durationStr = _formatDurationBrief(e.durationSeconds);
        final nameStr = e.name.trim().isEmpty ? cat.label : e.name.trim();

        buffer.writeln('  $startStr - $endStr [${cat.label}]: $nameStr ($durationStr)');
        if (e.note != null && e.note!.trim().isNotEmpty) {
          buffer.writeln('stats.note'.tr(args: [e.note!.trim()]));
        }
      }

      buffer.writeln();
      buffer.writeln('stats.day_summary'.tr());
      final activeCatStrings = <String>[];
      for (final cat in ActivityCategory.values) {
        final sec = categoryTotals[cat.storageKey] ?? 0;
        if (sec > 0) {
          activeCatStrings.add('${cat.label}: ${_formatDurationBrief(sec)}');
        }
      }
      buffer.writeln('  ${activeCatStrings.join(' | ')}');
    }

    buffer.writeln('──────────────────────────────────────────');
    buffer.writeln('stats.audit_generated_by'.tr());
    return buffer.toString();
  }

  /// Генерирует текстовый аудит за Диапазон Дней (Неделя, Месяц, Год).
  Future<String> generatePeriodAuditText({
    required String startDateKey,
    required String endDateKey,
    required String periodLabel,
  }) async {
    final entries = await getEntriesInRange(
      startDateKey: startDateKey,
      endDateKey: endDateKey,
    );

    final buffer = StringBuffer();
    buffer.writeln('stats.audit_period'.tr(args: [periodLabel]));
    buffer.writeln('stats.interval'.tr(args: [startDateKey, endDateKey]));
    buffer.writeln();

    if (entries.isEmpty) {
      buffer.writeln('stats.no_entries_period'.tr());
    } else {
      final entriesByDate = <String, List<ActivityEntry>>{};
      final categoryTotals = <String, int>{};
      int overallTotalSec = 0;

      for (final e in entries) {
        overallTotalSec += e.durationSeconds;
        categoryTotals[e.categoryKey] = (categoryTotals[e.categoryKey] ?? 0) + e.durationSeconds;
        entriesByDate.putIfAbsent(e.dateKey, () => []).add(e);
      }

      final sortedDateKeys = entriesByDate.keys.toList()..sort();

      for (final dKey in sortedDateKeys) {
        final date = du.DateUtils.dateKeyToDate(dKey);
        final dateHeader = DateFormat('EEEE, dd.MM.yyyy (d MMMM)').format(date);

        buffer.writeln('📅 $dateHeader:');

        final dayEntries = entriesByDate[dKey]!;
        for (final e in dayEntries) {
          final startStr = _formatTimeHHmm(e.startedAt);
          final endStr = _formatTimeHHmm(e.endedAt);
          final cat = ActivityCategory.fromStorageKey(e.categoryKey);
          final durationStr = _formatDurationBrief(e.durationSeconds);
          final nameStr = e.name.trim().isEmpty ? cat.label : e.name.trim();

          buffer.writeln('  $startStr - $endStr [${cat.label}]: $nameStr ($durationStr)');
          if (e.note != null && e.note!.trim().isNotEmpty) {
            buffer.writeln('stats.note'.tr(args: [e.note!.trim()]));
          }
        }
        buffer.writeln();
      }

      buffer.writeln('stats.period_summary'.tr(args: [_formatDurationBrief(overallTotalSec)]));
      final activeCatStrings = <String>[];
      for (final cat in ActivityCategory.values) {
        final sec = categoryTotals[cat.storageKey] ?? 0;
        if (sec > 0) {
          activeCatStrings.add('${cat.label}: ${_formatDurationBrief(sec)}');
        }
      }
      buffer.writeln('  ${activeCatStrings.join(' | ')}');
    }

    buffer.writeln('──────────────────────────────────────────');
    buffer.writeln('stats.audit_generated_by'.tr());
    return buffer.toString();
  }
}
