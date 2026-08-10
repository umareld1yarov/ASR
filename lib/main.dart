import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/isar_service.dart';
import 'shared/widgets/app_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await IsarService.open();

  // Красим системную навигацию (кнопки назад/домой или жестовую полосу)
  // в тот же тёмный цвет, что и фон приложения — иначе на новых версиях
  // Android эта зона рисуется системой отдельно и выглядит как чёрная
  // полоса/чужеродный элемент поверх нашего UI.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const ProviderScope(child: AsrApp()));
}

class AsrApp extends StatelessWidget {
  const AsrApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ASR',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: const Color(0xFF0A0A0A)),
      home: const AppBottomNav(),
    );
  }
}
