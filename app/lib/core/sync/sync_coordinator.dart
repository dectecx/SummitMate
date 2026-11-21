// ignore_for_file: prefer_initializing_formals

import 'dart:async';

import '../auth/auth_state.dart';
import 'outbox_counts.dart';
import 'sync_engine.dart';

/// Decides when to call [SyncEngine.sync]: on sign-in, foreground, regained connectivity, newly
/// queued local changes, after a transient failure (with backoff) and on demand.
///
/// At most one run is active at a time; triggers that arrive meanwhile collapse into a single
/// follow-up run.
class SyncCoordinator {
  SyncCoordinator({
    required SyncEngine engine,
    required Stream<AuthState> auth,
    required Stream<OutboxCounts> outbox,
    required Stream<bool> online,
    required Stream<void> resumed,
    this.debounce = const Duration(seconds: 1),
    this.onError,
  }) : _engine = engine {
    _subs.addAll([
      auth.listen(_onAuth, onError: _report),
      outbox.listen(_onOutbox, onError: _report),
      online.listen(_onOnline, onError: _report),
      resumed.listen((_) => _request(), onError: _report),
    ]);
  }

  final SyncEngine _engine;
  final Duration debounce;

  /// Receives exceptions thrown by the engine or by an input stream.
  final void Function(Object error, StackTrace stack)? onError;

  final _subs = <StreamSubscription<Object?>>[];
  final _waiters = <Completer<void>>[];
  Timer? _debounceTimer;
  Timer? _retryTimer;

  bool _signedIn = false;
  bool _online = true;
  int? _pending;
  bool _running = false;
  bool _queued = false;
  bool _disposed = false;

  /// Pull-to-refresh: forgets the backoff and syncs now. Completes when the run (and any
  /// follow-up it coalesced) is done; completes at once when syncing is not possible.
  Future<void> refresh() {
    if (_disposed) return Future.value();
    _engine.resetBackoff();
    if (!_signedIn) return Future.value();
    final done = Completer<void>();
    _waiters.add(done);
    _request();
    return done.future;
  }

  void _onAuth(AuthState state) {
    final wasSignedIn = _signedIn;
    _signedIn = state is SignedIn;
    if (_signedIn) {
      if (!wasSignedIn) _request();
    } else {
      // Guest or needs re-login: nothing to retry until the person signs in.
      _stopPending();
    }
  }

  void _onOutbox(OutboxCounts counts) {
    final previous = _pending;
    _pending = counts.pending;
    if (previous == null || counts.pending <= previous) return;
    if (!_signedIn) return;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(debounce, () {
      _debounceTimer = null;
      _request();
    });
  }

  void _onOnline(bool online) {
    final regained = online && !_online;
    _online = online;
    if (!regained) return;
    _engine.resetBackoff();
    _request();
  }

  /// Starts a run now, or marks that one more is needed after the active run.
  void _request() {
    if (_disposed || !_signedIn) return;
    _debounceTimer?.cancel();
    _debounceTimer = null;
    if (_running) {
      _queued = true;
      return;
    }
    _runLoop();
  }

  Future<void> _runLoop() async {
    _running = true;
    try {
      do {
        _queued = false;
        _retryTimer?.cancel();
        _retryTimer = null;
        SyncOutcome? outcome;
        try {
          outcome = await _engine.sync();
        } catch (e, st) {
          // Not retried by timer (it may be permanent); the next trigger tries again.
          _report(e, st);
        }
        if (_disposed) return;
        switch (outcome) {
          case SyncOutcome.needsReauth:
            _stopPending();
          case SyncOutcome.retryLater:
            if (_signedIn && !_queued) _retryTimer = Timer(_engine.retryDelay, _request);
          case SyncOutcome.success || SyncOutcome.skipped || null:
            break;
        }
        if (!_signedIn) _queued = false;
      } while (_queued && !_disposed);
    } finally {
      _running = false;
      _completeWaiters();
    }
  }

  void _stopPending() {
    _debounceTimer?.cancel();
    _debounceTimer = null;
    _retryTimer?.cancel();
    _retryTimer = null;
    _queued = false;
  }

  void _completeWaiters() {
    final waiters = List.of(_waiters);
    _waiters.clear();
    for (final w in waiters) {
      if (!w.isCompleted) w.complete();
    }
  }

  void _report(Object error, StackTrace stack) => onError?.call(error, stack);

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _stopPending();
    final cancels = [for (final s in _subs) s.cancel()];
    _subs.clear();
    await Future.wait(cancels);
    _completeWaiters();
  }
}
