import 'package:flutter/material.dart';

import '../../features/feed/presentation/screens/feed_screen.dart';
import '../../features/timer/presentation/screens/focus_screen.dart';

/// Корневой экран с нижней навигацией между Фокусом и Лентой.
/// Аналог <nav class="nav"> из index.html (PWA).
class AppBottomNav extends StatefulWidget {
  const AppBottomNav({super.key});

  @override
  State<AppBottomNav> createState() => _AppBottomNavState();
}

class _AppBottomNavState extends State<AppBottomNav> {
  int _selectedIndex = 0;

  // IndexedStack сохраняет состояние обоих экранов при переключении —
  // таймер на Фокусе не будет пересоздаваться при уходе на Ленту и обратно.
  static const _screens = [FocusScreen(), FeedScreen()];

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
        ],
      ),
    );
  }
}
