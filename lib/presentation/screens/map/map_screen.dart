import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';

import '../../../services/log_service.dart';
import '../../providers/map_provider.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> with TickerProviderStateMixin {
  // 嘉明湖國家步道大致中心點
  static const LatLng _initialCenter = LatLng(23.29, 121.03);
  final MapController _mapController = MapController();
  // 追蹤目前縮放層級
  double _currentZoom = 13.0;

  @override
  void initState() {
    super.initState();
    LogService.info('initState: Requesting store initialization...', source: 'MapScreen');
    // 確保 Store 已初始化
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MapProvider>().initStore();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          return Stack(
            children: [
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _initialCenter,
                  initialZoom: 13.0,
                  maxZoom: 20.0, // 設定最大縮放層級為 20 (雖然圖資可能模糊，但方便閱讀)
                  interactionOptions: const InteractionOptions(flags: InteractiveFlag.all),
                  onPositionChanged: (pos, hasGesture) {
                    setState(() => _currentZoom = pos.zoom);
                  },
                ),
                children: [
                  // 1. 底圖層 (OpenStreetMap + FMTC Cache)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: provider.packageName,
                    maxNativeZoom: 19, // 支援過度縮放到 20 (使用 level 19 tiles 放大)
                    // FMTC v10: 使用 FMTCTileProvider 攔截並快取
                    // 若 Store 尚未準備好，暫時使用預設 (NetworkTileProvider) 避免 Crash
                    tileProvider: provider.isStoreReady
                        ? FMTCTileProvider(stores: {provider.store.storeName: BrowseStoreStrategy.readUpdateCreate})
                        : null,
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

                  // 4. 目前位置 (Blue Dot & Heading)
                  if (provider.currentLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: LatLng(provider.currentLocation!.latitude, provider.currentLocation!.longitude),
                          width: 40,
                          height: 40,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // 準心/方向箭頭 (如果有羅盤數據)
                              if (provider.currentHeading != null)
                                Transform.rotate(
                                  angle: (provider.currentHeading! * (3.14159 / 180) * -1),
                                  child: const Icon(Icons.navigation, color: Colors.blueAccent, size: 40),
                                ),
                              // 藍色圓點
                              Container(
                                width: 16,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),

              // Loading Indicator
              if (provider.isLoading) const Center(child: CircularProgressIndicator()),

              // 資訊顯示 (左上角)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    'Zoom: ${_currentZoom.toStringAsFixed(1)}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),

              // 功能按鈕區 (右上角: 匯入 & 下載)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FloatingActionButton(
                      heroTag: 'load_gpx',
                      mini: true,
                      onPressed: () async {
                        try {
                          await provider.loadGpxFile();
                          if (provider.trackPoints.isNotEmpty) {
                            _mapController.move(provider.trackPoints.first, 15.0);
                          }
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('讀取 GPX 失敗: $e')));
                          }
                        }
                      },
                      tooltip: '匯入 GPX',
                      child: const Icon(Icons.file_upload_outlined),
                    ),
                    const SizedBox(height: 12),
                    FloatingActionButton(
                      heroTag: 'download_map',
                      mini: true,
                      backgroundColor: Colors.orange,
                      onPressed: () => _showDownloadDialog(context, _mapController, provider),
                      tooltip: '下載離線地圖',
                      child: const Icon(Icons.download_for_offline),
                    ),
                    const SizedBox(height: 12),
                    // 定位按鈕
                    FloatingActionButton(
                      heroTag: 'my_location',
                      mini: true,
                      onPressed: () {
                        if (provider.currentLocation != null) {
                          _animatedMapMove(
                            LatLng(provider.currentLocation!.latitude, provider.currentLocation!.longitude),
                            15.0,
                          );
                        } else {
                          // 尚未取得定位，嘗試觸發初始化
                          provider.initLocation();
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('定位中...')));
                        }
                      },
                      tooltip: '我的位置',
                      child: const Icon(Icons.my_location),
                    ),
                  ],
                ),
              ),

              // 縮放按鈕區 (右中)
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
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
                      const SizedBox(height: 16),
                      FloatingActionButton(
                        heroTag: 'zoom_out',
                        mini: true,
                        onPressed: () {
                          _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                        },
                        child: const Icon(Icons.remove),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // 顯示下載確認對話框
  void _showDownloadDialog(BuildContext context, MapController mapController, MapProvider provider) {
    final bounds = mapController.camera.visibleBounds;
    final zoom = mapController.camera.zoom;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('下載此區域地圖?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目前縮放層級: ${zoom.toStringAsFixed(1)}'),
            const Text('將下載縮放層級 12 ~ 16 的圖資 (適合登山使用)。'),
            const SizedBox(height: 8),
            const Text('注意: 若範圍過大可能會佔用大量空間與流量。', style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _startDownload(context, provider, bounds);
            },
            child: const Text('開始下載'),
          ),
        ],
      ),
    );
  }

  // 執行下載並顯示進度
  void _startDownload(BuildContext context, MapProvider provider, LatLngBounds bounds) {
    LogService.info('Starting download for bounds: $bounds', source: 'MapScreen');
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            double progress = 0.0;

            // 啟動下載 (不 await，因為要在對話框內顯示進度)
            provider
                .downloadRegion(
                  bounds: bounds,
                  minZoom: 12,
                  maxZoom: 16,
                  onProgress: (p) {
                    // 安全地更新 UI
                    if (context.mounted) {
                      setState(() => progress = p);
                    }
                  },
                )
                .then((_) {
                  if (context.mounted) {
                    Navigator.pop(context); // 關閉進度框
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('地圖下載完成!')));
                  }
                })
                .catchError((e) {
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('下載失敗: $e')));
                  }
                });

            return AlertDialog(
              title: const Text('下載中...'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LinearProgressIndicator(value: progress),
                  const SizedBox(height: 8),
                  Text('${(progress * 100).toStringAsFixed(1)}%'),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// 平滑移動地圖視角
  void _animatedMapMove(LatLng destLocation, double destZoom) {
    // 建立 AnimationController (500ms 動畫)
    final controller = AnimationController(duration: const Duration(milliseconds: 500), vsync: this);

    // 起始位置與縮放
    final latTween = Tween<double>(begin: _mapController.camera.center.latitude, end: destLocation.latitude);
    final lngTween = Tween<double>(begin: _mapController.camera.center.longitude, end: destLocation.longitude);
    final zoomTween = Tween<double>(begin: _mapController.camera.zoom, end: destZoom);

    // 動畫執行過程
    final animation = CurvedAnimation(parent: controller, curve: Curves.fastOutSlowIn);

    controller.addListener(() {
      _mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    // 動畫結束後釋放 Controller
    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        controller.dispose();
      } else if (status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
}
