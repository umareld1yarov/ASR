import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/application/auth_controller.dart';
import '../../../auth/presentation/screens/auth_screen.dart';
import '../../../backup/application/sync_controller.dart';
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
          style: const TextStyle(color: Colors.white),
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
    final authState = ref.watch(authControllerProvider);
    final authNotifier = ref.read(authControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Блок "Облачный бэкап"
        const Text(
          'Синхронизация и Облако',
          style: TextStyle(
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
            border: Border.all(
              color: authState.isCloudBackupEnabled
                  ? const Color(0xFF06B6D4).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            children: [
              SwitchListTile(
                value: authState.isCloudBackupEnabled,
                onChanged: (enabled) {
                  if (enabled && !authState.isAuthenticated) {
                    // Переход на экран входа
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  } else {
                    authNotifier.toggleCloudBackup(enabled);
                  }
                },
                secondary: const Icon(
                  Icons.cloud_sync_outlined,
                  color: Color(0xFF06B6D4),
                ),
                title: const Text(
                  'Облачный бэкап (Supabase)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  authState.isCloudBackupEnabled
                      ? (authState.isAuthenticated
                          ? 'Активен (${authState.user?.email})'
                          : 'Включен (требуется вход)')
                      : 'Отключен (данные только локально)',
                  style: const TextStyle(fontSize: 12, color: Colors.white54),
                ),
                activeTrackColor: const Color(0xFF06B6D4),
              ),


              if (authState.isAuthenticated) ...[
                const Divider(color: Colors.white12, height: 1),
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
                                    content: Text(res.message ?? 'Синхронизировано'),
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
                      title: const Text(
                        'Синхронизировать сейчас',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF06B6D4),
                        ),
                      ),
                      subtitle: syncState.lastSyncedAt != null
                          ? Text(
                              'Последний бэкап: ${DateFormat('HH:mm').format(syncState.lastSyncedAt!)}',
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
                ListTile(
                  leading: const Icon(Icons.account_circle_outlined,
                      size: 20, color: Colors.white70),
                  title: Text(
                    authState.user?.email ?? 'Авторизован',
                    style: const TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  trailing: TextButton(
                    onPressed: () => authNotifier.signOut(),
                    child: const Text(
                      'Выйти',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                    ),
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (dialogCtx) => AlertDialog(
                        backgroundColor: const Color(0xFF1F1F1F),
                        title: const Text(
                          'Удалить аккаунт?',
                          style: TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.bold),
                        ),
                        content: const Text(
                          'Вы намерены безвозвратно удалить свой аккаунт, все прикреплённые фото из хранилища и все сохраненные записи. Это действие нельзя отменить.',
                          style: TextStyle(color: Colors.white70, height: 1.4),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(dialogCtx).pop(),
                            child: const Text('Отмена',
                                style: TextStyle(color: Colors.white54)),
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
                            child: const Text('Удалить навсегда',
                                style: TextStyle(color: Colors.white)),
                          ),
                        ],
                      ),
                    );
                  },
                  leading: const Icon(Icons.delete_forever,
                      size: 20, color: Colors.redAccent),
                  title: const Text(
                    'Удалить аккаунт и данные',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ]

 else if (authState.isCloudBackupEnabled) ...[
                const Divider(color: Colors.white12, height: 1),
                ListTile(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    );
                  },
                  leading: const Icon(Icons.login,
                      size: 20, color: Color(0xFF06B6D4)),
                  title: const Text(
                    'Войти или зарегистрироваться',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF06B6D4),
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right,
                      size: 18, color: Colors.white38),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Блок основных настроек
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
