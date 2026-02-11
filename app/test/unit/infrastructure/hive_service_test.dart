import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:summitmate/infrastructure/tools/hive_service.dart';

// Mocks
class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

// mocktail Mock class automatically implements all methods as stubs
class MockPathProviderPlatform extends Mock with MockPlatformInterfaceMixin implements PathProviderPlatform {}

void main() {
  late HiveService hiveService;
  late MockFlutterSecureStorage mockSecureStorage;
  late MockPathProviderPlatform mockPathProvider;
  const keyStorageKey = 'hive_encryption_key';

  setUpAll(() {
    mockPathProvider = MockPathProviderPlatform();
    PathProviderPlatform.instance = mockPathProvider;

    // Stub path provider method used by Hive.initFlutter
    when(() => mockPathProvider.getApplicationDocumentsPath()).thenAnswer((_) async => '.');
  });

  setUp(() async {
    mockSecureStorage = MockFlutterSecureStorage();

    // Stub default behavior for setUp initialization
    when(() => mockSecureStorage.read(key: any(named: 'key'))).thenAnswer((_) async => null);
    when(
      () => mockSecureStorage.write(
        key: any(named: 'key'),
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async => {});

    // Inject mock via constructor
    hiveService = HiveService(secureStorage: mockSecureStorage);
    await hiveService.init();
    // Reset init state if exposed? No method to reset _isInitialized via public API.
    // Workaround: Call close() to reset _isInitialized to false.
    await hiveService.close();

    // Clear interactions recorded during setUp
    reset(mockSecureStorage);
  });

  tearDown(() async {
    await hiveService.close(); // Resets _isInitialized
  });

  group('HiveService Initialization & Keys', () {
    test('init() should generate new key if none exists', () async {
      // Arrange
      when(() => mockSecureStorage.read(key: keyStorageKey)).thenAnswer((_) async => null);
      when(
        () => mockSecureStorage.write(
          key: keyStorageKey,
          value: any(named: 'value'),
        ),
      ).thenAnswer((_) async => {});

      // Act
      await hiveService.init();

      // Assert
      verify(() => mockSecureStorage.read(key: keyStorageKey)).called(1);
      verify(
        () => mockSecureStorage.write(
          key: keyStorageKey,
          value: any(named: 'value'),
        ),
      ).called(1);
      expect(hiveService.isInitialized, true);
    });

    test('init() should load existing key if present', () async {
      // Arrange
      // Create a valid 32-byte key
      final key = Hive.generateSecureKey();
      final keyString = base64Url.encode(key);

      when(() => mockSecureStorage.read(key: keyStorageKey)).thenAnswer((_) async => keyString);

      // Act
      await hiveService.init();

      // Assert
      verify(() => mockSecureStorage.read(key: keyStorageKey)).called(1);
      verifyNever(
        () => mockSecureStorage.write(
          key: keyStorageKey,
          value: any(named: 'value'),
        ),
      );
      expect(hiveService.isInitialized, true);
    });
  });

  // Note: Testing 'openBox' with encryption is hard because it calls real Hive.openBox.
  // Real Hive.openBox requires real file I/O and encryption logic.
  // Since we initialized Hive in '.', it might try to create files.
  // Ideally we should use 'hive_test', but we don't have it added.
  // We can trust Hive library works and only verify our Service orchestration (key generation) which we did above.
}
