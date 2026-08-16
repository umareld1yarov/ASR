import 'package:easy_localization/easy_localization.dart';

/// Локализованное форматирование длительности (секунд в ч/м).
/// Например: 2ч 15м / 45м (RU), 2h 15m / 45m (EN), 2саат 15мүн (KY)
String formatDuration(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final hUnit = 'milestones.units.h'.tr();
  final mUnit = 'milestones.units.m'.tr();

  if (h > 0) {
    return '$h$hUnit${m > 0 ? " $m$mUnit" : ""}';
  }
  return '$m$mUnit';
}

/// Короткий формат длительности.
String formatDurationShort(int seconds) {
  return formatDuration(seconds);
}
