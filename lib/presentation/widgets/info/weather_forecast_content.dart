import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../data/models/weather_data.dart';

/// 天氣預報詳細內容 Widget
///
/// 顯示目前天氣和 7 天預報
class WeatherForecastContent extends StatefulWidget {
  final WeatherData? weather;
  final bool isLoading;
  final String selectedLocation;
  final VoidCallback onRefresh;
  final ValueChanged<String> onLocationChanged;

  const WeatherForecastContent({
    super.key,
    required this.weather,
    required this.isLoading,
    required this.selectedLocation,
    required this.onRefresh,
    required this.onLocationChanged,
  });

  @override
  State<WeatherForecastContent> createState() => _WeatherForecastContentState();
}

class _WeatherForecastContentState extends State<WeatherForecastContent> {
  int _selectedForecastIndex = -1;
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    if (widget.weather == null && widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.weather == null) {
      return ListTile(
        leading: const Icon(Icons.cloud_off),
        title: Text(widget.isLoading ? '讀取中...' : '請更新氣象資料', style: const TextStyle(color: Colors.grey)),
        subtitle: const Text('點擊右側按鈕取得最新預報'),
        trailing: IconButton(
          onPressed: widget.onRefresh,
          icon: const Icon(Icons.refresh, color: Colors.blue),
        ),
      );
    }

    final w = widget.weather!;
    final timeStr = DateFormat('MM/dd HH:mm').format(w.timestamp.toLocal());

    // View Model Logic
    final viewModel = _buildViewModel(w);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Location Dropdown
          _buildHeader(w, timeStr),
          const Divider(),

          // Stale data warning
          if (w.isStale) _buildStaleWarning(),

          // Main Weather Display
          _buildMainWeatherDisplay(viewModel),

          // 7-Day Forecast (Collapsible)
          if (_isExpanded && w.dailyForecasts.isNotEmpty) ...[const Divider(height: 24), _buildForecastList(w)],
        ],
      ),
    );
  }

  _WeatherViewModel _buildViewModel(WeatherData w) {
    String displayTemp;
    String displayCondition;
    String displayRain;
    String displayHumidity;
    String displayWind;
    String displayApparentTemp;
    String displayDateTitle;
    IconData displayIcon;

    // Common Sun Logic
    final sunrise = DateFormat('HH:mm').format(w.sunrise);
    final sunset = DateFormat('HH:mm').format(w.sunset);
    final displaySun = '日出 $sunrise / 日落 $sunset';

    if (_selectedForecastIndex >= 0 && _selectedForecastIndex < w.dailyForecasts.length) {
      final d = w.dailyForecasts[_selectedForecastIndex];
      displayDateTitle = '預報: ${DateFormat('MM/dd').format(d.date)}';

      if (d.minTemp.round() == d.maxTemp.round()) {
        displayTemp = '${d.minTemp.round()}°C';
      } else {
        displayTemp = '${d.minTemp.round()} ~ ${d.maxTemp.round()}°C';
      }

      displayCondition = d.dayCondition;
      displayRain = '${d.rainProbability}%';

      final minApp = (d.minApparentTemp ?? d.minTemp).round();
      final maxApp = (d.maxApparentTemp ?? d.maxTemp).round();
      if (minApp == maxApp) {
        displayApparentTemp = '$minApp°C';
      } else {
        displayApparentTemp = '$minApp ~ $maxApp°C';
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

    return _WeatherViewModel(
      dateTitle: displayDateTitle,
      temp: displayTemp,
      condition: displayCondition,
      rain: displayRain,
      humidity: displayHumidity,
      wind: displayWind,
      apparentTemp: displayApparentTemp,
      sun: displaySun,
      icon: displayIcon,
      iconColor: _getWeatherColor(displayCondition),
    );
  }

  Widget _buildHeader(WeatherData w, String timeStr) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        DropdownButton<String>(
          value: widget.selectedLocation,
          underline: const SizedBox(),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.blue),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black, fontSize: 16),
          onChanged: (String? newValue) {
            if (newValue != null && newValue != widget.selectedLocation) {
              setState(() => _selectedForecastIndex = -1);
              widget.onLocationChanged(newValue);
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
        if (widget.isLoading)
          const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
        else
          InkWell(
            onTap: () {
              setState(() => _selectedForecastIndex = -1);
              widget.onRefresh();
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
    );
  }

  Widget _buildStaleWarning() {
    return Container(
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
    );
  }

  Widget _buildMainWeatherDisplay(_WeatherViewModel vm) {
    return InkWell(
      onTap: () {
        setState(() {
          if (_selectedForecastIndex != -1) {
            _selectedForecastIndex = -1;
          } else {
            _isExpanded = !_isExpanded;
          }
        });
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            vm.dateTitle,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Icon(vm.icon, size: 48, color: vm.iconColor),
                  const SizedBox(height: 2),
                  Text(
                    vm.temp,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(vm.condition, style: const TextStyle(fontSize: 14)),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildWeatherRow(Icons.water_drop, Colors.blue, '降雨機率: ${vm.rain}'),
                  const SizedBox(height: 4),
                  _buildWeatherRow(Icons.water, Colors.lightBlue, '濕度: ${vm.humidity}'),
                  const SizedBox(height: 4),
                  _buildWeatherRow(Icons.air, Colors.grey, '風速: ${vm.wind}'),
                  const SizedBox(height: 4),
                  _buildWeatherRow(Icons.thermostat, Colors.orangeAccent, '體感: ${vm.apparentTemp}'),
                  const SizedBox(height: 4),
                  _buildWeatherRow(Icons.wb_twilight, Colors.orange, vm.sun),
                ],
              ),
              Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherRow(IconData icon, Color color, String text) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(text),
      ],
    );
  }

  Widget _buildForecastList(WeatherData w) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('未來 7 天預報 (點擊切換顯示)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: w.dailyForecasts.asMap().entries.map((entry) {
              final index = entry.key;
              final d = entry.value;
              return _buildForecastItem(index, d);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildForecastItem(int index, DailyForecast d) {
    final dateStr = DateFormat('MM/dd').format(d.date);
    final isWeekend = d.date.weekday == 6 || d.date.weekday == 7;
    final isSelected = index == _selectedForecastIndex;

    String listTempStr;
    if (d.minTemp.round() == d.maxTemp.round()) {
      listTempStr = '${d.minTemp.round()}°C';
    } else {
      listTempStr = '${d.minTemp.round()}-${d.maxTemp.round()}°C';
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedForecastIndex = (_selectedForecastIndex == index) ? -1 : index),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey.shade200, width: isSelected ? 2 : 1),
        ),
        child: Column(
          children: [
            Text(
              dateStr,
              style: TextStyle(fontWeight: FontWeight.bold, color: isWeekend ? Colors.red : Colors.black87),
            ),
            const SizedBox(height: 4),
            Icon(_getWeatherIcon(d.dayCondition), color: isSelected ? Colors.blue : Colors.orange, size: 24),
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

    if (c.contains('晴') && (c.contains('雲') || c.contains('陰'))) return Icons.wb_cloudy;
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

/// 天氣顯示 ViewModel
class _WeatherViewModel {
  final String dateTitle;
  final String temp;
  final String condition;
  final String rain;
  final String humidity;
  final String wind;
  final String apparentTemp;
  final String sun;
  final IconData icon;
  final Color iconColor;

  _WeatherViewModel({
    required this.dateTitle,
    required this.temp,
    required this.condition,
    required this.rain,
    required this.humidity,
    required this.wind,
    required this.apparentTemp,
    required this.sun,
    required this.icon,
    required this.iconColor,
  });
}
