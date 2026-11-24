import 'package:dio/dio.dart';

import '../../members/domain/member_logic.dart';

/// A person in the friends lists.
class Friend {
  const Friend({required this.userId, required this.displayName, required this.avatar});
  final String userId;
  final String displayName;
  final String avatar;

  FoundUser toFoundUser() => FoundUser(id: userId, displayName: displayName, avatar: avatar);
}

/// A pending request. [user] is the other person (the sender for incoming, the receiver for outgoing).
class FriendRequest {
  const FriendRequest({required this.id, required this.user});
  final String id;
  final Friend user;
}

class FriendsOverview {
  const FriendsOverview({this.friends = const [], this.incoming = const [], this.outgoing = const []});
  final List<Friend> friends;
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;

  bool isFriend(String userId) => friends.any((f) => f.userId == userId);
  bool hasOutgoingTo(String userId) => outgoing.any((r) => r.user.userId == userId);
  bool hasIncomingFrom(String userId) => incoming.any((r) => r.user.userId == userId);
}

enum FriendRequestResult { pending, accepted }

class FriendsException implements Exception {
  const FriendsException({required this.code, this.status = 0});
  final String code;
  final int status;

  bool get isNetwork => code == 'network';

  String get text => switch (code) {
    'network' => '需要連線，請檢查網路後再試。',
    'unauthorized' => '請先登入。',
    'cannot_friend_self' => '不能加自己為好友。',
    'user_not_found' => '找不到這個人。',
    'too_many_pending_requests' => '已送出的邀請太多，請等對方回覆或先收回幾個。',
    'friend_request_not_found' => '這個邀請已不存在，請重新整理。',
    'forbidden' => '這個操作不被允許。',
    'too_many_requests' || 'http_429' => '送出太頻繁，請稍後再試。',
    _ => '操作失敗，請稍後再試。',
  };
}

/// The friends API (online only; friends are shared between two accounts, so they are not synced offline).
abstract interface class FriendsApi {
  Future<FriendsOverview> overview();
  Future<FriendRequestResult> sendRequest(String userId);
  Future<void> accept(String requestId);

  /// The addressee declines, or the sender cancels.
  Future<void> dismiss(String requestId);
  Future<void> unfriend(String userId);
}

class DioFriendsApi implements FriendsApi {
  DioFriendsApi(this._dio);
  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw const FriendsException(code: 'network');
      final data = res.data;
      final status = res.statusCode ?? 0;
      throw FriendsException(
        status: status,
        code: data is Map && data['code'] is String ? data['code'] as String : (status == 401 ? 'unauthorized' : 'http_$status'),
      );
    }
  }

  static Friend _person(Object? j) {
    final m = (j as Map).cast<String, dynamic>();
    return Friend(
      userId: (m['user_id'] ?? m['id']) as String,
      displayName: (m['display_name'] as String?) ?? '',
      avatar: (m['avatar'] as String?) ?? '',
    );
  }

  static List<FriendRequest> _requests(Object? j) => [
    for (final r in (j as List? ?? const [])) FriendRequest(id: (r as Map)['request_id'] as String, user: _person(r['user'])),
  ];

  @override
  Future<FriendsOverview> overview() => _run(() async {
    final res = await _dio.get<Map<String, dynamic>>('/friends');
    final d = res.data ?? const {};
    return FriendsOverview(
      friends: [for (final f in (d['friends'] as List? ?? const [])) _person(f)],
      incoming: _requests(d['incoming']),
      outgoing: _requests(d['outgoing']),
    );
  });

  @override
  Future<FriendRequestResult> sendRequest(String userId) => _run(() async {
    final res = await _dio.post<Map<String, dynamic>>('/friends/requests', data: {'user_id': userId});
    return res.data?['status'] == 'accepted' ? FriendRequestResult.accepted : FriendRequestResult.pending;
  });

  @override
  Future<void> accept(String requestId) => _run(() => _dio.post<Object?>('/friends/requests/$requestId/accept'));

  @override
  Future<void> dismiss(String requestId) => _run(() => _dio.delete<Object?>('/friends/requests/$requestId'));

  @override
  Future<void> unfriend(String userId) => _run(() => _dio.delete<Object?>('/friends/$userId'));
}
