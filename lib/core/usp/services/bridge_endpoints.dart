/// Endpoint configuration for [UspBridgeClient].
///
/// Allows switching between local usp-bridge and remote Guardian proxy
/// endpoints without changing the client implementation.
class BridgeEndpoints {
  final String notifications;
  final String subscription;
  final String health;
  final String turboPrefix;

  const BridgeEndpoints({
    required this.notifications,
    required this.subscription,
    required this.health,
    required this.turboPrefix,
  });

  /// Local usp-bridge endpoints (on-router).
  static const local = BridgeEndpoints(
    notifications: '/api/v1/notifications',
    subscription: '/api/v1/subscription',
    health: '/api/v1/health',
    turboPrefix: '/api/v1/turbo',
  );

  /// Remote Guardian proxy endpoints.
  static BridgeEndpoints remote(String sessionId) => BridgeEndpoints(
        notifications:
            '/v1/guardians/remote-assistances/sessions/$sessionId/usp/notifications',
        subscription:
            '/v1/guardians/remote-assistances/sessions/$sessionId/usp/subscriptions',
        health:
            '/v1/guardians/remote-assistances/sessions/$sessionId/usp/health',
        turboPrefix:
            '/v1/guardians/remote-assistances/sessions/$sessionId/usp/turbo',
      );
}

/// The read-only endpoints that exist on the Guardian proxy and **nowhere else**.
///
/// A separate, optional table rather than three more `required` fields on
/// [BridgeEndpoints], and the reason is the type system rather than tidiness:
/// these are the first endpoints with no local counterpart at all. The
/// on-router usp-bridge keeps no notification store — Guardian persists notifies
/// to DynamoDB, the router forgets them the moment they are published — so there
/// is nothing a local path here could point at. `null` is the local answer, and
/// it is a fact the type carries rather than a placeholder path nobody would
/// ever call.
///
/// That distinction is not theoretical. `BridgeEndpoints.remote()`'s `health`
/// path was given the same treatment in reverse — declared as if it were real,
/// then never called — and three docstrings and a test comment spent a release
/// cycle asserting that Guardian did not serve it. Guardian served it all along
/// (#1576).
///
/// Session-scoped, with one exception worth knowing before reading the values:
/// [state] is *per device*, not per session, so it is the one read here whose
/// answer outlives the session that asked. The path still carries the session id
/// because that is how the proxy authorises the read.
class RemoteReads {
  /// One record per device — `deviceUuid`, `lastBoot`, `lastUspActivity`, as
  /// camelCase JSON with epoch-**millisecond** timestamps.
  ///
  /// Both timestamps `null` is a normal `200`, not a `404`: it means the device
  /// has produced nothing yet. The device need not be online.
  final String state;

  /// This session's notification metadata, newest first, **unpaged** and
  /// carrying no `body`.
  ///
  /// Session-scoped, so an empty list at session start is the normal state
  /// rather than a fault.
  final String notificationsHistory;

  /// Base the per-entry read appends a `msgId` to. Not a path on its own.
  final String _notificationsBase;

  /// Base the results read appends its required query parameter to. Not a path on
  /// its own — `commandKey` has no default and the endpoint rejects a bare call.
  final String _resultsBase;

  const RemoteReads({
    required this.state,
    required this.notificationsHistory,
    required String notificationsBase,
    required String resultsBase,
  })  : _notificationsBase = notificationsBase,
        _resultsBase = resultsBase;

  /// One notification including its `body`.
  ///
  /// A `404` here covers both "does not exist" and "is not yours", and the spec
  /// says so deliberately — do not try to tell them apart.
  ///
  /// `msgId` can never usefully be the literal `history`: that route wins on the
  /// server, so such a request answers with the list. Nothing needs to guard it;
  /// no id the client holds came from anywhere but [notificationsHistory].
  String notification(String msgId) => '$_notificationsBase/$msgId';

  /// Every stored result for one `commandKey` — a **bare array**, newest first, one
  /// row per execution (#1578).
  ///
  /// This is the recovery path for a diagnostic whose push never arrived: Guardian
  /// publishes that signal **at most once and never retries it**, so a signal lost to
  /// a reconnect is otherwise unrecoverable. **The device does not need to be
  /// online**, which is the whole point — the device having dropped is a likely
  /// reason the push went missing.
  ///
  /// An empty array is a normal `200` and **is not worth retrying**: the index is a
  /// strongly-consistent LSI, so "not there" is an answer rather than a race. Do not
  /// build a retry loop on it, and do not poll — the server already polls DynamoDB on
  /// our behalf.
  ///
  /// `commandKey` is percent-encoded because it reaches us from a JSON response and
  /// is echoed into a query string; the UUIDs Guardian mints need no escaping today,
  /// which is exactly why an unescaped interpolation would survive review and break on
  /// the first key that does.
  String results(String commandKey) =>
      '$_resultsBase?commandKey=${Uri.encodeQueryComponent(commandKey)}';

  /// The reads for one Remote Assistance session.
  ///
  /// A factory rather than a const, for the same reason
  /// [BridgeEndpoints.remote] is: every path embeds the session id, so a
  /// refactor that hoisted this to a `static const` could only compile by
  /// dropping the interpolation.
  static RemoteReads forSession(String sessionId) {
    const prefix = '/v1/guardians/remote-assistances/sessions';
    return RemoteReads(
      state: '$prefix/$sessionId/usp/state',
      notificationsHistory: '$prefix/$sessionId/usp/notifications/history',
      notificationsBase: '$prefix/$sessionId/usp/notifications',
      resultsBase: '$prefix/$sessionId/usp/results',
    );
  }
}
