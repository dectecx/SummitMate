import 'package:flutter/foundation.dart';
import 'dart:async';

import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/map/maplibre/rudy_map_view.dart';
import 'package:summitmate/features/map/maplibre/rudy_providers.dart';
import 'package:summitmate/features/map/rudy/rudy_installer.dart';

/// An installer the test drives by hand; `installed` is what the app believes is on the phone.
class FakeRudyInstaller implements RudyInstaller {
  RudyInstallState _state = const RudyInstallState(RudyInstallPhase.idle);
  final _controller = StreamController<RudyInstallState>.broadcast();
  bool installed = false;
  int starts = 0, cancels = 0, removes = 0;

  @override
  RudyInstallState get state => _state;
  @override
  Stream<RudyInstallState> get states => _controller.stream;

  void emit(RudyInstallState s) {
    _state = s;
    if (s.phase == RudyInstallPhase.done) installed = true;
    _controller.add(s);
  }

  @override
  Future<void> start() async {
    starts++;
    emit(const RudyInstallState(RudyInstallPhase.downloadingMap, progress: 0.1, bytesDone: 30000000, bytesTotal: 325000000));
  }

  @override
  Future<void> cancel() async {
    cancels++;
    emit(const RudyInstallState(RudyInstallPhase.idle));
  }

  @override
  Future<void> remove() async {
    removes++;
    installed = false;
    emit(const RudyInstallState(RudyInstallPhase.idle));
  }
}

/// Stands in for the MapLibre view in widget tests (it needs the real platform view).
class FakeMapHandle implements MapHandle {
  double zoomValue = 8;
  final calls = <String>[];
  void Function(List<dynamic>)? onPeaks;
  @override
  double get zoom => zoomValue;
  final northValue = ValueNotifier<double>(0);
  @override
  ValueListenable<double> get north => northValue;
  @override
  Future<void> resetNorth() async {
    calls.add('north');
    northValue.value = 0;
  }
  @override
  Future<void> moveTo(double lat, double lng, {double? minZoom}) async => calls.add('move');
  @override
  @override
  Future<void> setMe(double? lat, double? lng) async => calls.add('me');
  @override
  Future<void> setRoute(List<({double lat, double lng})> points) async => calls.add('route:${points.length}');
}

const fakeRudyMapKey = Key('fake-rudy-map');

/// Overrides that keep the Rudy providers away from the file system and the platform view.
List<Override> rudyTestOverrides({FakeRudyInstaller? installer, FakeMapHandle? handle}) {
  final fake = installer ?? FakeRudyInstaller();
  var created = false;
  return [
    rudyInstallerProvider.overrideWith((ref) async => fake),
    rudyReadyProvider.overrideWith((ref) async {
      ref.watch(rudyInstallStateProvider);
      return fake.installed;
    }),
    rudyStyleProvider.overrideWith((ref) async => (await ref.watch(rudyReadyProvider.future)) ? '{"version":8,"sources":{},"layers":[]}' : null),
    rudyMapBuilderProvider.overrideWithValue((context, style, mountains, onPeaks, onCreated) {
      final h = handle ?? FakeMapHandle();
      if (!created) {
        created = true; // the real map reports its creation once
        WidgetsBinding.instance.addPostFrameCallback((_) => onCreated(h));
      }
      return GestureDetector(
        key: fakeRudyMapKey,
        behavior: HitTestBehavior.opaque,
        onTap: () => onPeaks(mountains.take(2).toList()),
        child: const SizedBox.expand(),
      );
    }),
  ];
}
