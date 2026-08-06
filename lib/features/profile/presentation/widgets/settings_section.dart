import 'package:flutter/material.dart';

/// Настройки — минимальный список для v1. "О приложении" уже работает,
/// остальные пункты — задел на будущее (нет ни экспорта, ни уведомлений,
/// ни политики конфиденциальности) — показаны неактивными с пометкой "скоро".
class SettingsSection extends StatelessWidget {
  const SettingsSection({super.key});

  void _showAbout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1F1F1F),
        title: const Text(
          'О приложении',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'ASR — трекер активности и времени, который помогает не терять время '
          'впустую, видеть свой путь и честно понимать, на что уходят дни.',
          style: TextStyle(color: Colors.white70, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Закрыть'),
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
        const Text(
          'Настройки',
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            children: [
              _SettingsTile(
                icon: Icons.info_outline,
                label: 'О приложении',
                onTap: () => _showAbout(context),
              ),
              const Divider(color: Colors.white12, height: 1),
              const _SettingsTile(
                icon: Icons.download_outlined,
                label: 'Экспорт данных',
                comingSoon: true,
              ),
              const Divider(color: Colors.white12, height: 1),
              const _SettingsTile(
                icon: Icons.notifications_outlined,
                label: 'Напоминания',
                comingSoon: true,
              ),
              const Divider(color: Colors.white12, height: 1),
              const _SettingsTile(
                icon: Icons.lock_outline,
                label: 'Конфиденциальность',
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
    this.comingSoon = false,
    this.isLast = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
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
      trailing: comingSoon
          ? const Text(
              'скоро',
              style: TextStyle(fontSize: 11.5, color: Colors.white24),
            )
          : const Icon(Icons.chevron_right, size: 18, color: Colors.white38),
      shape: isLast
          ? const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            )
          : null,
    );
  }
}
