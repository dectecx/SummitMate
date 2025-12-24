import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // 嘉明湖國家步道大致中心點
  static const LatLng _initialCenter = LatLng(23.29, 121.03);
  final MapController _mapController = MapController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 13.0,
                  interactionOptions: InteractionOptions(flags: InteractiveFlag.all),
                ),
                children: [
                  // 1. 底圖層 (OpenStreetMap)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.dectecx.summitmate',
                    // 未來可加入 FMTC 的 TileProvider
                  ),

                  // 2. 軌跡層 (GPX Polyline)
                  if (provider.trackPoints.isNotEmpty)
                    PolylineLayer(
                      polylines: [Polyline(points: provider.trackPoints, color: Colors.blue, strokeWidth: 4.0)],
                    ),

                  // 3. 起終點標記 (可選)
                  if (provider.trackPoints.isNotEmpty)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: provider.trackPoints.first,
                          child: const Icon(Icons.trip_origin, color: Colors.green, size: 32),
                        ),
                        Marker(
                          point: provider.trackPoints.last,
                          child: const Icon(Icons.flag, color: Colors.red, size: 32),
                        ),
                      ],
                    ),
                ],
              ),

              // Loading Indicator
              if (provider.isLoading) const Center(child: CircularProgressIndicator()),

              // 功能按鈕區
              Positioned(
                bottom: 24,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'zoom_in',
                      mini: true,
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                      },
                      child: const Icon(Icons.add),
                    ),
                    const SizedBox(height: 8),
                    FloatingActionButton(
                      heroTag: 'zoom_out',
                      mini: true,
                      onPressed: () {
                        _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                      },
                      child: const Icon(Icons.remove),
                    ),
                    const SizedBox(height: 16),
                    FloatingActionButton.extended(
                      heroTag: 'load_gpx',
                      onPressed: () async {
                        try {
                          await provider.loadGpxFile();
                          // 如果有載入軌跡，自動移動視角到軌跡起點
                          if (provider.trackPoints.isNotEmpty) {
                            _mapController.move(provider.trackPoints.first, 15.0);
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('讀取 GPX 失敗: $e')));
                          }
                        }
                      },
                      label: const Text('匯入 GPX'),
                      icon: const Icon(Icons.map_outlined),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
