import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../../../shared/widgets/app_bottom_nav.dart';
import '../../application/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.isFromSettings = false});

  final bool isFromSettings;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isFinishing = false;

  final List<Map<String, String>> _languages = const [
    {'code': 'ru', 'name': 'Русский', 'flag': '🇷🇺'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧'},
    {'code': 'ky', 'name': 'Кыргызча', 'flag': '🇰🇬'},
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷'},
    {'code': 'ar', 'name': 'العربية', 'flag': '🇸🇦'},
    {'code': 'de', 'name': 'Deutsch', 'flag': '🇩🇪'},
    {'code': 'es', 'name': 'Español', 'flag': '🇪🇸'},
    {'code': 'pt', 'name': 'Português', 'flag': '🇧🇷'},
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    HapticFeedback.selectionClick();
    setState(() => _currentPage = index);
  }

  void _nextPage() {
    if (_currentPage < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    if (_isFinishing) return;
    setState(() => _isFinishing = true);

    HapticFeedback.mediumImpact();

    await ref.read(onboardingControllerProvider).completeOnboarding();

    if (!mounted) return;

    if (widget.isFromSettings) {
      Navigator.of(context).pop();
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AppBottomNav()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Верхняя панель: Назад / Точки прогресса / Пропустить
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Кнопка назад (если не на 1 экране)
                    if (_currentPage > 0)
                      IconButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white70,
                          size: 18,
                        ),
                      )
                    else
                      const SizedBox(width: 40),

                    // Индикатор точек прогресса
                    Row(
                      children: List.generate(5, (index) {
                        final isCurrent = index == _currentPage;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(right: 6),
                          width: isCurrent ? 24 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? const Color(0xFF06B6D4)
                                : Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: isCurrent
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF06B6D4)
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    ),
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),

                    if (widget.isFromSettings)
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close, color: Colors.white70),
                      )
                    else if (_currentPage < 4)
                      TextButton(
                        onPressed: _finishOnboarding,
                        child: Text(
                          'onboarding.skip_btn'.tr(),
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.45),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 40),
                  ],
                ),
              ),

              // Слайды PageView
              Expanded(
                child: PageView(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  children: [
                    _buildLanguageScreen(),
                    _buildTextSlide(
                      icon: Icons.hourglass_empty_rounded,
                      iconColor: const Color(0xFF06B6D4),
                      title: 'onboarding.slide1_title'.tr(),
                      text1: 'onboarding.slide1_text1'.tr(),
                      text2: 'onboarding.slide1_text2'.tr(),
                    ),
                    _buildTextSlide(
                      icon: Icons.all_inclusive_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'onboarding.slide2_title'.tr(),
                      text1: 'onboarding.slide2_text1'.tr(),
                      text2: 'onboarding.slide2_text2'.tr(),
                    ),
                    _buildTextSlide(
                      icon: Icons.auto_stories_rounded,
                      iconColor: const Color(0xFFF59E0B),
                      title: 'onboarding.slide3_title'.tr(),
                      text1: 'onboarding.slide3_text1'.tr(),
                      text2: 'onboarding.slide3_text2'.tr(),
                    ),
                    _buildSecuritySlide(),
                  ],
                ),
              ),

              // Нижняя кнопка
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                child: ElevatedButton(
                  onPressed: _isFinishing ? null : _nextPage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF06B6D4),
                    foregroundColor: Colors.black,
                    minimumSize: const Size(double.infinity, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF06B6D4).withValues(alpha: 0.5),
                  ),
                  child: _isFinishing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.black,
                          ),
                        )
                      : Text(
                          _currentPage == 0
                              ? 'onboarding.continue_btn'.tr()
                              : _currentPage == 4
                                  ? 'onboarding.start_btn'.tr()
                                  : 'onboarding.next_btn'.tr(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── ЭКРАН 1: Приветствие на английском + Выбор языка ─────
  Widget _buildLanguageScreen() {
    final currentCode = context.locale.languageCode;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'ASR',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Welcome to ASR',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Your Time. Your Life. Your Story.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'onboarding.choose_language'.tr(),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 2.3,
            ),
            itemCount: _languages.length,
            itemBuilder: (context, index) {
              final lang = _languages[index];
              final isSelected = currentCode == lang['code'];

              return GestureDetector(
                onTap: () async {
                  HapticFeedback.selectionClick();
                  await context.setLocale(Locale(lang['code']!));
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF06B6D4).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF06B6D4)
                          : Colors.white.withValues(alpha: 0.08),
                      width: isSelected ? 1.8 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(lang['flag']!, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lang['name']!,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.w800
                                : FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isSelected)
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF06B6D4),
                          size: 16,
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ── ТЕКСТОВЫЙ СЛАЙД (Экраны 2, 3, 4) ──────────────────────
  Widget _buildTextSlide({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String text1,
    required String text2,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.1),
              border: Border.all(
                color: iconColor.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: iconColor.withValues(alpha: 0.25),
                  blurRadius: 24,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: 38,
                color: iconColor,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            text1,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF06B6D4),
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            text2,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 15,
              height: 1.55,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  // ── ЭКРАН 5: Приватность & Облачный сейф ─────────────────
  Widget _buildSecuritySlide() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              border: Border.all(
                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.25),
                  blurRadius: 24,
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.shield_outlined,
                size: 38,
                color: Color(0xFF10B981),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'onboarding.slide4_title'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'onboarding.slide4_text1'.tr(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.phone_android, color: Color(0xFF10B981), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'onboarding.slide4_offline_title'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'onboarding.slide4_offline_desc'.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(color: Colors.white12, height: 1),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.cloud_outlined, color: Color(0xFF3B82F6), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'onboarding.slide4_cloud_title'.tr(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'onboarding.slide4_cloud_desc'.tr(),
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
