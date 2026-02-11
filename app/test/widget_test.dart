// SummitMate Widget Tests
// 注意：完整的 Widget 測試需要 Mock 依賴注入
// 此處僅提供基礎架構測試範例

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Basic Widget Tests', () {
    testWidgets('MaterialApp can be created', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          title: 'SummitMate Test',
          theme: ThemeData.dark(),
          home: const Scaffold(body: Center(child: Text('SummitMate'))),
        ),
      );

      expect(find.text('SummitMate'), findsOneWidget);
    });

    testWidgets('BottomNavigationBar renders correctly', (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: const Center(child: Text('Content')),
                bottomNavigationBar: BottomNavigationBar(
                  currentIndex: selectedIndex,
                  onTap: (index) => setState(() => selectedIndex = index),
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.schedule), label: '行程'),
                    BottomNavigationBarItem(icon: Icon(Icons.forum), label: '協作'),
                    BottomNavigationBarItem(icon: Icon(Icons.build), label: '工具'),
                  ],
                ),
              );
            },
          ),
        ),
      );

      // 驗證三個 Tab 存在
      expect(find.text('行程'), findsOneWidget);
      expect(find.text('協作'), findsOneWidget);
      expect(find.text('工具'), findsOneWidget);

      // 測試 Tab 切換
      await tester.tap(find.text('協作'));
      await tester.pumpAndSettle();
      // Tab 應該可以正常點擊
    });

    testWidgets('Onboarding TextField renders', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('歡迎使用 SummitMate'),
                  const SizedBox(height: 16),
                  const TextField(decoration: InputDecoration(hintText: '你的暱稱')),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: () {}, child: const Text('開始使用')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('歡迎使用 SummitMate'), findsOneWidget);
      expect(find.text('開始使用'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
