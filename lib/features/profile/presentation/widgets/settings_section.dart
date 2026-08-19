import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../backup/application/sync_controller.dart';
import '../../../onboarding/presentation/screens/onboarding_screen.dart';
import '../../../premium/application/premium_controller.dart';
import '../../../premium/presentation/screens/paywall_screen.dart';
import 'language_selector_sheet.dart';

class SettingsSection extends ConsumerWidget {
  const SettingsSection({super.key});

  void _showLanguageSelector(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const LanguageSelectorSheet(),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: Text(
          'profile.about_title'.tr(),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'profile.about_desc'.tr(),
          style: const TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('common.done'.tr()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final _ = context.locale;
    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);
    final isPro = ref.watch(isProProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. БАННЕР ASR PRO
        GestureDetector(
          onTap: () {
            if (!isPro) {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const PaywallScreen()),
              );
            }
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isPro
                    ? [const Color(0xFF059669), const Color(0xFF10B981)]
                    : [const Color(0xFF06B6D4), const Color(0xFF3B82F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: (isPro ? const Color(0xFF10B981) : const Color(0xFF06B6D4))
                      .withValues(alpha: 0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isPro ? Icons.verified : Icons.workspace_premium,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isPro ? 'premium.pro_active_title'.tr() : 'premium.get_pro_title'.tr(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isPro
                            ? 'premium.pro_active_desc'.tr()
                            : 'premium.get_pro_desc'.tr(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white70,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isPro)
                  const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        // 2. СЕКЦИЯ АККАУНТА (Для всех)
        Text(
          'auth.account_title'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),

        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              if (!authState.isAuthenticated) ...[
                // Гостевой режим: предложение войти
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: Colors.white70,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'auth.guest_account'.tr(),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'auth.guest_account_desc'.tr(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white54,
                                    height: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const AuthScreen()),
                            );
                          },
                          icon: const Icon(Icons.login, size: 18),
                          label: Text(
                            'auth.login_or_register'.tr(),
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF06B6D4),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Авторизованный аккаунт: Профиль & Синхронизация
                ListTile(
                  leading: const Icon(Icons.account_circle,
                      size: 26, color: Color(0xFF06B6D4)),
                  title: Text(
                    authState.user?.email ?? 'ASR User',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Text(
                    isPro ? 'ASR PRO 👑' : 'Free Account',
                    style: TextStyle(
                      fontSize: 12,
                      color: isPro ? const Color(0xFF06B6D4) : Colors.white38,
                    ),
                  ),
                  trailing: TextButton(
                    onPressed: () => authNotifier.signOut(),
                    child: Text(
                      'auth.logout'.tr(),
                      style: const TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),

                // Строка синхронизации
                Consumer(
                  builder: (context, ref, _) {
                    final syncState = ref.watch(syncControllerProvider);
                    final syncController =
                        ref.read(syncControllerProvider.notifier);

                    return ListTile(
                      onTap: syncState.isSyncing
                          ? null
                          : () async {
                              final res = await syncController.triggerSync();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: res.isSuccess
                                        ? const Color(0xFF06B6D4)
                                        : Colors.redAccent,
                                    content: Text(
                                      res.isSuccess
                                          ? 'auth.sync_success'.tr()
                                          : (res.message ?? 'Error'),
                                    ),
                                  ),
                                );
                              }
                            },
                      leading: syncState.isSyncing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF06B6D4),
                              ),
                            )
                          : const Icon(Icons.sync,
                              size: 20, color: Color(0xFF06B6D4)),
                      title: Text(
                        'auth.sync_now'.tr(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                      subtitle: syncState.lastSyncedAt != null
                          ? Text(
                              'auth.last_sync'.tr(args: [
                                DateFormat('HH:mm').format(syncState.lastSyncedAt!)
                              ]),
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.white38),
                            )
                          : null,
                      trailing: const Icon(Icons.chevron_right,
                          size: 18, color: Colors.white38),
                    );
                  },
                ),
                const Divider(color: Colors.white12, height: 1),

                // Удаление аккаунта
                ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF1F1F1F),
                        title: Text(
                          'auth.delete_dialog_title'.tr(),
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                        content: Text(
                          'auth.delete_dialog_desc'.tr(),
                          style: const TextStyle(color: Colors.white70, height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: Text('common.cancel'.tr(),
                                style: const TextStyle(color: Colors.white54)),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              Navigator.of(dialogCtx).pop();
                              final success = await authNotifier.deleteAccount();
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    backgroundColor: success
                                        ? const Color(0xFF06B6D4)
                                        : Colors.redAccent,
                                    content: Text(
                                      success
                                          ? 'Аккаунт и все данные успешно удалены.'
                                          : 'Ошибка при удалении аккаунта',
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.redAccent,
                            ),
                            child: Text('auth.delete_confirm'.tr(),
                                style: const TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  leading: const Icon(Icons.delete_forever,
                      size: 20, color: Colors.redAccent),
                  title: Text(
                    'auth.delete_account'.tr(),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // 3. БЛОК ОБЩИХ НАСТРОЕК
        Text(
          'profile.settings'.tr(),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.language,
                label: 'profile.language'.tr(),
                trailingWidget: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      context.locale.languageCode.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF06B6D4),
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right,
                        size: 18, color: Colors.white38),
                  ],
                ),
                onTap: () => _showLanguageSelector(context),
              ),
              const Divider(color: Colors.white12, height: 1),
              _SettingsTile(
                icon: Icons.lightbulb_outline,
                label: 'onboarding.view_onboarding'.tr(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const OnboardingScreen(isFromSettings: true),
                  ),
                ),
              ),
              const Divider(color: Colors.white12, height: 1),
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'profile.about_title'.tr(),
                onTap: () => _showAbout(context),
              ),
              const Divider(color: Colors.white12, height: 1),
              _SettingsTile(
                icon: Icons.download_outlined,
                label: 'profile.export_data'.tr(),
                comingSoon: true,
              ),
              const Divider(color: Colors.white12, height: 1),
              _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'profile.reminders'.tr(),
                comingSoon: true,
                isLast: true,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.label,
    this.onTap,
    this.trailingWidget,
    this.comingSoon = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final Widget? trailingWidget;
  final bool comingSoon;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      enabled: !comingSoon,
      onTap: onTap,
      leading: Icon(
        icon,
        size: 20,
        color: comingSoon ? Colors.white24 : Colors.white70,
      ),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 14,
          color: comingSoon ? Colors.white38 : Colors.white,
        ),
      ),
      trailing: trailingWidget ??
          (comingSoon
              ? Text(
                  'profile.coming_soon'.tr(),
                  style: const TextStyle(fontSize: 11.5, color: Colors.white24),
                )
              : const Icon(Icons.chevron_right, size: 18, color: Colors.white38)),
      shape: isLast
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            )
          : null,
    );
  }
}

