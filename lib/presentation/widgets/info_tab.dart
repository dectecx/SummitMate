import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/di.dart';
import '../../core/constants.dart';
import '../../services/interfaces/i_weather_service.dart';
import '../../services/toast_service.dart';
import '../../data/models/weather_data.dart';
import '../providers/settings_provider.dart';
import '../screens/map/map_screen.dart';
import 'zoomable_image.dart';

/// Tab 4: 資訊整合頁 (步道概況 + 工具 + 外部連結)
class InfoTab extends StatefulWidget {
  final Key? keyElevation;
  final Key? keyTimeMap;

  const InfoTab({super.key, this.keyElevation, this.keyTimeMap});

  @override
  State<InfoTab> createState() => InfoTabState();
}

class InfoTabState extends State<InfoTab> {
  int _selectedForecastIndex = -1;
  bool _isElevationExpanded = false;
  bool _isTimeMapExpanded = false;
  WeatherData? _weather;
  String _selectedLocation = '向陽山';
  bool _isWeatherExpanded = false;
  bool _loadingWeather = false;

  @override
  void initState() {
    super.initState();
    _refreshWeather();
  }

  Future<void> _refreshWeather({bool force = false}) async {
    // 離線模式禁止手動更新
    if (force) {
      final isOffline = context.read<SettingsProvider>().isOfflineMode;
      if (isOffline) {
        ToastService.warning('離線模式無法更新天氣資料');
        return;
      }
    }

    setState(() => _loadingWeather = true);
    try {
      final weather = await getIt<IWeatherService>().getWeather(forceRefresh: force, locationName: _selectedLocation);
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
        // 頂部視覺圖 (嘉明湖) - 可點擊放大
        GestureDetector(
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
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey),
                ),
                // 漸層遮罩
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.6)],
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
                      color: Colors.black.withOpacity(0.5),
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
        ),

        // 內容列表
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 步道概況
              Card(
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
                            key: widget.keyElevation,
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
                            key: widget.keyTimeMap,
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
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '📏 高度變化圖',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const ZoomableImage(
                                assetPath: 'assets/images/elevation_profile.png',
                                borderRadius: 8,
                                title: '高度變化圖',
                              ),
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
                          padding: const EdgeInsets.only(top: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '⏱️ 路程時間參考',
                                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
                              ),
                              const SizedBox(height: 8),
                              const ZoomableImage(
                                assetPath: 'assets/images/trail_time_map.png',
                                borderRadius: 8,
                                title: '路程時間參考',
                              ),
                            ],
                          ),
                        ),
                        crossFadeState: _isTimeMapExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                        duration: const Duration(milliseconds: 300),
                      ),

                      const SizedBox(height: 16),
                      const Text(
                        '嘉明湖國家步道為中央山脈南二段的一部分，穿越台灣鐵杉林、高山深谷與箭竹草原，以高山寒原與藍寶石般的嘉明湖聞名。',
                        style: TextStyle(height: 1.5),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const MapScreen())),
                          icon: const Icon(Icons.map),
                          label: const Text('查看步道導覽地圖'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 天氣預報 (可縮合)
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.cloud, color: Colors.blue),
                  title: const Text('天氣預報', style: TextStyle(fontWeight: FontWeight.bold)),
                  initiallyExpanded: true,
                  children: [_buildWeatherContent()],
                ),
              ),
              const SizedBox(height: 8),

              // 外部資訊連結 (可縮合)
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.link),
                  title: const Text('相關連結', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.article_outlined, color: Colors.green),
                      title: const Text('申請入山證'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.permitUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.home_work, color: Colors.brown),
                      title: const Text('山屋預約申請'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.cabinUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.public, color: Colors.indigo),
                      title: const Text('台灣山林悠遊網 (官網)'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.trailPageUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.map, color: Colors.green),
                      title: const Text('GPX 軌跡檔下載 (健行筆記)'),
                      trailing: const Icon(Icons.download, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.gpxUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.cloud, color: Colors.blue),
                      title: const Text('Windy 天氣預報'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.windyUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.wb_sunny, color: Colors.orange),
                      title: const Text('中央氣象署 (三叉山)'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.cwaUrl),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.hotel, color: Colors.purple),
                      title: const Text('鋤禾日好-站前館 (住宿)'),
                      trailing: const Icon(Icons.open_in_new, size: 18),
                      onTap: () => _launchUrl(ExternalLinks.accommodationUrl),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),

              // 電話訊號資訊
              Card(
                child: ExpansionTile(
                  leading: const Icon(Icons.signal_cellular_alt),
                  title: const Text('電話訊號資訊', style: TextStyle(fontWeight: FontWeight.bold)),
                  children: const [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SignalInfoRow(location: '起點 ~ 3.3K', signal: '有訊號'),
                          _SignalInfoRow(location: '3.3K ~ 向陽山屋', signal: '無訊號'),
                          _SignalInfoRow(location: '黑水塘稜線', signal: '中華/遠傳 1~2 格'),
                          _SignalInfoRow(location: '向陽山屋 ~ 10K', signal: '無訊號'),
                          _SignalInfoRow(location: '10K', signal: '遠傳微弱 (風大易失溫)'),
                          _SignalInfoRow(location: '10.5K', signal: '遠傳 2 格穩定'),
                          _SignalInfoRow(location: '嘉明湖本湖', signal: '中華/遠傳 (視雲況)'),
                          SizedBox(height: 8),
                          Text('💡 建議使用遠傳門號以獲得較多通訊點', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    IconData icon,
    String label,
    String value, {
    Key? key,
    VoidCallback? onTap,
    bool highlight = false,
  }) {
    return Expanded(
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: highlight
              ? BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
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

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    try {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    } catch (e) {
      debugPrint('無法開啟連結: $e');
    }
  }

  Widget _buildWeatherContent() {
    if (_weather == null && _loadingWeather) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_weather == null) {
      return ListTile(
        leading: const Icon(Icons.cloud_off),
        title: Text(_loadingWeather ? '讀取中...' : '請更新氣象資料', style: TextStyle(color: Colors.grey)),
        subtitle: const Text('點擊右側按鈕取得最新預報'),
        trailing: IconButton(
          onPressed: () => _refreshWeather(force: true),
          icon: const Icon(Icons.refresh, color: Colors.blue),
        ),
      );
    }

    final w = _weather!;
    final timeStr = DateFormat('MM/dd HH:mm').format(w.timestamp.toLocal());

    // View Model Logic
    String displayTemp;
    String displayCondition;
    String displayRain;
    String displayHumidity;
    String displayWind;
    String displayApparentTemp;
    String displaySun;
    IconData displaySunIcon;
    Color displaySunColor;
    String displayDateTitle;
    IconData displayIcon;
    Color displayIconColor;

    // Common Sun Logic (Show both Sunrise and Sunset)
    displaySunIcon = Icons.wb_twilight;
    displaySunColor = Colors.orange;

    final sunrise = DateFormat('HH:mm').format(w.sunrise);
    final sunset = DateFormat('HH:mm').format(w.sunset);
    displaySun = '日出 $sunrise / 日落 $sunset';

    if (_selectedForecastIndex >= 0 && _selectedForecastIndex < w.dailyForecasts.length) {
      final d = w.dailyForecasts[_selectedForecastIndex];
      displayDateTitle = '預報: ${DateFormat('MM/dd').format(d.date)}';

      // Temp Range Logic
      if (d.minTemp.round() == d.maxTemp.round()) {
        displayTemp = '${d.minTemp.round()}°C';
      } else {
        displayTemp = '${d.minTemp.round()} ~ ${d.maxTemp.round()}°C';
      }

      displayCondition = d.dayCondition;
      displayRain = '${d.rainProbability}%';

      // Apparent Temp Range Logic
      final minApp = (d.minApparentTemp ?? d.minTemp).round();
      final maxApp = (d.maxApparentTemp ?? d.maxTemp).round();
      if (minApp == maxApp) {
        displayApparentTemp = '${minApp}°C';
      } else {
        displayApparentTemp = '$minApp ~ ${maxApp}°C';
      }

      displayHumidity = '- %';
      displayWind = '- m/s';
      displayIcon = _getWeatherIcon(d.dayCondition);
    } else {
      displayDateTitle = '目前天氣';
      displayTemp = '${w.temperature.toStringAsFixed(1)}°C';
      displayCondition = w.condition;
      displayRain = '${w.rainProbability}%';
      displayApparentTemp = '${(w.apparentTemperature ?? w.temperature).toStringAsFixed(1)}°C';
      displayHumidity = '${w.humidity.toStringAsFixed(0)}%';
      displayWind = '${w.windSpeed} m/s';
      displayIcon = _getWeatherIcon(w.condition);
    }

    displayIconColor = _getWeatherColor(displayCondition);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Location Dropdown
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              DropdownButton<String>(
                value: _selectedLocation,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
                onChanged: (String? newValue) {
                  if (newValue != null && newValue != _selectedLocation) {
                    setState(() {
                      _selectedLocation = newValue;
                      _weather = null; // Clear old data visually
                      _selectedForecastIndex = -1; // Reset selection
                      _refreshWeather(force: false);
                    });
                  }
                },
                items: <String>['向陽山', '三叉山', '池上'].map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(value),
                      ],
                    ),
                  );
                }).toList(),
              ),
              if (_loadingWeather)
                const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              else
                InkWell(
                  onTap: () {
                    setState(() => _selectedForecastIndex = -1); // Reset
                    _refreshWeather(force: true);
                  },
                  child: Row(
                    children: [
                      Text(
                        '更新: $timeStr${w.isStale ? " (過期)" : ""}',
                        style: TextStyle(fontSize: 10, color: w.isStale ? Colors.red : Colors.grey),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.refresh, size: 14, color: Colors.grey),
                    ],
                  ),
                ),
            ],
          ),
          const Divider(),
          if (w.isStale)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(4)),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, size: 16, color: Colors.red.shade700),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('資料已過期，請點擊右上角重整更新', style: TextStyle(fontSize: 12, color: Colors.red.shade700)),
                  ),
                ],
              ),
            ),

          // Main Weather Display
          InkWell(
            onTap: () {
              setState(() {
                if (_selectedForecastIndex != -1) {
                  _selectedForecastIndex = -1; // Click main area to reset to "Current"
                } else {
                  _isWeatherExpanded = !_isWeatherExpanded;
                }
              });
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayDateTitle,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        Icon(displayIcon, size: 48, color: displayIconColor),
                        const SizedBox(height: 2),
                        Text(
                          displayTemp,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(displayCondition, style: const TextStyle(fontSize: 14)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.water_drop, size: 14, color: Colors.blue),
                            const SizedBox(width: 4),
                            Text('降雨機率: $displayRain'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.water, size: 14, color: Colors.lightBlue),
                            const SizedBox(width: 4),
                            Text('濕度: $displayHumidity'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.air, size: 14, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text('風速: $displayWind'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.thermostat, size: 14, color: Colors.orangeAccent),
                            const SizedBox(width: 4),
                            Text('體感: $displayApparentTemp'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(displaySunIcon, size: 14, color: displaySunColor),
                            const SizedBox(width: 4),
                            Text(displaySun),
                          ],
                        ),
                      ],
                    ),
                    Icon(_isWeatherExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
                  ],
                ),
              ],
            ),
          ),

          // 7-Day Forecast (Collapsible)
          if (_isWeatherExpanded && w.dailyForecasts.isNotEmpty) ...[
            const Divider(height: 24),
            const Text('未來 7 天預報 (點擊切換顯示)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: w.dailyForecasts.asMap().entries.map((entry) {
                  final index = entry.key;
                  final d = entry.value;
                  final dateStr = DateFormat('MM/dd').format(d.date);
                  final isWeekend = d.date.weekday == 6 || d.date.weekday == 7;
                  final isSelected = index == _selectedForecastIndex;

                  // Temp format for list item (simplified)
                  String listTempStr;
                  if (d.minTemp.round() == d.maxTemp.round()) {
                    listTempStr = '${d.minTemp.round()}°C';
                  } else {
                    listTempStr = '${d.minTemp.round()}-${d.maxTemp.round()}°C';
                  }

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedForecastIndex = (_selectedForecastIndex == index) ? -1 : index;
                      });
                    },
                    child: Container(
                      width: 90,
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.blue : Colors.grey.shade200,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isWeekend ? Colors.red : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Icon(
                            _getWeatherIcon(d.dayCondition),
                            color: isSelected ? Colors.blue : Colors.orange,
                            size: 24,
                          ),
                          const SizedBox(height: 4),
                          Text(d.dayCondition, style: const TextStyle(fontSize: 10), overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 4),
                          Text(listTempStr, style: const TextStyle(fontSize: 12)),
                          if ((d.maxApparentTemp ?? 0) != 0)
                            Text(
                              '體感 ${(d.minApparentTemp ?? d.minTemp).round()}~${(d.maxApparentTemp ?? d.maxTemp).round()}',
                              style: const TextStyle(fontSize: 10, color: Colors.grey),
                            ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.water_drop, size: 10, color: Colors.blue),
                              Text('${d.rainProbability}%', style: const TextStyle(fontSize: 10)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getWeatherIcon(String condition) {
    final c = condition.replaceAll(' ', '');

    switch (c) {
      case '多雲時晴':
      case '晴時多雲':
        return Icons.wb_cloudy;
      case '多雲':
        return Icons.cloud_queue;
      case '陰天':
      case '陰時多雲':
      case '多雲時陰':
        return Icons.cloud;
      case '多雲短暫雨':
      case '陰時多雲短暫雨':
      case '多雲時陰短暫雨':
      case '陰短暫雨':
        return Icons.water_drop;
      case '多雲短暫雨或雪':
      case '多雲時陰短暫雨或雪':
      case '陰短暫雨或雪':
      case '陰時多雲短暫雨或雪':
        return Icons.ac_unit;
    }

    if (c.contains('雪') || c.contains('冰')) return Icons.ac_unit;
    if (c.contains('雷')) return Icons.thunderstorm;
    if (c.contains('霧')) return Icons.blur_on;

    if (c.contains('雨')) {
      if (c.contains('豪') || c.contains('大')) return Icons.grain;
      return Icons.water_drop;
    }

    if (c.contains('晴') && (c.contains('雲') || c.contains('陰'))) {
      return Icons.wb_cloudy;
    }

    if (c.contains('晴')) return Icons.wb_sunny;
    if (c.contains('陰')) return Icons.cloud;
    if (c.contains('多雲')) return Icons.cloud_queue;
    if (c.contains('雲')) return Icons.cloud;

    return Icons.help_outline;
  }

  Color _getWeatherColor(String condition) {
    final c = condition.replaceAll(' ', '');
    if (c.contains('雪') || c.contains('冰')) return Colors.lightBlue;
    if (c.contains('雨') || c.contains('雷')) return Colors.blue;
    if (c.contains('晴')) return Colors.orange;
    return Colors.grey;
  }
}

/// 訊號資訊行
class _SignalInfoRow extends StatelessWidget {
  final String location;
  final String signal;

  const _SignalInfoRow({required this.location, required this.signal});

  @override
  Widget build(BuildContext context) {
    final isNoSignal = signal.contains('無');
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isNoSignal ? Icons.signal_cellular_off : Icons.signal_cellular_alt,
            size: 16,
            color: isNoSignal ? Colors.red : Colors.green,
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(location)),
          Text(
            signal,
            style: TextStyle(color: isNoSignal ? Colors.red : null, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
