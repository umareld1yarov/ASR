/// Утилиты работы с датами — аналог dateKey()/dateUtils из storage.js.
class DateUtils {
  DateUtils._();

  /// Ключ дня в формате YYYY-MM-DD, по локальному времени устройства.
  static String dateKey(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  static String dateKeyFromMillis(int millis) {
    return dateKey(DateTime.fromMillisecondsSinceEpoch(millis));
  }

  /// Парсит dateKey (YYYY-MM-DD) обратно в DateTime (полночь этого дня).
  static DateTime dateKeyToDate(String key) {
    final parts = key.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  /// Начало следующих суток относительно [dt] (то есть ближайшая полночь ПОСЛЕ dt).
  /// Аналог nextMidnight из timer.js (_ensureSliced).
  static DateTime nextMidnight(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day).add(const Duration(days: 1));
  }

  /// Полночь сегодняшнего дня (обнуляет время суток).
  static DateTime startOfDay(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day);
  }

  // ── Неделя (понедельник—воскресенье) ─────────────

  /// Понедельник недели, содержащей [dt].
  /// DateTime.weekday: 1 = понедельник ... 7 = воскресенье.
  static DateTime startOfWeek(DateTime dt) {
    final day = startOfDay(dt);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  /// Воскресенье недели, содержащей [dt].
  static DateTime endOfWeek(DateTime dt) {
    return startOfWeek(dt).add(const Duration(days: 6));
  }

  // ── Месяц ──────────────────────────────────────

  static DateTime startOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month, 1);
  }

  /// Последний день месяца, содержащего [dt] (0-й день следующего месяца).
  static DateTime endOfMonth(DateTime dt) {
    return DateTime(dt.year, dt.month + 1, 0);
  }

  // ── Год ────────────────────────────────────────

  static DateTime startOfYear(DateTime dt) {
    return DateTime(dt.year, 1, 1);
  }

  static DateTime endOfYear(DateTime dt) {
    return DateTime(dt.year, 12, 31);
  }

  static const List<String> monthsGenitiveRu = [
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

  /// Короткая дата на русском в родительном падеже: "12 июля".
  static String formatShortRu(DateTime dt) {
    return '${dt.day} ${monthsGenitiveRu[dt.month - 1]}';
  }
}
