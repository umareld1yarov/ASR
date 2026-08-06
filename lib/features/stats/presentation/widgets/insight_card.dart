import 'package:flutter/material.dart';

import '../../application/insight_engine.dart';

/// Карточка одного инсайта — цвет обводки/фона зависит от тона.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight});

  final Insight insight;

  Color _toneColor(InsightTone tone) {
    switch (tone) {
      case InsightTone.positive:
        return const Color(0xFF22C55E);
      case InsightTone.warning:
        return const Color(0xFFEF4444);
      case InsightTone.neutral:
        return Colors.white54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(insight.tone);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(insight.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              insight.text,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
