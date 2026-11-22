// Entry point for `flutter drive` runs of the integration tests (lets a demo leave the app running on the device):
//   flutter drive --driver=test_driver/integration_test.dart --target=integration_test/<file>.dart -d <device> --keep-app-running
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
