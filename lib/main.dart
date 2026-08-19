import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/services/purchases_service.dart';
import 'core/services/supabase_service.dart';
import 'data/isar_service.dart';
import 'features/onboarding/application/onboarding_provider.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'shared/widgets/app_bottom_nav.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();
  await IsarService.open();

  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {
    // .env файл не найден или пуст
  }

  await SupabaseService.initialize();
  await PurchasesService.initialize();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Color(0xFF0A0A0A),
      systemNavigationBarIconBrightness: Brightness.light,
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [
        Locale('ru'),
        Locale('ky'),
        Locale('en'),
        Locale('ar'),
        Locale('tr'),
        Locale('de'),
        Locale('es'),
        Locale('pt'),
      ],
      path: 'assets/translations',
      fallbackLocale: const Locale('ru'),
      child: const ProviderScope(child: AsrApp()),
    ),
  );
}

class AsrApp extends ConsumerWidget {
  const AsrApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingAsync = ref.watch(isOnboardingCompletedProvider);

    return MaterialApp(
      title: 'ASR',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: ThemeData.dark(
        useMaterial3: true,
      ).copyWith(scaffoldBackgroundColor: const Color(0xFF0A0A0A)),
      home: onboardingAsync.when(
        data: (completed) =>
            completed ? const AppBottomNav() : const OnboardingScreen(),
        loading: () => const Scaffold(
          backgroundColor: Color(0xFF0A0A0A),
          body: Center(
            child: CircularProgressIndicator(color: Color(0xFF06B6D4)),
          ),
        ),
        error: (e, s) => const AppBottomNav(),
      ),
    );
  }
}
