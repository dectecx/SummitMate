import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/presentation/widgets/trip/trip_card.dart';

void main() {
  group('TripCard Widget Test', () {
    final testTrip = Trip(
      id: 't1',
      userId: 'u1',
      name: '嘉明湖三天兩夜',
      startDate: DateTime(2023, 11, 1),
      endDate: DateTime(2023, 11, 3),
      description: '天使的眼淚',
      createdAt: DateTime.now(),
      createdBy: 'u1',
      updatedAt: DateTime.now(),
      updatedBy: 'u1',
    );

    testWidgets('Should display basic trip info correctly', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TripCard(
            trip: testTrip,
            isActive: false,
            roleLabel: '嚮導',
            onTap: () {},
          ),
        ),
      ));

      expect(find.text('嘉明湖三天兩夜'), findsOneWidget);
      expect(find.text('天使的眼淚'), findsOneWidget);
      expect(find.text('嚮導'), findsOneWidget);
      expect(find.text('進行中'), findsNothing);
    });

    testWidgets('Should show "進行中" badge when isActive is true', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TripCard(
            trip: testTrip,
            isActive: true, // Active
            roleLabel: '成員',
            onTap: () {},
          ),
        ),
      ));

      expect(find.text('進行中'), findsOneWidget);
    });

    testWidgets('Should display action buttons and trigger callbacks', (WidgetTester tester) async {
      bool editCalled = false;
      bool deleteCalled = false;
      bool uploadCalled = false;
      bool manageMembersCalled = false;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TripCard(
            trip: testTrip,
            isActive: false,
            roleLabel: 'Member',
            onTap: () {},
            onEdit: () => editCalled = true,
            onDelete: () => deleteCalled = true,
            onUpload: () => uploadCalled = true,
            onManageMembers: () => manageMembersCalled = true,
          ),
        ),
      ));

      expect(find.text('編輯'), findsOneWidget);
      expect(find.text('刪除'), findsOneWidget);
      expect(find.text('同步'), findsOneWidget);
      expect(find.text('成員'), findsOneWidget);

      await tester.tap(find.text('編輯'));
      expect(editCalled, true);

      await tester.tap(find.text('刪除'));
      expect(deleteCalled, true);
      
      await tester.tap(find.text('同步'));
      expect(uploadCalled, true);

      await tester.tap(find.text('成員'));
      expect(manageMembersCalled, true);
    });

    testWidgets('Should hide action buttons if callbacks are null', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: TripCard(
            trip: testTrip,
            isActive: false,
            roleLabel: 'Member',
            onTap: () {},
            onManageMembers: () {},
            // No other callbacks
          ),
        ),
      ));

      expect(find.text('編輯'), findsNothing);
      expect(find.text('刪除'), findsNothing);
      expect(find.text('同步'), findsNothing);
      expect(find.text('成員'), findsOneWidget); // Always required/shown if provided
    });
  });
}
