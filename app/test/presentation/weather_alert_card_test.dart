import 'dart:async';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:summitmate/data/models/weather_data.dart';
import 'package:summitmate/presentation/widgets/weather/weather_alert_card.dart';
import 'package:summitmate/domain/interfaces/i_weather_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:summitmate/domain/interfaces/i_geolocator_service.dart';
import 'package:summitmate/presentation/cubits/settings/settings_cubit.dart';
import 'package:summitmate/presentation/cubits/settings/settings_state.dart';
import 'package:summitmate/domain/domain.dart';
import 'package:summitmate/core/theme/theme_types.dart';

// Mocks
class MockSettingsCubit extends MockCubit<SettingsState> implements SettingsCubit {}

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
  final _controller = StreamController<WeatherData?>.broadcast();

  void setMockResponse(WeatherData data) {
    _mockResponse = data;
    _controller.add(data);
  }

  @override
  Future<void> init() async {}

  @override
  Future<WeatherData?> getWeatherByName(String locationName, {bool forceRefresh = false}) async {
    return _mockResponse;
  }

  @override
  Future<WeatherData?> getWeatherByLocation(double lat, double lon, {bool forceRefresh = false}) async {
    return _mockResponse;
  }

  @override
  Stream<WeatherData?> get onWeatherChanged => _controller.stream;
}

void main() {
  final fakeWeatherService = FakeWeatherService();
  final fakeGeolocatorService = FakeGeolocatorService();
  late MockSettingsCubit mockSettingsCubit;

  setUpAll(() {
    GetIt.I.registerSingleton<IWeatherService>(fakeWeatherService);
    GetIt.I.registerSingleton<IGeolocatorService>(fakeGeolocatorService);
  });

  tearDownAll(() {
    GetIt.I.reset();
  });

  setUp(() {
    mockSettingsCubit = MockSettingsCubit();
    when(() => mockSettingsCubit.state).thenReturn(
      SettingsLoaded(
        settings: Settings(username: 'Test User', theme: AppThemeType.nature),
        hasSeenOnboarding: true,
      ),
    );
  });

  Widget createWidgetUnderTest() {
    return MaterialApp(
      home: Scaffold(
        body: BlocProvider<SettingsCubit>.value(
          value: mockSettingsCubit,
          child: const WeatherAlertCard(animate: false),
        ),
      ),
    );
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
    await tester.pump();

    // Assert
    expect(find.text('測試鄉鎮'), findsOneWidget);
    expect(find.textContaining('降雨率 65%'), findsOneWidget);
    expect(find.text('攜帶雨具'), findsOneWidget);
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
    await tester.pump();

    // Assert
    expect(find.text('危險鄉鎮'), findsOneWidget);
    expect(find.text('豪雨特報'), findsOneWidget);
  });
}
