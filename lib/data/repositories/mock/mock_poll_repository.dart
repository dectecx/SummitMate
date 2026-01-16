import '../../models/poll.dart';
import '../interfaces/i_poll_repository.dart';
import '../../../core/error/result.dart';

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
      ],
    ),
  ];

  // ========== Init ==========

  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  // ========== Data Operations ==========

  @override
  List<Poll> getAll() => List.from(_mockPolls);

  @override
  Poll? getById(String id) {
    try {
      return _mockPolls.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveAll(List<Poll> polls) async {}

  @override
  Future<void> save(Poll poll) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Future<Result<void, Exception>> clearAll() async => const Success(null);

  // ========== Sync Operations ==========

  @override
  Future<Result<void, Exception>> sync({required String userId}) async => const Success(null);

  @override
  DateTime? getLastSyncTime() => DateTime.now();

  // ========== Remote Write Operations ==========

  @override
  Future<Result<String, Exception>> create({
    required String title,
    String description = '',
    required String creatorId,
    DateTime? deadline,
    bool isAllowAddOption = false,
    int maxOptionLimit = 20,
    bool allowMultipleVotes = false,
    List<String> initialOptions = const [],
  }) async => const Success('mock-new-poll-id');

  @override
  Future<Result<void, Exception>> vote({
    required String pollId,
    required List<String> optionIds,
    required String userId,
    String userName = 'Anonymous',
  }) async => const Success(null);

  @override
  Future<Result<void, Exception>> addOption({
    required String pollId,
    required String text,
    required String creatorId,
  }) async => const Success(null);

  @override
  Future<Result<void, Exception>> close({required String pollId, required String userId}) async =>
      const Success(null);

  @override
  Future<Result<void, Exception>> remove({required String pollId, required String userId}) async =>
      const Success(null);

  @override
  Future<Result<void, Exception>> removeOption({required String optionId, required String userId}) async =>
      const Success(null);
}
