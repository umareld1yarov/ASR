import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/activity_category.dart';
import '../../application/timer_provider.dart';

/// Карточка текущей активности в стеклянном (glassmorphism) стиле:
/// категория (цветная) → название → большой таймер (тоже цветной).
class TimerDisplay extends ConsumerWidget {
  const TimerDisplay({super.key});

  static const double _aspectRatio = 442 / 252;

  String _formatHMS(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(currentActivityProvider);
    final elapsedAsync = ref.watch(elapsedSecondsProvider);

    return AspectRatio(
      aspectRatio: _aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          final radius = width * 0.115;
          final hPad = width * 0.085;
          final vPad = height * 0.10;

          return currentAsync.when(
            data: (current) {
              final category = current != null
                  ? ActivityCategory.fromStorageKey(current.categoryKey)
                  : null;
              final accentColor = Colors.white;
              final elapsed = elapsedAsync.maybeWhen(
                data: (s) => s,
                orElse: () => 0,
              );

              return _GlassCard(
                width: width,
                height: height,
                radius: radius,
                hPad: hPad,
                vPad: vPad,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: category?.color ?? Colors.white38,
                              ),
                            ),
                            const SizedBox(width: 6),
                            _AutoFitText(
                              category?.label.toUpperCase() ?? 'НЕТ АКТИВНОСТИ',
                              style: TextStyle(
                                color: category?.color ?? Colors.white38,
                                fontSize: width * 0.045,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          current?.name ?? 'Нажми «Сменить активность»',
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontSize: width * 0.058,
                            fontWeight: FontWeight.w600,
                            height: 1.1,
                            letterSpacing: 0.1,
                          ),
                        ),
                      ],
                    ),
                    _AutoFitText(
                      _formatHMS(elapsed),
                      style: TextStyle(
                        color: accentColor,
                        fontSize: width * 0.186,
                        fontWeight: FontWeight.w700,
                        height: 0.95,
                        letterSpacing: -1.0,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => _GlassCard(
              width: width,
              height: height,
              radius: radius,
              hPad: hPad,
              vPad: vPad,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Ошибка: $e'),
          );
        },
      ),
    );
  }
}

/// Стеклянная обёртка карточки — обводка, тень, размытие фона, блик.
class _GlassCard extends StatelessWidget {
  const _GlassCard({
    required this.width,
    required this.height,
    required this.radius,
    required this.hPad,
    required this.vPad,
    required this.child,
  });

  final double width;
  final double height;
  final double radius;
  final double hPad;
  final double vPad;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 25,
            spreadRadius: -5,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius - 1),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF63656E).withValues(alpha: 0.45),
                      const Color(0xFF2A2B30).withValues(alpha: 0.55),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: -height * 0.35,
              left: -width * 0.15,
              width: width * 1.1,
              height: height * 1.2,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Colors.white.withValues(alpha: 0.28),
                      Colors.white.withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  color: Colors.white.withValues(alpha: 0.04),
                  padding: EdgeInsets.symmetric(
                    horizontal: hPad,
                    vertical: vPad,
                  ),
                  child: child,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Автоматически уменьшает шрифт, если текст не помещается по ширине.
class _AutoFitText extends StatelessWidget {
  const _AutoFitText(this.text, {required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(text, maxLines: 1, style: style),
    );
  }
}
