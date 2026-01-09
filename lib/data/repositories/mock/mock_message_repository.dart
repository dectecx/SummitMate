import 'dart:async';
import 'package:hive/hive.dart';
import '../../models/message.dart';
import '../interfaces/i_message_repository.dart';
import 'mock_itinerary_repository.dart';

/// 模擬留言資料庫
/// 用於教學模式，返回靜態假資料，所有寫入操作皆為空實作。
class MockMessageRepository implements IMessageRepository {
  /// 模擬留言資料
  final List<Message> _mockMessages = [
    Message(
      uuid: 'mock-msg-001',
      tripId: MockItineraryRepository.mockTripId,
      parentId: null,
      user: 'Admin',
      category: 'Chat',
      content: '歡迎使用 SummitMate！這是行程協作留言板。',
      avatar: '🤖',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    Message(
      uuid: 'mock-msg-002',
      tripId: MockItineraryRepository.mockTripId,
      parentId: null,
      user: '小明',
      category: 'Chat',
      content: '大家好！期待這次的登山之旅～',
      avatar: '🐻',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
    ),
    Message(
      uuid: 'mock-msg-003',
      tripId: MockItineraryRepository.mockTripId,
      parentId: 'mock-msg-002',
      user: '小華',
      category: 'Chat',
      content: '我也是！裝備都準備好了',
      avatar: '🐰',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  @override
  Future<void> init() async {}

  @override
  List<Message> getAllMessages() => List.unmodifiable(_mockMessages);

  @override
  List<Message> getMessagesByCategory(String category) =>
      _mockMessages.where((msg) => msg.category == category).toList();

  @override
  List<Message> getMainMessages({String? category}) =>
      _mockMessages.where((msg) => msg.parentId == null && (category == null || msg.category == category)).toList();

  @override
  List<Message> getReplies(String parentUuid) => _mockMessages.where((msg) => msg.parentId == parentUuid).toList();

  @override
  Message? getByUuid(String uuid) =>
      _mockMessages.cast<Message?>().firstWhere((msg) => msg?.uuid == uuid, orElse: () => null);

  @override
  Future<void> addMessage(Message message) async {}

  @override
  Future<void> deleteByUuid(String uuid) async {}

  @override
  Future<void> syncFromCloud(List<Message> cloudMessages) async {}

  @override
  List<Message> getPendingMessages(Set<String> cloudUuids) => [];

  @override
  Stream<BoxEvent> watchAllMessages() => const Stream.empty();

  @override
  Future<void> saveLastSyncTime(DateTime time) async {}

  @override
  DateTime? getLastSyncTime() => DateTime.now();

  @override
  Future<void> sync(String tripId) async {}

  @override
  Future<void> clearAll() async {}
}
