import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/presentation/widgets/common/user_avatar.dart';

void main() {
  group('UserAvatar Widget Tests', () {
    testWidgets('renders emoji avatar directly in Text', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              avatar: '🐻',
              fallbackText: 'Alice',
            ),
          ),
        ),
      );

      expect(find.text('🐻'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('renders fallback text initial when avatar is empty or null', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              avatar: '',
              fallbackText: 'Bob',
            ),
          ),
        ),
      );

      expect(find.text('B'), findsOneWidget);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              avatar: null,
              fallbackText: 'Charlie',
            ),
          ),
        ),
      );

      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('renders network image without crashing on URL', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: UserAvatar(
              avatar: 'https://example.com/avatar.png',
              fallbackText: 'Dave',
            ),
          ),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
    });
  });
}
