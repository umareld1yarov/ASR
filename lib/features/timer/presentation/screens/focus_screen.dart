import 'package:asr/features/timer/presentation/widgets/switch_activity_button.dart';
import 'package:asr/shared/widgets/app_background.dart';
import 'package:flutter/material.dart';

import '../widgets/category_stats_grid.dart';
import '../widgets/timer_display.dart';

/// Экран 1 — Фокус. Главный экран приложения.
/// Аналог #screen-main из index.html (PWA).
class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBackground(
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
              const SwitchActivityButton(),
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
