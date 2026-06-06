import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/di/injection.dart';
import '../../../domain/interfaces/i_connectivity_service.dart';

class OfflineStatusBanner extends StatefulWidget {
  const OfflineStatusBanner({super.key});

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  late final IConnectivityService _connectivityService;
  StreamSubscription<bool>? _subscription;
  bool _isOffline = false;

  @override
  void initState() {
    super.initState();
    _connectivityService = getIt<IConnectivityService>();
    _isOffline = _connectivityService.isOffline;
    _subscription = _connectivityService.onConnectivityChanged.listen((isOnline) {
      if (mounted) {
        setState(() {
          _isOffline = !isOnline;
        });
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isOffline) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.errorContainer,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.wifi_off_rounded, size: 16, color: theme.colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              '無網環境 (離線模式)，編輯將在連線後自動同步',
              style: TextStyle(color: theme.colorScheme.onErrorContainer, fontSize: 12, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
