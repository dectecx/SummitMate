import 'dart:async';
import 'package:hive/hive.dart';
import '../../models/message.dart';
import '../interfaces/i_message_repository.dart';
import '../../../core/error/result.dart';
import 'mock_itinerary_repository.dart';

/// 模擬留言資料庫
/// 用於教學模式，返回靜態假資料，所有寫入操作皆為空實作。
class MockMessageRepository implements IMessageRepository {
  /// 模擬留言資料
  final List<Message> _mockMessages = [
    Message(
      id: 'mock-msg-001',
      tripId: MockItineraryRepository.mockTripId,
      parentId: null,
      user: 'Admin',
      category: 'Chat',
      content: '歡迎使用 SummitMate！這是行程協作留言板。',
      avatar: '🤖',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      createdBy: 'Admin',
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedBy: 'Admin',
    ),
    Message(
      id: 'mock-msg-002',
      tripId: MockItineraryRepository.mockTripId,
      parentId: null,
      user: '小明',
      category: 'Chat',
      content: '大家好！期待這次的登山之旅～',
      avatar: '🐻',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      createdAt: DateTime.now().subtract(const Duration(hours: 1)),
      createdBy: '小明',
      updatedAt: DateTime.now().subtract(const Duration(hours: 1)),
      updatedBy: '小明',
    ),
    Message(
      id: 'mock-msg-003',
      tripId: MockItineraryRepository.mockTripId,
      parentId: 'mock-msg-002',
      user: '小華',
      category: 'Chat',
      content: '我也是！裝備都準備好了',
      avatar: '🐰',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
      createdBy: '小華',
      updatedAt: DateTime.now().subtract(const Duration(minutes: 30)),
      updatedBy: '小華',
    ),
  ];

  @override
  Future<Result<void, Exception>> init() async => const Success(null);

  @override
  Future<Result<List<Message>, Exception>> getAllMessages() async => Success(List.unmodifiable(_mockMessages));

  @override
  Future<Result<List<Message>, Exception>> getMessagesByCategory(String category) async =>
      Success(_mockMessages.where((msg) => msg.category == category).toList());

  @override
  Future<Result<List<Message>, Exception>> getMainMessages({String? category}) async => Success(
    _mockMessages.where((msg) => msg.parentId == null && (category == null || msg.category == category)).toList(),
  );

  @override
  Future<Result<List<Message>, Exception>> getReplies(String parentId) async =>
      Success(_mockMessages.where((msg) => msg.parentId == parentId).toList());

  @override
  Future<Result<Message?, Exception>> getById(String id) async =>
      Success(_mockMessages.cast<Message?>().firstWhere((msg) => msg?.id == id, orElse: () => null));

  @override
  Future<Result<void, Exception>> addMessage(Message message) async => const Success(null);

  @override
  Future<Result<void, Exception>> deleteById(String id) async => const Success(null);

  @override
  Future<Result<void, Exception>> syncFromCloud(List<Message> cloudMessages) async => const Success(null);

  @override
  Future<Result<List<Message>, Exception>> getPendingMessages(Set<String> cloudIds) async => const Success([]);

  @override
  Stream<BoxEvent> watchAllMessages() => const Stream.empty();

  @override
  Future<Result<void, Exception>> saveLastSyncTime(DateTime time) async => const Success(null);

  @override
  Future<Result<DateTime?, Exception>> getLastSyncTime() async => Success(DateTime.now());

  @override
  Future<Result<void, Exception>> sync(String tripId) async => const Success(null);

  @override
  Future<Result<void, Exception>> clearAll() async => const Success(null);
}
