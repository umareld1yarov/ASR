import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/premium_controller.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  int _selectedPlanIndex = 0; // 0: Yearly (Trial), 1: Monthly
  bool _isLoading = false;

  Future<void> _restorePurchases() async {
    setState(() => _isLoading = true);
    try {
      final isPro = await ref.read(premiumControllerProvider).restorePurchases();
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: isPro ? const Color(0xFF06B6D4) : Colors.amber.shade800,
            content: Text(
              isPro
                  ? 'premium.restore_success'.tr()
                  : 'premium.restore_not_found'.tr(),
            ),
          ),
        );
        if (isPro) Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text('${"common.error".tr()}: $e'),
          ),
        );
      }
    }
  }

  Future<void> _subscribe() async {
    final offeringsAsync = ref.read(offeringsProvider);
    final offerings = offeringsAsync.asData?.value;

    if (offerings != null && offerings.current != null) {
      final currentOffering = offerings.current!;
      final package = _selectedPlanIndex == 0
          ? (currentOffering.annual ?? currentOffering.availablePackages.first)
          : (currentOffering.monthly ?? currentOffering.availablePackages.last);

      setState(() => _isLoading = true);
      try {
        final success =
            await ref.read(premiumControllerProvider).purchasePackage(package);
        if (mounted) {
          setState(() => _isLoading = false);
          if (success) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: const Color(0xFF06B6D4),
                content: Text('premium.pro_active_title'.tr()),
              ),
            );
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.redAccent,
              content: Text('${"common.error".tr()}: $e'),
            ),
          );
        }
      }
    } else {
      // Локальный режим эмуляции (если RevenueCat ключи еще не настроены в сторе)
      setState(() => _isLoading = true);
      await Future.delayed(const Duration(milliseconds: 600));
      await ref.read(isProProvider.notifier).setProStatus(true);
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF06B6D4),
            content: Text('${"premium.pro_active_title".tr()} (Test Mode)'),
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final _ = context.locale;
    final offeringsAsync = ref.watch(offeringsProvider);
    final currentOffering = offeringsAsync.asData?.value?.current;

    final annualPackage = currentOffering?.annual ??
        (currentOffering != null && currentOffering.availablePackages.isNotEmpty
            ? currentOffering.availablePackages.first
            : null);
    final monthlyPackage = currentOffering?.monthly ??
        (currentOffering != null && currentOffering.availablePackages.length > 1
            ? currentOffering.availablePackages[1]
            : null);

    final yearlyPrice = annualPackage?.storeProduct.priceString ?? 'premium.yearly_price_fallback'.tr();
    final monthlyPrice = monthlyPackage?.storeProduct.priceString ?? 'premium.monthly_price_fallback'.tr();

    return Scaffold(
      body: AppBackground(
        child: SafeArea(
          child: Column(
            children: [
              // Верхний бар с бейджем и кнопкой закрытия
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium,
                              size: 16, color: Color(0xFF06B6D4)),
                          const SizedBox(width: 6),
                          Text(
                            'ASR PRO',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF06B6D4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, color: Colors.white60),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Заголовок
                      Text(
                        'premium.title'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'premium.subtitle'.tr(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white60,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 3 Главных Столпа ASR Pro
                      _PillarTile(
                        icon: Icons.insights_rounded,
                        title: 'premium.pillar1_title'.tr(),
                        description: 'premium.pillar1_desc'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _PillarTile(
                        icon: Icons.cloud_done_outlined,
                        title: 'premium.pillar2_title'.tr(),
                        description: 'premium.pillar2_desc'.tr(),
                      ),
                      const SizedBox(height: 12),
                      _PillarTile(
                        icon: Icons.people_alt_outlined,
                        title: 'premium.pillar3_title'.tr(),
                        description: 'premium.pillar3_desc'.tr(),
                      ),
                      const SizedBox(height: 28),

                      // Выбор Тарифа
                      _PlanCard(
                        isSelected: _selectedPlanIndex == 0,
                        onTap: () => setState(() => _selectedPlanIndex = 0),
                        badgeText: 'premium.yearly_badge'.tr(),
                        title: 'premium.yearly_plan'.tr(),
                        priceText: yearlyPrice,
                        subText: 'premium.yearly_subtext'.tr(),
                        isBestValue: true,
                      ),
                      const SizedBox(height: 12),
                      _PlanCard(
                        isSelected: _selectedPlanIndex == 1,
                        onTap: () => setState(() => _selectedPlanIndex = 1),
                        title: 'premium.monthly_plan'.tr(),
                        priceText: monthlyPrice,
                        subText: 'premium.monthly_subtext'.tr(),
                      ),
                      const SizedBox(height: 28),

                      // Главная кнопка действия
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _subscribe,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  _selectedPlanIndex == 0
                                      ? 'premium.try_trial_btn'.tr()
                                      : 'premium.subscribe_btn'.tr(),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Футер (Restore Purchases, Terms, Privacy)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton(
                            onPressed: _isLoading ? null : _restorePurchases,
                            child: Text(
                              'premium.restore_btn'.tr(),
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.white54),
                            ),
                          ),
                          const Text('•',
                              style: TextStyle(color: Colors.white24)),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Terms of Service: https://asr.app/terms'),
                                ),
                              );
                            },
                            child: Text(
                              'premium.terms'.tr(),
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.white54),
                            ),
                          ),
                          const Text('•',
                              style: TextStyle(color: Colors.white24)),
                          TextButton(
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Privacy Policy: https://asr.app/privacy'),
                                ),
                              );
                            },
                            child: Text(
                              'premium.privacy'.tr(),
                              style: const TextStyle(
                                  fontSize: 11.5, color: Colors.white54),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PillarTile extends StatelessWidget {
  const _PillarTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF06B6D4).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF06B6D4), size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white60,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.isSelected,
    required this.onTap,
    required this.title,
    required this.priceText,
    required this.subText,
    this.badgeText,
    this.isBestValue = false,
  });

  final bool isSelected;
  final VoidCallback onTap;
  final String title;
  final String priceText;
  final String subText;
  final String? badgeText;
  final bool isBestValue;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF06B6D4).withValues(alpha: 0.12)
                  : Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFF06B6D4)
                    : Colors.white.withValues(alpha: 0.1),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subText,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      priceText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (badgeText != null)
            Positioned(
              top: -10,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF3B82F6)],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badgeText!,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

