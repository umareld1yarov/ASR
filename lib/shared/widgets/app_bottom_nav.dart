import 'package:flutter/material.dart';

import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/stats/presentation/screens/stats_screen.dart';
import '../../features/timer/presentation/screens/focus_screen.dart';

/// Корневой экран с нижней навигацией между Фокусом, Лентой и Статистикой.
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
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.radio_button_unchecked),
            selectedIcon: Icon(Icons.radio_button_checked),
            label: 'Фокус',
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'Лента',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart),
            label: 'Статистика',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Профиль',
          ),
        ],
      ),
    );
  }
}
