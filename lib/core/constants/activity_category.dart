import 'package:flutter/material.dart';

/// Девять фиксированных категорий активности.
/// Список захардкожен намеренно — редактируемость не нужна.
enum ActivityCategory {
  religion,
  work,
  growth,
  finance,
  sport,
  family,
  rest,
  waste,
  base;

  /// Название на русском для UI
  String get label {
    switch (this) {
      case ActivityCategory.religion:
        return 'Религия';
      case ActivityCategory.work:
        return 'Работа';
      case ActivityCategory.growth:
        return 'Развитие';
      case ActivityCategory.finance:
        return 'Финансы';
      case ActivityCategory.sport:
        return 'Спорт';
      case ActivityCategory.family:
        return 'Семья/Друзья';
      case ActivityCategory.rest:
        return 'Отдых';
      case ActivityCategory.waste:
        return 'Потери';
      case ActivityCategory.base:
        return 'Базовые';
    }
  }

  /// Цвет категории — используется в таймере, статах, ленте
  Color get color {
    switch (this) {
      case ActivityCategory.religion:
        return const Color(0xFFA855F7); // фиолетовый
      case ActivityCategory.work:
        return const Color(0xFF22C55E); // зелёный
      case ActivityCategory.growth:
        return const Color(0xFFF97316); // оранжевый
      case ActivityCategory.finance:
        return const Color(0xFFEAB308); // золотистый
      case ActivityCategory.sport:
        return const Color(0xFF3B82F6); // синий
      case ActivityCategory.family:
        return const Color(0xFFEC4899); // розовый
      case ActivityCategory.rest:
        return const Color(0xFF06B6D4); // бирюзовый
      case ActivityCategory.waste:
        return const Color(0xFFEF4444); // красный
      case ActivityCategory.base:
        return const Color(0xFFA3A3A3); // серый
    }
  }

  /// Иконка категории — используется в плитках статистики и пикере.
  /// Эмодзи категории — используется в плитках статистики и пикере.
  String get emoji {
    switch (this) {
      case ActivityCategory.religion:
        return '🕌';
      case ActivityCategory.work:
        return '💼';
      case ActivityCategory.growth:
        return '📚';
      case ActivityCategory.finance:
        return '💰';
      case ActivityCategory.sport:
        return '💪';
      case ActivityCategory.family:
        return '👪';
      case ActivityCategory.rest:
        return '🌴';
      case ActivityCategory.waste:
        return '⏳';
      case ActivityCategory.base:
        return '🏠';
    }
  }

  /// Строковый ключ для хранения в Isar (стабильный, не зависит от порядка enum)
  String get storageKey => name;

  /// Обратное преобразование из storageKey — нужно при чтении из БД
  static ActivityCategory fromStorageKey(String key) {
    return ActivityCategory.values.firstWhere(
      (e) => e.storageKey == key,
      orElse: () => ActivityCategory.base,
    );
  }
}
