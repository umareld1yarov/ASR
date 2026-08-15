import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'language_selector_sheet.dart';

class SettingsSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
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
