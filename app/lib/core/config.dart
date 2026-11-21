/// Build-time configuration. Pass values with `--dart-define`, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1` (Android emulator).
abstract final class AppConfig {
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080/api/v1');
}
