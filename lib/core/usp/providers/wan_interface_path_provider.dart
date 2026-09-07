import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Fallback WAN interface path used when the instance cannot be resolved
/// (client unavailable, `Alias` query failed, or resolution still pending).
///
/// Matches the fallback baked into the generated `_resolveInstance` helpers
/// (e.g. `WanStatus._resolveInstance`), so behavior is identical to the
/// previously hardcoded `.2.` assumption whenever resolution is unavailable —
/// this change can only ever match *more* correctly, never worse.
const kWanInterfaceFallbackPath = 'Device.IP.Interface.2.';

/// Resolves the WAN `Device.IP.Interface.{i}.` path by searching for the
/// interface whose `Alias` is `wan`.
///
/// Mirrors the per-fetch resolution the generated codegen models already do
/// (`_resolveInstance`), but is shared so the non-generated consumers — the
/// SSE invalidation classifier and the WAN gateway lookup — stop hardcoding
/// instance `.2.`. Returns [kWanInterfaceFallbackPath] on any failure.
Future<String> resolveWanInterfacePath(UspClient client) async {
  try {
    final response = await client.get(['Device.IP.Interface.*.Alias']);
    for (final entry in response.entries) {
      if (entry.value == 'wan') {
        final match =
            RegExp(r'Device\.IP\.Interface\.(\d+)\.').firstMatch(entry.key);
        if (match != null) {
          return 'Device.IP.Interface.${match.group(1)}.';
        }
      }
    }
  } catch (e) {
    logger.w('[USP][WAN]: WAN interface resolution failed: $e');
  }
  return kWanInterfaceFallbackPath;
}

/// Resolved WAN interface path, cached and re-resolved per connected router.
///
/// The [UspClient] is a getIt singleton behind the app-lifetime global
/// [ProviderContainer], and this provider is not autoDispose — so once
/// resolved it would stay cached for the whole app run. That is stale if the
/// user switches to a different physical router on the same origin without a
/// page reload (a passive serial-number change in `_prepareLocal`, or a
/// logout→login onto another router): the WAN instance could differ.
///
/// To stay correct we key the cache on the connected router's serial number
/// (`sessionProvider.deviceInfo.serialNumber`), which changes on every router
/// switch — `forceFetchDeviceInfo`/`fetchDeviceInfoAndInitializeServices`
/// update it and logout's `clear()` resets it — forcing a re-resolve against
/// the new router. `select` narrows the dependency to just the serial so other
/// device-info fields don't trigger needless re-resolution.
///
/// Consumed synchronously by the SSE invalidation classifier (with a
/// [kWanInterfaceFallbackPath] fallback while still pending) and awaited by the
/// WAN data service's gateway lookup.
final wanInterfacePathProvider = FutureProvider<String>((ref) async {
  // Re-resolve whenever the connected router changes.
  ref.watch(sessionProvider.select((s) => s.deviceInfo?.serialNumber));
  final client = ref.watch(uspClientProvider);
  if (client == null) return kWanInterfaceFallbackPath;
  return resolveWanInterfacePath(client);
});
