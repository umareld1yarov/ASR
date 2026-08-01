import 'package:flutter/material.dart';

/// Шесть фиксированных категорий активности.
/// В MVP список захардкожен — редактируемые категории отложены на этап 2.
enum ActivityCategory {
  focus,
  religion,
  growth,
  sport,
  base,
  waste;

  /// Название на русском для UI
  String get label {
    switch (this) {
      case ActivityCategory.focus:
        return 'Фокус';
      case ActivityCategory.religion:
        return 'Религия';
      case ActivityCategory.growth:
        return 'Развитие';
      case ActivityCategory.sport:
        return 'Спорт';
      case ActivityCategory.base:
        return 'Базовые';
      case ActivityCategory.waste:
        return 'Потери';
    }
  }

  /// Цвет категории — используется в таймере, статах, ленте
  Color get color {
    switch (this) {
      case ActivityCategory.focus:
        return const Color(0xFF22C55E); // зелёный
      case ActivityCategory.religion:
        return const Color(0xFFA855F7); // фиолетовый
      case ActivityCategory.growth:
        return const Color(0xFFF97316); // оранжевый
      case ActivityCategory.sport:
        return const Color(0xFF3B82F6); // синий
      case ActivityCategory.base:
        return const Color(0xFFA3A3A3); // серый
      case ActivityCategory.waste:
        return const Color(0xFFEF4444); // красный
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
