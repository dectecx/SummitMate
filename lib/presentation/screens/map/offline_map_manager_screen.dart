import 'package:flutter/material.dart';
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

              // 2. 目前下載任務
              if (provider.isDownloading)
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text('正在下載地圖...', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            Text('${(provider.downloadProgress * 100).toStringAsFixed(1)}%'),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () async {
                                await provider.cancelDownload();
                                _refreshStats(); // 取消後更新統計
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(value: provider.downloadProgress),
                        const SizedBox(height: 8),
                        const Text('請勿強制關閉 App，可返回地圖繼續操作。', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 16),

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
}
