import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/presentation/screens/auth/register_screen.dart';
import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/auth/auth_state.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';
import 'package:summitmate/data/models/settings.dart';

class MockAuthCubit extends Mock implements AuthCubit {}

class MockSettingsCubit extends Mock implements SettingsCubit {}

void main() {
  late MockAuthCubit mockAuthCubit;
  late MockSettingsCubit mockSettingsCubit;

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockSettingsCubit = MockSettingsCubit();

    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.stream).thenAnswer((_) => Stream.fromIterable([AuthInitial()]));

    // Setup SettingsCubit state
    final settings = Settings.withDefaults();
    when(() => mockSettingsCubit.state).thenReturn(SettingsLoaded(settings: settings, hasSeenOnboarding: true));
    when(
      () => mockSettingsCubit.stream,
    ).thenAnswer((_) => Stream.fromIterable([SettingsLoaded(settings: settings, hasSeenOnboarding: true)]));
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: mockAuthCubit),
          BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
        ],
        child: const RegisterScreen(),
      ),
    );
  }

  group('RegisterScreen Validation', () {
    testWidgets('should show error for invalid email', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final emailField = find.byType(TextFormField).first;
      await tester.enterText(emailField, 'invalid-email');

      final registerButton = find.text('註冊');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('請輸入有效的 Email 格式'), findsOneWidget);
    });

    testWidgets('should show error for weak password', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.byType(TextFormField).at(1); // 0: Display Name, 1: Email, 2: Password
      // Wait, let's check the order in RegisterScreen.
      // Order: Display Name, Email, Password, Confirm Password.
      // So Password is index 2.

      await tester.enterText(passwordField, 'short');

      final registerButton = find.text('註冊');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('密碼至少需要 8 個字元'), findsOneWidget);
    });

    testWidgets('should show password strength indicator', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.byType(TextFormField).at(2);

      // Enter weak password
      await tester.enterText(passwordField, '12345678');
      await tester.pump();
      expect(find.text('弱'), findsOneWidget);

      // Enter moderate password
      await tester.enterText(passwordField, 'pass1234');
      await tester.pump();
      expect(find.text('中'), findsOneWidget);

      // Enter strong password
      await tester.enterText(passwordField, 'P@ssw0rd12345');
      await tester.pump();
      expect(find.text('強'), findsOneWidget);
    });

    testWidgets('should show error when passwords do not match', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      final passwordField = find.byType(TextFormField).at(2);
      final confirmField = find.byType(TextFormField).at(3);

      await tester.enterText(passwordField, 'Password123');
      await tester.enterText(confirmField, 'Different123');

      final registerButton = find.text('註冊');
      await tester.tap(registerButton);
      await tester.pump();

      expect(find.text('密碼不一致'), findsOneWidget);
    });
  });
}
