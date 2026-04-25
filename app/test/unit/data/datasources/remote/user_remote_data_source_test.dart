import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/api/models/user_api_models.dart';
import 'package:summitmate/data/api/services/user_api_service.dart';
import 'package:summitmate/data/datasources/remote/user_remote_data_source.dart';
import 'package:summitmate/data/models/user_profile.dart';

class MockUserApiService extends Mock implements UserApiService {}
class FakeUserUpdateRequest extends Fake implements UserUpdateRequest {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUserUpdateRequest());
  });

  late UserRemoteDataSource dataSource;
  late MockUserApiService mockUserApi;

  setUp(() {
    mockUserApi = MockUserApiService();
    dataSource = UserRemoteDataSource(mockUserApi);
  });

  final testUserResponse = UserResponse.fromJson({
    'id': 'user-1',
    'email': 'test@example.com',
    'display_name': 'Test User',
    'avatar': '🐻',
    'role': 'member',
    'permissions': [],
    'is_verified': true,
  });

  group('UserRemoteDataSource', () {
    test('searchUserByEmail returns mapped user', () async {
      when(() => mockUserApi.searchUserByEmail('test@example.com'))
          .thenAnswer((_) async => testUserResponse);

      final result = await dataSource.searchUserByEmail('test@example.com');

      expect(result.id, 'user-1');
      expect(result.email, 'test@example.com');
      verify(() => mockUserApi.searchUserByEmail('test@example.com')).called(1);
    });

    test('getUserById returns mapped user', () async {
      when(() => mockUserApi.getUserById('user-1'))
          .thenAnswer((_) async => testUserResponse);

      final result = await dataSource.getUserById('user-1');

      expect(result.id, 'user-1');
      verify(() => mockUserApi.getUserById('user-1')).called(1);
    });

    test('getCurrentUser returns mapped user', () async {
      when(() => mockUserApi.getCurrentUser())
          .thenAnswer((_) async => testUserResponse);

      final result = await dataSource.getCurrentUser();

      expect(result.id, 'user-1');
      verify(() => mockUserApi.getCurrentUser()).called(1);
    });

    test('updateProfile returns mapped updated user', () async {
      when(() => mockUserApi.updateProfile(any()))
          .thenAnswer((_) async => testUserResponse);

      final profile = UserProfile(
        id: 'user-1',
        email: 'test@example.com',
        displayName: 'New Name',
      );

      final result = await dataSource.updateProfile(profile);

      expect(result.id, 'user-1');
      verify(() => mockUserApi.updateProfile(any())).called(1);
    });
  });
}
