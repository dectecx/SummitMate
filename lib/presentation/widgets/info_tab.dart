import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/di.dart';
import '../../domain/interfaces/i_weather_service.dart';
import '../../infrastructure/tools/toast_service.dart';
import '../../data/models/weather_data.dart';
import '../cubits/settings/settings_cubit.dart';
import '../cubits/settings/settings_state.dart';
import '../screens/map/map_screen.dart';
import 'zoomable_image.dart';
import 'weather/weather_alert_card.dart';
import 'info/weather_forecast_content.dart';
import 'info/external_links_card.dart';
import 'info/signal_info_card.dart';
import 'info/beginner_peaks_card.dart';

/// Tab 4: 資訊整合頁 (步道概況 + 工具 + 外部連結)
class InfoTab extends StatefulWidget {
  final GlobalKey? expandedElevationKey;
  final GlobalKey? expandedTimeMapKey;

  const InfoTab({super.key, this.expandedElevationKey, this.expandedTimeMapKey});

  @override
  State<InfoTab> createState() => InfoTabState();
}

class InfoTabState extends State<InfoTab> {
  bool _isElevationExpanded = false;
  bool _isTimeMapExpanded = false;
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

  void expandElevation() {
    setState(() {
      _isElevationExpanded = true;
      _isTimeMapExpanded = false;
    });
  }

  void expandTimeMap() {
    setState(() {
      _isTimeMapExpanded = true;
      _isElevationExpanded = false;
    });
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
              _buildTrailOverviewCard(context),
              const SizedBox(height: 8),

              // 天氣預報
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.cloud, color: Colors.blue),
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

  /// 步道概況卡片
  Widget _buildTrailOverviewCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('步道概況', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildStatItem(context, Icons.straighten, '全長', '13 km'),
                _buildStatItem(
                  context,
                  Icons.landscape,
                  '海拔 (點擊展開高度圖)',
                  '2320~3603m',
                  onTap: () => setState(() {
                    _isElevationExpanded = !_isElevationExpanded;
                    if (_isElevationExpanded) _isTimeMapExpanded = false;
                  }),
                  highlight: _isElevationExpanded,
                ),
                _buildStatItem(
                  context,
                  Icons.timer,
                  '路程時間',
                  '點擊查看參考圖',
                  onTap: () => setState(() {
                    _isTimeMapExpanded = !_isTimeMapExpanded;
                    if (_isTimeMapExpanded) _isElevationExpanded = false;
                  }),
                  highlight: _isTimeMapExpanded,
                ),
              ],
            ),

            // 高度圖 (可縮合)
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: Padding(
                key: widget.expandedElevationKey,
                padding: const EdgeInsets.only(top: 16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📏 高度變化圖',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ZoomableImage(assetPath: 'assets/images/elevation_profile.png', borderRadius: 8, title: '高度變化圖'),
                  ],
                ),
              ),
              crossFadeState: _isElevationExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            // 路程時間圖 (可縮合)
            AnimatedCrossFade(
              firstChild: const SizedBox(height: 0, width: double.infinity),
              secondChild: Padding(
                key: widget.expandedTimeMapKey,
                padding: const EdgeInsets.only(top: 16),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '⏱️ 路程時間參考',
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 8),
                    ZoomableImage(assetPath: 'assets/images/trail_time_map.png', borderRadius: 8, title: '路程時間參考'),
                  ],
                ),
              ),
              crossFadeState: _isTimeMapExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 300),
            ),

            const SizedBox(height: 16),
            const Text('嘉明湖國家步道為中央山脈南二段的一部分，穿越台灣鐵杉林、高山深谷與箭竹草原，以高山寒原與藍寶石般的嘉明湖聞名。', style: TextStyle(height: 1.5)),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                icon: const Icon(Icons.map),
                label: const Text('查看步道導覽地圖'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: highlight
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
                )
              : null,
          child: Row(
            children: [
              Icon(icon, size: 20, color: highlight ? Theme.of(context).colorScheme.primary : Colors.grey),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 12,
                        color: highlight ? Theme.of(context).colorScheme.primary : Colors.grey,
                      ),
                    ),
                    Text(
                      value,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: highlight ? Theme.of(context).colorScheme.primary : null,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
