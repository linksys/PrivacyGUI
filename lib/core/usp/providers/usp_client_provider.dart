import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

import 'bridge_request_throttler_provider.dart';

/// Provides UspClient instance via Riverpod.
///
/// Returns null on non-Web platforms since USP is only available
/// through the WASM transport layer.
///
/// Also null in a Remote Assistance build until
/// `RemoteAssistanceNotifier.activate()` has registered the session client —
/// such builds get no boot-time client, because the app's own origin is not the
/// USP host (see `canUseAppOriginUspClient` in `di.dart`).
///
/// Caches for the container's lifetime: a `ref.read` consumer keeps the instance
/// it first saw. `activate()` invalidates this provider after the swap so
/// `ref.watch` consumers follow.
///
/// Binds the [BridgeRequestThrottler] so all `usp.get()` calls are
/// automatically throttled to prevent overwhelming the router.
final uspClientProvider = Provider<UspClient?>((ref) {
  if (!kIsWeb) return null;
  if (!getIt.isRegistered<UspClient>()) return null;
  final usp = getIt<UspClient>();
  usp.throttler = ref.read(bridgeRequestThrottlerProvider);
  return usp;
});
