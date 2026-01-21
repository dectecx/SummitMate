import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/presentation/widgets/error_dialog.dart';

void main() {
  group('ErrorDialog Widget Test', () {
    testWidgets('Should display title and message correctly', (WidgetTester tester) async {
      // Arrange
      const testTitle = 'Authentication Error';
      const testMessage = 'Please login again.';

      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ErrorDialog(title: testTitle, message: testMessage),
          ),
        ),
      );

      // Assert
      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testMessage), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('Should display "Close" button when no callbacks are provided', (WidgetTester tester) async {
      // Act
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: ErrorDialog(message: 'Error')),
        ),
      );

      // Assert
      expect(find.text('關閉'), findsOneWidget);
      expect(find.text('取消'), findsNothing);
      expect(find.text('重試'), findsNothing);
    });

    testWidgets('Should call onRetry when retry button is pressed', (WidgetTester tester) async {
      // Arrange
      bool isRetryCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDialog(message: 'Error', onRetry: () => isRetryCalled = true, retryText: 'My Retry'),
          ),
        ),
      );

      // Assert
      expect(find.text('My Retry'), findsOneWidget);

      // Tap retry
      await tester.tap(find.text('My Retry'));
      await tester
          .pumpAndSettle(); // Wait for navigation pop if any (though in this test environment we might need to mock navigator or just check callback)

      // Note: In real usage, ErrorDialog pops context.
      // Inside the test wrapper, popping might be tricky if not pushed.
      // However, we just want to verify callback is called.
      // The ErrorDialog code does `Navigator.of(context).pop();` then `onRetry!()`.
      // If there is no route to pop, it might throw exception in test if not handled?
      // Actually standard MaterialApp has a root navigator. 'pop' will just pop the dialog/widget.
      // Since we put ErrorDialog directly in body (not via showDialog), pop might behave differently.
      // Let's wrapping it in a Builder and showDialog to simulate real usage more closely?
      // Or just ignore the pop effect as long as callback runs?
      // Actually, since it calls pop(), we should ensure there is something to pop.
      // But simpler: just assert the bool is true.

      expect(isRetryCalled, true);
    });

    testWidgets('Should call onDismiss when cancel button is pressed', (WidgetTester tester) async {
      // Arrange
      bool isDismissCalled = false;

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDialog(message: 'Error', onDismiss: () => isDismissCalled = true),
          ),
        ),
      );

      // Assert
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('關閉'), findsNothing);

      // Tap cancel
      await tester.tap(find.text('取消'));
      await tester.pumpAndSettle();

      expect(isDismissCalled, true);
    });
  });
}
