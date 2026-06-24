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
            '/remote-assistances/sessions/$sessionId/usp/notifications',
        subscription:
            '/remote-assistances/sessions/$sessionId/usp/subscriptions',
        health: '/remote-assistances/sessions/$sessionId/usp/health',
        turboPrefix: '/remote-assistances/sessions/$sessionId/usp/turbo',
      );
}
