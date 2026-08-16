import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';

class ActivityStatusPill extends StatelessWidget {
  const ActivityStatusPill({
    super.key,
    this.activityName,
    this.categoryKey,
    this.startedAt,
    this.embedded = false,
  });

  final String? activityName;
  final String? categoryKey;
  final int? startedAt;
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    final category = categoryKey != null
        ? ActivityCategory.fromStorageKey(categoryKey!)
        : ActivityCategory.base;

    final content = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: category.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 7),
              Text(
                category.label.toUpperCase(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.7,
                ),
              ),
            ],
          ),
          if (activityName != null &&
              activityName!.trim().isNotEmpty &&
              activityName!.trim().toLowerCase() !=
                  category.label.trim().toLowerCase()) ...[
            const SizedBox(height: 7),
            Text(
              activityName!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.22,
              ),
            ),
          ],
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: category.color),
              const SizedBox(width: 6),
              _ElapsedTime(startedAt: startedAt, color: Colors.white70),
            ],
          ),
        ],
      );

    if (embedded) return content;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      decoration: BoxDecoration(
        color: category.color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: category.color.withValues(alpha: 0.38)),
      ),
      child: content,
    );
  }
}

class _ElapsedTime extends StatefulWidget {
  const _ElapsedTime({required this.startedAt, required this.color});

  final int? startedAt;
  final Color color;

  @override
  State<_ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<_ElapsedTime> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final startedAt = widget.startedAt;
    if (startedAt == null) {
      return Text(
        'community.now_status'.tr(),
        style: TextStyle(color: widget.color, fontSize: 14, fontWeight: FontWeight.w500),
      );
    }

    final seconds = ((DateTime.now().millisecondsSinceEpoch - startedAt) / 1000)
        .floor()
        .clamp(0, 1 << 31) as int;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    final remainingSeconds = seconds % 60;
    final formatted =
        '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';

    return Text(
      'community.ongoing_duration'.tr(args: [formatted]),
      style: TextStyle(color: widget.color, fontSize: 14, fontWeight: FontWeight.w500),
    );
  }
}
