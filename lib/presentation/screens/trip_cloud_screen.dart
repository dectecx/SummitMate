import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../data/models/trip.dart';
import '../../data/repositories/interfaces/i_trip_repository.dart';
import '../../core/di.dart';
import '../../services/toast_service.dart';
import '../providers/trip_provider.dart';
import '../providers/settings_provider.dart';

/// 雲端行程同步畫面
class TripCloudScreen extends StatefulWidget {
  const TripCloudScreen({super.key});

  @override
  State<TripCloudScreen> createState() => _TripCloudScreenState();
}

class _TripCloudScreenState extends State<TripCloudScreen> {
  // Use Repository directly for Cloud Operations (Facade)
  final ITripRepository _tripRepository = getIt<ITripRepository>();

  bool _isLoading = false;
  List<Trip> _cloudTrips = [];
  String? _errorMessage;
  bool _hasFetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Only fetch once and not in offline mode
    if (!_hasFetched) {
      final isOffline = context.read<SettingsProvider>().isOfflineMode;
      if (!isOffline) {
        _hasFetched = true;
        _getCloudTrips();
      }
    }
  }

  Future<void> _getCloudTrips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final trips = await _tripRepository.getRemoteTrips();
      setState(() {
        _isLoading = false;
        _cloudTrips = trips;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _uploadTrip(Trip trip) async {
    setState(() => _isLoading = true);

    try {
      await _tripRepository.uploadTripToRemote(trip);
      setState(() => _isLoading = false);
      ToastService.success('已上傳: ${trip.name}');
      _getCloudTrips(); // 刷新列表
    } catch (e) {
      setState(() => _isLoading = false);
      ToastService.error('上傳失敗: $e');
    }
  }

  Future<void> _downloadTrip(Trip cloudTrip) async {
    final tripProvider = context.read<TripProvider>();

    // 檢查是否已存在
    final exists = tripProvider.trips.any((t) => t.id == cloudTrip.id);

    if (exists) {
      final overwrite = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('行程已存在'),
          content: Text('本地已有「${cloudTrip.name}」。要覆蓋嗎？'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('覆蓋')),
          ],
        ),
      );

      if (overwrite != true) return;

      // 更新現有
      await tripProvider.updateTrip(cloudTrip);
      ToastService.success('已覆蓋: ${cloudTrip.name}');
    } else {
      // 新增 - 使用命名參數
      await tripProvider.addTrip(
        name: cloudTrip.name,
        startDate: cloudTrip.startDate,
        endDate: cloudTrip.endDate,
        description: cloudTrip.description,
        coverImage: cloudTrip.coverImage,
        setAsActive: false,
      );
      ToastService.success('已下載: ${cloudTrip.name}');
    }
  }

  Future<void> _deleteCloudTrip(Trip trip) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('刪除雲端行程'),
        content: Text('確定要從雲端刪除「${trip.name}」嗎？\n本地行程不會受影響。'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('刪除'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _tripRepository.deleteRemoteTrip(trip.id);
      setState(() => _isLoading = false);
      ToastService.success('已從雲端刪除: ${trip.name}');
      _getCloudTrips();
    } catch (e) {
      setState(() => _isLoading = false);
      ToastService.error('刪除失敗: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final isOffline = settingsProvider.isOfflineMode;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('雲端行程'),
            if (isOffline) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(12)),
                child: const Text('離線', style: TextStyle(fontSize: 12, color: Colors.white)),
              ),
            ],
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: isOffline ? null : _getCloudTrips, tooltip: '重新整理'),
        ],
      ),
      body: isOffline
          ? _buildOfflineView()
          : _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? _buildErrorView()
          : _buildBody(),
    );
  }

  Widget _buildOfflineView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_off, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('離線模式', style: TextStyle(fontSize: 18, color: Colors.grey)),
          SizedBox(height: 8),
          Text('請關閉離線模式以使用雲端功能', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text('載入失敗', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(_errorMessage ?? '', style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          ElevatedButton.icon(onPressed: _getCloudTrips, icon: const Icon(Icons.refresh), label: const Text('重試')),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return Consumer<TripProvider>(
      builder: (context, tripProvider, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 上傳本地行程區塊
            _buildUploadSection(tripProvider),
            const SizedBox(height: 24),
            // 雲端行程列表
            _buildCloudTripsSection(),
          ],
        );
      },
    );
  }

  Widget _buildUploadSection(TripProvider tripProvider) {
    final localTrips = tripProvider.trips;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.upload, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                const Text('上傳本地行程', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            if (localTrips.isEmpty)
              const Text('目前沒有本地行程', style: TextStyle(color: Colors.grey))
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: localTrips.map((trip) {
                  final isInCloud = _cloudTrips.any((ct) => ct.id == trip.id);
                  return ActionChip(
                    avatar: Icon(
                      isInCloud ? Icons.cloud_done : Icons.cloud_upload_outlined,
                      size: 18,
                      color: isInCloud ? Colors.green : null,
                    ),
                    label: Text(trip.name),
                    onPressed: () => _uploadTrip(trip),
                    tooltip: isInCloud ? '已在雲端 (點擊更新)' : '點擊上傳',
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCloudTripsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.cloud, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text('雲端行程 (${_cloudTrips.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        if (_cloudTrips.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.cloud_queue, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('雲端尚無行程', style: TextStyle(color: Colors.grey)),
                  ],
                ),
              ),
            ),
          )
        else
          ...(_cloudTrips.map(
            (trip) =>
                _TripCard(trip: trip, onDownload: () => _downloadTrip(trip), onDelete: () => _deleteCloudTrip(trip)),
          )),
      ],
    );
  }
}

/// 行程卡片
class _TripCard extends StatelessWidget {
  final Trip trip;
  final VoidCallback onDownload;
  final VoidCallback onDelete;

  const _TripCard({required this.trip, required this.onDownload, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('yyyy/MM/dd');
    final startDate = dateFormat.format(trip.startDate);
    final endDate = trip.endDate != null ? dateFormat.format(trip.endDate!) : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: trip.isActive ? Colors.green : Colors.blueGrey,
          child: const Icon(Icons.terrain, color: Colors.white),
        ),
        title: Text(trip.name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(endDate != null ? '$startDate ~ $endDate' : startDate, style: const TextStyle(fontSize: 12)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.download, color: Colors.blue),
              onPressed: onDownload,
              tooltip: '下載到本地',
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: onDelete,
              tooltip: '從雲端刪除',
            ),
          ],
        ),
      ),
    );
  }
}
