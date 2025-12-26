import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:twicon/twicon.dart';

import '../../../services/log_service.dart';
import '../../providers/map_provider.dart';
import 'offline_map_manager_screen.dart';

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
  // 追蹤地圖旋轉角度 (for compass)
  double _currentRotation = 0.0;

  // 下載預覽框 (呈現當前視窗範圍)
  List<LatLng>? _previewBounds;

  // UI 狀態
  bool _isMiniMapExpanded = true; // Mini-map 展開/收合
  bool _isFabExpanded = true; // FAB 按鈕列展開/收合
  bool _isMapReady = false; // 地圖是否已渲染完成

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
                    setState(() {
                      _currentZoom = pos.zoom;
                      _currentRotation = pos.rotation;
                    });
                  },
                  onMapReady: () {
                    setState(() => _isMapReady = true);
                  },
                ),
                children: [
                  // 1. 底圖層 (OpenStreetMap + FMTC Cache)
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: provider.packageName,
                    maxNativeZoom: 19, // 支援過度縮放到 20 (使用 level 19 tiles 放大)
                    // FMTC v10: 使用 FMTCTileProvider 攔截並快取 (僅限非 Web 平台)
                    // Web 使用預設 NetworkTileProvider
                    tileProvider: (!kIsWeb && provider.isStoreReady)
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

                  // 5. 下載區域預覽框 (紅框)
                  if (_previewBounds != null)
                    PolygonLayer(
                      polygons: [
                        Polygon(
                          points: _previewBounds!,
                          color: Colors.red.withValues(alpha: 0.2),
                          borderColor: Colors.red,
                          borderStrokeWidth: 3,
                        ),
                      ],
                    ),
                ],
              ),

              // Loading Indicator
              if (provider.isLoading) const Center(child: CircularProgressIndicator()),

              // Mini-map (左下角，可收合，長條形)
              Positioned(
                bottom: 16,
                left: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 收合/展開按鈕
                    GestureDetector(
                      onTap: () => setState(() => _isMiniMapExpanded = !_isMiniMapExpanded),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isMiniMapExpanded ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white,
                              size: 16,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _isMiniMapExpanded ? '隱藏' : '小地圖',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // 可收合的 Mini-map
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _isMiniMapExpanded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: GestureDetector(
                                onTap: () {
                                  _animatedMapMove(const LatLng(23.5, 121.0), 8.0);
                                },
                                child: Container(
                                  width: 80, // 長條形：寬度較窄
                                  height: 160, // 高度較高 (類似台灣形狀)
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black54, width: 2),
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: const [
                                      BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(2, 2)),
                                    ],
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: IgnorePointer(
                                    child: FlutterMap(
                                      options: const MapOptions(
                                        initialCenter: LatLng(23.5, 121.0),
                                        initialZoom: 6.0,
                                        interactionOptions: InteractionOptions(flags: InteractiveFlag.none),
                                      ),
                                      children: [
                                        TileLayer(
                                          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                          userAgentPackageName: provider.packageName,
                                          tileProvider: (!kIsWeb && provider.isStoreReady)
                                              ? FMTCTileProvider(
                                                  stores: {
                                                    provider.store.storeName: BrowseStoreStrategy.readUpdateCreate,
                                                  },
                                                )
                                              : null,
                                        ),
                                        // 顯示目前視窗範圍的紅框 (只在 map ready 後)
                                        if (_isMapReady)
                                          PolygonLayer(
                                            polygons: [
                                              Polygon(
                                                points: [
                                                  _mapController.camera.visibleBounds.northWest,
                                                  _mapController.camera.visibleBounds.northEast,
                                                  _mapController.camera.visibleBounds.southEast,
                                                  _mapController.camera.visibleBounds.southWest,
                                                ],
                                                color: Colors.red.withValues(alpha: 0.3),
                                                borderColor: Colors.red,
                                                borderStrokeWidth: 2,
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

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

              // 功能按鈕區 (右上角: 可收合)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 16,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 收合/展開按鈕
                    FloatingActionButton(
                      heroTag: 'toggle_fab',
                      mini: true,
                      backgroundColor: Colors.grey.shade700,
                      onPressed: () => setState(() => _isFabExpanded = !_isFabExpanded),
                      tooltip: _isFabExpanded ? '收合選單' : '展開選單',
                      child: Icon(_isFabExpanded ? Icons.expand_less : Icons.expand_more),
                    ),
                    // 可收合的按鈕列表
                    AnimatedSize(
                      duration: const Duration(milliseconds: 200),
                      child: _isFabExpanded
                          ? Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(height: 12),
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
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(SnackBar(content: Text('讀取 GPX 失敗: $e')));
                                      }
                                    }
                                  },
                                  tooltip: '匯入 GPX',
                                  child: const Icon(Icons.file_upload_outlined),
                                ),
                                const SizedBox(height: 12),
                                // 離線地圖功能 (僅限非 Web 平台)
                                if (!kIsWeb) ...[
                                  FloatingActionButton(
                                    heroTag: 'map_manager',
                                    mini: true,
                                    backgroundColor: Colors.blueGrey,
                                    onPressed: () async {
                                      final result = await Navigator.push<LatLngBounds>(
                                        context,
                                        MaterialPageRoute(builder: (_) => const OfflineMapManagerScreen()),
                                      );
                                      if (result != null && mounted) {
                                        setState(() {
                                          _previewBounds = [
                                            result.northWest,
                                            result.northEast,
                                            result.southEast,
                                            result.southWest,
                                          ];
                                        });
                                        final center = LatLng(
                                          (result.north + result.south) / 2,
                                          (result.east + result.west) / 2,
                                        );
                                        _animatedMapMove(center, 10.0);
                                      }
                                    },
                                    tooltip: '離線地圖管理',
                                    child: const Icon(Icons.folder_open),
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
                                ],
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
                                      provider.initLocation();
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(const SnackBar(content: Text('定位中...')));
                                    }
                                  },
                                  tooltip: '我的位置',
                                  child: const Icon(Icons.my_location),
                                ),
                                const SizedBox(height: 12),
                                // 回到台灣全島視角 (使用 Taiwan icon)
                                FloatingActionButton(
                                  heroTag: 'reset_taiwan',
                                  mini: true,
                                  backgroundColor: Colors.teal,
                                  onPressed: () {
                                    _animatedMapMove(const LatLng(23.5, 121.0), 8.0);
                                  },
                                  tooltip: '回到台灣',
                                  child: const Icon(TaiwanIcons.taiwan_main_island, size: 20),
                                ),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // 指北針 (右上角偏左，平滑淡入淡出)
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                right: 80, // FAB 旁邊
                child: AnimatedOpacity(
                  duration: const Duration(milliseconds: 300),
                  opacity: _currentRotation.abs() > 0.5 ? 1.0 : 0.0,
                  child: GestureDetector(
                    onTap: () {
                      // 平滑旋轉回正北
                      _animatedRotateNorth();
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                      ),
                      child: Transform.rotate(
                        angle: _currentRotation * (3.14159 / 180), // 角度轉弧度
                        child: const Icon(Icons.navigation, color: Colors.red, size: 28),
                      ),
                    ),
                  ),
                ),
              ),

              // 預覽紅框取消按鈕 (右下角，只在有預覽時顯示)
              if (_previewBounds != null)
                Positioned(
                  bottom: 150,
                  right: 16,
                  child: FloatingActionButton(
                    heroTag: 'cancel_preview',
                    mini: true,
                    backgroundColor: Colors.red,
                    onPressed: () => setState(() => _previewBounds = null),
                    tooltip: '取消預覽',
                    child: const Icon(Icons.close),
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

    // 設定預覽框 (顯示紅框)
    setState(() {
      _previewBounds = [bounds.northWest, bounds.northEast, bounds.southEast, bounds.southWest];
    });

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('下載此區域地圖?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('目前縮放層級: ${zoom.toStringAsFixed(1)}'),
            const Text('將下載縮放層級 12 ~ 20 的圖資 (最高解析度)。'),
            const SizedBox(height: 8),
            const Text('注意: 若範圍過大可能會佔用大量空間與流量。', style: TextStyle(color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              // 取消時清除紅框
              setState(() => _previewBounds = null);
              Navigator.pop(ctx);
            },
            child: const Text('取消'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _previewBounds = null); // 開始下載後清除紅框 (或者可以保留直到下載開始)
              _startDownload(bounds);
            },
            child: const Text('加入下載'),
          ),
        ],
      ),
    ).then((_) {
      // 確保對話框以任何方式關閉時 (點擊外部)，紅框都會消失
      if (_previewBounds != null && mounted) {
        setState(() => _previewBounds = null);
      }
    });
  }

  // 執行下載 (背景)
  Future<void> _startDownload(LatLngBounds bounds) async {
    // 先取得必要的參照，避免 async gap 後 context 無效
    final provider = Provider.of<MapProvider>(context, listen: false);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    LogService.info('Starting background download for bounds: $bounds', source: 'MapScreen');

    try {
      // 觸發 Provider 下載 (內部會檢查網路)
      await provider.downloadRegion(
        bounds: bounds,
        minZoom: 12,
        maxZoom: 20,
        name: '自訂區域 ${DateTime.now().hour}:${DateTime.now().minute}',
        onProgress: null,
      );

      // 如果 mounted，顯示成功提示
      if (mounted) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: const Text('已加入下載佇列，將在背景下載...'),
            action: SnackBarAction(
              label: '查看進度',
              onPressed: () {
                navigator.push(MaterialPageRoute(builder: (_) => const OfflineMapManagerScreen()));
              },
            ),
          ),
        );
      }
    } catch (e) {
      // 顯示失敗提示 (包含網路錯誤)
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('下載失敗: $e'), backgroundColor: Colors.red));
      }
    }
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

  /// 平滑旋轉地圖至正北
  void _animatedRotateNorth() {
    final controller = AnimationController(duration: const Duration(milliseconds: 300), vsync: this);

    // 計算最短旋轉路徑
    double startRotation = _currentRotation;
    // 正規化至 -180 ~ 180
    while (startRotation > 180) startRotation -= 360;
    while (startRotation < -180) startRotation += 360;

    final rotationTween = Tween<double>(begin: startRotation, end: 0);
    final animation = CurvedAnimation(parent: controller, curve: Curves.easeOutCubic);

    controller.addListener(() {
      final newRotation = rotationTween.evaluate(animation);
      _mapController.rotate(newRotation);
      // 同步更新 _currentRotation 讓指北針圖示即時旋轉
      setState(() => _currentRotation = newRotation);
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed || status == AnimationStatus.dismissed) {
        controller.dispose();
      }
    });

    controller.forward();
  }
}
