import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';

/// Resolves the WAN `Device.IP.Interface.{i}.` path by searching for the
/// interface whose `Alias` is `wan`.
///
/// Mirrors the per-fetch resolution the generated codegen models already do
/// (`_resolveInstance`), but is shared so the non-generated consumers — the
/// SSE invalidation classifier and the WAN gateway lookup — never hardcode an
/// instance. A router with no such interface throws [ResourceNotFoundError],
/// as the generated models do with 9996: there is no guessed `Interface.2`.
Future<String> resolveWanInterfacePath(UspClient client) async {
  final Map<String, dynamic> response;
  try {
    response = await client.get(['Device.IP.Interface.*.Alias']);
  } catch (e) {
    if (e is ServiceError) rethrow;
    throw mapUspErrorToServiceError(e);
  }
  final path = interfacePathsByAlias(response)[wanInterfaceAlias];
  if (path != null) return path;
  throw const ResourceNotFoundError(
      detail: 'No Device.IP.Interface with Alias wan');
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
/// Consumed synchronously by the SSE invalidation classifier, which matches no
/// WAN path while this is pending or null. Null when there is no client, or
/// when the router has no WAN interface or cannot be read.
final wanInterfacePathProvider = FutureProvider<String?>((ref) async {
  // Re-resolve whenever the connected router changes.
  ref.watch(sessionProvider.select((s) => s.deviceInfo?.serialNumber));
  final client = ref.watch(uspClientProvider);
  if (client == null) return null;
  try {
    return await resolveWanInterfacePath(client);
  } on ServiceError catch (e) {
    logger.w('[USP][WAN]: WAN interface resolution failed: $e');
    return null;
  }
});

/// The shortest time between two re-resolves of an unresolved WAN path.
///
/// A firmware with no `Alias == wan` interface stays unresolved, and every SSE
/// event would otherwise re-read the alias table. Overridden in tests.
final wanInterfacePathRetryIntervalProvider =
    Provider<Duration>((ref) => const Duration(seconds: 30));

/// When [retryWanInterfacePathIfUnresolved] last re-resolved, for the
/// connected router: it resets with the serial, as [wanInterfacePathProvider]
/// does, so a new router is not held back by the previous one's retry.
final _wanInterfacePathLastRetryProvider = StateProvider<DateTime?>((ref) {
  ref.watch(sessionProvider.select((s) => s.deviceInfo?.serialNumber));
  return null;
});

/// Re-resolves [wanInterfacePathProvider] when its last resolve ended without
/// a path, at most once per [wanInterfacePathRetryIntervalProvider].
///
/// A path that resolved is never re-read, nor is a resolve still in flight,
/// so calling this while SSE is healthy does nothing. The resolve only reads
/// the alias table; nothing watches [wanInterfacePathProvider], so re-reading
/// it rebuilds no SSE provider and drops no connection.
void retryWanInterfacePathIfUnresolved(Ref ref) {
  final current = ref.read(wanInterfacePathProvider);
  if (current.isLoading || current.valueOrNull != null) return;
  final now = DateTime.now();
  final last = ref.read(_wanInterfacePathLastRetryProvider);
  if (last != null &&
      now.difference(last) < ref.read(wanInterfacePathRetryIntervalProvider)) {
    return;
  }
  ref.read(_wanInterfacePathLastRetryProvider.notifier).state = now;
  // Nothing listens to the provider, so an invalidate alone would wait for
  // the next read to rebuild it: read it now so the resolve starts here.
  ref.invalidate(wanInterfacePathProvider);
  ref.read(wanInterfacePathProvider);
}
