import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:summitmate/core/di.dart';
import 'package:summitmate/data/models/weather_data.dart';
import 'package:summitmate/presentation/widgets/weather/weather_alert_card.dart';
import 'package:summitmate/services/interfaces/i_weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:summitmate/services/interfaces/i_geolocator_service.dart';

// Manual Fake implementation
class FakeGeolocatorService implements IGeolocatorService {
  @override
  Future<Position> getCurrentPosition() async {
    return Position(
      latitude: 23.5,
      longitude: 121.0,
      timestamp: DateTime.now(),
      accuracy: 0.0,
      altitude: 0.0,
      heading: 0.0,
      speed: 0.0,
      speedAccuracy: 0.0,
      altitudeAccuracy: 0.0,
      headingAccuracy: 0.0,
    );
  }
}

// Manual Fake implementation to avoid Mockito overhead
class FakeWeatherService implements IWeatherService {
  WeatherData? _mockResponse;

  void setMockResponse(WeatherData data) {
    _mockResponse = data;
  }

  @override
  Future<WeatherData?> getWeatherByCoordinates(double lat, double lon) async {
    return _mockResponse;
  }

  // Implement other methods if required by interface, returning null or throw
  @override
  Future<void> init() async {}

  @override
  Future<WeatherData> fetchWeather({String locationName = '向陽山'}) async {
    if (_mockResponse != null) return _mockResponse!;
    throw Exception('Mock response not set');
  }

  @override
  Future<WeatherData?> getWeather({bool forceRefresh = false, String locationName = '向陽山'}) async {
    return _mockResponse;
  }
}

void main() {
  final fakeWeatherService = FakeWeatherService();
  final fakeGeolocatorService = FakeGeolocatorService();

  setUpAll(() {
    GetIt.I.registerSingleton<IWeatherService>(fakeWeatherService);
    GetIt.I.registerSingleton<IGeolocatorService>(fakeGeolocatorService);
  });

  tearDownAll(() {
    GetIt.I.reset();
  });

  Widget createWidgetUnderTest() {
    return const MaterialApp(home: Scaffold(body: WeatherAlertCard()));
  }

  testWidgets('WeatherAlertCard displays info correctly for high rain probability', (WidgetTester tester) async {
    // Arrange
    fakeWeatherService.setMockResponse(
      WeatherData(
        temperature: 25.0,
        humidity: 80.0,
        rainProbability: 65,
        windSpeed: 10.0,
        condition: '陰短暫雨',
        sunrise: DateTime.now(),
        sunset: DateTime.now(),
        timestamp: DateTime.now(),
        locationName: '測試鄉鎮',
        dailyForecasts: [],
        apparentTemperature: 28.0,
        issueTime: DateTime.now(),
      ),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('目前位置: 測試鄉鎮'), findsOneWidget);
    expect(find.textContaining('降雨機率 65%'), findsOneWidget);
    expect(find.text('注意'), findsOneWidget);
    expect(find.byIcon(Icons.umbrella), findsOneWidget);
  });

  testWidgets('WeatherAlertCard displays red alert for critical rain probability', (WidgetTester tester) async {
    // Arrange
    fakeWeatherService.setMockResponse(
      WeatherData(
        temperature: 25.0,
        humidity: 90.0,
        rainProbability: 85,
        windSpeed: 20.0,
        condition: '豪雨',
        sunrise: DateTime.now(),
        sunset: DateTime.now(),
        timestamp: DateTime.now(),
        locationName: '危險鄉鎮',
        dailyForecasts: [],
        apparentTemperature: 28.0,
        issueTime: DateTime.now(),
      ),
    );

    // Act
    await tester.pumpWidget(createWidgetUnderTest());
    await tester.pumpAndSettle();

    // Assert
    expect(find.text('目前位置: 危險鄉鎮'), findsOneWidget);
    expect(find.text('注意'), findsOneWidget);
  });
}
