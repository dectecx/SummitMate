import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../providers/map_provider.dart';

class OfflineMapManagerScreen extends StatefulWidget {
  const OfflineMapManagerScreen({super.key});

  @override
  State<OfflineMapManagerScreen> createState() => _OfflineMapManagerScreenState();
}

class _OfflineMapManagerScreenState extends State<OfflineMapManagerScreen> {
  int _tileCount = 0;
  double _sizeMb = 0.0;
  bool _isLoadingStats = true;

  // 預定義推薦區域 (約 10km x 10km)
  // 經緯度約 0.1 度 ~ 11km
  final List<({String name, LatLngBounds bounds})> _presets = [
    (name: '玉山主峰 (Mt. Jade)', bounds: LatLngBounds(const LatLng(23.51, 120.91), const LatLng(23.43, 120.99))),
    (name: '雪山主東 (Snow Mtn)', bounds: LatLngBounds(const LatLng(24.42, 121.19), const LatLng(24.34, 121.27))),
    (name: '合歡群峰 (Hehuan Mtn)', bounds: LatLngBounds(const LatLng(24.18, 121.23), const LatLng(24.10, 121.31))),
    (name: '嘉明湖 (Jiaming Lake)', bounds: LatLngBounds(const LatLng(23.33, 120.98), const LatLng(23.25, 121.06))),
    (name: '北大武山 (Beidawu)', bounds: LatLngBounds(const LatLng(22.67, 120.71), const LatLng(22.59, 120.79))),
  ];

  @override
  void initState() {
    super.initState();
    _refreshStats();
  }

  Future<void> _refreshStats() async {
    setState(() => _isLoadingStats = true);
    final provider = context.read<MapProvider>();
    final stats = await provider.getStoreStats();
    if (mounted) {
      setState(() {
        _tileCount = stats.tileCount;
        _sizeMb = stats.sizeMb;
        _isLoadingStats = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('離線地圖管理'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refreshStats, tooltip: '重新整理')],
      ),
      body: Consumer<MapProvider>(
        builder: (context, provider, child) {
          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              // Web 平台警告
              if (kIsWeb)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Web 版本不支援離線地圖功能。\n請使用 Android/iOS App 以獲得完整離線體驗。',
                          style: TextStyle(color: Colors.black87),
                        ),
                      ),
                    ],
                  ),
                ),
              // 1. 儲存空間統計卡片
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('儲存空間使用量', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      if (_isLoadingStats)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem(Icons.map, '$_tileCount', '圖磚數量 (Tiles)'),
                            _buildStatItem(Icons.storage, '${_sizeMb.toStringAsFixed(1)} MB', '佔用空間'),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. 下載佇列
              if (provider.downloadQueue.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text('下載任務佇列', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                ...provider.downloadQueue.map(
                  (task) => Card(
                    color: task.status == TaskStatus.downloading ? Colors.blue.shade50 : null,
                    child: ListTile(
                      title: Text(task.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          if (task.status == TaskStatus.pending)
                            const Text('等待下載中...', style: TextStyle(color: Colors.orange))
                          else if (task.status == TaskStatus.downloading) ...[
                            Row(
                              children: [
                                Expanded(child: LinearProgressIndicator(value: task.progress)),
                                const SizedBox(width: 8),
                                Text('${(task.progress * 100).toStringAsFixed(1)}%'),
                              ],
                            ),
                            Text(
                              'Tiles: ${task.successfulTiles} / Fail: ${task.failedTiles}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ] else if (task.status == TaskStatus.failed)
                            const Text('下載失敗', style: TextStyle(color: Colors.red))
                          else if (task.status == TaskStatus.completed)
                            const Text('下載完成', style: TextStyle(color: Colors.green))
                          else if (task.status == TaskStatus.cancelled)
                            const Text('已取消', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      trailing: (task.status == TaskStatus.downloading || task.status == TaskStatus.pending)
                          ? IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => provider.cancelTask(task.id),
                            )
                          : const Icon(Icons.check_circle, color: Colors.green),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. 推薦下載區域
              if (!provider.isDownloading) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.0),
                  child: Text('推薦區域下載 (熱門百岳)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 8),
                ..._presets.map(
                  (preset) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.terrain, color: Colors.green),
                      title: Text(preset.name),
                      subtitle: const Text('範圍: 約 10x10 km, Zoom 12-20'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // 預覽按鈕
                          IconButton(
                            icon: const Icon(Icons.visibility, color: Colors.teal),
                            tooltip: '預覽範圍',
                            onPressed: () {
                              // 返回 MapScreen 並傳遞 bounds 進行預覽
                              Navigator.pop(context, preset.bounds);
                            },
                          ),
                          // 下載按鈕
                          IconButton(
                            icon: const Icon(Icons.download_for_offline_outlined, color: Colors.blue),
                            tooltip: '加入下載',
                            onPressed: () => _confirmDownloadPreset(context, provider, preset),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. 管理操作
              ListTile(
                leading: const Icon(Icons.delete_forever, color: Colors.red),
                title: const Text('清除所有離線地圖'),
                subtitle: const Text('這將刪除所有已下載的圖資，無法復原。'),
                onTap: () => _showClearConfirmation(context, provider),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blueGrey),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
        ),
        Text(label, style: const TextStyle(color: Colors.grey)),
      ],
    );
  }

  void _showClearConfirmation(BuildContext context, MapProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('確定清除所有地圖?'),
        content: const Text('此操作將會刪除裝置上所有已下載的離線圖資。\n\n(注意: 下次瀏覽時需要重新下載)'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await provider.clearStore();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已清除所有離線地圖')));
                _refreshStats();
              }
            },
            child: const Text('確認清除'),
          ),
        ],
      ),
    );
  }

  void _confirmDownloadPreset(BuildContext context, MapProvider provider, ({String name, LatLngBounds bounds}) preset) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('下載 ${preset.name}?'),
        content: const Text('將下載該區域 Zoom 12-20 之圖資。\n\n請確保網路連線穩定。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('已在背景開始下載...')));
              provider.downloadRegion(
                bounds: preset.bounds,
                minZoom: 12,
                maxZoom: 20,
                name: preset.name,
                onProgress: null,
              );
              // 下載加入佇列後 refresh stats (如果有立即變動) 但是通常要等下載
              if (mounted) _refreshStats();
            },
            child: const Text('加入下載'),
          ),
        ],
      ),
    );
  }
}
