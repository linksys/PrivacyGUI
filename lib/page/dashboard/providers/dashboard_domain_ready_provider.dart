import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/local_network/providers/ethernet_data_provider.dart';

/// Resolves when all essential domain providers have completed their first
/// fetch attempt (success or failure).
///
/// Polling providers (traffic analysis, system monitor) should listen to this
/// before starting their timers, so they don't compete for throttler slots
/// during the initial domain data load phase.
///
/// Uses [ref.read] (not watch) so this provider resolves exactly once and is
/// NOT re-triggered by SSE-driven domain provider rebuilds.
///
/// Each domain future is individually error-handled — a single domain failure
/// does not block polling from starting.
final dashboardDomainReadyProvider = FutureProvider<void>((ref) async {
  final sw = Stopwatch()..start();

  await Future.wait<void>([
    ref.read(systemInfoDataProvider.future).then((_) {}).catchError((_) {}),
    ref.read(devicesDataProvider.future).then((_) {}).catchError((_) {}),
    ref.read(ethernetDataProvider.future).then((_) {}).catchError((_) {}),
  ]);

  logger.d(
      '[USP][DomainReady] All domain providers settled in ${sw.elapsedMilliseconds}ms');
});
