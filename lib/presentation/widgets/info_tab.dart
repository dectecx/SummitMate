import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../data/models/weather_data.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import 'zoomable_image.dart';
import 'weather/weather_alert_card.dart';
import 'info/weather_forecast_content.dart';
import 'info/external_links_card.dart';
import 'info/signal_info_card.dart';
import 'info/beginner_peaks_card.dart';
import 'info/trail_overview_card.dart';

/// Tab 4: 資訊整合頁 (步道概況 + 工具 + 外部連結)
class InfoTab extends StatefulWidget {
  final GlobalKey? expandedElevationKey;
  final GlobalKey? expandedTimeMapKey;

  const InfoTab({super.key, this.expandedElevationKey, this.expandedTimeMapKey});

  @override
  State<InfoTab> createState() => InfoTabState();
}

class InfoTabState extends State<InfoTab> {
  WeatherData? _weather;
  String _selectedLocation = '向陽山';
  bool _loadingWeather = false;

  @override
  void initState() {
    super.initState();
    _refreshWeather();
  }

  Future<void> _refreshWeather({bool force = false}) async {
    // 離線模式禁止手動更新
    if (force) {
      final settingsState = context.read<SettingsCubit>().state;
      final isOffline = settingsState is SettingsLoaded && settingsState.isOfflineMode;
      if (isOffline) {
        ToastService.warning('離線模式無法更新天氣資料');
        return;
      }
    }

    setState(() => _loadingWeather = true);
    try {
      final weather = await getIt<IWeatherService>().getWeatherByName(_selectedLocation, forceRefresh: force);
      if (mounted) {
        setState(() => _weather = weather);
        if (force) ToastService.success('天氣更新成功！');
      }
    } catch (e) {
      if (mounted && force) ToastService.error('天氣更新失敗：$e');
    } finally {
      if (mounted) setState(() => _loadingWeather = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // 頂部視覺圖 (嘉明湖)
        _buildHeroImage(context),

        // 內容列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 目前位置天氣警報
              const WeatherAlertCard(),
              const SizedBox(height: 16),

              // 新手百岳推薦入口
              const BeginnerPeaksCard(),
              const SizedBox(height: 8),

              // 步道概況
              TrailOverviewCard(
                expandedElevationKey: widget.expandedElevationKey,
                expandedTimeMapKey: widget.expandedTimeMapKey,
              ),
              const SizedBox(height: 8),

              // 天氣預報
              Card(
                child: ExpansionTile(
                  leading: Icon(Icons.cloud, color: Theme.of(context).colorScheme.primary),
                  title: const Text('天氣預報', style: TextStyle(fontWeight: FontWeight.bold)),
                  initiallyExpanded: true,
                  children: [
                    WeatherForecastContent(
                      weather: _weather,
                      isLoading: _loadingWeather,
                      selectedLocation: _selectedLocation,
                      onRefresh: () => _refreshWeather(force: true),
                      onLocationChanged: (location) {
                        setState(() {
                          _selectedLocation = location;
                          _weather = null;
                        });
                        _refreshWeather();
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 外部連結
              const ExternalLinksCard(),
              const SizedBox(height: 8),

              // 電話訊號資訊
              const SignalInfoCard(),
            ],
          ),
        ),
      ],
    );
  }

  /// 頂部視覺圖
  Widget _buildHeroImage(BuildContext context) {
    return GestureDetector(
      onTap: () => ImageViewerDialog.show(context, assetPath: 'assets/images/jiaming_lake.jpg', title: '嘉明湖'),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/jiaming_lake.jpg',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey),
            ),
            // 漸層遮罩
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                  stops: const [0.6, 1.0],
                ),
              ),
            ),
            // 放大提示 icon
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
              ),
            ),
            const Positioned(
              bottom: 16,
              left: 16,
              child: Text(
                '嘉明湖國家步道',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  shadows: [Shadow(blurRadius: 4, color: Colors.black)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
