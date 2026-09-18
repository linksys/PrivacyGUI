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

  const RemoteReads({
    required this.state,
    required this.notificationsHistory,
    required String notificationsBase,
  }) : _notificationsBase = notificationsBase;

  /// One notification including its `body`.
  ///
  /// A `404` here covers both "does not exist" and "is not yours", and the spec
  /// says so deliberately — do not try to tell them apart.
  ///
  /// `msgId` can never usefully be the literal `history`: that route wins on the
  /// server, so such a request answers with the list. Nothing needs to guard it;
  /// no id the client holds came from anywhere but [notificationsHistory].
  String notification(String msgId) => '$_notificationsBase/$msgId';

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
    );
  }
}
