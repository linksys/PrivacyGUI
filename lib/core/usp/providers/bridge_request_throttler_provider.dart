import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';

/// Singleton [BridgeRequestThrottler] — limits concurrent outbound requests
/// to the router (USP GET + HTTP/CGI) to prevent connection overload.
final bridgeRequestThrottlerProvider = Provider<BridgeRequestThrottler>((ref) {
  return BridgeRequestThrottler();
});
