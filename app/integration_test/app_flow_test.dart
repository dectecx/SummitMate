// Runs the real app on a simulator or device against a running backend:
//
//   flutter test integration_test/app_flow_test.dart -d <device> \
//     --dart-define=E2E_API=http://localhost:8080/api/v1 \
//     --dart-define=E2E_EMAIL=<verified account email> --dart-define=E2E_PASSWORD=<its password>
//
// The account must already exist and be verified. The app itself uses an in-memory database and a
// fake keychain, so each run starts as a fresh install.
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/auth/token_store.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/main.dart';

const _api = String.fromEnvironment('E2E_API');
const _email = String.fromEnvironment('E2E_EMAIL');
const _password = String.fromEnvironment('E2E_PASSWORD');

/// Pumps until [finder] matches, so the test follows the real network and database instead of fixed delays.
Future<void> pumpUntil(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 20)}) async {
  final end = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(end)) {
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }
  final texts = find.byType(Text).evaluate().map((e) => (e.widget as Text).data).whereType<String>().toList();
  throw TestFailure('Timed out waiting for $finder. On screen: $texts');
}

Future<void> tapAndSettle(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await tester.pumpAndSettle(const Duration(milliseconds: 300), EnginePhase.sendSemanticsUpdate, const Duration(seconds: 10));
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('guest plans a trip, signs in, and the trip syncs', (tester) async {
    expect(_api.isNotEmpty && _email.isNotEmpty && _password.isNotEmpty, isTrue, reason: 'pass E2E_API, E2E_EMAIL and E2E_PASSWORD');
    await tester.pumpWidget(await buildApp(database: AppDatabase(NativeDatabase.memory()), tokens: MemoryTokenStore(), apiBaseUrl: _api));
    await tester.pumpAndSettle();

    // First launch: welcome page, continue as a guest.
    expect(find.text('開始使用'), findsOneWidget);
    await tapAndSettle(tester, find.text('開始使用'));

    // Plan a trip offline.
    await tapAndSettle(tester, find.text('建立第一個行程'));
    await tester.enterText(find.widgetWithText(TextFormField, '行程名稱'), '整合測試行程');
    await tapAndSettle(tester, find.text('建立'));
    await tapAndSettle(tester, find.text('新增節點'));
    await tester.enterText(find.widgetWithText(TextFormField, '名稱'), '向陽山屋');
    await tapAndSettle(tester, find.text('新增'));
    expect(find.text('向陽山屋'), findsOneWidget);
    await tester.tap(find.byTooltip('返回'));
    await tester.pumpAndSettle();
    expect(find.text('整合測試行程'), findsOneWidget);

    // Sign in from the account tab: the guest data is adopted and uploaded.
    await tapAndSettle(tester, find.text('我'));
    expect(find.text('訪客模式'), findsOneWidget);
    await tapAndSettle(tester, find.text('登入或註冊').last);
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), _email);
    await tester.enterText(find.widgetWithText(TextFormField, '密碼'), _password);
    await tapAndSettle(tester, find.widgetWithText(FilledButton, '登入'));
    await pumpUntil(tester, find.text(_email));

    // The sync coordinator uploads in the background; the status settles on "已同步".
    await pumpUntil(tester, find.text('已同步'));

    // Sign out: nothing is waiting to upload, so it goes through and the device is a guest again.
    await tapAndSettle(tester, find.text('登出'));
    await tapAndSettle(tester, find.widgetWithText(FilledButton, '登出'));
    await pumpUntil(tester, find.text('訪客模式'));
    await tapAndSettle(tester, find.text('行程'));
    expect(find.text('還沒有行程'), findsOneWidget, reason: 'the account data was removed from the device');
  });
}
