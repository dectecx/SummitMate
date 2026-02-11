import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/presentation/widgets/zoomable_image.dart';

class TestAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    final Uint8List transparentImage = Uint8List.fromList([
      0x89,
      0x50,
      0x4E,
      0x47,
      0x0D,
      0x0A,
      0x1A,
      0x0A,
      0x00,
      0x00,
      0x00,
      0x0D,
      0x49,
      0x48,
      0x44,
      0x52,
      0x00,
      0x00,
      0x00,
      0x01,
      0x00,
      0x00,
      0x00,
      0x01,
      0x08,
      0x06,
      0x00,
      0x00,
      0x00,
      0x1F,
      0x15,
      0xC4,
      0x89,
      0x00,
      0x00,
      0x00,
      0x0A,
      0x49,
      0x44,
      0x41,
      0x54,
      0x78,
      0x9C,
      0x63,
      0x60,
      0x00,
      0x00,
      0x00,
      0x02,
      0x00,
      0x01,
      0xE5,
      0x27,
      0xDE,
      0xFC,
      0x00,
      0x00,
      0x00,
      0x00,
      0x49,
      0x45,
      0x4E,
      0x44,
      0xAE,
      0x42,
      0x60,
      0x82,
    ]);
    return ByteData.view(transparentImage.buffer);
  }
}

void main() {
  group('ZoomableImage Widget Tests', () {
    testWidgets('renders fallback when asset not found', (WidgetTester tester) async {
      const errorKey = Key('error-widget');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ZoomableImage(
              assetPath: 'assets/images/non_existent.png',
              errorWidget: const SizedBox(key: errorKey, height: 100, width: 100),
            ),
          ),
        ),
      );

      // 讓 Image 嘗試載入 (這會失敗，因為即使是 Mock Bundle 也可能無法解析為圖片格式)
      // 但我們預期它失敗並顯示 errorWidget
      await tester.pumpAndSettle();
      expect(find.byKey(errorKey), findsOneWidget);
    });

    testWidgets('shows zoom hint icon by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: const MaterialApp(
            home: Scaffold(body: ZoomableImage(assetPath: 'assets/images/test.png')),
          ),
        ),
      );

      expect(find.byIcon(Icons.zoom_in), findsOneWidget);
    });

    testWidgets('hides zoom hint icon when showZoomHint is false', (WidgetTester tester) async {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: const MaterialApp(
            home: Scaffold(body: ZoomableImage(assetPath: 'assets/images/test.png', showZoomHint: false)),
          ),
        ),
      );

      expect(find.byIcon(Icons.zoom_in), findsNothing);
    });

    testWidgets('opens ImageViewerDialog on tap', skip: true, (WidgetTester tester) async {
      await tester.pumpWidget(
        DefaultAssetBundle(
          bundle: TestAssetBundle(),
          child: const MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 300,
                height: 300,
                child: ZoomableImage(assetPath: 'assets/images/test.png', title: 'Test Image'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ZoomableImage));
      await tester.pumpAndSettle();

      expect(find.byType(ImageViewerDialog), findsOneWidget);
      expect(find.text('Test Image'), findsOneWidget);
    });
  });
}
