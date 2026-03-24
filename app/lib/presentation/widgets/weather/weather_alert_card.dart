import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/theme.dart';
import '../../../core/di/injection.dart';
import '../../cubits/settings/settings_cubit.dart';
import '../../cubits/settings/settings_state.dart';

import 'package:summitmate/infrastructure/infrastructure.dart';
import '../../../data/models/weather_data.dart';

class WeatherAlertCard extends StatefulWidget {
  final bool animate;
  const WeatherAlertCard({super.key, this.animate = true});

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

    return BlocBuilder<SettingsCubit, SettingsState>(
      builder: (context, state) {
        AppThemeType currentThemeType = AppThemeType.nature;
        if (state is SettingsLoaded) {
          currentThemeType = state.settings.theme;
        }

        final strategy = AppTheme.getStrategy(currentThemeType);

        // 載入中狀態
        if (_isLoading) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
          );
        }

        // 錯誤狀態
        if (_error != null) {
          final errorColor = strategy.errorColor;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: errorColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: errorColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.error_outline, color: errorColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('無法取得天氣資訊: $_error', style: TextStyle(color: errorColor)),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: errorColor),
                  onPressed: _fetchWeather,
                ),
              ],
            ),
          );
        }

        if (_weather == null) {
          final infoColor = strategy.infoColor;
          return Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: infoColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: infoColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.cloud_off, color: infoColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('暫無天氣資料', style: TextStyle(color: infoColor)),
                ),
                IconButton(
                  icon: Icon(Icons.refresh, color: infoColor),
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
          statusColor = strategy.errorColor;
          statusIcon = Icons.warning_amber_rounded;
          badgeText = '豪雨特報';
        } else if (isRainy) {
          statusColor = strategy.warningColor;
          statusIcon = Icons.umbrella;
          badgeText = '攜帶雨具';
        } else {
          statusColor = strategy.infoColor;
          statusIcon = Icons.wb_sunny_outlined;
          badgeText = null;
        }

        // Icon widget
        Widget iconWidget = Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(statusIcon, color: statusColor, size: 28),
        );

        if (widget.animate) {
          iconWidget = iconWidget
              .animate(onPlay: (controller) => controller.repeat(reverse: true))
              .shimmer(duration: 1200.ms, color: Colors.white.withValues(alpha: 0.2))
              .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2000.ms);
        }

        // Badge widget
        Widget? badgeWidget;
        if (badgeText != null) {
          badgeWidget = Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: statusColor, borderRadius: BorderRadius.circular(20)),
            child: Text(
              badgeText,
              style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          );
          if (widget.animate) {
            badgeWidget = badgeWidget.animate().scale(delay: 400.ms, duration: 400.ms, curve: Curves.easeOutBack);
          }
        }

        // Content Row
        Widget content = Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              iconWidget,
              const SizedBox(width: 16),
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
              if (badgeWidget != null) badgeWidget,
            ],
          ),
        );

        // Main Container
        Widget mainContainer = Container(
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
              child: content,
            ),
          ),
        );

        if (widget.animate) {
          mainContainer = mainContainer.animate().fadeIn(duration: 600.ms).slideX(begin: 0.2, end: 0, curve: Curves.easeOutQuad);
        }

        return Dismissible(
          key: const Key('weather_alert'),
          direction: DismissDirection.horizontal,
          onDismissed: (_) {
            setState(() => _isVisible = false);
          },
          child: mainContainer,
        );
      },
    );
  }
}
