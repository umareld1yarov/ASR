import '../../../core/constants/activity_category.dart';

/// Наборы тегов "Что помешало?" для шторки рефлексии.
class FocusReviewObstacles {
  FocusReviewObstacles._();

  static List<String> _tagsForWork() => [
    'obstacles.phone',
    'obstacles.tired',
    'obstacles.distracted',
    'obstacles.procrastination',
  ];

  static List<String> _tagsForGrowth() => [
    'obstacles.hard_topic',
    'obstacles.phone',
    'obstacles.tired',
    'obstacles.no_material',
  ];

  static List<String> _tagsForSport() => [
    'obstacles.lack_of_sleep',
    'obstacles.no_energy',
    'obstacles.light_pain',
    'obstacles.weather',
  ];

  static List<String> _tagsForReligion() => [
    'obstacles.phone',
    'obstacles.tired',
    'obstacles.scattered_thoughts',
    'obstacles.no_time',
  ];

  static List<String> _fallbackTags() => [
    'obstacles.phone',
    'obstacles.tired',
    'obstacles.distracted',
    'obstacles.other',
  ];

  static bool appliesTo(ActivityCategory category) {
    return category == ActivityCategory.work ||
        category == ActivityCategory.growth ||
        category == ActivityCategory.sport ||
        category == ActivityCategory.religion;
  }

  static List<String> tagsFor(ActivityCategory category) {
    switch (category) {
      case ActivityCategory.work:
        return _tagsForWork();
      case ActivityCategory.growth:
        return _tagsForGrowth();
      case ActivityCategory.sport:
        return _tagsForSport();
      case ActivityCategory.religion:
        return _tagsForReligion();
      default:
        return _fallbackTags();
    }
  }
}
