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

  /// Начало следующих суток относительно [dt] (то есть ближайшая полночь ПОСЛЕ dt).
  /// Аналог nextMidnight из timer.js (_ensureSliced).
  static DateTime nextMidnight(DateTime dt) {
    return DateTime(dt.year, dt.month, dt.day).add(const Duration(days: 1));
  }
}
