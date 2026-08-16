import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/timer/presentation/screens/focus_screen.dart';

/// Корневой экран с нижней навигацией между Фокусом, Лентой, Статистикой
/// и Профилем.
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({super.key});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _selectedIndex = 0;

  static const _screens = [
    FocusScreen(),
    FeedScreen(),
    StatsScreen(),
    CommunityScreen(),
    ProfileScreen(),
  ];

  static const _accentColor = Color(0xFF06B6D4);
  static const _navBackgroundColor = Color.fromARGB(255, 26, 25, 25);

  @override
  Widget build(BuildContext context) {
    // Регистрируем зависимость от локали для мгновенного обновления подписей вкладок
    final _ = context.locale;

    final items = [
      (Icons.radio_button_unchecked, Icons.radio_button_checked, 'nav.focus'.tr()),
      (Icons.list_alt_outlined, Icons.list_alt, 'nav.feed'.tr()),
      (Icons.bar_chart_outlined, Icons.bar_chart, 'nav.stats'.tr()),
      (Icons.people_outline, Icons.people, 'nav.community'.tr()),
      (Icons.person_outline, Icons.person, 'nav.profile'.tr()),
    ];

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: ColoredBox(
        color: _navBackgroundColor,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 58,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: _NavItem(
                      outlineIcon: items[i].$1,
                      filledIcon: items[i].$2,
                      label: items[i].$3,
                      isSelected: i == _selectedIndex,
                      accentColor: _accentColor,
                      onTap: () => setState(() => _selectedIndex = i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.outlineIcon,
    required this.filledIcon,
    required this.label,
    required this.isSelected,
    required this.accentColor,
    required this.onTap,
  });

  final IconData outlineIcon;
  final IconData filledIcon;
  final String label;
  final bool isSelected;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? accentColor : Colors.white38;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(isSelected ? filledIcon : outlineIcon, size: 24, color: color),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
