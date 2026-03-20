/// A parsed notification payload from an SSE "notification" event.
class SseNotification {
  final String subscriptionId;
  final String
      type; // "ValueChange", "ObjectCreation", "ObjectDeletion", "OperationComplete"
  final Map<String, dynamic> payload; // Full decoded JSON

  const SseNotification({
    required this.subscriptionId,
    required this.type,
    required this.payload,
  });

  @override
  String toString() => 'SseNotification(sub=$subscriptionId, type=$type)';
}

/// Callback signature for notification handlers.
typedef SseNotificationHandler = void Function(SseNotification notification);
