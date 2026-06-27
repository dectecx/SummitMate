import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';

import '../../../cubits/trip/trip_cubit.dart';
import '../../../cubits/connectivity/connectivity_cubit.dart';
import '../../../widgets/app_drawer.dart';
import '../../../widgets/common/offline_status_banner.dart';
import '../dialogs/trip_selection_dialog.dart';

/// 無行程時顯示的歡迎 Scaffold
///
/// 提供從雲端匯入或建立新行程的入口。
class EmptyTripScaffold extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  final VoidCallback onWelcomePressed;
  final VoidCallback onSettingsPressed;

  const EmptyTripScaffold({
    super.key,
    required this.scaffoldKey,
    required this.onWelcomePressed,
    required this.onSettingsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOffline = context.watch<ConnectivityCubit>().state.isOffline;

    return Scaffold(
      key: scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => scaffoldKey.currentState?.openDrawer(),
          tooltip: '選單',
        ),
        title: const Text('SummitMate 山友'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: '歡迎訊息 / 教學',
            onPressed: onWelcomePressed,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: onSettingsPressed,
            tooltip: '設定',
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: Column(
        children: [
          const OfflineStatusBanner(),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.hiking, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    '歡迎使用 SummitMate',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text('您目前還沒有任何行程', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 32),
                  FilledButton.icon(
                    onPressed: isOffline
                        ? () => ToastService.error('離線模式下無法從雲端匯入行程')
                        : () => TripSelectionDialog.show(context),
                    icon: const Icon(Icons.cloud_download),
                    label: const Text('從雲端匯入行程'),
                    style: isOffline
                        ? FilledButton.styleFrom(
                            backgroundColor: theme.disabledColor,
                            foregroundColor: theme.colorScheme.onSurface.withValues(alpha: 0.38),
                          )
                        : null,
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => context.read<TripCubit>().createDefaultTrip(),
                    icon: const Icon(Icons.add),
                    label: const Text('建立新行程'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
