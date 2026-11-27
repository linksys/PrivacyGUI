/// A parsed notification payload from an SSE "notification" event.
class SseNotification {
  /// The id the notification arrived under. Not a key to hear by:
  /// - Guardian sends `remote-<id>`, the id `RemoteSseStrategy` registered
  ///   there, so a handler keyed by our id never hears it;
  /// - the local bridge sends the id we registered on 2.0.4.26112521, but
  ///   hands every stream the other sessions' notifications as well, and an
  ///   earlier firmware sent the CPE's own `cpe-N` instead
  ///   (doc/usp/integration/sse_implementation.md §4.1).
  ///
  /// Guardian and 2.0.4.26112521 were measured on 2026-11-26. Read [path] and
  /// [type] to tell which subscription a notification is for — see [isFor].
  final String subscriptionId;
  final String
      type; // "ValueChange", "ObjectCreation", "ObjectDeletion", "OperationComplete"
  final Map<String, dynamic> payload; // Full decoded JSON

  const SseNotification({
    required this.subscriptionId,
    required this.type,
    required this.payload,
  });

  /// The TR-181 path the notification is about, or null for a type that names
  /// none here.
  ///
  /// Each type stores it under a different key:
  /// - ValueChange → `value_change.param_path`
  /// - ObjectCreation → `obj_creation.obj_path`
  /// - ObjectDeletion → `obj_deletion.obj_path`
  ///
  /// Null for OperationComplete: the local bridge sends no `obj_path` for it,
  /// so its readers match on `command_key` instead (`SseOperationAwaiter`).
  String? get path {
    switch (type) {
      case 'ValueChange':
        return (payload['value_change'] as Map<String, dynamic>?)?['param_path']
            as String?;
      case 'ObjectCreation':
        return (payload['obj_creation'] as Map<String, dynamic>?)?['obj_path']
            as String?;
      case 'ObjectDeletion':
        return (payload['obj_deletion'] as Map<String, dynamic>?)?['obj_path']
            as String?;
      default:
        return null;
    }
  }

  /// Whether this is a notification a subscription of [notifType] on
  /// [referenceList] asked for: the same type, and a [path] the reference list
  /// covers.
  ///
  /// The reference list is one TR-181 path, as every subscription here
  /// registers:
  /// - ending in `.` (an object), it covers that object and everything under
  ///   it;
  /// - otherwise (a parameter), it covers that parameter only;
  /// - a `*` segment matches any one instance, as in `Device.WiFi.SSID.*.SSID`
  ///   (the form the package widget authoring guide shows);
  /// - from a segment holding a search expression (`[...]`) on, it covers
  ///   everything the path has there, because the expression is the router's
  ///   to evaluate. Too much rather than nothing: the readers filter what they
  ///   get. A path that stops before that segment is not under it.
  bool isFor({required String notifType, required String referenceList}) {
    if (type != notifType) return false;
    final path = this.path;
    if (path == null) return false;
    return _covers(referenceList, path);
  }

  @override
  String toString() => 'SseNotification(sub=$subscriptionId, type=$type)';
}

/// See [SseNotification.isFor].
bool _covers(String referenceList, String path) {
  final isObject = referenceList.endsWith('.');
  final pattern = _segments(referenceList);
  final segments = _segments(path);
  for (var i = 0; i < pattern.length; i++) {
    final want = pattern[i];
    if (i >= segments.length) return false;
    if (want.contains('[')) return true;
    if (want != '*' && want != segments[i]) return false;
  }
  return isObject || segments.length == pattern.length;
}

List<String> _segments(String path) {
  final trimmed =
      path.endsWith('.') ? path.substring(0, path.length - 1) : path;
  return trimmed.isEmpty ? const [] : trimmed.split('.');
}

/// Callback signature for notification handlers.
typedef SseNotificationHandler = void Function(SseNotification notification);
