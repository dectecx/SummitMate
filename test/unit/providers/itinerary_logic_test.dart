import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/models/itinerary_item.dart';
import 'package:summitmate/data/repositories/itinerary_repository.dart';
import 'package:summitmate/presentation/providers/itinerary_provider.dart';

// Mock
class MockItineraryRepository extends Mock implements ItineraryRepository {}

void main() {
  late ItineraryProvider provider;
  late MockItineraryRepository mockRepo;

  setUp(() async {
    mockRepo = MockItineraryRepository();
    await GetIt.I.reset();
    GetIt.I.registerSingleton<ItineraryRepository>(mockRepo);

    // Default mock behavior
    when(() => mockRepo.getAllItems()).thenReturn([]);
    registerFallbackValue(DateTime.now());
  });

  group('ItineraryProvider Logic Tests', () {
    test('should calculate progress correctly', () {
      // Arrange
      final items = [
        ItineraryItem(day: 'D1', name: 'A', estTime: '08:00', altitude: 100, distance: 1.0, note: '')
          ..actualTime = DateTime.now(), // Checked
        ItineraryItem(day: 'D1', name: 'B', estTime: '09:00', altitude: 200, distance: 2.0, note: ''), // Unchecked
        ItineraryItem(day: 'D2', name: 'C', estTime: '10:00', altitude: 300, distance: 3.0, note: ''), // Unchecked
      ];
      when(() => mockRepo.getAllItems()).thenReturn(items);

      provider = ItineraryProvider();

      // Act
      final progress = provider.progress;

      // Assert
      expect(progress, equals(1 / 3)); // 0.333...
    });

    test('progress should be 0 when empty', () {
      when(() => mockRepo.getAllItems()).thenReturn([]);
      provider = ItineraryProvider();
      expect(provider.progress, equals(0));
    });

    test('currentTarget should return first unchecked item of selected day', () {
      // Arrange
      final d1Items = [
        ItineraryItem(day: 'D1', name: 'A', estTime: '08:00', altitude: 100, distance: 1.0, note: '')
          ..actualTime = DateTime.now(),
        ItineraryItem(day: 'D1', name: 'B', estTime: '09:00', altitude: 200, distance: 2.0, note: ''),
      ];
      final d2Items = [ItineraryItem(day: 'D2', name: 'C', estTime: '10:00', altitude: 300, distance: 3.0, note: '')];

      when(() => mockRepo.getAllItems()).thenReturn([...d1Items, ...d2Items]);

      provider = ItineraryProvider();
      provider.selectDay('D1');

      // Act
      final target = provider.currentTarget;

      // Assert
      expect(target?.name, 'B');
    });

    test('checkIn should call repository and reload', () async {
      // Arrange
      final item = ItineraryItem(day: 'D1', name: 'A', estTime: '08:00', altitude: 100, distance: 1.0, note: '');
      when(() => mockRepo.getAllItems()).thenReturn([item]);
      when(() => mockRepo.checkIn(any(), any())).thenAnswer((_) async {});

      provider = ItineraryProvider();

      // Act
      await provider.checkIn(item.key, DateTime.now());

      // Assert
      verify(() => mockRepo.checkIn(any(), any())).called(1);
      verify(() => mockRepo.getAllItems()).called(2); // Init + Reload
    });

    test('reload should just reload items', () {
      when(() => mockRepo.getAllItems()).thenReturn([]);
      provider = ItineraryProvider();

      clearInteractions(mockRepo);
      provider.reload();

      verify(() => mockRepo.getAllItems()).called(1);
    });
  });
}
