import 'package:dio/dio.dart';

/// What a group event is about.
enum EventCategory {
  hiking('登山'),
  camping('露營'),
  bouldering('攀岩'),
  other('其他');

  const EventCategory(this.label);
  final String label;

  static EventCategory parse(String? s) => values.firstWhere((v) => v.name == s, orElse: () => EventCategory.other);
}

enum EventStatus {
  open,
  closed,
  cancelled;

  static EventStatus parse(String? s) => values.firstWhere((v) => v.name == s, orElse: () => EventStatus.open);
}

/// A person's application to an event.
enum ApplicationStatus {
  pending,
  approved,
  rejected,
  cancelled;

  static ApplicationStatus? tryParse(String? s) {
    for (final v in values) {
      if (v.name == s) return v;
    }
    return null;
  }
}

/// Which list the event list shows (the `scope` query parameter).
enum EventScope {
  all('全部'),
  upcoming('即將出發'),
  popular('熱門'),
  joined('我參加的'),
  hosting('我主辦的');

  const EventScope(this.label);
  final String label;

  /// The server needs a signed-in person for these.
  bool get needsLogin => this == joined || this == hosting;
}

/// Public profile of a host, applicant or commenter (never an e-mail or account id).
class EventPerson {
  const EventPerson({this.id = '', required this.displayName, required this.avatar});

  /// The person's account id ('' when the server did not send one).
  final String id;
  final String displayName;
  final String avatar;

  factory EventPerson.fromJson(Object? j) {
    final m = j is Map ? j : const {};
    return EventPerson(id: (m['id'] as String?) ?? '', displayName: (m['display_name'] as String?) ?? '', avatar: (m['avatar'] as String?) ?? '');
  }
}

DateTime _time(Object? v) => DateTime.tryParse((v as String?) ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);

class EventSummary {
  const EventSummary({
    required this.id,
    required this.title,
    required this.category,
    required this.location,
    required this.startDate,
    this.endDate,
    required this.maxMembers,
    required this.approvedCount,
    this.pendingCount = 0,
    required this.commentCount,
    required this.status,
    required this.approvalRequired,
    required this.host,
    required this.createdAt,
    this.myStatus,
    required this.isHost,
  });

  final String id;
  final String title;
  final EventCategory category;
  final String location;

  /// YYYY-MM-DD.
  final String startDate;
  final String? endDate;
  final int maxMembers;
  final int approvedCount;

  /// Applications waiting for review; 0 unless the person is the host.
  final int pendingCount;
  final int commentCount;
  final EventStatus status;
  final bool approvalRequired;
  final EventPerson host;
  final DateTime createdAt;
  final ApplicationStatus? myStatus;
  final bool isHost;

  factory EventSummary.fromJson(Map<String, dynamic> j) => EventSummary(
    id: j['id'] as String,
    title: (j['title'] as String?) ?? '',
    category: EventCategory.parse(j['category'] as String?),
    location: (j['location'] as String?) ?? '',
    startDate: ((j['start_date'] as String?) ?? '').split('T').first,
    endDate: (j['end_date'] as String?)?.split('T').first,
    maxMembers: ((j['max_members'] as num?) ?? 0).toInt(),
    approvedCount: ((j['approved_count'] as num?) ?? 0).toInt(),
    pendingCount: ((j['pending_count'] as num?) ?? 0).toInt(),
    commentCount: ((j['comment_count'] as num?) ?? 0).toInt(),
    status: EventStatus.parse(j['status'] as String?),
    approvalRequired: j['approval_required'] != false,
    host: EventPerson.fromJson(j['host']),
    createdAt: _time(j['created_at']),
    myStatus: ApplicationStatus.tryParse(j['my_status'] as String?),
    isHost: j['is_host'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'category': category.name,
    'location': location,
    'start_date': startDate,
    'end_date': endDate,
    'max_members': maxMembers,
    'approved_count': approvedCount,
    'pending_count': pendingCount,
    'comment_count': commentCount,
    'status': status.name,
    'approval_required': approvalRequired,
    'host': {'id': host.id, 'display_name': host.displayName, 'avatar': host.avatar},
    'created_at': createdAt.toUtc().toIso8601String(),
    'my_status': myStatus?.name,
    'is_host': isHost,
  };
}

class EventDetail extends EventSummary {
  const EventDetail({
    required super.id,
    required super.title,
    required super.category,
    required super.location,
    required super.startDate,
    super.endDate,
    required super.maxMembers,
    required super.approvedCount,
    super.pendingCount,
    required super.commentCount,
    required super.status,
    required super.approvalRequired,
    required super.host,
    required super.createdAt,
    super.myStatus,
    required super.isHost,
    this.description = '',
    this.privateMessage,
    this.privateMessageLocked = true,
    this.myRejectionReason,
    this.linkedTripId,
    this.tripSnapshot,
    this.snapshotUpdatedAt,
  });

  final String description;

  /// Null unless the person is the host or approved.
  final String? privateMessage;
  final bool privateMessageLocked;
  final String? myRejectionReason;

  /// Host only.
  final String? linkedTripId;
  final TripSnapshot? tripSnapshot;
  final DateTime? snapshotUpdatedAt;

  factory EventDetail.fromJson(Map<String, dynamic> j) {
    final s = EventSummary.fromJson(j);
    final snap = j['trip_snapshot'];
    final reason = j['my_rejection_reason'] as String?;
    return EventDetail(
      id: s.id,
      title: s.title,
      category: s.category,
      location: s.location,
      startDate: s.startDate,
      endDate: s.endDate,
      maxMembers: s.maxMembers,
      approvedCount: s.approvedCount,
      pendingCount: s.pendingCount,
      commentCount: s.commentCount,
      status: s.status,
      approvalRequired: s.approvalRequired,
      host: s.host,
      createdAt: s.createdAt,
      myStatus: s.myStatus,
      isHost: s.isHost,
      description: (j['description'] as String?) ?? '',
      privateMessage: j['private_message'] as String?,
      privateMessageLocked: j['private_message_locked'] == true,
      myRejectionReason: (reason == null || reason.isEmpty) ? null : reason,
      linkedTripId: j['linked_trip_id'] as String?,
      tripSnapshot: snap is Map ? TripSnapshot.fromJson(snap.cast<String, dynamic>()) : null,
      snapshotUpdatedAt: j['snapshot_updated_at'] == null ? null : _time(j['snapshot_updated_at']),
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    ...super.toJson(),
    'description': description,
    'private_message': privateMessage,
    'private_message_locked': privateMessageLocked,
    'my_rejection_reason': myRejectionReason,
    'linked_trip_id': linkedTripId,
    'trip_snapshot': tripSnapshot?.toJson(),
    'snapshot_updated_at': snapshotUpdatedAt?.toUtc().toIso8601String(),
  };

  /// The same event after a local change (like, application, counts).
  EventDetail copyWith({
    int? commentCount,
    int? approvedCount,
    ApplicationStatus? myStatus,
    bool clearMyStatus = false,
    bool clearRejection = false,
  }) => EventDetail(
    id: id,
    title: title,
    category: category,
    location: location,
    startDate: startDate,
    endDate: endDate,
    maxMembers: maxMembers,
    approvedCount: approvedCount ?? this.approvedCount,
    pendingCount: pendingCount,
    commentCount: commentCount ?? this.commentCount,
    status: status,
    approvalRequired: approvalRequired,
    host: host,
    createdAt: createdAt,
    myStatus: clearMyStatus ? null : (myStatus ?? this.myStatus),
    isHost: isHost,
    description: description,
    privateMessage: privateMessage,
    privateMessageLocked: privateMessageLocked,
    myRejectionReason: clearRejection ? null : myRejectionReason,
    linkedTripId: linkedTripId,
    tripSnapshot: tripSnapshot,
    snapshotUpdatedAt: snapshotUpdatedAt,
  );
}

/// One stop of a [TripSnapshot].
class SnapshotItem {
  const SnapshotItem({required this.day, required this.name, this.time, this.altitude = 0, this.lat, this.lng});
  final int day;
  final String name;

  /// 'HH:mm'.
  final String? time;
  final int altitude;
  final double? lat;
  final double? lng;

  factory SnapshotItem.fromJson(Map<String, dynamic> j) => SnapshotItem(
    day: ((j['day'] as num?) ?? 1).toInt(),
    name: (j['name'] as String?) ?? '',
    time: j['time'] as String?,
    altitude: ((j['altitude'] as num?) ?? 0).toInt(),
    lat: (j['lat'] as num?)?.toDouble(),
    lng: (j['lng'] as num?)?.toDouble(),
  );

  Map<String, dynamic> toJson() => {
    'day': day,
    'name': name,
    'time': time,
    'altitude': altitude,
    'lat': lat,
    'lng': lng,
  };

  @override
  bool operator ==(Object other) =>
      other is SnapshotItem &&
      other.day == day &&
      other.name == name &&
      other.time == time &&
      other.altitude == altitude &&
      other.lat == lat &&
      other.lng == lng;
  @override
  int get hashCode => Object.hash(day, name, time, altitude, lat, lng);
}

/// A simplified copy of a trip, shown to people who are not in it.
class TripSnapshot {
  const TripSnapshot({required this.name, required this.startDate, this.endDate, required this.itinerary});
  final String name;
  final String startDate;
  final String? endDate;
  final List<SnapshotItem> itinerary;

  factory TripSnapshot.fromJson(Map<String, dynamic> j) => TripSnapshot(
    name: (j['name'] as String?) ?? '',
    startDate: ((j['start_date'] as String?) ?? '').split('T').first,
    endDate: (j['end_date'] as String?)?.split('T').first,
    itinerary: [
      for (final i in (j['itinerary'] as List? ?? const [])) SnapshotItem.fromJson((i as Map).cast<String, dynamic>()),
    ],
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'start_date': startDate,
    'end_date': endDate,
    'itinerary': [for (final i in itinerary) i.toJson()],
  };
}

/// An application as the host sees it.
class Application {
  const Application({
    required this.id,
    required this.user,
    required this.status,
    this.message = '',
    required this.createdAt,
  });
  final String id;
  final EventPerson user;
  final ApplicationStatus status;
  final String message;
  final DateTime createdAt;

  factory Application.fromJson(Map<String, dynamic> j) => Application(
    id: j['id'] as String,
    user: EventPerson.fromJson(j['user']),
    status: ApplicationStatus.tryParse(j['status'] as String?) ?? ApplicationStatus.pending,
    message: (j['message'] as String?) ?? '',
    createdAt: _time(j['created_at']),
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': {'id': user.id, 'display_name': user.displayName, 'avatar': user.avatar},
    'status': status.name,
    'message': message,
    'created_at': createdAt.toUtc().toIso8601String(),
  };
}

class EventComment {
  const EventComment({
    required this.id,
    required this.user,
    required this.body,
    required this.createdAt,
    required this.mine,
  });
  final String id;
  final EventPerson user;
  final String body;
  final DateTime createdAt;
  final bool mine;

  factory EventComment.fromJson(Map<String, dynamic> j) => EventComment(
    id: j['id'] as String,
    user: EventPerson.fromJson(j['user']),
    body: (j['body'] as String?) ?? '',
    createdAt: _time(j['created_at']),
    mine: j['mine'] == true,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'user': {'id': user.id, 'display_name': user.displayName, 'avatar': user.avatar},
    'body': body,
    'created_at': createdAt.toUtc().toIso8601String(),
    'mine': mine,
  };
}

class EventPage {
  const EventPage(this.items, this.nextCursor);
  final List<EventSummary> items;
  final String? nextCursor;
}

class CommentPage {
  const CommentPage(this.items, this.nextCursor);
  final List<EventComment> items;
  final String? nextCursor;
}

/// What a report is about.
enum ReportTarget {
  groupEvent('group_event'),
  groupEventComment('group_event_comment');

  const ReportTarget(this.wire);
  final String wire;
}

/// The fields of a group event the host writes (create and update).
class EventInput {
  const EventInput({
    required this.title,
    required this.category,
    this.location = '',
    required this.startDate,
    this.endDate,
    required this.maxMembers,
    this.approvalRequired = true,
    this.description = '',
    this.privateMessage = '',
    this.linkedTripId,
    this.tripSnapshot,
  });

  final String title;
  final EventCategory category;
  final String location;
  final String startDate;
  final String? endDate;
  final int maxMembers;
  final bool approvalRequired;
  final String description;
  final String privateMessage;

  /// Sent only when set; the trip link and snapshot are never cleared by an update.
  final String? linkedTripId;
  final TripSnapshot? tripSnapshot;

  /// Body of an update: like [toJson], but an explicit null clears the end date.
  Map<String, dynamic> toPatchJson() => {...toJson(), 'end_date': endDate};

  Map<String, dynamic> toJson() => {
    'title': title,
    'category': category.name,
    'location': location,
    'start_date': startDate,
    'end_date': ?endDate,
    'max_members': maxMembers,
    'approval_required': approvalRequired,
    'description': description,
    'private_message': privateMessage,
    'linked_trip_id': ?linkedTripId,
    'trip_snapshot': ?tripSnapshot?.toJson(),
  };
}

/// A failed request. [code] is the server's error code, or `network` when the server could not be reached.
class EventsException implements Exception {
  const EventsException({required this.code, this.status = 0, this.message = ''});
  final String code;
  final int status;
  final String message;

  bool get isNetwork => code == 'network';
  bool get needsLogin => code == 'unauthorized';
  bool get notFound => code == 'group_event_not_found';

  /// What to tell the person.
  String get text => switch (code) {
    'network' => '需要連線，請檢查網路後再試。',
    'event_full' => '名額已滿。',
    'registration_closed' => '這個揪團已經不接受報名。',
    'already_applied' => '你已經申請過了。',
    'host_cannot_apply' => '主辦人不需要申請。',
    'not_trip_owner' => '只能連結自己是團長的行程。',
    'invalid_snapshot' => '行程內容太大或格式不正確，無法附上路線預覽。',
    'invalid_review' => '這個申請目前無法審核，請重新整理後再試。',
    'group_event_not_found' => '找不到這個揪團，可能已被取消。',
    'unauthorized' => '請先登入。',
    'forbidden' => '你沒有這個操作的權限。',
    'application_not_found' => '找不到這筆申請，可能已經取消。',
    'comment_not_found' => '找不到這則留言，可能已被刪除。',
    'event_cancelled' => '這個揪團已經取消，不能再修改。',
    'too_many_requests' => '操作太頻繁，請稍後再試。',
    'invalid_title' => '標題長度不符（5 到 200 字）。',
    'invalid_max_members' => '人數上限需在 2 到 100 之間。',
    'invalid_dates' => '日期不正確，結束日期不能早於出發日期。',
    _ => message.isNotEmpty ? message : '發生錯誤（$code）',
  };

  @override
  String toString() => 'EventsException($status $code)';
}

/// The group events API (online only).
abstract interface class EventsApi {
  Future<EventPage> list({required EventScope scope, String q = '', String? cursor, int limit = 20});
  Future<EventDetail> create(EventInput input);
  Future<EventDetail> get(String id);

  /// PATCH the fields in [input] (and [status] when given).
  Future<void> update(String id, {EventInput? input, EventStatus? status});

  /// Cancels the event (status becomes `cancelled`).
  Future<void> cancel(String id);

  /// Applies; returns the resulting status (`approved` straight away when no approval is needed).
  Future<ApplicationStatus> apply(String id, {String message = ''});
  Future<void> cancelApply(String id);
  Future<List<Application>> applications(String id, {ApplicationStatus? status});
  Future<Application> review(String id, String applicationId, {required bool approve, String reason = ''});
  Future<void> removeMember(String id, String applicationId);
  Future<CommentPage> comments(String id, {String? cursor, int limit = 20});
  Future<EventComment> addComment(String id, String body);
  Future<void> deleteComment(String id, String commentId);
  Future<void> report({required ReportTarget target, required String targetId, required String reason});
}

class DioEventsApi implements EventsApi {
  DioEventsApi(this._dio);
  final Dio _dio;

  Future<T> _run<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (e) {
      final res = e.response;
      if (res == null) throw const EventsException(code: 'network');
      final data = res.data;
      final status = res.statusCode ?? 0;
      final code = data is Map && data['code'] is String
          ? data['code'] as String
          : (status == 401 ? 'unauthorized' : 'http_$status');
      throw EventsException(
        status: status,
        code: code,
        message: data is Map && data['message'] is String ? data['message'] as String : '',
      );
    }
  }

  Map<String, dynamic> _map(Object? data) => ((data as Map?) ?? const {}).cast<String, dynamic>();

  @override
  Future<EventPage> list({required EventScope scope, String q = '', String? cursor, int limit = 20}) => _run(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/group-events',
      queryParameters: {'scope': scope.name, if (q.trim().isNotEmpty) 'q': q.trim(), 'limit': limit, 'cursor': ?cursor},
    );
    final data = res.data ?? const {};
    return EventPage([
      for (final s in (data['items'] as List? ?? const [])) EventSummary.fromJson(_map(s)),
    ], data['next_cursor'] as String?);
  });

  @override
  Future<EventDetail> create(EventInput input) => _run(() async {
    final res = await _dio.post<Map<String, dynamic>>('/group-events', data: input.toJson());
    return EventDetail.fromJson(_map(res.data));
  });

  @override
  Future<EventDetail> get(String id) => _run(() async {
    final res = await _dio.get<Map<String, dynamic>>('/group-events/$id');
    return EventDetail.fromJson(_map(res.data));
  });

  @override
  Future<void> update(String id, {EventInput? input, EventStatus? status}) => _run(() async {
    await _dio.patch<void>(
      '/group-events/$id',
      data: {...?input?.toPatchJson(), if (status != null) 'status': status.name},
    );
  });

  @override
  Future<void> cancel(String id) => _run(() async {
    await _dio.delete<void>('/group-events/$id');
  });

  @override
  Future<ApplicationStatus> apply(String id, {String message = ''}) => _run(() async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/group-events/$id/apply',
      data: {if (message.trim().isNotEmpty) 'message': message.trim()},
    );
    return ApplicationStatus.tryParse(_map(res.data)['my_status'] as String?) ?? ApplicationStatus.pending;
  });

  @override
  Future<void> cancelApply(String id) => _run(() async {
    await _dio.delete<void>('/group-events/$id/apply');
  });

  @override
  Future<List<Application>> applications(String id, {ApplicationStatus? status}) => _run(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/group-events/$id/applications',
      queryParameters: {if (status != null) 'status': status.name},
    );
    return [for (final a in (res.data?['items'] as List? ?? const [])) Application.fromJson(_map(a))];
  });

  @override
  Future<Application> review(String id, String applicationId, {required bool approve, String reason = ''}) =>
      _run(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/group-events/$id/applications/$applicationId/review',
          data: {'approve': approve, if (reason.trim().isNotEmpty) 'reason': reason.trim()},
        );
        return Application.fromJson(_map(res.data));
      });

  @override
  Future<void> removeMember(String id, String applicationId) => _run(() async {
    await _dio.delete<void>('/group-events/$id/applications/$applicationId');
  });

  @override
  Future<CommentPage> comments(String id, {String? cursor, int limit = 20}) => _run(() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/group-events/$id/comments',
      queryParameters: {'limit': limit, 'cursor': ?cursor},
    );
    final data = res.data ?? const {};
    return CommentPage([
      for (final c in (data['items'] as List? ?? const [])) EventComment.fromJson(_map(c)),
    ], data['next_cursor'] as String?);
  });

  @override
  Future<EventComment> addComment(String id, String body) => _run(() async {
    final res = await _dio.post<Map<String, dynamic>>('/group-events/$id/comments', data: {'body': body});
    return EventComment.fromJson(_map(res.data));
  });

  @override
  Future<void> deleteComment(String id, String commentId) => _run(() async {
    await _dio.delete<void>('/group-events/$id/comments/$commentId');
  });

  @override
  Future<void> report({required ReportTarget target, required String targetId, required String reason}) =>
      _run(() async {
        await _dio.post<void>(
          '/reports',
          data: {'target_type': target.wire, 'target_id': targetId, 'reason': reason.trim()},
        );
      });
}
