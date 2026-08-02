import '../../../core/constants/activity_category.dart';

/// Наборы тегов "Что помешало?" для шторки рефлексии — свои под каждую
/// из четырёх категорий, где включена рефлексия (Работа, Развитие,
/// Спорт, Религия). Для остальных категорий рефлексия не показывается.
class FocusReviewObstacles {
  FocusReviewObstacles._();

  static const Map<ActivityCategory, List<String>> _byCategory = {
    ActivityCategory.work: [
      '📱 Телефон',
      '😴 Устал',
      '🗣️ Отвлекли',
      '🌀 Прокрастинация',
    ],
    ActivityCategory.growth: [
      '🤯 Сложная тема',
      '📱 Телефон',
      '😴 Устал',
      '📚 Не было материала',
    ],
    ActivityCategory.sport: [
      '😴 Не выспался',
      '💪 Не было сил',
      '🤕 Лёгкая боль/травма',
      '🌧️ Погода/условия',
    ],
    ActivityCategory.religion: [
      '📱 Телефон',
      '😴 Устал',
      '🌀 Мысли разбежались',
      '⏰ Не было времени',
    ],
  };

  /// Категории, для которых вообще показывается шторка рефлексии.
  static bool appliesTo(ActivityCategory category) =>
      _byCategory.containsKey(category);

  /// Список тегов для конкретной категории (пустой список, если категория
  /// не поддерживает рефлексию — на практике проверяй appliesTo() раньше).
  static List<String> tagsFor(ActivityCategory category) =>
      _byCategory[category] ?? const [];
}
