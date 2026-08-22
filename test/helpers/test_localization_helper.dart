import 'dart:convert';
import 'dart:io';
import 'package:easy_localization/easy_localization.dart';
import 'package:easy_localization/src/localization.dart';
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';

Map<String, dynamic>? _cachedRuTranslations;

Map<String, dynamic> getRuTranslations() {
  if (_cachedRuTranslations != null) return _cachedRuTranslations!;
  final file = File('assets/translations/ru.json');
  final content = file.readAsStringSync();
  _cachedRuTranslations = jsonDecode(content) as Map<String, dynamic>;
  return _cachedRuTranslations!;
}

void initTestLocalization() {
  EasyLocalization.logger.enableLevels = [];
  final translations = getRuTranslations();
  Localization.load(
    const Locale('ru'),
    translations: Translations(translations),
  );
}

class JsonAssetLoader extends AssetLoader {
  final Map<String, dynamic> data;
  const JsonAssetLoader(this.data);

  @override
  Future<Map<String, dynamic>> load(String path, Locale locale) async => data;
}

Widget createLocalizedTestApp({
  required Widget child,
}) {
  final translations = getRuTranslations();
  return EasyLocalization(
    supportedLocales: const [Locale('ru')],
    path: 'assets/translations',
    assetLoader: JsonAssetLoader(translations),
    fallbackLocale: const Locale('ru'),
    startLocale: const Locale('ru'),
    saveLocale: false,
    useOnlyLangCode: true,
    child: child,
  );
}
