import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/presentation/cubits/auth/auth_cubit.dart';
import 'package:summitmate/presentation/cubits/auth/auth_state.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';
import 'package:summitmate/presentation/widgets/settings_dialog.dart';
import 'package:summitmate/domain/interfaces/i_auth_service.dart';
import 'package:summitmate/data/models/settings.dart';

// Mocks
class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockSettingsCubit extends MockCubit<SettingsState> implements SettingsCubit {}

// Fake States
// AuthState is sealed, so we use a concrete subclass for callback or just AuthInitial
class FakeSettingsState extends Fake implements SettingsState {}

void main() {
  late MockAuthCubit mockAuthCubit;
  late MockSettingsCubit mockSettingsCubit;

  setUpAll(() {
    registerFallbackValue(AuthInitial()); // Use concrete class
    registerFallbackValue(FakeSettingsState());
  });

  setUp(() {
    mockAuthCubit = MockAuthCubit();
    mockSettingsCubit = MockSettingsCubit();
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: mockAuthCubit),
            BlocProvider<SettingsCubit>.value(value: mockSettingsCubit),
          ],
          child: const SettingsDialog(),
        ),
      ),
    );
  }

  group('SettingsDialog Integration', () {
    testWidgets('renders User ID when authenticated', (tester) async {
      // Arrange
      const userId = 'user_123';
      const userName = 'Test User';
      const avatar = '🐻';

      whenListen(
        mockAuthCubit,
        Stream.fromIterable([
          const AuthAuthenticated(
            userId: userId,
            userName: userName,
            email: 'test@example.com',
            avatar: avatar,
            isGuest: false,
          ),
        ]),
        initialState: const AuthAuthenticated(
          userId: userId,
          userName: userName,
          email: 'test@example.com',
          avatar: avatar,
          isGuest: false,
        ),
      );

      whenListen(
        mockSettingsCubit,
        Stream.fromIterable([
          SettingsLoaded(
            settings: Settings(username: userName, avatar: avatar),
            hasSeenOnboarding: true,
          ),
        ]),
        initialState: SettingsLoaded(
          settings: Settings(username: userName, avatar: avatar),
          hasSeenOnboarding: true,
        ),
      );

      // Act
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Assert
      expect(find.text('ID: $userId'), findsOneWidget);
      expect(find.text(userName), findsOneWidget); // Text field content logic?
      // Verify TextField content involves finding TextField and checking controller or content.
      // Usually finding text works if it's visible.
      // But TextField content is special.
      expect(find.widgetWithText(TextField, userName), findsOneWidget);
    });

    testWidgets('calls updateProfile on save', (tester) async {
      // Arrange
      const userId = 'user_123';
      const initialName = 'Old Name';

      final authState = const AuthAuthenticated(
        userId: userId,
        userName: initialName,
        email: 'test@example.com',
        avatar: '🐻',
        isGuest: false,
      );

      when(() => mockAuthCubit.state).thenReturn(authState);
      when(
        () => mockSettingsCubit.state,
      ).thenReturn(SettingsLoaded(settings: Settings(username: initialName), hasSeenOnboarding: true));

      when(
        () => mockAuthCubit.updateProfile(
          displayName: any(named: 'displayName'),
          avatar: any(named: 'avatar'),
        ),
      ).thenAnswer((_) async => AuthResult.success()); // Mock AuthResult

      // Need to verify settingsCubit.updateProfile is called.
      // SettingsCubit.updateProfile returns void/future.
      when(() => mockSettingsCubit.updateProfile(any(), any())).thenAnswer((_) async => {});

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      // Act
      // Find TextField and enter new name
      final textField = find.byType(TextField);
      await tester.enterText(textField, 'New Name');
      await tester.pump();

      // Find Save button and tap
      final saveBtn = find.widgetWithText(FilledButton, '儲存設定');
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle(); // Wait for async operations

      // Assert
      verify(() => mockAuthCubit.updateProfile(displayName: 'New Name', avatar: '🐻')).called(1);
      verify(() => mockSettingsCubit.updateProfile('New Name', '🐻')).called(1);
    });
  });
}
