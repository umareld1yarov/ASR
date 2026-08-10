import 'package:flutter/material.dart';

import '../../features/community/presentation/screens/community_screen.dart';
import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/timer/presentation/screens/focus_screen.dart';

/// Корневой экран с нижней навигацией между Фокусом, Лентой, Статистикой
/// и Профилем. Кастомная панель (не Material NavigationBar) в духе Telegram:
/// иконка + подпись, один акцентный цвет для выбранной вкладки, без "таблетки".
/// Фон панели совпадает с нижним цветом градиента AppBackground — панель
/// выглядит продолжением экрана, а не отдельным чёрным блоком.
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

  // Тот же цвет, в который упирается градиент AppBackground внизу —
  // см. app_background.dart. Держим значения синхронными.
  static const _navBackgroundColor = Color.fromARGB(255, 26, 25, 25);

  static const _items = [
    (Icons.radio_button_unchecked, Icons.radio_button_checked, 'Фокус'),
    (Icons.list_alt_outlined, Icons.list_alt, 'Лента'),
    (Icons.bar_chart_outlined, Icons.bar_chart, 'Статистика'),
    (Icons.people_outline, Icons.people, 'Сообщества'),
    (Icons.person_outline, Icons.person, 'Профиль'),
  ];

  @override
  Widget build(BuildContext context) {
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
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      outlineIcon: _items[i].$1,
                      filledIcon: _items[i].$2,
                      label: _items[i].$3,
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
