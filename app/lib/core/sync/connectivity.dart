import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';

/// Whether any network interface is up. Only a hint: an interface can be up with no route to the
/// server, and the sync engine's own failures remain the source of truth.
bool isOnline(List<ConnectivityResult> results) => results.any((r) => r != ConnectivityResult.none);

/// Emits whether the device appears online: the current value first, then every change.
Stream<bool> watchOnline([Connectivity? connectivity]) async* {
  final c = connectivity ?? Connectivity();
  try {
    yield isOnline(await c.checkConnectivity());
  } catch (_) {
    // The platform could not tell; assume online and let the change events correct it.
    yield true;
  }
  yield* c.onConnectivityChanged.map(isOnline).distinct();
}

/// Turns app lifecycle changes into a stream of "came back to the foreground" events.
class AppResumedObserver with WidgetsBindingObserver {
  AppResumedObserver({WidgetsBinding? binding}) : _binding = binding ?? WidgetsBinding.instance {
    _binding.addObserver(this);
  }

  final WidgetsBinding _binding;
  final _controller = StreamController<void>.broadcast();

  Stream<void> get resumed => _controller.stream;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.add(null);
  }

  void dispose() {
    _binding.removeObserver(this);
    _controller.close();
  }
}
