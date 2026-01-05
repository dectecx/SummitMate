import 'package:flutter/material.dart';
import '../../../services/interfaces/i_geolocator_service.dart';
import '../../../core/di.dart';
import '../../../services/interfaces/i_weather_service.dart';
import '../../../services/log_service.dart';
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
      final weather = await weatherService.getWeatherByCoordinates(position.latitude, position.longitude);

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

    // Hide if loading takes too long or just show nothing?
    // Show nothing if loading to avoid clutter, or a small loader?
    // User requested "Alert", so maybe only show if there IS an alert or data?
    // Let's show a compact card.

    // Debugging: Show Loading and Error states
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(
          child: Text('取得天氣資訊中...', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    if (_error != null) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Center(
          child: Text('⚠️ 天氣載入失敗: $_error', style: const TextStyle(color: Colors.red)),
        ),
      );
    }

    if (_weather == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: Text('無天氣資料')),
      );
    }

    // Check Alert Conditions
    final isRainy = _weather!.rainProbability >= 60 || _weather!.condition.contains('雨');
    final isHighAlert = _weather!.rainProbability >= 80;

    // Logic: Only show if there is something "interesting"?
    // Or show "Current Location Weather" always?
    // Let's show always for MVP verification, but style it differently.

    final alertColor = isHighAlert ? Colors.red : (isRainy ? Colors.orange : Colors.blueGrey);
    final icon = isRainy ? Icons.umbrella : Icons.wb_sunny;

    return Dismissible(
      key: const Key('weather_alert'),
      direction: DismissDirection.horizontal,
      onDismissed: (_) {
        // Allow user to dismiss for session
        setState(() => _isVisible = false);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: alertColor.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: alertColor.withValues(alpha: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: alertColor, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '目前位置: ${_weather!.locationName}',
                      style: TextStyle(fontWeight: FontWeight.bold, color: alertColor),
                    ),
                    Text(
                      '${_weather!.condition}  |  降雨機率 ${_weather!.rainProbability}%',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              if (isRainy)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: alertColor, borderRadius: BorderRadius.circular(12)),
                  child: const Text(
                    '注意',
                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
