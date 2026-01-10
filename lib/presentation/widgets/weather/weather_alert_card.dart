import 'package:flutter/material.dart';
import '../../../domain/interfaces/i_geolocator_service.dart';
import '../../../core/di.dart';
import '../../../domain/interfaces/i_weather_service.dart';
import '../../../infrastructure/tools/log_service.dart';
import '../../../data/models/weather_data.dart';

class WeatherAlertCard extends StatefulWidget {
  const WeatherAlertCard({super.key});

  @override
  State<WeatherAlertCard> createState() => _WeatherAlertCardState();
}

class _WeatherAlertCardState extends State<WeatherAlertCard> {
  WeatherData? _weather;
  bool _isLoading = false;
  String? _error;
  bool _isVisible = true;

  @override
  void initState() {
    super.initState();
    _fetchWeather();
  }

  Future<void> _fetchWeather() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // 1. Get Position (Permission handled in service)
      final geoService = getIt<IGeolocatorService>();
      final position = await geoService.getCurrentPosition();

      // 3. Get Weather
      final weatherService = getIt<IWeatherService>();
      final weather = await weatherService.getWeatherByLocation(position.latitude, position.longitude);

      if (mounted) {
        setState(() {
          _weather = weather;
          _isLoading = false;
        });
      }
    } catch (e) {
      LogService.error('Error fetching weather alert: $e', source: 'WeatherAlertCard');
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isVisible) return const SizedBox.shrink();

    // 載入中狀態
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16.0),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    // 錯誤狀態
    if (_error != null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text('無法取得天氣資訊: $_error', style: const TextStyle(color: Colors.red)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.red),
              onPressed: _fetchWeather,
            ),
          ],
        ),
      );
    }

    if (_weather == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.cloud_off, color: Colors.grey),
            const SizedBox(width: 12),
            const Expanded(
              child: Text('暫無天氣資料', style: TextStyle(color: Colors.grey)),
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.grey),
              onPressed: _fetchWeather,
            ),
          ],
        ),
      );
    }

    // 樣式邏輯
    final isHighAlert = _weather!.rainProbability >= 80;
    final isRainy = _weather!.rainProbability >= 60 || _weather!.condition.contains('雨');

    Color statusColor;
    IconData statusIcon;
    String? badgeText;

    if (isHighAlert) {
      statusColor = Colors.redAccent;
      statusIcon = Icons.warning_amber_rounded;
      badgeText = '豪雨特報';
    } else if (isRainy) {
      statusColor = Colors.orange;
      statusIcon = Icons.umbrella;
      badgeText = '攜帶雨具';
    } else {
      statusColor = Colors.blue;
      statusIcon = Icons.wb_sunny_outlined;
      badgeText = null;
    }

    return Dismissible(
      key: const Key('weather_alert'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        setState(() => _isVisible = false);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: statusColor, width: 6)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                    child: Icon(statusIcon, color: statusColor, size: 28),
                  ),
                  const SizedBox(width: 16),

                  // Text Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_weather!.locationName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Text(_weather!.condition, style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            const SizedBox(width: 8),
                            Text(
                              '降雨率 ${_weather!.rainProbability}%',
                              style: TextStyle(
                                color: isRainy ? statusColor : Colors.grey[600],
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Badge
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        badgeText,
                        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
