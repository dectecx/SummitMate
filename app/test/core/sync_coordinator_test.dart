import 'dart:async';

// ignore: depend_on_referenced_packages
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:summitmate/core/auth/auth_state.dart';
import 'package:summitmate/core/db/app_database.dart';
import 'package:summitmate/core/sync/sync_coordinator.dart';
import 'package:summitmate/core/sync/sync_engine.dart';

import 'support.dart';

const _user = AuthUser(id: 'u1', email: 'a@x.co', displayName: 'A', avatar: '');

/// An engine whose outcomes are scripted; it follows the real backoff rules for failures.
class ScriptedEngine extends SyncEngine {
  ScriptedEngine(AppDatabase db) : super(db: db, api: FakeServer(), gate: FakeGate());

  final outcomes = <Object>[]; // SyncOutcome or an exception to throw
  Duration runTime = Duration.zero;
  int calls = 0;
  int resets = 0;
  int failures = 0;
  int maxConcurrent = 0;
  int _active = 0;

  @override
  Duration get retryDelay => SyncEngine.backoffFor(failures);
  @override
  void resetBackoff() {
    resets++;
    failures = 0;
  }

  @override
  Future<SyncOutcome> sync() async {
    calls++;
    _active++;
    if (_active > maxConcurrent) maxConcurrent = _active;
    try {
      if (runTime > Duration.zero) await Future<void>.delayed(runTime);
      final next = outcomes.isEmpty ? SyncOutcome.success : outcomes.removeAt(0);
      if (next is SyncOutcome) {
        if (next == SyncOutcome.retryLater) {
          failures++;
        } else if (next == SyncOutcome.success) {
          failures = 0;
        }
        return next;
      }
      failures++;
      throw next;
    } finally {
      _active--;
    }
  }
}

class Harness {
  Harness(this.engine, {Duration debounce = const Duration(seconds: 1)}) {
    coordinator = SyncCoordinator(
      engine: engine,
      auth: auth.stream,
      outbox: outbox.stream,
      online: online.stream,
      resumed: resumed.stream,
      debounce: debounce,
      onError: (e, st) => errors.add(e),
    );
  }

  final ScriptedEngine engine;
  final auth = StreamController<AuthState>.broadcast(sync: true);
  final outbox = StreamController<OutboxCountsAlias>.broadcast(sync: true);
  final online = StreamController<bool>.broadcast(sync: true);
  final resumed = StreamController<void>.broadcast(sync: true);
  final errors = <Object>[];
  late final SyncCoordinator coordinator;

  void signIn() => auth.add(const SignedIn(_user));
  void pending(int n) => outbox.add((pending: n, failed: 0));
}

typedef OutboxCountsAlias = ({int pending, int failed});

void main() {
  late AppDatabase db;
  late ScriptedEngine engine;

  setUp(() {
    db = memoryDb();
    engine = ScriptedEngine(db);
  });
  tearDown(() => db.close());

  void flush(FakeAsync async, [Duration d = Duration.zero]) {
    async.elapse(d);
    async.flushMicrotasks();
  }

  test('syncs when the auth state becomes SignedIn, including on startup', () {
    fakeAsync((async) {
      final h = Harness(engine);
      flush(async);
      expect(engine.calls, 0);
      h.auth.add(const Guest());
      flush(async);
      expect(engine.calls, 0);
      h.signIn();
      flush(async);
      expect(engine.calls, 1);
      // A repeated SignedIn (profile update) is not a new sign-in.
      h.signIn();
      flush(async);
      expect(engine.calls, 1);
      h.coordinator.dispose();
    });
  });

  test('does nothing for guests and for NeedsReauth', () {
    fakeAsync((async) {
      final h = Harness(engine);
      h.auth.add(const Guest());
      h.resumed.add(null);
      h.online.add(false);
      h.online.add(true);
      h.pending(0);
      h.pending(5);
      flush(async, const Duration(minutes: 1));
      expect(engine.calls, 0);
      h.auth.add(const NeedsReauth(_user));
      h.resumed.add(null);
      flush(async, const Duration(minutes: 1));
      expect(engine.calls, 0);
      h.coordinator.dispose();
    });
  });

  test('syncs when the app returns to the foreground', () {
    fakeAsync((async) {
      final h = Harness(engine);
      h.signIn();
      flush(async);
      h.resumed.add(null);
      flush(async);
      expect(engine.calls, 2);
      h.coordinator.dispose();
    });
  });

  test('syncs and resets the backoff when connectivity is regained', () {
    fakeAsync((async) {
      final h = Harness(engine);
      h.signIn();
      flush(async);
      h.online.add(true); // still online: not a regain
      flush(async);
      expect(engine.calls, 1);
      expect(engine.resets, 0);
      h.online.add(false);
      flush(async);
      expect(engine.calls, 1);
      h.online.add(true);
      flush(async);
      expect(engine.calls, 2);
      expect(engine.resets, 1);
      h.coordinator.dispose();
    });
  });

  test('regained connectivity replaces a waiting retry with an immediate run', () {
    fakeAsync((async) {
      engine.outcomes.add(SyncOutcome.retryLater);
      final h = Harness(engine);
      h.signIn();
      flush(async);
      expect(engine.calls, 1);
      h.online.add(false);
      h.online.add(true);
      flush(async);
      expect(engine.calls, 2);
      flush(async, const Duration(minutes: 10));
      expect(engine.calls, 2); // the old retry timer was cancelled; success needs none
      h.coordinator.dispose();
    });
  });

  test('syncs after the outbox pending count increases, debounced', () {
    fakeAsync((async) {
      final h = Harness(engine);
      h.pending(0); // baseline
      h.signIn();
      flush(async);
      expect(engine.calls, 1);
      h.pending(1);
      flush(async, const Duration(milliseconds: 999));
      expect(engine.calls, 1);
      flush(async, const Duration(milliseconds: 1));
      expect(engine.calls, 2);
      // A decrease (upload finished) is not a trigger.
      h.pending(0);
      flush(async, const Duration(seconds: 5));
      expect(engine.calls, 2);
      h.coordinator.dispose();
    });
  });

  test('the debounce restarts on every new change and runs once', () {
    fakeAsync((async) {
      final h = Harness(engine);
      h.pending(0);
      h.signIn();
      flush(async);
      for (var i = 1; i <= 10; i++) {
        h.pending(i);
        flush(async, const Duration(milliseconds: 500));
      }
      expect(engine.calls, 1);
      flush(async, const Duration(milliseconds: 500));
      expect(engine.calls, 2);
      h.coordinator.dispose();
    });
  });

  test('a custom debounce duration is honoured', () {
    fakeAsync((async) {
      final h = Harness(engine, debounce: const Duration(milliseconds: 100));
      h.pending(0);
      h.signIn();
      flush(async);
      h.pending(1);
      flush(async, const Duration(milliseconds: 100));
      expect(engine.calls, 2);
      h.coordinator.dispose();
    });
  });

  test('triggers during a run coalesce into exactly one follow-up run', () {
    fakeAsync((async) {
      engine.runTime = const Duration(seconds: 3);
      final h = Harness(engine);
      h.signIn();
      flush(async, const Duration(seconds: 1));
      expect(engine.calls, 1);
      for (var i = 0; i < 10; i++) {
        h.resumed.add(null);
        h.online.add(false);
        h.online.add(true);
      }
      flush(async, const Duration(seconds: 1));
      expect(engine.calls, 1);
      flush(async, const Duration(seconds: 1)); // first run ends, follow-up starts
      expect(engine.calls, 2);
      flush(async, const Duration(seconds: 10));
      expect(engine.calls, 2);
      expect(engine.maxConcurrent, 1);
      h.coordinator.dispose();
    });
  });

  test('many pending-count changes while running yield one follow-up', () {
    fakeAsync((async) {
      engine.runTime = const Duration(seconds: 5);
      final h = Harness(engine);
      h.pending(0);
      h.signIn();
      flush(async);
      for (var i = 1; i <= 20; i++) {
        h.pending(i);
        flush(async, const Duration(milliseconds: 100));
      }
      flush(async, const Duration(seconds: 30));
      expect(engine.calls, 2);
      expect(engine.maxConcurrent, 1);
      h.coordinator.dispose();
    });
  });

  test('retryLater retries with exponential backoff 1s, 2s, 4s', () {
    fakeAsync((async) {
      engine.outcomes.addAll([
        SyncOutcome.retryLater,
        SyncOutcome.retryLater,
        SyncOutcome.retryLater,
        SyncOutcome.success,
      ]);
      final h = Harness(engine);
      h.signIn();
      flush(async);
      expect(engine.calls, 1);
      flush(async, const Duration(milliseconds: 999));
      expect(engine.calls, 1);
      flush(async, const Duration(milliseconds: 1));
      expect(engine.calls, 2);
      flush(async, const Duration(milliseconds: 1999));
      expect(engine.calls, 2);
      flush(async, const Duration(milliseconds: 1));
      expect(engine.calls, 3);
      flush(async, const Duration(milliseconds: 3999));
      expect(engine.calls, 3);
      flush(async, const Duration(milliseconds: 1));
      expect(engine.calls, 4);
      // Success: no more timers.
      flush(async, const Duration(minutes: 30));
      expect(engine.calls, 4);
      h.coordinator.dispose();
    });
  });

  test('a trigger during the wait for a retry runs at once and replaces the timer', () {
    fakeAsync((async) {
      engine.outcomes.addAll([SyncOutcome.retryLater, SyncOutcome.success]);
      final h = Harness(engine);
      h.signIn();
      flush(async);
      flush(async, const Duration(milliseconds: 400));
      h.resumed.add(null);
      flush(async);
      expect(engine.calls, 2);
      flush(async, const Duration(minutes: 5));
      expect(engine.calls, 2);
      h.coordinator.dispose();
    });
  });

  test('needsReauth stops retries', () {
    fakeAsync((async) {
      engine.outcomes.addAll([SyncOutcome.retryLater, SyncOutcome.needsReauth]);
      final h = Harness(engine);
      h.signIn();
      flush(async, const Duration(seconds: 1));
      expect(engine.calls, 2);
      flush(async, const Duration(minutes: 30));
      expect(engine.calls, 2);
      h.coordinator.dispose();
    });
  });

  test('skipped does not schedule a retry', () {
    fakeAsync((async) {
      engine.outcomes.add(SyncOutcome.skipped);
      final h = Harness(engine);
      h.signIn();
      flush(async, const Duration(minutes: 30));
      expect(engine.calls, 1);
      h.coordinator.dispose();
    });
  });

  test('signing out or losing the session cancels a pending retry', () {
    fakeAsync((async) {
      engine.outcomes.add(SyncOutcome.retryLater);
      final h = Harness(engine);
      h.signIn();
      flush(async);
      h.auth.add(const NeedsReauth(_user));
      flush(async, const Duration(minutes: 5));
      expect(engine.calls, 1);
      // Signing in again syncs.
      h.signIn();
      flush(async);
      expect(engine.calls, 2);
      h.coordinator.dispose();
    });
  });

  test('refresh resets the backoff, syncs now and completes after the run', () {
    fakeAsync((async) {
      engine.outcomes.add(SyncOutcome.retryLater);
      engine.runTime = const Duration(seconds: 2);
      final h = Harness(engine);
      h.signIn();
      flush(async, const Duration(seconds: 2));
      expect(engine.failures, 1);
      var done = false;
      h.coordinator.refresh().then((_) => done = true);
      flush(async);
      expect(engine.resets, 1);
      expect(engine.calls, 2);
      expect(done, isFalse);
      flush(async, const Duration(seconds: 2));
      expect(done, isTrue);
      h.coordinator.dispose();
    });
  });

  test('refresh while a run is active queues one follow-up and does not overlap', () {
    fakeAsync((async) {
      engine.runTime = const Duration(seconds: 2);
      final h = Harness(engine);
      h.signIn();
      flush(async);
      h.coordinator.refresh();
      h.coordinator.refresh();
      flush(async, const Duration(seconds: 10));
      expect(engine.calls, 2);
      expect(engine.maxConcurrent, 1);
      h.coordinator.dispose();
    });
  });

  test('refresh for a guest completes immediately without syncing', () {
    fakeAsync((async) {
      final h = Harness(engine);
      var done = false;
      h.coordinator.refresh().then((_) => done = true);
      flush(async);
      expect(done, isTrue);
      expect(engine.calls, 0);
      h.coordinator.dispose();
    });
  });

  test('an engine exception is reported and the coordinator keeps working', () {
    fakeAsync((async) {
      engine.outcomes.add(StateError('boom'));
      final h = Harness(engine);
      h.signIn();
      flush(async, const Duration(minutes: 1));
      expect(h.errors, hasLength(1));
      expect(engine.calls, 1); // no retry timer for an exception
      h.resumed.add(null);
      flush(async);
      expect(engine.calls, 2);
      h.pending(0);
      h.pending(1);
      flush(async, const Duration(seconds: 1));
      expect(engine.calls, 3);
      h.coordinator.dispose();
    });
  });

  test('an engine exception without an onError callback does not escape', () {
    fakeAsync((async) {
      engine.outcomes.add(StateError('boom'));
      final auth = StreamController<AuthState>.broadcast(sync: true);
      final c = SyncCoordinator(
        engine: engine,
        auth: auth.stream,
        outbox: const Stream.empty(),
        online: const Stream.empty(),
        resumed: const Stream.empty(),
      );
      auth.add(const SignedIn(_user));
      flush(async);
      expect(engine.calls, 1);
      c.dispose();
    });
  });

  test('dispose cancels the debounce, the retry timer and the subscriptions', () {
    fakeAsync((async) {
      engine.outcomes.add(SyncOutcome.retryLater);
      final h = Harness(engine);
      h.pending(0);
      h.signIn();
      flush(async);
      h.pending(1); // debounce armed; retry timer armed
      h.coordinator.dispose();
      flush(async, const Duration(minutes: 10));
      expect(engine.calls, 1);
      expect(async.pendingTimers, isEmpty);
      expect(h.auth.hasListener, isFalse);
      expect(h.outbox.hasListener, isFalse);
      expect(h.online.hasListener, isFalse);
      expect(h.resumed.hasListener, isFalse);
      h.signIn();
      h.resumed.add(null);
      flush(async);
      expect(engine.calls, 1);
    });
  });

  test('dispose during a run does not start the queued follow-up', () {
    fakeAsync((async) {
      engine.runTime = const Duration(seconds: 2);
      final h = Harness(engine);
      h.signIn();
      flush(async);
      h.resumed.add(null);
      h.coordinator.dispose();
      flush(async, const Duration(seconds: 10));
      expect(engine.calls, 1);
      expect(async.pendingTimers, isEmpty);
    });
  });
}
