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
/// Binds the [BridgeRequestThrottler] so all `usp.get()` calls are
/// automatically throttled to prevent overwhelming the router.
final uspClientProvider = Provider<UspClient?>((ref) {
  if (!kIsWeb) return null;
  if (!getIt.isRegistered<UspClient>()) return null;
  final usp = getIt<UspClient>();
  usp.throttler = ref.read(bridgeRequestThrottlerProvider);
  return usp;
});
