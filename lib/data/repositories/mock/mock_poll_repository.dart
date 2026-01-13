import '../../models/poll.dart';
import '../interfaces/i_poll_repository.dart';

/// 模擬投票資料庫
/// 用於教學模式，返回靜態假資料，所有寫入操作皆為空實作。
class MockPollRepository implements IPollRepository {
  final List<Poll> _mockPolls = [
    Poll(
      id: 'mock-poll-001',
      title: '晚餐吃什麼？',
      creatorId: 'admin',
      createdAt: DateTime.now().subtract(const Duration(hours: 5)),
      createdBy: 'admin',
      updatedAt: DateTime.now(),
      updatedBy: 'admin',
      options: [
        PollOption(
          id: 'opt-1',
          pollId: 'mock-poll-001',
          text: '泡麵',
          creatorId: 'admin',
          voteCount: 2,
          createdAt: DateTime.now(),
          createdBy: 'admin',
          updatedAt: DateTime.now(),
          updatedBy: 'admin',
        ),
        PollOption(
          id: 'opt-2',
          pollId: 'mock-poll-001',
          text: '乾燥飯',
          creatorId: 'admin',
          voteCount: 1,
          createdAt: DateTime.now(),
          createdBy: 'admin',
          updatedAt: DateTime.now(),
          updatedBy: 'admin',
        ),
        PollOption(
          id: 'opt-3',
          pollId: 'mock-poll-001',
          text: '自熱鍋',
          creatorId: 'admin',
          voteCount: 0,
          createdAt: DateTime.now(),
          createdBy: 'admin',
          updatedAt: DateTime.now(),
          updatedBy: 'admin',
        ),
      ],
    ),
    Poll(
      id: 'mock-poll-002',
      title: '明日出發時間',
      creatorId: 'user-1',
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      createdBy: 'user-1',
      updatedAt: DateTime.now(),
      updatedBy: 'user-1',
      options: [
        PollOption(
          id: 'opt-4',
          pollId: 'mock-poll-002',
          text: '04:00',
          creatorId: 'user-1',
          voteCount: 1,
          createdAt: DateTime.now(),
          createdBy: 'user-1',
          updatedAt: DateTime.now(),
          updatedBy: 'user-1',
        ),
        PollOption(
          id: 'opt-5',
          pollId: 'mock-poll-002',
          text: '05:00',
          creatorId: 'user-1',
          voteCount: 2,
          createdAt: DateTime.now(),
          createdBy: 'user-1',
          updatedAt: DateTime.now(),
          updatedBy: 'user-1',
        ),
        PollOption(
          id: 'opt-6',
          pollId: 'mock-poll-002',
          text: '06:00',
          creatorId: 'user-1',
          voteCount: 1,
          createdAt: DateTime.now(),
          createdBy: 'user-1',
          updatedAt: DateTime.now(),
          updatedBy: 'user-1',
        ),
      ],
    ),
  ];

  @override
  Future<void> init() async {}

  @override
  List<Poll> getAllPolls() => List.from(_mockPolls);

  @override
  Future<void> savePolls(List<Poll> polls) async {}

  @override
  Future<void> clearAll() async {}

  @override
  Future<void> saveLastSyncTime(DateTime time) async {}

  @override
  DateTime? getLastSyncTime() => DateTime.now();
}
