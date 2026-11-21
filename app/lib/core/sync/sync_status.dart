import '../auth/auth_state.dart';

/// The one thing the UI shows about syncing. Derived, never stored.
sealed class SyncStatus {
  const SyncStatus();
}

/// Guest: data is only on this device.
class GuestLocalOnly extends SyncStatus {
  const GuestLocalOnly();
}

class Synced extends SyncStatus {
  const Synced();
}

class Syncing extends SyncStatus {
  const Syncing();
}

/// [count] changes are waiting to upload.
class Pending extends SyncStatus {
  const Pending(this.count);
  final int count;
}

/// Same as [Pending] but there is currently no connection.
class Offline extends SyncStatus {
  const Offline(this.pending);
  final int pending;
}

/// [count] changes were rejected by the server and need the person's decision.
class Failed extends SyncStatus {
  const Failed(this.count);
  final int count;
}

class SessionExpired extends SyncStatus {
  const SessionExpired();
}

SyncStatus computeSyncStatus({
  required AuthState auth,
  required int pending,
  required int failed,
  required bool syncing,
  required bool online,
}) {
  switch (auth) {
    case Guest():
      return const GuestLocalOnly();
    case NeedsReauth():
      return const SessionExpired();
    case SignedIn():
      if (syncing) return const Syncing();
      if (failed > 0) return Failed(failed);
      if (pending > 0) return online ? Pending(pending) : Offline(pending);
      return const Synced();
  }
}
