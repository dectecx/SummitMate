import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/models/user_profile.dart';
import 'package:summitmate/data/repositories/interfaces/i_trip_repository.dart';
import 'package:summitmate/presentation/widgets/member/search_add_member_dialog.dart';

class MockTripRepository extends Mock implements ITripRepository {}

void main() {
  group('SearchAddMemberDialog Widget Test', () {
    late MockTripRepository mockTripRepo;

    setUp(() {
      mockTripRepo = MockTripRepository();
    });

    testWidgets('Should display initial search UI', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAddMemberDialog(
              tripId: 't1',
              tripRepository: mockTripRepo,
              currentUserId: 'u1',
              existingMemberIds: const ['u1'],
              onMemberAdded: () {},
            ),
          ),
        ),
      );

      expect(find.text('新增成員'), findsOneWidget);
      expect(find.text('請輸入 Email'), findsOneWidget);
      expect(find.text('搜尋'), findsOneWidget);
    });

    testWidgets('Should search user and display result', (WidgetTester tester) async {
      final user = UserProfile(id: 'u2', email: 'test@example.com', displayName: 'Test User', avatar: '');

      when(() => mockTripRepo.searchUserByEmail(any())).thenAnswer((_) async => Success(user));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SearchAddMemberDialog(
              tripId: 't1',
              tripRepository: mockTripRepo,
              currentUserId: 'u1',
              existingMemberIds: const ['u1'],
              onMemberAdded: () {},
            ),
          ),
        ),
      );

      // Enter email
      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      // Tap Search
      await tester.tap(find.widgetWithText(FilledButton, '搜尋'));
      await tester.pump();
      await tester.pump(); // For Future completion

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('加入'), findsOneWidget);
    });
  });
}
