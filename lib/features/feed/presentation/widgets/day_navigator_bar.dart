import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/feed_provider.dart';

/// Панель навигации ← дата → над лентой.
/// Аналог .calendar-nav из index.html (PWA).
class DayNavigatorBar extends ConsumerWidget {
  const DayNavigatorBar({super.key});

  String _label(DateTime date) {
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
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final base =
        '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]}';
    return isToday ? '$base (сегодня)' : base;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = ref.watch(selectedDateProvider);
    final earliest = ref.watch(earliestDateProvider).valueOrNull;
    final controller = ref.read(feedControllerProvider);

    final today = DateTime.now();
    final isAtToday =
        selectedDate.year == today.year &&
        selectedDate.month == today.month &&
        selectedDate.day == today.day;

    final isAtEarliest =
        earliest != null &&
        selectedDate.year == earliest.year &&
        selectedDate.month == earliest.month &&
        selectedDate.day == earliest.day;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: isAtEarliest ? null : controller.goToPreviousDay,
        ),
        Text(
          _label(selectedDate),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isAtToday ? null : controller.goToNextDay,
        ),
      ],
    );
  }
}
