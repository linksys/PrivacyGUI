/// A registered subscription record managed by the bridge.
///
/// The bridge handles the full OBUSPA `Device.LocalAgent.Subscription.{i}`
/// lifecycle automatically — the client only tracks logical state.
class SseSubscriptionRecord {
  /// Client-assigned ID (e.g., "connected-devices-objectcreation").
  final String subscriptionId;

  /// Notification type: "ValueChange", "ObjectCreation", "ObjectDeletion",
  /// "OperationComplete", "Event".
  final String notifType;

  /// TR-181 path being monitored (e.g., "Device.Hosts.Host.").
  final String referenceList;

  /// When this subscription was created.
  final DateTime createdAt;

  const SseSubscriptionRecord({
    required this.subscriptionId,
    required this.notifType,
    required this.referenceList,
    required this.createdAt,
  });

  @override
  String toString() =>
      'SseSubscriptionRecord($subscriptionId, $notifType, $referenceList)';
}
