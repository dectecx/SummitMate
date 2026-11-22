import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/db/app_database.dart';
import '../../trips/domain/trip_logic.dart';
import '../../trips/providers.dart';
import '../domain/weather_models.dart';
import '../providers.dart';

/// Label and icon for a WMO weather code.
({String label, IconData icon}) describeWeather(int code) => switch (code) {
  0 => (label: '晴', icon: Icons.wb_sunny_outlined),
  1 || 2 => (label: '晴時多雲', icon: Icons.wb_cloudy_outlined),
  3 => (label: '陰', icon: Icons.cloud_outlined),
  45 || 48 => (label: '霧', icon: Icons.foggy),
  >= 51 && <= 57 => (label: '毛毛雨', icon: Icons.grain),
  >= 61 && <= 67 => (label: '雨', icon: Icons.umbrella_outlined),
  >= 71 && <= 77 || 85 || 86 => (label: '雪', icon: Icons.ac_unit),
  >= 80 && <= 82 => (label: '陣雨', icon: Icons.shower_outlined),
  >= 95 && <= 99 => (label: '雷雨', icon: Icons.thunderstorm_outlined),
  _ => (label: '—', icon: Icons.help_outline),
};

/// Forecast for the first itinerary node that has coordinates.
class WeatherCard extends ConsumerWidget {
  const WeatherCard({super.key, required this.trip});
  final Trip trip;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(itineraryProvider(trip.id)).value ?? const <ItineraryItem>[];
    final query = weatherLocationOf(items);
    final theme = Theme.of(context);

    Widget body;
    if (query == null) {
      body = const Text('在行程節點選擇山岳地點後，這裡就會顯示該地的天氣預報。');
    } else {
      body = PlaceWeather(query: query, from: trip.start, to: trip.end);
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('天氣預報', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            body,
          ],
        ),
      ),
    );
  }
}

/// The forecast for a place, with the days between [from] and [to] (the trip) highlighted.
class PlaceWeather extends ConsumerWidget {
  const PlaceWeather({super.key, required this.query, this.from, this.to});
  final WeatherQuery query;
  final DateTime? from;
  final DateTime? to;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (ref.watch(weatherProvider(query)).value) {
      null || WeatherLoading() => const Padding(padding: EdgeInsets.all(8), child: Center(child: CircularProgressIndicator())),
      WeatherNeedsLogin() => const Text('登入後可以查看天氣預報。'),
      WeatherUnavailable() => const Text('目前無法取得天氣，請稍後再試。'),
      WeatherData(:final forecast, :final stale, :final refreshFailed) => _Forecast(query: query, from: from, to: to, forecast: forecast, stale: stale, refreshFailed: refreshFailed),
    };
  }
}

class _Forecast extends StatelessWidget {
  const _Forecast({required this.query, required this.from, required this.to, required this.forecast, required this.stale, required this.refreshFailed});
  final DateTime? from;
  final DateTime? to;
  final WeatherQuery query;
  final WeatherForecast forecast;
  final bool stale;
  final bool refreshFailed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final updated = forecast.fetchedAt.toLocal();
    final place = '${query.lat.toStringAsFixed(2)}, ${query.lng.toStringAsFixed(2)}${query.elevation == null ? '' : '，海拔 ${query.elevation} m'}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(place, style: theme.textTheme.bodySmall),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: forecast.daily.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final d = forecast.daily[i];
              final w = describeWeather(d.weatherCode);
              final inTrip = from != null && to != null && !d.date.isBefore(from!) && !d.date.isAfter(to!);
              return Container(
                key: ValueKey('weather-${formatDate(d.date)}'),
                width: 92,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: inTrip ? scheme.primaryContainer : scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text('${d.date.month}/${d.date.day}', style: theme.textTheme.labelLarge),
                    const SizedBox(height: 6),
                    Icon(w.icon),
                    Text(w.label, style: theme.textTheme.bodySmall),
                    const SizedBox(height: 6),
                    Text('${d.tempMin.round()}° / ${d.tempMax.round()}°', style: theme.textTheme.titleSmall),
                    Text(d.rainChance == null ? '${d.rainMm.toStringAsFixed(0)} mm' : '降雨 ${d.rainChance}%', style: theme.textTheme.bodySmall),
                    Text('風 ${d.windMax.round()} km/h', style: theme.textTheme.bodySmall),
                  ],
                ),
              );
            },
          ),
        ),
        Text(
          refreshFailed
              ? '無法更新，顯示 ${updated.month}/${updated.day} ${_hm(updated)} 的預報'
              : stale
              ? '更新中…（上次 ${updated.month}/${updated.day} ${_hm(updated)}）'
              : '更新於 ${_hm(updated)}',
          style: theme.textTheme.bodySmall,
        ),
        if (from != null && to != null && !forecast.daily.any((d) => !d.date.isBefore(from!) && !d.date.isAfter(to!)))
          Padding(padding: const EdgeInsets.only(top: 4), child: Text('行程日期還不在預報範圍內，以上是接下來幾天的天氣。', style: theme.textTheme.bodySmall)),
      ],
    );
  }

  static String _hm(DateTime t) => '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}
