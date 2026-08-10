import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_background.dart';
import '../../application/community_provider.dart';
import '../../domain/models/friendship.dart';
import '../../domain/models/sharing_permission.dart';
import '../../../../core/constants/activity_category.dart';

/// Настройка того, что Я разрешаю видеть КОНКРЕТНОМУ другу.
/// scope: none / live / category / fullDay — см. SharingPermission.
/// Категории — временный фиксированный список ключей (совпадает с
/// core/constants/activity_category.dart), пока без импорта самого enum,
/// чтобы не тянуть лишнюю зависимость в фичу community.
class SharingSettingsScreen extends ConsumerStatefulWidget {
  const SharingSettingsScreen({super.key, required this.friendship});

  final Friendship friendship;

  @override
  ConsumerState<SharingSettingsScreen> createState() =>
      _SharingSettingsScreenState();
}

class _SharingSettingsScreenState extends ConsumerState<SharingSettingsScreen> {
  late SharingScope _scope;
  late Set<String> _selectedCategories;

  static const _accentColor = Color(0xFF06B6D4);

  @override
  void initState() {
    super.initState();
    final permission = widget.friendship.myPermissionForFriend;
    _scope = permission.scope;
    _selectedCategories = permission.allowedCategoryKeys.toSet();
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
                      'Доступ для ${widget.friendship.friend.displayName}',
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
                    subtitle: 'Друг видит, что вы не в сети',
                    selected: _scope == SharingScope.none,
                    onTap: () => setState(() => _scope = SharingScope.none),
                  ),
                  _ScopeOption(
                    title: 'Только "сейчас"',
                    subtitle:
                        'Видно только текущую активность в реальном времени',
                    selected: _scope == SharingScope.live,
                    onTap: () => setState(() => _scope = SharingScope.live),
                  ),
                  _ScopeOption(
                    title: 'Выбранные категории',
                    subtitle:
                        'Видно live и записи только по отмеченным категориям',
                    selected: _scope == SharingScope.category,
                    onTap: () => setState(() => _scope = SharingScope.category),
                  ),
                  _ScopeOption(
                    title: 'Весь день',
                    subtitle: 'Видно всю ленту активностей за сегодня',
                    selected: _scope == SharingScope.fullDay,
                    onTap: () => setState(() => _scope = SharingScope.fullDay),
                  ),
                  if (_scope == SharingScope.category) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Категории',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ActivityCategory.values.map((category) {
                        final key = category.storageKey;
                        final label = category.label;
                        final selected = _selectedCategories.contains(key);
                        return ChoiceChip(
                          label: Text(label),
                          selected: selected,
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedCategories.add(key);
                              } else {
                                _selectedCategories.remove(key);
                              }
                            });
                          },
                          selectedColor: _accentColor.withOpacity(0.25),
                          backgroundColor: Colors.white.withOpacity(0.06),
                          labelStyle: TextStyle(
                            color: selected ? _accentColor : Colors.white60,
                            fontWeight: FontWeight.w600,
                          ),
                          side: BorderSide(
                            color: selected
                                ? _accentColor
                                : Colors.white.withOpacity(0.1),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
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
                        allowedCategoryKeys: _selectedCategories.toList(),
                      ),
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
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

  static const _accentColor = Color(0xFF06B6D4);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? _accentColor.withOpacity(0.12)
              : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? _accentColor : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected ? _accentColor : Colors.white30,
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
                      color: Colors.white.withOpacity(0.4),
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
