import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the floating developer panel is built in. On in debug builds; for a release or profile build pass
/// `--dart-define=DEV_TOOLS=true` to get it too. When false the panel is removed from the app at build time.
const devToolsEnabled = bool.fromEnvironment('DEV_TOOLS', defaultValue: kDebugMode);

/// What the app reads to decide whether to show the panel; tests turn it off so the button never covers their taps.
final devToolsVisibleProvider = Provider<bool>((ref) => devToolsEnabled);

/// The test account the panel signs in with (it is created on the first use).
const devAccountEmail = 'demo@test.co';
const devAccountPassword = 'Passw0rd1';
const devAccountName = '測試山友';

/// The verification code the development server accepts instead of a mailed one.
const devVerificationCode = '000000';
