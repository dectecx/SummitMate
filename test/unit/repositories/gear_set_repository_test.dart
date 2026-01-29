import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/core/error/result.dart';
import 'package:summitmate/data/datasources/interfaces/i_gear_key_local_data_source.dart';
import 'package:summitmate/data/models/gear_set.dart';
import 'package:summitmate/data/models/gear_item.dart';
import 'package:summitmate/data/models/gear_key_record.dart';
import 'package:summitmate/data/repositories/gear_set_repository.dart';
import 'package:summitmate/domain/interfaces/i_gear_cloud_service.dart';

class MockGearCloudService extends Mock implements IGearCloudService {}

class MockGearKeyLocalDataSource extends Mock implements IGearKeyLocalDataSource {}

void main() {
  late GearSetRepository repository;
  late MockGearCloudService mockRemoteDataSource;
  late MockGearKeyLocalDataSource mockLocalDataSource;

  setUp(() {
    mockRemoteDataSource = MockGearCloudService();
    mockLocalDataSource = MockGearKeyLocalDataSource();
    repository = GearSetRepository(remoteDataSource: mockRemoteDataSource, localDataSource: mockLocalDataSource);
  });

  group('GearSetRepository', () {
    const tKey = '1234';
    final tGearSet = GearSet(
      id: 'id1',
      title: 'Test Set',
      author: 'User',
      totalWeight: 100,
      itemCount: 1,
      visibility: GearSetVisibility.public,
      items: [],
      uploadedAt: DateTime.now(),
      createdAt: DateTime.now(),
      createdBy: 'User',
      updatedAt: DateTime.now(),
      updatedBy: 'User',
    );
    final tException = Exception('Test Error');

    group('getGearSets', () {
      test('should return list of GearSet when remote call is successful', () async {
        // Arrange
        when(() => mockRemoteDataSource.getGearSets()).thenAnswer((_) async => Success([tGearSet]));

        // Act
        final result = await repository.getGearSets();

        // Assert
        expect(result, isA<Success<List<GearSet>, Exception>>());
        expect((result as Success<List<GearSet>, Exception>).value, [tGearSet]);
        verify(() => mockRemoteDataSource.getGearSets()).called(1);
      });

      test('should return Failure when remote call fails', () async {
        // Arrange
        when(() => mockRemoteDataSource.getGearSets()).thenAnswer((_) async => Failure(tException));

        // Act
        final result = await repository.getGearSets();

        // Assert
        expect(result, isA<Failure<List<GearSet>, Exception>>());
        expect((result as Failure).exception, tException);
        verify(() => mockRemoteDataSource.getGearSets()).called(1);
      });
    });

    group('downloadGearSet', () {
      test('should return GearSet when successful', () async {
        // Arrange
        when(() => mockRemoteDataSource.downloadGearSet('uuid', key: tKey)).thenAnswer((_) async => Success(tGearSet));

        // Act
        final result = await repository.downloadGearSet('uuid', key: tKey);

        // Assert
        expect(result, isA<Success<GearSet, Exception>>());
        expect((result as Success).value, tGearSet);
        verify(() => mockRemoteDataSource.downloadGearSet('uuid', key: tKey)).called(1);
      });
    });

    group('uploadGearSet', () {
      final tItems = [GearItem(name: 'Item', weight: 10, category: 'Cat')];

      test('should call remoteDataSource with correct parameters', () async {
        // Arrange
        when(
          () => mockRemoteDataSource.uploadGearSet(
            tripId: 'trip1',
            title: 'Title',
            author: 'Author',
            visibility: GearSetVisibility.public,
            items: tItems,
            meals: null,
            key: null,
          ),
        ).thenAnswer((_) async => Success(tGearSet));

        // Act
        await repository.uploadGearSet(
          tripId: 'trip1',
          title: 'Title',
          author: 'Author',
          visibility: GearSetVisibility.public,
          items: tItems,
        );

        // Assert
        verify(
          () => mockRemoteDataSource.uploadGearSet(
            tripId: 'trip1',
            title: 'Title',
            author: 'Author',
            visibility: GearSetVisibility.public,
            items: tItems,
            meals: null,
            key: null,
          ),
        ).called(1);
      });
    });

    group('Key Management (Local)', () {
      final tRecords = [GearKeyRecord(key: '1234', title: 'Test', visibility: 'public', uploadedAt: DateTime.now())];

      test('getUploadedKeys should delegates to localDataSource', () async {
        when(() => mockLocalDataSource.getUploadedKeys()).thenAnswer((_) async => tRecords);

        final result = await repository.getUploadedKeys();

        expect(result, tRecords);
        verify(() => mockLocalDataSource.getUploadedKeys()).called(1);
      });

      test('saveUploadedKey should delegates to localDataSource', () async {
        when(() => mockLocalDataSource.saveUploadedKey(any(), any(), any())).thenAnswer((_) async {});

        await repository.saveUploadedKey('k', 't', 'v');

        verify(() => mockLocalDataSource.saveUploadedKey('k', 't', 'v')).called(1);
      });
    });
  });
}
