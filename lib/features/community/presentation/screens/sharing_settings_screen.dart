import 'package:asr/features/community/community_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/community_provider.dart';
import '../../domain/models/friendship.dart';
import '../../domain/models/sharing_permission.dart';

/// Настройка того, что Я разрешаю видеть КОНКРЕТНОМУ другу.
/// Настройка индивидуального доступа друга к текущей активности.
class SharingSettingsScreen extends ConsumerStatefulWidget {
  const SharingSettingsScreen({super.key, required this.friendship});

  final Friendship friendship;

  @override
  ConsumerState<SharingSettingsScreen> createState() =>
      _SharingSettingsScreenState();
}

class _SharingSettingsScreenState extends ConsumerState<SharingSettingsScreen> {
  late SharingScope _scope;

  @override
  void initState() {
    super.initState();
    final permission = widget.friendship.myPermissionForFriend;
    _scope = permission.scope;
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(communityControllerProvider);

    return AppBackground(
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                  ),
                  Expanded(
                    child: Text(
                      'Доступ к активности',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _ScopeOption(
                    title: 'Ничего не показывать',
                    subtitle: 'Друг не увидит, чем вы занимаетесь сейчас',
                    selected: _scope == SharingScope.none,
                    onTap: () => setState(() => _scope = SharingScope.none),
                  ),
                  _ScopeOption(
                    title: 'Только категория',
                    subtitle:
                        'Видны категория и время с начала, без названия дела',
                    selected: _scope == SharingScope.category,
                    onTap: () => setState(() => _scope = SharingScope.category),
                  ),
                  _ScopeOption(
                    title: 'Полная активность',
                    subtitle:
                        'Видны категория, название дела и время с начала',
                    selected: _scope == SharingScope.fullActivity,
                    onTap: () =>
                        setState(() => _scope = SharingScope.fullActivity),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await controller.updateSharingPermission(
                      SharingPermission(
                        friendId: widget.friendship.friend.id,
                        scope: _scope,
                      ),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CommunityTheme.accentColor,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Сохранить',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeOption extends StatelessWidget {
  const _ScopeOption({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? CommunityTheme.accentColor.withValues(alpha: 0.12)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? CommunityTheme.accentColor
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? CommunityTheme.accentColor : Colors.white30,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
