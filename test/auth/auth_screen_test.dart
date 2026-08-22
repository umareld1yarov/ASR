import 'dart:async';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:asr/features/auth/application/auth_controller.dart';
import 'package:asr/features/auth/presentation/screens/auth_screen.dart';
import 'package:asr/features/premium/application/premium_controller.dart';
import '../helpers/fake_auth_repository.dart';
import '../helpers/test_localization_helper.dart';

class FakeIsProNotifier extends StateNotifier<bool> implements IsProNotifier {
  FakeIsProNotifier([super.state = false]);

  @override
  Future<void> setProStatus(bool value) async {
    state = value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    initTestLocalization();
  });

  group('AuthScreen Widget Tests', () {
    late FakeAuthRepository fakeRepo;
    late ProviderContainer container;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      fakeRepo = FakeAuthRepository();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(fakeRepo),
          isProProvider.overrideWith((ref) => FakeIsProNotifier(false)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
      fakeRepo.dispose();
    });

    Future<void> pumpAuthScreen(WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        createLocalizedTestApp(
          child: UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: AuthScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('экран входа отображает поля email, пароль, кнопку входа, Google и Apple', (tester) async {
      await pumpAuthScreen(tester);

      expect(find.text('auth.login_title'.tr()), findsOneWidget);
      expect(find.text('auth.sign_in_tab'.tr()), findsOneWidget);
      expect(find.text('auth.sign_up_tab'.tr()), findsOneWidget);
      expect(find.text('auth.email_label'.tr()), findsOneWidget);
      expect(find.text('auth.password_label'.tr()), findsOneWidget);
      expect(find.text('auth.sign_in_btn'.tr()), findsOneWidget);
      expect(find.text('auth.google_sign_in'.tr()), findsOneWidget);
      expect(find.text('auth.apple_sign_in'.tr()), findsOneWidget);
      expect(find.text('profile.coming_soon'.tr()), findsOneWidget);

      // В режиме входа поле имени скрыто
      expect(find.text('auth.name_label'.tr()), findsNothing);
    });

    testWidgets('переключение на вкладку регистрации отображает поле имени и кнопку регистрации', (tester) async {
      await pumpAuthScreen(tester);

      // Нажимаем на таб «Регистрация»
      await tester.tap(find.text('auth.sign_up_tab'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('auth.register_title'.tr()), findsOneWidget);
      expect(find.text('auth.name_label'.tr()), findsOneWidget);
      expect(find.text('auth.sign_up_btn'.tr()), findsOneWidget);
      expect(find.text('auth.sign_in_btn'.tr()), findsNothing);

      // Переключаемся обратно на «Вход»
      await tester.tap(find.text('auth.sign_in_tab'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('auth.login_title'.tr()), findsOneWidget);
      expect(find.text('auth.name_label'.tr()), findsNothing);
      expect(find.text('auth.sign_in_btn'.tr()), findsOneWidget);
    });

    testWidgets('изоляция Email-loading: спиннер отображается только в кнопке Email, Google и Apple не крутятся', (tester) async {
      fakeRepo.signInWithEmailCompleter = Completer<AuthResponse>();
      await pumpAuthScreen(tester);

      // Заполняем форму
      await tester.enterText(
        find.widgetWithText(TextFormField, 'auth.email_label'.tr()),
        'user@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'auth.password_label'.tr()),
        'password123',
      );
      await tester.pumpAndSettle();

      // Нажимаем «Войти»
      await tester.tap(find.widgetWithText(ElevatedButton, 'auth.sign_in_btn'.tr()));
      await tester.pump(); // Не settle, чтобы увидеть промежуточное состояние

      // Проверяем, что в ElevatedButton появился CircularProgressIndicator
      final elevatedButton = find.byType(ElevatedButton);
      expect(
        find.descendant(of: elevatedButton, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );

      // Проверяем, что в кнопках Google и Apple (OutlinedButton) индикатора нет
      final outlinedButtons = find.byType(OutlinedButton);
      expect(
        find.descendant(of: outlinedButtons, matching: find.byType(CircularProgressIndicator)),
        findsNothing,
      );

      // Завершаем операцию
      fakeRepo.signInWithEmailCompleter!.complete(
        createTestAuthResponse(
          user: createTestUser(email: 'user@example.com'),
          session: createTestSession(user: createTestUser(email: 'user@example.com')),
        ),
      );
      await tester.pumpAndSettle();
    });

    testWidgets('изоляция Google-loading: спиннер отображается только в Google-кнопке, Email и Apple не крутятся', (tester) async {
      fakeRepo.signInWithGoogleCompleter = Completer<bool>();
      await pumpAuthScreen(tester);

      // Нажимаем кнопку Google
      await tester.tap(find.widgetWithText(OutlinedButton, 'auth.google_sign_in'.tr()));
      await tester.pump(); // Промежуточное состояние

      // В ElevatedButton (Email кнопка) спиннера нет
      final elevatedButton = find.byType(ElevatedButton);
      expect(
        find.descendant(of: elevatedButton, matching: find.byType(CircularProgressIndicator)),
        findsNothing,
      );

      // В OutlinedButton (Google) есть ровно один CircularProgressIndicator
      final outlinedButtons = find.byType(OutlinedButton);
      expect(
        find.descendant(of: outlinedButtons, matching: find.byType(CircularProgressIndicator)),
        findsOneWidget,
      );

      // Завершаем операцию
      fakeRepo.signInWithGoogleCompleter!.complete(true);
      await tester.pumpAndSettle();
    });

    testWidgets('Apple-кнопка отключена и содержит бейдж заглушки Скоро', (tester) async {
      await pumpAuthScreen(tester);

      final appleButtonFinder = find.widgetWithText(OutlinedButton, 'auth.apple_sign_in'.tr());
      expect(appleButtonFinder, findsOneWidget);

      final appleButton = tester.widget<OutlinedButton>(appleButtonFinder);
      expect(appleButton.onPressed, isNull, reason: 'Apple-вход должен быть отключен по умолчанию');
      expect(find.text('profile.coming_soon'.tr()), findsOneWidget);
    });

    testWidgets('валидация формы: пустые поля, невалидный email, короткий пароль', (tester) async {
      await pumpAuthScreen(tester);

      // 1. Нажимаем «Войти» с пустыми полями
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('auth.email_required'.tr()), findsOneWidget);
      expect(find.text('auth.password_required'.tr()), findsOneWidget);

      // 2. Вводим невалидный email (без @)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'auth.email_label'.tr()),
        'invalid-email',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('auth.email_invalid'.tr()), findsOneWidget);

      // 3. Вводим короткий пароль (< 6 символов)
      await tester.enterText(
        find.widgetWithText(TextFormField, 'auth.password_label'.tr()),
        '123',
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.text('auth.password_min_length'.tr()), findsOneWidget);
    });

    testWidgets('отображение SnackBar при ошибке авторизации', (tester) async {
      fakeRepo.signInWithEmailException = const AuthException('Invalid login credentials');
      await pumpAuthScreen(tester);

      await tester.enterText(
        find.widgetWithText(TextFormField, 'auth.email_label'.tr()),
        'valid@test.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'auth.password_label'.tr()),
        'password123',
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsOneWidget);
      expect(find.text('Invalid login credentials'), findsOneWidget);
    });
  });
}
