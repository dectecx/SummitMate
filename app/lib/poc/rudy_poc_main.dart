// PoC ONLY (not part of the app): renders the Rudy Map PMTiles with MapLibre from local files.
// Run: flutter run -t lib/poc/rudy_poc_main.dart --dart-define=RUDY_STYLE=/abs/path/poc_style.json
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:maplibre_gl/maplibre_gl.dart';

const _stylePath = String.fromEnvironment('RUDY_STYLE');

void main() => runApp(const MaterialApp(home: RudyPoc()));

class RudyPoc extends StatefulWidget {
  const RudyPoc({super.key});

  @override
  State<RudyPoc> createState() => _RudyPocState();
}

class _RudyPocState extends State<RudyPoc> {
  MapLibreMapController? _c;
  String _status = 'loading';
  late final String _style = File(_stylePath).readAsStringSync();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          MapLibreMap(
            styleString: _style,
            initialCameraPosition: const CameraPosition(target: LatLng(23.47, 120.96), zoom: 12),
            onMapCreated: (c) => _c = c,
            onStyleLoadedCallback: () => setState(() => _status = 'style loaded'),
            onMapIdle: () => setState(() => _status = 'idle'),
            compassEnabled: true,
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Container(color: Colors.black54, padding: const EdgeInsets.all(6), child: Text(_status, style: const TextStyle(color: Colors.white))),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(heroTag: 'in', onPressed: () => _c?.animateCamera(CameraUpdate.zoomIn()), child: const Icon(Icons.add)),
                  const SizedBox(height: 8),
                  FloatingActionButton.small(heroTag: 'out', onPressed: () => _c?.animateCamera(CameraUpdate.zoomOut()), child: const Icon(Icons.remove)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
