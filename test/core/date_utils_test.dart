import 'package:flutter_test/flutter_test.dart';
import 'package:asr/core/utils/date_utils.dart' as du;

void main() {
  group('DateUtils', () {
    test('dateKey форматирует дату в YYYY-MM-DD с ведущими нулями', () {
      final dt = DateTime(2026, 4, 5, 14, 30);
      expect(du.DateUtils.dateKey(dt), equals('2026-04-05'));
    });

    test('dateKeyFromMillis форматирует timestamp в YYYY-MM-DD', () {
      final dt = DateTime(2026, 8, 21, 10, 0);
      expect(
        du.DateUtils.dateKeyFromMillis(dt.millisecondsSinceEpoch),
        equals('2026-08-21'),
      );
    });

    test('dateKeyToDate парсит ключ обратно в DateTime на полночь', () {
      final parsed = du.DateUtils.dateKeyToDate('2026-12-31');
      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(12));
      expect(parsed.day, equals(31));
      expect(parsed.hour, equals(0));
      expect(parsed.minute, equals(0));
    });

    test('startOfDay обнуляет время суток', () {
      final dt = DateTime(2026, 8, 21, 23, 59, 59);
      final start = du.DateUtils.startOfDay(dt);
      expect(start, equals(DateTime(2026, 8, 21, 0, 0, 0)));
    });

    test('nextMidnight возвращает полночь следующих суток', () {
      final dt = DateTime(2026, 8, 21, 23, 30);
      final next = du.DateUtils.nextMidnight(dt);
      expect(next, equals(DateTime(2026, 8, 22, 0, 0, 0)));
    });

    test('startOfWeek и endOfWeek возвращают понедельник и воскресенье недели', () {
      // 2026-08-21 — пятница (weekday 5)
      final friday = DateTime(2026, 8, 21, 15, 0);

      final start = du.DateUtils.startOfWeek(friday);
      expect(start.weekday, equals(DateTime.monday));
      expect(start, equals(DateTime(2026, 8, 17, 0, 0, 0)));

      final end = du.DateUtils.endOfWeek(friday);
      expect(end.weekday, equals(DateTime.sunday));
      expect(end, equals(DateTime(2026, 8, 23, 0, 0, 0)));
    });

    test('startOfMonth и endOfMonth возвращают первый и последний день месяца', () {
      final dt = DateTime(2026, 2, 15);

      final start = du.DateUtils.startOfMonth(dt);
      expect(start, equals(DateTime(2026, 2, 1)));

      final end = du.DateUtils.endOfMonth(dt);
      // 2026 год не високосный (28 дней в феврале)
      expect(end, equals(DateTime(2026, 2, 28)));
    });

    test('startOfYear и endOfYear возвращают 1 января и 31 декабря', () {
      final dt = DateTime(2026, 6, 15);
      expect(du.DateUtils.startOfYear(dt), equals(DateTime(2026, 1, 1)));
      expect(du.DateUtils.endOfYear(dt), equals(DateTime(2026, 12, 31)));
    });
  });
}
