import 'package:flutter/material.dart';

import '../widgets/category_picker_sheet.dart';
import '../widgets/category_stats_grid.dart';
import '../widgets/timer_display.dart';

/// Экран 1 — Фокус. Главный экран приложения.
/// Аналог #screen-main из index.html (PWA).
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 125, 125, 137), // светлее сверху
            Color.fromARGB(255, 26, 25, 25), // чистый чёрный к низу
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // ── Шапка с датой ──
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _todayLabel(),
                  style: const TextStyle(fontSize: 13, color: Colors.white38),
                ),
              ),

              const SizedBox(height: 8),

              // ── Таймер и текущая активность ──
              const TimerDisplay(),

              const SizedBox(height: 28),

              // ── Мини-статы по категориям ──
              const CategoryStatsGrid(),

              const Spacer(),

              // ── Кнопка смены активности ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => CategoryPickerSheet.show(context),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Сменить активность'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _todayLabel() {
    const days = ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс'];
    const months = [
      'янв',
      'фев',
      'мар',
      'апр',
      'май',
      'июн',
      'июл',
      'авг',
      'сен',
      'окт',
      'ноя',
      'дек',
    ];
    final now = DateTime.now();
    return '${days[now.weekday - 1]}, ${now.day} ${months[now.month - 1]}';
  }
}
