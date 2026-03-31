import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';

import 'bridge_request_throttler_provider.dart';

/// Provides UspService instance via Riverpod.
///
/// Returns null on non-Web platforms since USP is only available
/// through the WASM transport layer.
///
/// Binds the [BridgeRequestThrottler] so all `usp.get()` calls are
/// automatically throttled to prevent overwhelming the router.
final uspServiceProvider = Provider<UspService?>((ref) {
  if (!kIsWeb) return null;
  if (!getIt.isRegistered<UspService>()) return null;
  final usp = getIt<UspService>();
  usp.throttler = ref.read(bridgeRequestThrottlerProvider);
  return usp;
});
