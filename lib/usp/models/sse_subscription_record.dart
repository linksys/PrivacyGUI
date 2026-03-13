/// A registered subscription record tracking both OBUSPA and bridge layers.
class SseSubscriptionRecord {
  /// Client-assigned ID (e.g., "connected-devices-objectcreation").
  final String subscriptionId;

  /// OBUSPA instance path (e.g., "Device.LocalAgent.Subscription.3.").
  final String obuspaInstancePath;

  /// Notification type: "ValueChange", "ObjectCreation", "ObjectDeletion",
  /// "OperationComplete", "Event".
  final String notifType;

  /// TR-181 path being monitored (e.g., "Device.Hosts.Host.").
  final String referenceList;

  /// When this subscription was created.
  final DateTime createdAt;

  const SseSubscriptionRecord({
    required this.subscriptionId,
    required this.obuspaInstancePath,
    required this.notifType,
    required this.referenceList,
    required this.createdAt,
  });

  @override
  String toString() =>
      'SseSubscriptionRecord($subscriptionId, $notifType, $referenceList)';
}
