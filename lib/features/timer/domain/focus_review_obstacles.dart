import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/activity_category.dart';

/// Наборы тегов "Что помешало?" для шторки рефлексии.
class FocusReviewObstacles {
  FocusReviewObstacles._();

  static List<String> _tagsForWork() => [
    'obstacles.phone'.tr(),
    'obstacles.tired'.tr(),
    'obstacles.distracted'.tr(),
    'obstacles.procrastination'.tr(),
  ];

  static List<String> _tagsForGrowth() => [
    'obstacles.hard_topic'.tr(),
    'obstacles.phone'.tr(),
    'obstacles.tired'.tr(),
    'obstacles.no_material'.tr(),
  ];

  static List<String> _tagsForSport() => [
    'obstacles.lack_of_sleep'.tr(),
    'obstacles.no_energy'.tr(),
    'obstacles.light_pain'.tr(),
    'obstacles.weather'.tr(),
  ];

  static List<String> _tagsForReligion() => [
    'obstacles.phone'.tr(),
    'obstacles.tired'.tr(),
    'obstacles.scattered_thoughts'.tr(),
    'obstacles.no_time'.tr(),
  ];

  static List<String> _fallbackTags() => [
    'obstacles.phone'.tr(),
    'obstacles.tired'.tr(),
    'obstacles.distracted'.tr(),
    'obstacles.other'.tr(),
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
