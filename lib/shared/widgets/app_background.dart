import 'package:flutter/material.dart';

/// Общий фон приложения — градиент от чуть более светлого верха
/// к чистому чёрному низу. Используется на всех основных экранах,
/// чтобы визуально они ощущались одним приложением.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color.fromARGB(255, 125, 125, 137),
            Color.fromARGB(255, 26, 25, 25),
          ],
          stops: [0.0, 0.4],
        ),
      ),
      child: child,
    );
  }
}
