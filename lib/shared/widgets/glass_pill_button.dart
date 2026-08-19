import 'dart:ui';

import 'package:flutter/material.dart';

/// Переиспользуемая стеклянная кнопка-таблетка — тот же материал, что у
/// карточки таймера (градиент + блик + блюр). Используется и для
/// "Сменить активность", и для "Запустить" в пикере категорий.
class GlassPillButton extends StatelessWidget {
  const GlassPillButton({
    super.key,
    required this.onTap,
    required this.child,
    this.height = 58,
    this.subtle = false,
  });

  final VoidCallback onTap;
  final Widget child;
  final double height;
  final bool subtle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height / 2),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            border: Border.all(
              color: Colors.white.withValues(alpha: subtle ? 0.16 : 0.22),
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
            borderRadius: BorderRadius.circular(height / 2 - 1),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(
                            0xFF63656E,
                          ).withValues(alpha: subtle ? 0.24 : 0.45),
                          const Color(
                            0xFF2A2B30,
                          ).withValues(alpha: subtle ? 0.32 : 0.55),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: -20,
                  left: -20,
                  width: 160,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: subtle ? 0.12 : 0.28),
                          Colors.white.withValues(alpha: subtle ? 0.04 : 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                    child: Material(
                      color: Colors.white.withValues(
                        alpha: subtle ? 0.02 : 0.04,
                      ),
                      child: InkWell(
                        onTap: onTap,
                        child: Center(child: child),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
