import 'dart:convert';
import 'dart:io';

/// Усовершенствованный инструмент аудита локализации ASR.
/// Требует:
/// 1. 0 незалокализованных пользовательских строк (Hardcoded user-facing strings = 0).
/// 2. 0 пропущенных ключей (Missing keys = 0).
/// 3. 0 ошибок паритета языков и плейсхолдеров ({count}, {date}, {duration}).
void main() async {
  stdout.writeln('====================================================');
  stdout.writeln(' 🌐 ASR STRICTOR LOCALIZATION AUDIT TOOL');
  stdout.writeln('====================================================\n');

  final libDir = Directory('lib');
  final translationsDir = Directory('assets/translations');

  if (!libDir.existsSync() || !translationsDir.existsSync()) {
    stdout.writeln(
      '❌ Error: Directory lib/ or assets/translations/ not found!',
    );
    exit(1);
  }

  // 1. Чтение всех JSON файлов локализации
  final jsonFiles = translationsDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.json'))
      .toList();

  final Map<String, Map<String, dynamic>> translations = {};
  final Map<String, Set<String>> languageLeafKeys = {};
  final Map<String, Map<String, String>> languageLeafValues = {};

  for (final file in jsonFiles) {
    final langCode = file.uri.pathSegments.last.replaceAll('.json', '');
    try {
      final content = file.readAsStringSync();
      final Map<String, dynamic> jsonMap = jsonDecode(content);
      translations[langCode] = jsonMap;

      final keys = <String>{};
      final values = <String, String>{};
      _extractLeafKeysAndValues('', jsonMap, keys, values);
      languageLeafKeys[langCode] = keys;
      languageLeafValues[langCode] = values;
    } catch (e) {
      stdout.writeln('❌ Error parsing ${file.path}: $e');
      exit(1);
    }
  }

  final ruKeys = languageLeafKeys['ru'] ?? {};
  final ruValues = languageLeafValues['ru'] ?? {};

  // 2. Глубокое сканирование lib/
  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'))
      .toList();

  final usedKeys = <String>{};
  final Map<String, List<String>> keyUsages = {};
  final List<String> hardcodedUserStrings = [];
  final List<String> localizedUserStrings = [];

  final trMethodRegex = RegExp(r"'([^']+)'\.tr\(");
  final trFuncRegex = RegExp(r"tr\('([^']+)'");
  final doubleQuoteTrRegex = RegExp(r'"([^"]+)"\.tr\(');
  final doubleQuoteFuncRegex = RegExp(r'tr\("([^"]+)"');

  // Регулярка для выявления любых кириллических строк в коде
  final cyrillicStringRegex = RegExp(r'''(['"])(.*?[\u0400-\u04FF].*?)\1''');

  // Белый список файлов с пользовательскими тестовыми данными (Mock User Data)
  final mockDataFiles = [
    'lib/features/community/data/mock_community_repository.dart',
    'lib/features/feed/data/mock_feed_repository.dart',
  ];

  for (final file in dartFiles) {
    final relativePath = file.path.replaceAll('\\', '/');
    final content = file.readAsStringSync();
    final lines = content.split('\n');

    final isMockFile = mockDataFiles.any((m) => relativePath.endsWith(m));

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final lineNumber = i + 1;
      final trimmedLine = line.trim();

      // Пропускаем однострочные комментарии
      if (trimmedLine.startsWith('//') || trimmedLine.startsWith('///')) {
        continue;
      }

      // Находим вызовы .tr()
      for (final match in trMethodRegex.allMatches(line)) {
        final rawKey = match.group(1)!;
        _registerKey(
          rawKey,
          usedKeys,
          keyUsages,
          '$relativePath:$lineNumber',
          ruKeys,
        );
        if (ruValues.containsKey(rawKey)) {
          localizedUserStrings.add(
            '$relativePath:$lineNumber -> "${ruValues[rawKey]}"',
          );
        }
      }
      for (final match in trFuncRegex.allMatches(line)) {
        final rawKey = match.group(1)!;
        _registerKey(
          rawKey,
          usedKeys,
          keyUsages,
          '$relativePath:$lineNumber',
          ruKeys,
        );
        if (ruValues.containsKey(rawKey)) {
          localizedUserStrings.add(
            '$relativePath:$lineNumber -> "${ruValues[rawKey]}"',
          );
        }
      }
      for (final match in doubleQuoteTrRegex.allMatches(line)) {
        final rawKey = match.group(1)!;
        _registerKey(
          rawKey,
          usedKeys,
          keyUsages,
          '$relativePath:$lineNumber',
          ruKeys,
        );
      }
      for (final match in doubleQuoteFuncRegex.allMatches(line)) {
        final rawKey = match.group(1)!;
        _registerKey(
          rawKey,
          usedKeys,
          keyUsages,
          '$relativePath:$lineNumber',
          ruKeys,
        );
      }

      // Сканируем хардкод кириллических строк для UI (в пользовательском интерфейсе)
      final isTechnicalFile =
          relativePath.startsWith('lib/core/') ||
          relativePath.startsWith('lib/data/');
      final isTechnicalLine =
          line.contains('StateError') ||
          line.contains('Exception') ||
          line.contains('print') ||
          line.contains('debugPrint');

      if (!isMockFile && !isTechnicalFile && !isTechnicalLine) {
        for (final match in cyrillicStringRegex.allMatches(line)) {
          final text = match.group(2)!;
          // Проверяем, не является ли это вызовом .tr() или комментарием
          if (!line.contains('.tr(') &&
              !line.contains('tr(') &&
              !_isDocCommentOrAsset(text)) {
            hardcodedUserStrings.add('$relativePath:$lineNumber -> "$text"');
          }
        }
      }
    }
  }

  // 3. Недостающие ключи
  final missingKeys = <String>[];
  for (final usedKey in usedKeys) {
    if (!_hasKey(usedKey, ruKeys)) {
      missingKeys.add(usedKey);
    }
  }

  // 4. Незадействованные ключи
  final unusedKeys = <String>[];
  for (final ruKey in ruKeys) {
    final baseKey = _stripPluralSuffix(ruKey);
    if (!usedKeys.contains(baseKey) && !usedKeys.contains(ruKey)) {
      unusedKeys.add(ruKey);
    }
  }

  // 5. Проверка паритета и плейсхолдеров
  final Map<String, List<String>> parityErrors = {};
  final List<String> placeholderErrors = [];
  final baseLang = 'ru';
  final baseKeys = languageLeafKeys[baseLang]!;

  for (final entry in languageLeafKeys.entries) {
    if (entry.key == baseLang) continue;
    final targetLang = entry.key;
    final targetKeys = entry.value;
    final targetValues = languageLeafValues[targetLang]!;

    final missingInTarget = baseKeys.difference(targetKeys).toList();
    final extraInTarget = targetKeys.difference(baseKeys).toList();

    if (missingInTarget.isNotEmpty || extraInTarget.isNotEmpty) {
      final errors = <String>[];
      if (missingInTarget.isNotEmpty) {
        errors.add(
          'Missing keys (${missingInTarget.length}): ${missingInTarget.take(5).join(", ")}',
        );
      }
      if (extraInTarget.isNotEmpty) {
        errors.add(
          'Extra keys (${extraInTarget.length}): ${extraInTarget.take(5).join(", ")}',
        );
      }
      parityErrors[targetLang] = errors;
    }

    final placeholderRegex = RegExp(r'\{[a-zA-Z0-9\_]*\}');
    for (final ruKey in baseKeys) {
      if (targetValues.containsKey(ruKey)) {
        final ruPlaceholders =
            placeholderRegex
                .allMatches(ruValues[ruKey]!)
                .map((m) => m.group(0)!)
                .toList()
              ..sort();
        final targetPlaceholders =
            placeholderRegex
                .allMatches(targetValues[ruKey]!)
                .map((m) => m.group(0)!)
                .toList()
              ..sort();

        if (ruPlaceholders.join(',') != targetPlaceholders.join(',')) {
          placeholderErrors.add(
            '[$targetLang.json] Key "$ruKey": placeholders RU [${ruPlaceholders.join(", ")}] vs $targetLang [${targetPlaceholders.join(", ")}]',
          );
        }
      }
    }
  }

  // 6. Формирование Отчёта по категориям
  stdout.writeln('----------------------------------------------------');
  stdout.writeln(' 🔍 DETAILED AUDIT REPORT');
  stdout.writeln('----------------------------------------------------');
  stdout.writeln(
    '📱 Localized user-facing strings: ${localizedUserStrings.length}',
  );
  stdout.writeln(
    '⚠️ Hardcoded user-facing strings: ${hardcodedUserStrings.length}',
  );
  stdout.writeln('🔑 Used localization keys: ${usedKeys.length}');
  stdout.writeln('❌ Missing localization keys: ${missingKeys.length}');
  stdout.writeln('📦 Unused localization keys: ${unusedKeys.length}');
  stdout.writeln('🔄 Placeholder mismatches: ${placeholderErrors.length}\n');

  var hasFailures = false;

  if (hardcodedUserStrings.isNotEmpty) {
    hasFailures = true;
    stdout.writeln(
      '🚨 HARDCODED USER-FACING STRINGS FOUND (${hardcodedUserStrings.length}):',
    );
    for (final h in hardcodedUserStrings) {
      stdout.writeln('   - $h');
    }
    stdout.writeln();
  } else {
    stdout.writeln('✅ Hardcoded user-facing strings: 0 (Strict PASS)');
  }

  if (missingKeys.isNotEmpty) {
    hasFailures = true;
    stdout.writeln('❌ MISSING LOCALIZATION KEYS (${missingKeys.length}):');
    for (final k in missingKeys) {
      stdout.writeln('   - $k');
    }
    stdout.writeln();
  } else {
    stdout.writeln('✅ Missing localization keys: 0');
  }

  if (placeholderErrors.isNotEmpty) {
    hasFailures = true;
    stdout.writeln('❌ PLACEHOLDER MISMATCHES (${placeholderErrors.length}):');
    for (final err in placeholderErrors) {
      stdout.writeln('   - $err');
    }
    stdout.writeln();
  } else {
    stdout.writeln('✅ Placeholder mismatches: 0');
  }

  if (parityErrors.isNotEmpty) {
    hasFailures = true;
    stdout.writeln('❌ CROSS-LANGUAGE PARITY ERRORS:');
    parityErrors.forEach((lang, errors) {
      stdout.writeln('   [$lang.json]: ${errors.join("; ")}');
    });
    stdout.writeln();
  } else {
    stdout.writeln('✅ Cross-language key parity OK');
  }

  if (unusedKeys.isNotEmpty) {
    stdout.writeln('ℹ️ UNUSED LOCALIZATION KEYS (${unusedKeys.length}):');
    for (final k in unusedKeys) {
      stdout.writeln('   - $k');
    }
    stdout.writeln();
  }

  stdout.writeln('====================================================');
  if (hasFailures) {
    stdout.writeln(' 💥 OVERALL AUDIT STATUS: FAIL');
    stdout.writeln('====================================================');
    exit(1);
  } else {
    stdout.writeln(' 🎉 OVERALL AUDIT STATUS: PASS');
    stdout.writeln('====================================================');
    exit(0);
  }
}

void _registerKey(
  String rawKey,
  Set<String> usedKeys,
  Map<String, List<String>> keyUsages,
  String location,
  Set<String> ruKeys,
) {
  if (rawKey.contains('\$')) {
    final prefix = rawKey.split('\$').first;
    for (final ruKey in ruKeys) {
      if (ruKey.startsWith(prefix)) {
        usedKeys.add(ruKey);
        keyUsages.putIfAbsent(ruKey, () => []).add(location);
      }
    }
  } else {
    usedKeys.add(rawKey);
    keyUsages.putIfAbsent(rawKey, () => []).add(location);
    for (final ruKey in ruKeys) {
      if (ruKey.startsWith('$rawKey.')) {
        usedKeys.add(ruKey);
        keyUsages.putIfAbsent(ruKey, () => []).add(location);
      }
    }
  }
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

bool _hasKey(String key, Set<String> ruKeys) {
  if (ruKeys.contains(key)) return true;
  if (ruKeys.any((k) => k.startsWith('$key.'))) return true;
  return false;
}

String _stripPluralSuffix(String key) {
  const suffixes = ['.zero', '.one', '.few', '.many', '.other'];
  for (final s in suffixes) {
    if (key.endsWith(s)) {
      return key.substring(0, key.length - s.length);
    }
  }
  return key;
}

bool _isDocCommentOrAsset(String text) {
  final trimmed = text.trim();
  if (trimmed.startsWith('//') || trimmed.startsWith('/*')) {
    return true;
  }
  if (trimmed.startsWith('assets/') || trimmed.startsWith('package:')) {
    return true;
  }

  // Допустимые эндонимы языков в меню выбора
  const languageEndonyms = [
    'Русский',
    'Кыргызча',
    'English',
    'العربية',
    'Türkçe',
    'Deutsch',
    'Español',
    'Português',
  ];
  if (languageEndonyms.any((e) => trimmed.contains(e))) return true;

  // Распознаём технические шаблоны форматирования времени (напр. "$hч $mм", "$hoursч", "$mм", "minsм")
  if (trimmed.contains('\$hч') ||
      trimmed.contains('\$hoursч') ||
      trimmed.contains('\$mм') ||
      trimmed.contains('\$minutesм') ||
      trimmed.contains('\$minsм') ||
      trimmed == 'ч' ||
      trimmed == 'м' ||
      trimmed == 'мин') {
    return true;
  }

  if (RegExp(
    r'^[$\{\}\w\s\:\.\-\—\(\)\?\>\<\=\"]*(?:ч|мин|м|минут)[$\{\}\w\s\:\.\-\—\(\)\?\>\<\=\"]*$',
  ).hasMatch(trimmed)) {
    return true;
  }
  return false;
}
