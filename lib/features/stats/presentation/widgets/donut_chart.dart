import 'dart:math' as math;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../../timer/application/timer_provider.dart';
import '../../application/stats_provider.dart';

/// Интерактивная Донат-Диаграмма.
class DonutChart extends ConsumerStatefulWidget {
  const DonutChart({super.key, required this.stats, this.size = 220});

  final Map<String, int> stats;
  final double size;

  @override
  ConsumerState<DonutChart> createState() => _DonutChartState();
}

class _DonutChartState extends ConsumerState<DonutChart> {
  int _displayMode = 0; // 0: total time, 1: top category %, 2: sessions

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '$hч $mм';
    return '$mм';
  }

  void _cycleMode() {
    setState(() {
      _displayMode = (_displayMode + 1) % 3;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentActivityProvider).valueOrNull;
    final liveSeconds = current != null
        ? ref.watch(liveCategorySecondsProvider(current.categoryKey))
        : 0;

    final displayStats = Map<String, int>.from(widget.stats);
    if (current != null && liveSeconds > 0) {
      displayStats[current.categoryKey] =
          (displayStats[current.categoryKey] ?? 0) + liveSeconds;
    }

    final totalSeconds = displayStats.values.fold(0, (a, b) => a + b);
    final sessionSummary = ref.watch(periodSessionSummaryProvider).valueOrNull;

    MapEntry<String, int>? topEntry;
    if (totalSeconds > 0) {
      final valid = displayStats.entries.where((e) => e.value > 0).toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      if (valid.isNotEmpty) {
        topEntry = valid.first;
      }
    }

    return GestureDetector(
      onTap: _cycleMode,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size),
              painter: _DonutPainter(stats: displayStats, total: totalSeconds),
            ),
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                transitionBuilder: (child, anim) {
                  return FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: anim, child: child),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_displayMode),
                  child: _buildCenterContent(
                    totalSeconds: totalSeconds,
                    topEntry: topEntry,
                    totalSessions: sessionSummary?.totalSessions ?? 0,
                    avgSeconds: sessionSummary?.averageSeconds ?? 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterContent({
    required int totalSeconds,
    required MapEntry<String, int>? topEntry,
    required int totalSessions,
    required int avgSeconds,
  }) {
    switch (_displayMode) {
      case 1:
        if (topEntry != null && totalSeconds > 0) {
          final topCat = ActivityCategory.fromStorageKey(topEntry.key);
          final percent = ((topEntry.value / totalSeconds) * 100).round();
          return Column(
            key: const ValueKey(1),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: topCat.color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${topCat.emoji} ${topCat.label}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                _formatDuration(topEntry.value),
                style: const TextStyle(fontSize: 10.5, color: Colors.white54),
              ),
            ],
          );
        }
        continue defaultCase;

      case 2:
        if (totalSessions > 0) {
          return Column(
            key: const ValueKey(2),
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$totalSessions',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF06B6D4),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'stats.total_sessions'.tr(),
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              Text(
                '${"stats.avg_session".tr()} ${_formatDuration(avgSeconds)}',
                style: const TextStyle(fontSize: 10.5, color: Colors.white54),
              ),
            ],
          );
        }
        continue defaultCase;

      defaultCase:
      case 0:
      default:
        return Column(
          key: const ValueKey(0),
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _formatDuration(totalSeconds),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'stats.total_focus'.tr(),
              style: const TextStyle(fontSize: 11, color: Colors.white54),
            ),
          ],
        );
    }
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.stats, required this.total});

  final Map<String, int> stats;
  final int total;

  static const _strokeWidth = 22.0;
  static const _gapRadians = 0.04;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      _strokeWidth / 2,
      _strokeWidth / 2,
      size.width - _strokeWidth,
      size.height - _strokeWidth,
    );

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    canvas.drawArc(rect, 0, math.pi * 2, false, trackPaint);

    if (total == 0) return;

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
