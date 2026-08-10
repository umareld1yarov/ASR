import 'package:flutter/material.dart';

/// Общий фон приложения — градиент от чуть более светлого верха
/// к чистому чёрному низу. SizedBox.expand гарантирует, что фон всегда
/// занимает весь экран целиком, даже если содержимого внутри мало
/// (например, короткий SingleChildScrollView) — иначе фон "сжимался" бы
/// по размеру контента и снизу оставался пустой чёрный Scaffold.
class AppBackground extends StatelessWidget {
  const AppBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Container(
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
      ),
    );
  }
}
