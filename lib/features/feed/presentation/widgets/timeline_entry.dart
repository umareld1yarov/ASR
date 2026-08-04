import 'package:flutter/material.dart';

import '../../../../core/constants/activity_category.dart';

/// Обёртка одной записи в таймлайне — точка цвета категории слева +
/// непрерывная вертикальная линия, соединяющая записи между собой.
class TimelineEntry extends StatelessWidget {
  const TimelineEntry({
    super.key,
    required this.category,
    required this.isFirst,
    required this.isLast,
    required this.child,
  });

  final ActivityCategory category;
  final bool isFirst;
  final bool isLast;
  final Widget child;

  static const _lineColor = Color(0x26FFFFFF); // белый, ~15% непрозрачности
  static const _lineWidth = 2.0;
  static const _dotSize = 14.0;
  static const _railWidth = 18.0;
  static const _dotTop = 22.0; // высота от верха до центра точки
  static const _gapAfter = 14.0; // отступ до следующей записи

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _railWidth,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                if (!isFirst)
                  Positioned(
                    top: 0,
                    child: Container(
                      width: _lineWidth,
                      height: _dotTop,
                      color: _lineColor,
                    ),
                  ),
                if (!isLast)
                  Positioned(
                    top: _dotTop,
                    bottom: 0,
                    child: Container(width: _lineWidth, color: _lineColor),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                child,
                if (!isLast) const SizedBox(height: _gapAfter),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
