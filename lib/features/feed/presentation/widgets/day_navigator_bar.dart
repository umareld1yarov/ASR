import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/feed_provider.dart';

class DayNavigatorBar extends ConsumerWidget {
  const DayNavigatorBar({super.key});

  String _label(BuildContext context, DateTime date) {
    final localeStr = context.locale.toString();
    final dayName = DateFormat('E', localeStr).format(date);
    final monthName = DateFormat('MMM', localeStr).format(date);
    final today = DateTime.now();
    final isToday =
        date.year == today.year &&
        date.month == today.month &&
        date.day == today.day;
    final base = '$dayName, ${date.day} $monthName';
    return isToday ? '$base (${"feed.today".tr().toLowerCase()})' : base;
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
          _label(context, selectedDate),
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
