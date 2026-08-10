import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../timer/application/timer_provider.dart';
import '../../application/stats_provider.dart';

/// Донат-диаграмма долей категорий. Сам подмешивает live-время текущей
/// активности через liveCategorySecondsProvider — тикает только этот
/// виджет, а не весь экран.
class DonutChart extends ConsumerWidget {
  const DonutChart({super.key, required this.stats, this.size = 220});

  final Map<String, int> stats;
  final double size;

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч $mм';
    return '$mм';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentActivityProvider).valueOrNull;
    final liveSeconds = current != null
        ? ref.watch(liveCategorySecondsProvider(current.categoryKey))
        : 0;

    final displayStats = Map<String, int>.from(stats);
    if (current != null && liveSeconds > 0) {
      displayStats[current.categoryKey] =
          (displayStats[current.categoryKey] ?? 0) + liveSeconds;
    }

    final total = displayStats.values.fold(0, (a, b) => a + b);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _DonutPainter(stats: displayStats, total: total),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatDuration(total),
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'всего за период',
                style: TextStyle(fontSize: 11, color: Colors.white54),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.stats, required this.total});

  final Map<String, int> stats;
  final int total;

  static const _strokeWidth = 24.0;
  static const _gapRadians = 0.035;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    if (total == 0) {
      final emptyPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, 0, math.pi * 2 - 0.01, false, emptyPaint);
      return;
    }

    final entries = stats.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    double startAngle = -math.pi / 2;

    for (final entry in entries) {
      final category = ActivityCategory.fromStorageKey(entry.key);
      final sweep = (entry.value / total) * (2 * math.pi) - _gapRadians;
      if (sweep <= 0) continue;

      final paint = Paint()
        ..color = category.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = _strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep + _gapRadians;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.stats != stats || oldDelegate.total != total;
  }
}
