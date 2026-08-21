import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Localization Files Audit', () {
    final translationsDir = Directory('assets/translations');

    test('папка translations существует и содержит JSON файлы', () {
      expect(translationsDir.existsSync(), isTrue);
      final jsonFiles = translationsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();
      expect(jsonFiles.length, greaterThanOrEqualTo(8));
    });

    test('все JSON файлы локализации валидны и могут быть распарсены', () {
      final jsonFiles = translationsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json'))
          .toList();

      for (final file in jsonFiles) {
        final content = file.readAsStringSync();
        expect(
          () => jsonDecode(content),
          returnsNormally,
          reason: 'Ошибка парсинга файла ${file.path}',
        );
      }
    });

    test('полный двусторонний паритет ключей и плейсхолдеров во всех языках относительно ru.json', () {
      final ruFile = File('assets/translations/ru.json');
      expect(ruFile.existsSync(), isTrue);

      final ruJson = jsonDecode(ruFile.readAsStringSync()) as Map<String, dynamic>;
      final ruKeys = <String>{};
      final ruValues = <String, String>{};
      _extractLeafKeysAndValues('', ruJson, ruKeys, ruValues);

      final jsonFiles = translationsDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.json') && !f.path.endsWith('ru.json'))
          .toList();

      // Регулярное выражение захватывает как именованные {key}, так и позиционные {} плейсхолдеры
      final placeholderRegex = RegExp(r'\{[a-zA-Z0-9\_]*\}');

      for (final targetFile in jsonFiles) {
        final targetLang = targetFile.uri.pathSegments.last.replaceAll('.json', '');
        final targetJson = jsonDecode(targetFile.readAsStringSync()) as Map<String, dynamic>;
        final targetKeys = <String>{};
        final targetValues = <String, String>{};
        _extractLeafKeysAndValues('', targetJson, targetKeys, targetValues);

        // 1. Проверка отсутствующих ключей (Missing in target)
        final missingInTarget = ruKeys.difference(targetKeys);
        expect(
          missingInTarget,
          isEmpty,
          reason: 'В $targetLang.json отсутствуют ключи (${missingInTarget.length}): ${missingInTarget.take(10).join(", ")}',
        );

        // 2. Проверка лишних/устаревших ключей (Extra in target)
        final extraInTarget = targetKeys.difference(ruKeys);
        expect(
          extraInTarget,
          isEmpty,
          reason: 'В $targetLang.json обнаружены лишние/устаревшие ключи (${extraInTarget.length}): ${extraInTarget.take(10).join(", ")}',
        );

        // 3. Проверка количества и состава плейсхолдеров
        for (final key in ruKeys) {
          if (targetValues.containsKey(key)) {
            final ruPlaceholders = placeholderRegex
                .allMatches(ruValues[key]!)
                .map((m) => m.group(0)!)
                .toList()
              ..sort();
            final targetPlaceholders = placeholderRegex
                .allMatches(targetValues[key]!)
                .map((m) => m.group(0)!)
                .toList()
              ..sort();

            expect(
              targetPlaceholders,
              equals(ruPlaceholders),
              reason: 'Несовпадение плейсхолдеров для ключа "$key" в $targetLang.json: RU $ruPlaceholders vs $targetLang $targetPlaceholders',
            );
          }
        }
      }
    });
  });
}

void _extractLeafKeysAndValues(
  String prefix,
  dynamic json,
  Set<String> keys,
  Map<String, String> values,
) {
  if (json is Map<String, dynamic>) {
    json.forEach((key, value) {
      final newPrefix = prefix.isEmpty ? key : '$prefix.$key';
      if (value is Map<String, dynamic>) {
        _extractLeafKeysAndValues(newPrefix, value, keys, values);
      } else {
        keys.add(newPrefix);
        values[newPrefix] = value.toString();
      }
    });
  }
}
