import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:summitmate/data/datasources/remote/poll_remote_data_source.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late PollRemoteDataSource dataSource;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    dataSource = PollRemoteDataSource(mockDio);
  });

  group('PollRemoteDataSource.getPolls', () {
    test('returns list of polls on success', () async {
      final tripId = 'trip-1';
      final responseData = [
        {
          'id': 'poll-1',
          'trip_id': tripId,
          'title': 'Test Poll',
          'description': 'Desc',
          'creator_id': 'user-1',
          'is_allow_add_option': true,
          'max_option_limit': 10,
          'allow_multiple_votes': false,
          'options': [],
          'created_at': '2024-01-01T00:00:00Z',
          'created_by': 'user-1',
          'updated_at': '2024-01-01T00:00:00Z',
          'updated_by': 'user-1',
        },
      ];

      when(() => mockDio.get('/trips/$tripId/polls')).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips/$tripId/polls'),
          data: responseData,
          statusCode: 200,
        ),
      );

      final result = await dataSource.getPolls(tripId);

      expect(result.length, 1);
      expect(result[0].id, 'poll-1');
      expect(result[0].title, 'Test Poll');
    });
  });

  group('PollRemoteDataSource.createPoll', () {
    test('returns new poll ID on success', () async {
      final tripId = 'trip-1';
      when(() => mockDio.post('/trips/$tripId/polls', data: any(named: 'data'))).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/trips/$tripId/polls'),
          data: {
            'id': 'new-poll-id',
            'title': 'New Poll',
            'creator_id': 'u1',
            'created_at': '2024-01-01T00:00:00Z',
            'created_by': 'u1',
            'updated_at': '2024-01-01T00:00:00Z',
            'updated_by': 'u1',
          },
          statusCode: 201,
        ),
      );

      final result = await dataSource.createPoll(
        tripId: tripId,
        title: 'New Poll',
        initialOptions: ['Op 1', 'Op 2'],
      );

      expect(result, 'new-poll-id');
      verify(() => mockDio.post('/trips/$tripId/polls', data: any(named: 'data'))).called(1);
    });
  });

  group('PollRemoteDataSource Operations', () {
    test('voteOption calls post correctly', () async {
      when(
        () => mockDio.post('/trips/t1/polls/p1/options/o1/vote'),
      ).thenAnswer((_) async => Response(requestOptions: RequestOptions(path: '/trips/t1/polls/p1/options/o1/vote'), statusCode: 200));

      await dataSource.voteOption(tripId: 't1', pollId: 'p1', optionId: 'o1');

      verify(() => mockDio.post('/trips/t1/polls/p1/options/o1/vote')).called(1);
    });

    test('addOption calls post correctly', () async {
      when(
        () => mockDio.post('/trips/t1/polls/p1/options', data: any(named: 'data')),
      ).thenAnswer((_) async => Response(
            requestOptions: RequestOptions(path: '/trips/t1/polls/p1/options'),
            data: {
              'id': 'o1',
              'poll_id': 'p1',
              'text': 'New Case',
              'creator_id': 'u1',
              'created_at': '2024-01-01T00:00:00Z',
              'created_by': 'u1',
              'updated_at': '2024-01-01T00:00:00Z',
              'updated_by': 'u1',
            },
            statusCode: 201,
          ));

      await dataSource.addOption(tripId: 't1', pollId: 'p1', text: 'New Case');

      verify(() => mockDio.post('/trips/t1/polls/p1/options', data: {'text': 'New Case'})).called(1);
    });
  });
}
