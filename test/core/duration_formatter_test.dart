import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:asr/core/utils/duration_formatter.dart';

void main() {
  group('formatDuration', () {
    setUpAll(() {
      Localization.load(
        const Locale('ru'),
        translations: Translations({
          'milestones': {
            'units': {
              'h': 'ч',
              'm': 'м',
            },
          },
        }),
      );
    });

    test('форматирует секунды менее 1 часа (только минуты)', () {
      expect(formatDuration(0), equals('0м'));
      expect(formatDuration(45 * 60), equals('45м'));
      expect(formatDuration(59 * 60 + 59), equals('59м'));
    });

    test('форматирует ровные часы без лишних минут', () {
      expect(formatDuration(3600), equals('1ч'));
      expect(formatDuration(5 * 3600), equals('5ч'));
    });

    test('форматирует часы и минуты вместе', () {
      expect(formatDuration(3600 + 15 * 60), equals('1ч 15м'));
      expect(formatDuration(2 * 3600 + 45 * 60), equals('2ч 45м'));
    });
  });
}
