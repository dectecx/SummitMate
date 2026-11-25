import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/providers.dart';
import '../core/settings/app_settings.dart';

/// The person's "動畫" switch, on unless they turned it off.
final animationsSettingProvider = StreamProvider<bool>(
  (ref) => ref.watch(settingsStoreProvider).watch(SettingsStore.animations).map((v) => v != 'false'),
);

/// Whether decorative motion should run: the switch is on and the system is not asking to reduce motion.
bool animationsOn(BuildContext context, WidgetRef ref) =>
    (ref.watch(animationsSettingProvider).value ?? true) && !MediaQuery.disableAnimationsOf(context);
