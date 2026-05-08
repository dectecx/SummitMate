import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/core/core.dart';
import 'package:summitmate/domain/domain.dart';
import '../../../cubits/sync/sync_cubit.dart';
import '../../../cubits/trip/trip_cubit.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

class TripSelectionDialog extends StatefulWidget {
  const TripSelectionDialog({super.key});

  static Future<void> show(BuildContext context) async {
    return showDialog(context: context, builder: (context) => const TripSelectionDialog());
  }

  @override
  State<TripSelectionDialog> createState() => _TripSelectionDialogState();
}

class _TripSelectionDialogState extends State<TripSelectionDialog> {
  bool _isLoading = true;
  bool _isImporting = false;
  List<Trip> _cloudTrips = [];
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTrips();
  }

  Future<void> _fetchTrips() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final tripCubit = context.read<TripCubit>();
    final result = await tripCubit.getCloudTrips();

    if (!mounted) return;

    if (result is Failure) {
      setState(() {
        _isLoading = false;
        _errorMessage = (result as Failure).exception.toString();
      });
    } else {
      setState(() {
        _isLoading = false;
        _cloudTrips = (result as Success<List<Trip>, Exception>).value;
      });
    }
  }

  Future<void> _importAndSwitchTrip(Trip cloudTrip) async {
    setState(() => _isImporting = true);

    try {
      final tripCubit = context.read<TripCubit>();

      // 1. 新增/更新 Trip Meta 到本地
      final existing = await tripCubit.getTripById(cloudTrip.id);
      if (existing != null) {
        await tripCubit.updateTrip(cloudTrip);
      } else {
        await tripCubit.importTrip(cloudTrip);
      }

      // 2. 切換為 Active
      await tripCubit.setActiveTrip(cloudTrip.id);

      // 3. 觸發 Sync (下載該 Trip 的 itinerary/messages)
      if (!mounted) return;
      await context.read<SyncCubit>().syncAll(force: true);

      if (mounted) {
        ToastService.success('行程匯入成功');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isImporting = false);
        ToastService.error('匯入失敗: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('選擇要匯入的行程'),
      content: SizedBox(width: double.maxFinite, child: _buildContent()),
      actions: [
        TextButton(
          onPressed: (_isLoading || _isImporting) ? null : () => Navigator.pop(context),
          child: const Text('取消'),
        ),
      ],
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [CircularProgressIndicator(), SizedBox(height: 16), Text('正在取得雲端行程...')],
        ),
      );
    }

    if (_errorMessage != null) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          const SizedBox(height: 16),
          Text(_errorMessage!, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _fetchTrips, child: const Text('重試')),
        ],
      );
    }

    if (_cloudTrips.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('雲端目前沒有行程資料', textAlign: TextAlign.center),
      );
    }

    return Stack(
      children: [
        ListView.builder(
          shrinkWrap: true,
          itemCount: _cloudTrips.length,
          itemBuilder: (context, index) {
            final trip = _cloudTrips[index];
            return ListTile(
              leading: const Icon(Icons.map),
              title: Text(trip.name),
              subtitle: Text(trip.startDate.toIso8601String().split('T').first),
              onTap: _isImporting ? null : () => _importAndSwitchTrip(trip),
            );
          },
        ),
        if (_isImporting)
          Positioned.fill(
            child: Container(
              color: Colors.white.withValues(alpha: 0.7),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [CircularProgressIndicator(), SizedBox(height: 16), Text('正在匯入並同步資料...')],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
