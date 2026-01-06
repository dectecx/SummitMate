import 'package:summitmate/data/models/weather_data.dart';
import 'package:summitmate/services/interfaces/i_weather_service.dart';

class MockWeatherService implements IWeatherService {
  @override
  Future<void> init() async {}

  @override
  Future<WeatherData?> getWeatherByLocation(double lat, double lon, {bool forceRefresh = false}) async {
    return _getMockData();
  }

  @override
  Future<WeatherData?> getWeatherByName(String locationName, {bool forceRefresh = false}) async {
    return _getMockData();
  }

  WeatherData _getMockData() {
    return WeatherData(
      temperature: 20.0,
      apparentTemperature: 18.0,
      humidity: 60.0,
      windSpeed: 2.5,
      condition: '多雲',
      locationName: 'Mock Location',
      sunrise: DateTime.now().copyWith(hour: 6, minute: 0),
      sunset: DateTime.now().copyWith(hour: 18, minute: 0),
      timestamp: DateTime.now(),
      rainProbability: 10,
      issueTime: DateTime.now(),
      dailyForecasts: [
        DailyForecast(
          date: DateTime.now(),
          maxTemp: 22.0,
          minTemp: 18.0,
          dayCondition: '多雲',
          nightCondition: '晴',
          rainProbability: 10,
        ),
        DailyForecast(
          date: DateTime.now().add(const Duration(days: 1)),
          maxTemp: 23.0,
          minTemp: 19.0,
          dayCondition: '晴',
          nightCondition: '晴',
          rainProbability: 0,
        ),
      ],
    );
  }
}
