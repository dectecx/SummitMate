import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/shared/link_text.dart';
import 'package:summitmate/shared/open_link.dart';

void main() {
  test('findLinks finds addresses and leaves trailing punctuation out', () {
    final links = findLinks('看 https://rudymap.tw/a?b=1, 還有（http://x.org/y）。');
    expect(links.map((l) => l.url), ['https://rudymap.tw/a?b=1', 'http://x.org/y']);
    expect(findLinks('沒有連結'), isEmpty);
  });

  testWidgets('tapping a link opens it in the browser; a failure is explained', (tester) async {
    final opened = <Uri>[];
    var ok = true;
    await tester.pumpWidget(ProviderScope(
      overrides: [linkOpenerProvider.overrideWithValue((u) async { opened.add(u); return ok; })],
      child: const MaterialApp(home: Scaffold(body: LinkText('集合資訊 https://example.com/go 請看', linkLabel: siteName))),
    ));
    final text = tester.widget<RichText>(find.byType(RichText).last);
    TapGestureRecognizer? tap;
    text.text.visitChildren((s) {
      if (s is TextSpan && s.recognizer is TapGestureRecognizer) tap = s.recognizer as TapGestureRecognizer;
      return true;
    });
    expect(find.textContaining('example.com', findRichText: true), findsOneWidget);
    tap!.onTap!();
    await tester.pump();
    expect(opened.single.toString(), 'https://example.com/go');
    ok = false;
    tap!.onTap!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('無法開啟這個連結'), findsOneWidget);
  });
}
