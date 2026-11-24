import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:summitmate/features/friends/data/friends_api.dart';
import 'package:summitmate/features/friends/providers.dart';
import 'package:summitmate/features/members/data/user_search_api.dart';
import 'package:summitmate/features/members/domain/member_logic.dart';
import 'package:summitmate/features/members/providers.dart';

import 'events_fakes.dart';
import 'harness.dart';

class FakeFriends implements FriendsApi {
  FakeFriends({List<Friend>? friends, List<FriendRequest>? incoming, List<FriendRequest>? outgoing})
    : friends = friends ?? [],
      incoming = incoming ?? [],
      outgoing = outgoing ?? [];
  final List<Friend> friends;
  final List<FriendRequest> incoming;
  final List<FriendRequest> outgoing;
  final sent = <String>[];
  final log = <String>[];

  @override
  Future<FriendsOverview> overview() async => FriendsOverview(friends: [...friends], incoming: [...incoming], outgoing: [...outgoing]);

  @override
  Future<FriendRequestResult> sendRequest(String userId) async {
    sent.add(userId);
    outgoing.add(FriendRequest(id: 'r-$userId', user: Friend(userId: userId, displayName: 'X', avatar: '🙂')));
    return FriendRequestResult.pending;
  }

  @override
  Future<void> accept(String requestId) async {
    log.add('accept $requestId');
    final r = incoming.firstWhere((r) => r.id == requestId);
    incoming.remove(r);
    friends.add(r.user);
  }

  @override
  Future<void> dismiss(String requestId) async {
    log.add('dismiss $requestId');
    incoming.removeWhere((r) => r.id == requestId);
    outgoing.removeWhere((r) => r.id == requestId);
  }

  @override
  Future<void> unfriend(String userId) async {
    log.add('unfriend $userId');
    friends.removeWhere((f) => f.userId == userId);
  }
}

class FakeSearchUsers implements UserSearchApi {
  @override
  Future<List<FoundUser>> findByEmail(String email) async =>
      email == 'bob@x.co' ? [const FoundUser(id: 'bob-id', displayName: 'Bob', avatar: '🦊')] : [];
}

Future<AppHarness> start(WidgetTester tester, FakeFriends api, {FakeEventsApi? events}) => startEvents(
  tester,
  events ?? FakeEventsApi(),
  signedIn: true,
  overrides: [friendsApiProvider.overrideWithValue(api), userSearchApiProvider.overrideWithValue(FakeSearchUsers())],
);

void main() {
  testWidgets('requests are answered on the friends page and friends can be removed', (tester) async {
    final api = FakeFriends(
      friends: [const Friend(userId: 'f1', displayName: 'Fay', avatar: '🐻')],
      incoming: [const FriendRequest(id: 'in1', user: Friend(userId: 'c1', displayName: 'Cara', avatar: '🐱'))],
      outgoing: [const FriendRequest(id: 'out1', user: Friend(userId: 'd1', displayName: 'Dan', avatar: '🐶'))],
    );
    final app = await start(tester, api);
    await tapText(tester, '我');
    await tapText(tester, '好友');
    await settleUntil(tester, find.byKey(const ValueKey('incoming-c1')));
    expect(find.text('想加你為好友'), findsOneWidget);
    expect(find.text('等待對方接受'), findsOneWidget);

    await tester.tap(find.byTooltip('接受'));
    await settle(tester);
    expect(api.log, ['accept in1']);
    expect(find.byKey(const ValueKey('friend-c1')), findsOneWidget);
    expect(find.byKey(const ValueKey('incoming-c1')), findsNothing);

    await tester.tap(find.text('收回'));
    await settle(tester);
    expect(api.log.last, 'dismiss out1');

    await tester.tap(find.byTooltip('管理 Fay'));
    await settle(tester);
    await tapText(tester, '移除好友');
    await tapText(tester, '移除');
    await settle(tester);
    expect(api.log.last, 'unfriend f1');
    expect(find.byKey(const ValueKey('friend-f1')), findsNothing);
    await app.dispose(tester);
  });

  testWidgets('adding a friend by e-mail sends one request that waits for the other side', (tester) async {
    final api = FakeFriends();
    final app = await start(tester, api);
    await tapText(tester, '我');
    await tapText(tester, '好友');
    await settleUntil(tester, find.byKey(const ValueKey('add-friend')));
    await tester.tap(find.byKey(const ValueKey('add-friend')));
    await settle(tester);
    await tester.enterText(find.byKey(const ValueKey('friend-email')), 'nobody@x.co');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    expect(find.textContaining('找不到這個 Email'), findsOneWidget);

    await tester.enterText(find.byKey(const ValueKey('friend-email')), 'bob@x.co');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await settle(tester);
    await tester.tap(find.byKey(const ValueKey('send-friend-request')));
    await settle(tester);
    expect(api.sent, ['bob-id']);
    expect(find.textContaining('已送出邀請'), findsOneWidget);
    await app.dispose(tester);
  });

  testWidgets('a person met in a group event can be added as a friend from the event page', (tester) async {
    final api = FakeFriends();
    final events = FakeEventsApi(events: [ev('e1', '嘉明湖三日')]);
    final app = await start(tester, api, events: events);
    await openEvents(tester);
    await openEvent(tester, 'e1');
    await settleUntil(tester, find.byKey(const ValueKey('add-friend-host-id')));
    await tester.tap(find.byKey(const ValueKey('add-friend-host-id')));
    await settle(tester);
    expect(api.sent, ['host-id']);
    expect(find.byKey(const ValueKey('friend-pending-host-id')), findsOneWidget);
    await app.dispose(tester);
  });
}
