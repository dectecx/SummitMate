import 'package:uuid/uuid.dart';

/// Namespace of the deterministic poll_votes ids. Must equal the server's `voteNamespace`.
const voteNamespace = 'b3a7d1f4-2c58-4e0a-8f6b-5d1e9c3a7b42';

/// Stands in for the voter's id while nobody is signed in; sign-in re-keys those votes.
const guestVoterId = 'local';

/// The id of [userId]'s vote for [optionId] (uuid v5, same rule as the server).
/// Retracting and voting again therefore revives one row instead of creating a second.
String voteIdFor(String optionId, String userId) =>
    const Uuid().v5(voteNamespace, '$optionId:$userId');
