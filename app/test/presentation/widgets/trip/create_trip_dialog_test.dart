import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/trip.dart';
import 'package:summitmate/presentation/cubits/trip/trip_cubit.dart';
import 'package:summitmate/presentation/cubits/trip/trip_state.dart';
import 'package:summitmate/presentation/widgets/trip/create_trip_dialog.dart';

class MockTripCubit extends MockCubit<TripState> implements TripCubit {}

class FakeTrip extends Fake implements Trip {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeTrip());
  });

  group('CreateTripDialog Widget Test', () {
    late MockTripCubit mockTripCubit;

    setUp(() {
      mockTripCubit = MockTripCubit();
    });

    testWidgets('Should display correct title for creating new trip', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TripCubit>.value(value: mockTripCubit, child: const CreateTripDialog()),
        ),
      );

      expect(find.text('新增行程'), findsOneWidget);
    });

    testWidgets('Should display correct title and initial values for editing trip', (WidgetTester tester) async {
      final trip = Trip(
        id: '1',
        userId: 'u1',
        name: 'Existing Trip',
        startDate: DateTime(2023, 11, 1),
        endDate: DateTime(2023, 11, 3),
        createdAt: DateTime.now(),
        createdBy: 'u1',
        updatedAt: DateTime.now(),
        updatedBy: 'u1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TripCubit>.value(
            value: mockTripCubit,
            child: CreateTripDialog(tripToEdit: trip),
          ),
        ),
      );

      expect(find.text('編輯行程'), findsOneWidget);
      expect(find.text('Existing Trip'), findsOneWidget);
    });

    testWidgets('Should invoke addTrip on Cubit when form is valid and submitted', (WidgetTester tester) async {
      // Stub addTrip with strictly matched named arguments (optional ones not passed by UI are omitted)
      when(
        () => mockTripCubit.addTrip(
          name: any(named: 'name'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TripCubit>.value(value: mockTripCubit, child: const CreateTripDialog()),
        ),
      );

      await tester.enterText(find.widgetWithText(TextFormField, '行程名稱'), 'New Adventure');
      await tester.pump();

      await tester.tap(find.widgetWithText(FilledButton, '新增'));
      await tester.pump();

      verify(
        () => mockTripCubit.addTrip(
          name: any(named: 'name'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
        ),
      ).called(1);
    });

    testWidgets('Should show validation error if name is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<TripCubit>.value(value: mockTripCubit, child: const CreateTripDialog()),
        ),
      );

      await tester.tap(find.widgetWithText(FilledButton, '新增'));
      await tester.pump();

      expect(find.text('請輸入行程名稱'), findsOneWidget);

      // Verification
      verifyNever(
        () => mockTripCubit.addTrip(
          name: any(named: 'name'),
          startDate: any(named: 'startDate'),
          endDate: any(named: 'endDate'),
          description: any(named: 'description'),
        ),
      );
    });
  });
}
