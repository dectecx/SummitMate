import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/core/auth/auth_state.dart';
import 'package:summitmate/core/providers.dart';
import 'package:summitmate/features/events/data/events_api.dart';
import 'package:summitmate/features/events/providers.dart';
import 'package:summitmate/features/trips/providers.dart';

import 'harness.dart';

/// Today in these tests.
final today = DateTime(2026, 11, 22, 9);

const host = EventPerson(displayName: '陳大山', avatar: '🐻');
const anna = EventPerson(displayName: 'Anna', avatar: '🦊');

EventDetail ev(
  String id,
  String title, {
  EventCategory category = EventCategory.hiking,
  String location = '台東海端',
  String start = '2026-12-05',
  String? end,
  int max = 8,
  int approved = 3,
  int likes = 2,
  int comments = 0,
  EventStatus status = EventStatus.open,
  bool approval = true,
  bool liked = false,
  ApplicationStatus? mine,
  bool isHost = false,
  String description = '',
  String privateMessage = '',
  String? rejection,
  String? linkedTripId,
  TripSnapshot? snapshot,
}) => EventDetail(
  id: id,
  title: title,
  category: category,
  location: location,
  startDate: start,
  endDate: end,
  maxMembers: max,
  approvedCount: approved,
  likeCount: likes,
  commentCount: comments,
  status: status,
  approvalRequired: approval,
  host: host,
  createdAt: DateTime.utc(2026, 11, 1),
  liked: liked,
  myStatus: mine,
  isHost: isHost,
  description: description,
  privateMessage: privateMessage.isEmpty ? null : privateMessage,
  privateMessageLocked: privateMessage.isNotEmpty,
  myRejectionReason: rejection,
  linkedTripId: linkedTripId,
  tripSnapshot: snapshot,
);

EventComment cm(String id, String body, {bool mine = false, EventPerson who = anna}) =>
    EventComment(id: id, user: who, body: body, createdAt: DateTime.utc(2026, 11, 2), mine: mine);

Application ap(String id, String name, ApplicationStatus s, {String message = ''}) => Application(
  id: id,
  user: EventPerson(displayName: name, avatar: '🙂'),
  status: s,
  message: message,
  createdAt: DateTime.utc(2026, 11, 3),
);

/// An in-memory server for group events. [events] hold the truth as the signed-in person sees it
/// (the secret message of an event is shown only to its host and approved people, like the real server).
class FakeEventsApi implements EventsApi {
  FakeEventsApi({List<EventDetail>? events}) : events = events ?? [];

  final List<EventDetail> events;
  final Map<String, List<EventComment>> comments_ = {};
  final Map<String, List<Application>> apps = {};
  final Map<String, String> secrets = {};

  /// Page size of the list (to test paging).
  int pageSize = 20;
  bool offline = false;

  /// Thrown (once) by the next write call, if set.
  EventsException? failNext;

  final log = <String>[];
  final listCalls = <({EventScope scope, String q, String? cursor})>[];
  final created = <EventInput>[];
  final updated = <({String id, EventInput? input, EventStatus? status})>[];
  final reports = <({ReportTarget target, String id, String reason})>[];
  final reviews = <({String appId, bool approve, String reason})>[];
  final applyMessages = <String>[];

  void _check() {
    if (offline) throw const EventsException(code: 'network');
  }

  void _write() {
    _check();
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  int _index(String id) {
    final i = events.indexWhere((e) => e.id == id);
    if (i < 0) throw const EventsException(code: 'group_event_not_found', status: 404);
    return i;
  }

  EventDetail _view(EventDetail e) {
    final secret = secrets[e.id] ?? e.privateMessage;
    final visible = e.isHost || e.myStatus == ApplicationStatus.approved;
    final json = e.toJson()
      ..['private_message'] = visible ? (secret ?? '') : null
      ..['private_message_locked'] = !visible;
    return EventDetail.fromJson(json);
  }

  @override
  Future<EventPage> list({required EventScope scope, String q = '', String? cursor, int limit = 20}) async {
    _check();
    listCalls.add((scope: scope, q: q, cursor: cursor));
    var all = events
        .where((e) => e.status != EventStatus.cancelled || scope == EventScope.hosting || scope == EventScope.joined)
        .toList();
    all = switch (scope) {
      EventScope.all => all,
      EventScope.upcoming => all.where((e) => e.startDate.compareTo('2026-11-22') >= 0).toList(),
      EventScope.popular =>
        all..sort((a, b) => (b.likeCount + b.approvedCount).compareTo(a.likeCount + a.approvedCount)),
      EventScope.joined =>
        all.where((e) => e.myStatus == ApplicationStatus.pending || e.myStatus == ApplicationStatus.approved).toList(),
      EventScope.hosting => all.where((e) => e.isHost).toList(),
    };
    if (q.isNotEmpty) all = all.where((e) => e.title.contains(q) || e.location.contains(q)).toList();
    final from = int.tryParse(cursor ?? '') ?? 0;
    final to = (from + pageSize).clamp(0, all.length);
    return EventPage(all.sublist(from, to), to < all.length ? '$to' : null);
  }

  @override
  Future<EventDetail> create(EventInput input) async {
    _write();
    created.add(input);
    final e = ev(
      'new-${created.length}',
      input.title,
      category: input.category,
      location: input.location,
      start: input.startDate,
      end: input.endDate,
      max: input.maxMembers,
      approved: 0,
      likes: 0,
      approval: input.approvalRequired,
      isHost: true,
      description: input.description,
      privateMessage: input.privateMessage,
      linkedTripId: input.linkedTripId,
      snapshot: input.tripSnapshot,
    );
    events.add(e);
    return _view(e);
  }

  @override
  Future<EventDetail> get(String id) async {
    _check();
    log.add('get $id');
    return _view(events[_index(id)]);
  }

  @override
  Future<void> update(String id, {EventInput? input, EventStatus? status}) async {
    _write();
    updated.add((id: id, input: input, status: status));
    final i = _index(id);
    final e = events[i];
    final json = e.toJson();
    if (status != null) json['status'] = status.name;
    if (input != null) {
      json
        ..['title'] = input.title
        ..['category'] = input.category.name
        ..['location'] = input.location
        ..['start_date'] = input.startDate
        ..['end_date'] = input.endDate
        ..['max_members'] = input.maxMembers
        ..['approval_required'] = input.approvalRequired
        ..['description'] = input.description;
      if (input.tripSnapshot != null) json['trip_snapshot'] = input.tripSnapshot!.toJson();
      if (input.linkedTripId != null) json['linked_trip_id'] = input.linkedTripId;
      secrets[id] = input.privateMessage;
    }
    events[i] = EventDetail.fromJson(json);
  }

  @override
  Future<void> cancel(String id) async {
    _write();
    log.add('cancel $id');
    final i = _index(id);
    events[i] = EventDetail.fromJson(events[i].toJson()..['status'] = 'cancelled');
  }

  @override
  Future<ApplicationStatus> apply(String id, {String message = ''}) async {
    _write();
    applyMessages.add(message);
    final i = _index(id);
    final e = events[i];
    if (e.isHost) throw const EventsException(code: 'host_cannot_apply', status: 409);
    if (e.myStatus == ApplicationStatus.pending || e.myStatus == ApplicationStatus.approved) {
      throw const EventsException(code: 'already_applied', status: 409);
    }
    if (e.status != EventStatus.open) throw const EventsException(code: 'registration_closed', status: 409);
    final direct = !e.approvalRequired;
    if (direct && e.approvedCount >= e.maxMembers) throw const EventsException(code: 'event_full', status: 409);
    final s = direct ? ApplicationStatus.approved : ApplicationStatus.pending;
    events[i] = e.copyWith(myStatus: s, approvedCount: direct ? e.approvedCount + 1 : null);
    log.add('apply $id');
    return s;
  }

  @override
  Future<void> cancelApply(String id) async {
    _write();
    final i = _index(id);
    final e = events[i];
    events[i] = e.copyWith(
      myStatus: ApplicationStatus.cancelled,
      approvedCount: e.myStatus == ApplicationStatus.approved ? e.approvedCount - 1 : null,
    );
    log.add('cancelApply $id');
  }

  @override
  Future<List<Application>> applications(String id, {ApplicationStatus? status}) async {
    _check();
    return [
      for (final a in apps[id] ?? const <Application>[])
        if (status == null
            ? (a.status == ApplicationStatus.pending || a.status == ApplicationStatus.approved)
            : a.status == status)
          a,
    ];
  }

  void _setApp(String eventId, String appId, ApplicationStatus s) {
    final list = apps[eventId]!;
    final i = list.indexWhere((a) => a.id == appId);
    final a = list[i];
    list[i] = Application(id: a.id, user: a.user, status: s, message: a.message, createdAt: a.createdAt);
  }

  @override
  Future<Application> review(String id, String applicationId, {required bool approve, String reason = ''}) async {
    _write();
    reviews.add((appId: applicationId, approve: approve, reason: reason));
    final i = _index(id);
    final e = events[i];
    if (approve && e.approvedCount >= e.maxMembers) throw const EventsException(code: 'event_full', status: 409);
    _setApp(id, applicationId, approve ? ApplicationStatus.approved : ApplicationStatus.rejected);
    if (approve) events[i] = e.copyWith(approvedCount: e.approvedCount + 1);
    return apps[id]!.firstWhere((a) => a.id == applicationId);
  }

  @override
  Future<void> removeMember(String id, String applicationId) async {
    _write();
    log.add('remove $applicationId');
    final i = _index(id);
    _setApp(id, applicationId, ApplicationStatus.cancelled);
    events[i] = events[i].copyWith(approvedCount: events[i].approvedCount - 1);
  }

  @override
  Future<CommentPage> comments(String id, {String? cursor, int limit = 20}) async {
    _check();
    return CommentPage(List.of(comments_[id] ?? const []), null);
  }

  @override
  Future<EventComment> addComment(String id, String body) async {
    _write();
    final c = cm(
      'c${(comments_[id]?.length ?? 0) + 1}-new',
      body,
      mine: true,
      who: const EventPerson(displayName: 'Me', avatar: '🙂'),
    );
    (comments_[id] ??= []).add(c);
    final i = _index(id);
    events[i] = events[i].copyWith(commentCount: events[i].commentCount + 1);
    return c;
  }

  @override
  Future<void> deleteComment(String id, String commentId) async {
    _write();
    log.add('deleteComment $commentId');
    comments_[id]!.removeWhere((c) => c.id == commentId);
    final i = _index(id);
    events[i] = events[i].copyWith(commentCount: events[i].commentCount - 1);
  }

  LikeResult _like(String id, bool liked) {
    final i = _index(id);
    final e = events[i];
    final n = e.liked == liked ? e.likeCount : e.likeCount + (liked ? 1 : -1);
    events[i] = e.copyWith(liked: liked, likeCount: n);
    return LikeResult(liked: liked, likeCount: n);
  }

  @override
  Future<LikeResult> like(String id) async {
    _write();
    return _like(id, true);
  }

  @override
  Future<LikeResult> unlike(String id) async {
    _write();
    return _like(id, false);
  }

  @override
  Future<void> report({required ReportTarget target, required String targetId, required String reason}) async {
    _write();
    reports.add((target: target, id: targetId, reason: reason));
  }
}

/// A running app with [api] as the events server. A signed-in person is "Anna" (id-a).
Future<AppHarness> startEvents(
  WidgetTester tester,
  FakeEventsApi api, {
  bool signedIn = false,
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(800, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final app = await AppHarness.start(
    tester,
    welcomeSeen: true,
    seed: (a) => a.addAccount('a@x.co', 'Passw0rd1', name: 'Anna'),
    overrides: [eventsApiProvider.overrideWithValue(api), clockProvider.overrideWithValue(() => today), ...overrides],
  );
  if (signedIn) {
    await real(tester, () => app.container.read(authRepositoryProvider).login(email: 'a@x.co', password: 'Passw0rd1'));
    expect(app.container.read(authRepositoryProvider).state, isA<SignedIn>());
  }
  return app;
}

/// Opens the explore tab on the group events segment.
Future<void> openEvents(WidgetTester tester) async {
  await tapText(tester, '探索');
  await tapText(tester, '揪團');
  await settle(tester);
}

/// Opens an event from the list.
Future<void> openEvent(WidgetTester tester, String id) async {
  await settleUntil(tester, find.byKey(ValueKey('event-$id')));
  await tester.tap(find.byKey(ValueKey('event-$id')));
  await settle(tester);
}

/// Removes a snack bar (it can cover the bottom button of the page).
Future<void> clearSnacks(WidgetTester tester) async {
  ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).clearSnackBars();
  await settle(tester);
}
