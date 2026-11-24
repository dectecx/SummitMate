import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/auth/auth_state.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/core/settings/app_settings.dart';
import 'package:summitmate/core/sync/outbox_writer.dart';
import 'package:summitmate/core/sync/sync_entity.dart';

import '../core/support.dart';
import 'harness.dart';

void main() {
  group('first launch', () {
    testWidgets('shows the welcome page once; "開始使用" enters the app as a guest', (tester) async {
      final app = await AppHarness.start(tester);
      expect(find.text('山友 SummitMate'), findsOneWidget);
      expect(find.text('開始使用'), findsOneWidget);
      expect(find.byType(NavigationBar), findsNothing);

      await tapText(tester, '開始使用');

      expect(find.byType(NavigationBar), findsOneWidget);
      for (final label in ['行程', '地圖', '探索', '我']) {
        expect(find.descendant(of: find.byType(NavigationBar), matching: find.text(label)), findsOneWidget);
      }
      expect(await real(tester, () => app.container.read(settingsStoreProvider).getBool(SettingsStore.welcomeSeen)), isTrue);
      expect(app.container.read(authRepositoryProvider).state, isA<Guest>());
      await app.dispose(tester);
    });

    testWidgets('later launches skip the welcome page', (tester) async {
      final app = await AppHarness.start(tester, welcomeSeen: true);
      expect(find.text('開始使用'), findsNothing);
      expect(find.byType(NavigationBar), findsOneWidget);
      await app.dispose(tester);
    });
  });

  group('sign in', () {
    testWidgets('validates the form before calling the server', (tester) async {
      final app = await AppHarness.start(tester, seed: (api) => api.addAccount('a@x.co', 'Passw0rd1'));
      await tapText(tester, '登入或註冊');

      await tapText(tester, '登入');
      expect(find.text('請輸入 Email'), findsOneWidget);
      expect(find.text('請輸入密碼'), findsOneWidget);

      await enter(tester, 'Email', 'not-an-email');
      await tapText(tester, '登入');
      expect(find.text('Email 格式不正確'), findsOneWidget);
      expect(app.api.loginCalls, 0);
      await app.dispose(tester);
    });

    testWidgets('a wrong password shows a readable message and stays on the page', (tester) async {
      final app = await AppHarness.start(tester, seed: (api) => api.addAccount('a@x.co', 'Passw0rd1'));
      await tapText(tester, '登入或註冊');
      await enter(tester, 'Email', 'a@x.co');
      await enter(tester, '密碼', 'wrong-password1');
      await tapText(tester, '登入');

      expect(find.text('帳號或密碼錯誤'), findsOneWidget);
      expect(find.text('登入'), findsWidgets);
      expect(app.container.read(authRepositoryProvider).state, isA<Guest>());
      await app.dispose(tester);
    });

    testWidgets('signing in from the welcome page lands in the app and the account tab shows the person', (tester) async {
      final app = await AppHarness.start(tester, seed: (api) => api.addAccount('a@x.co', 'Passw0rd1', name: 'Alice'));
      await tapText(tester, '登入或註冊');
      await enter(tester, 'Email', ' A@X.co ');
      await enter(tester, '密碼', 'Passw0rd1');
      await tapText(tester, '登入');

      expect(find.byType(NavigationBar), findsOneWidget);
      expect(await real(tester, () => app.container.read(settingsStoreProvider).getBool(SettingsStore.welcomeSeen)), isTrue);
      await tapText(tester, '我');
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('a@x.co'), findsOneWidget);
      expect(find.text('已同步'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('an unverified account is sent to the verification page', (tester) async {
      final app = await AppHarness.start(tester, seed: (api) => api.addAccount('new@x.co', 'Passw0rd1', verified: false));
      await tapText(tester, '登入或註冊');
      await enter(tester, 'Email', 'new@x.co');
      await enter(tester, '密碼', 'Passw0rd1');
      await tapText(tester, '登入');

      expect(find.text('驗證 Email'), findsOneWidget);
      expect(find.textContaining('new@x.co'), findsOneWidget);
      await app.dispose(tester);
    });
  });

  group('register', () {
    testWidgets('register, verify with the emailed code, and end up signed in', (tester) async {
      final app = await AppHarness.start(tester);
      await tapText(tester, '登入或註冊');
      await tapText(tester, '還沒有帳號？註冊');

      await enter(tester, '暱稱', 'Newbie');
      await enter(tester, 'Email', 'new@x.co');
      await enter(tester, '密碼', 'short');
      await tapText(tester, '註冊並寄送驗證碼');
      expect(find.text('密碼至少需要 8 個字元'), findsOneWidget);

      await enter(tester, '密碼', 'Passw0rd1');
      await tapText(tester, '註冊並寄送驗證碼');
      expect(find.text('驗證 Email'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '000000');
      await tapText(tester, '驗證並登入');
      expect(find.text('驗證碼不正確'), findsOneWidget);

      await tester.enterText(find.byType(TextField), app.api.lastCode);
      await tapText(tester, '驗證並登入');
      expect(find.byType(NavigationBar), findsOneWidget);
      expect(app.container.read(authRepositoryProvider).state, isA<SignedIn>());
      await app.dispose(tester);
    });

    testWidgets('an email that is already registered offers to sign in instead', (tester) async {
      final app = await AppHarness.start(tester, seed: (api) => api.addAccount('a@x.co', 'Passw0rd1'));
      await tapText(tester, '登入或註冊');
      await tapText(tester, '還沒有帳號？註冊');
      await enter(tester, '暱稱', 'Dup');
      await enter(tester, 'Email', 'a@x.co');
      await enter(tester, '密碼', 'Passw0rd1');
      await tapText(tester, '註冊並寄送驗證碼');

      expect(find.text('這個 Email 已經註冊過了，請直接登入'), findsOneWidget);
      expect(find.text('改為登入'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('the resend button waits 60 seconds', (tester) async {
      final app = await AppHarness.start(tester);
      await tapText(tester, '登入或註冊');
      await tapText(tester, '還沒有帳號？註冊');
      await enter(tester, '暱稱', 'N');
      await enter(tester, 'Email', 'n@x.co');
      await enter(tester, '密碼', 'Passw0rd1');
      await tapText(tester, '註冊並寄送驗證碼');

      expect(find.textContaining('秒後可重新寄送'), findsOneWidget);
      await tester.pump(const Duration(seconds: 61));
      expect(find.text('重新寄送驗證碼'), findsOneWidget);
      await app.dispose(tester);
    });
  });

  group('account tab', () {
    testWidgets('a guest sees what guest mode means and can open the sign-in page', (tester) async {
      tester.view.physicalSize = const Size(800, 2400); // tall: the grouped list is long
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await AppHarness.start(tester, welcomeSeen: true);
      await tapText(tester, '我');
      expect(find.text('訪客模式'), findsOneWidget);
      expect(find.text('資料只存在這支手機'), findsOneWidget);
      expect(find.text('登出'), findsNothing);

      await tapText(tester, '登入或註冊');
      expect(find.text('Email'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('signing out is refused softly while changes are waiting to upload', (tester) async {
    tester.view.physicalSize = const Size(800, 2400); // tall: the help entry pushes the list down
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
      final app = await AppHarness.start(tester, welcomeSeen: true, seed: (api) => api.addAccount('a@x.co', 'Passw0rd1'));
      await real(tester, () => app.container.read(authRepositoryProvider).login(email: 'a@x.co', password: 'Passw0rd1'));
      await real(tester, () => localCreate(app.db, OutboxWriter(app.db), tripsEntity, tripRow('t1')));
      await tapText(tester, '我');
      await settle(tester);
      expect(find.text('1 筆變更等待上傳'), findsOneWidget);

      await tapText(tester, '登出');
      await tapText(tester, '登出'); // the dialog's confirm button
      expect(find.text('還有 1 筆變更沒有上傳'), findsOneWidget);

      await tapText(tester, '取消');
      expect(app.container.read(authRepositoryProvider).state, isA<SignedIn>());

      await tapText(tester, '登出');
      await tapText(tester, '登出');
      await tapText(tester, '仍要登出');
      expect(app.container.read(authRepositoryProvider).state, isA<Guest>());
      expect(find.text('訪客模式'), findsOneWidget);
      await app.dispose(tester);
    });

    testWidgets('an expired session shows a banner that keeps the same email', (tester) async {
      final app = await AppHarness.start(tester, welcomeSeen: true, seed: (api) => api.addAccount('a@x.co', 'Passw0rd1'));
      await real(tester, () => app.container.read(authRepositoryProvider).login(email: 'a@x.co', password: 'Passw0rd1'));
      app.container.read(authRepositoryProvider).markNeedsReauth();
      await tapText(tester, '我');

      expect(find.text('登入已過期'), findsWidgets);
      await tapText(tester, '重新登入');
      final email = tester.widget<TextFormField>(find.widgetWithText(TextFormField, 'Email'));
      expect(email.controller!.text, 'a@x.co');
      expect(find.text('註冊'), findsNothing, reason: 'switching accounts is not offered here');
      await app.dispose(tester);
    });

    testWidgets('the theme choice is stored', (tester) async {
      tester.view.physicalSize = const Size(800, 2400); // tall: the grouped list is long
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final app = await AppHarness.start(tester, welcomeSeen: true);
      await tapText(tester, '我');
      await tapText(tester, '深色');
      expect(await real(tester, () => app.container.read(settingsStoreProvider).get(SettingsStore.themeMode)), 'dark');
      await app.dispose(tester);
    });
  });
}
