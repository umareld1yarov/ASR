import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../profile/application/profile_provider.dart';
import '../../timer/application/timer_provider.dart';

const String _kOnboardingCompletedKey = 'onboarding_completed_v1';

/// Провайдер флага завершения онбординга.
final isOnboardingCompletedProvider = FutureProvider<bool>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getBool(_kOnboardingCompletedKey) ?? false;
});

class OnboardingController {
  OnboardingController(this._ref);

  final Ref _ref;

  /// Завершить онбординг, сохранить стартовое имя и выбранную категорию фокуса.
  Future<void> completeOnboarding({
    String? name,
    String? categoryKey,
  }) async {
    final cleanName = name?.trim();
    if (cleanName != null && cleanName.isNotEmpty) {
      await _ref
          .read(profileControllerProvider)
          .updateProfile(name: cleanName);
    }

    if (categoryKey != null && categoryKey.isNotEmpty) {
      final timerController = _ref.read(timerControllerProvider);
      await timerController.switchActivity(
        name: cleanName != null && cleanName.isNotEmpty ? 'Старт пути' : 'Фокус',
        categoryKey: categoryKey,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kOnboardingCompletedKey, true);
    _ref.invalidate(isOnboardingCompletedProvider);
  }
}

final onboardingControllerProvider = Provider<OnboardingController>((ref) {
  return OnboardingController(ref);
});
