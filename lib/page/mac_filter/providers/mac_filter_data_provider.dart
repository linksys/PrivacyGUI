import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_data.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';
import 'package:privacy_gui/page/mac_filter/services/usp_mac_filter_data_service.dart';

/// L1: the MAC filter as the device has it applied, for the whole session.
///
/// Read by surfaces that only show the mode, such as the menu's Instant Privacy
/// badge. The router pushes a change of the mode (`mac-filter-mode-valuechange`)
/// whoever makes it: a save from either page, or the hardware privacy switch,
/// which writes the filter without the app (PrivacyGUI#1755). A push re-reads
/// the filter here.
///
/// Only the mode is kept current: a change to the list alone is not pushed, so
/// [MacFilterData.macs] is as of the last read. Do not show the list from here.
///
/// The Instant Privacy and MAC Filter pages keep their own working copy and
/// read the router when they open; a push never reaches them (constitution
/// Article IV Rule 2). Their save invalidates this provider.
final macFilterDataProvider =
    AsyncNotifierProvider<MacFilterDataNotifier, MacFilterData>(
  MacFilterDataNotifier.new,
);

/// Reads the filter through [UspMacFilterDataService] when first watched, and
/// again 500 ms after the last pushed [InvalidationDomain.macFilter], so a burst
/// of pushes costs one read. A pushed read that fails keeps the value it had.
class MacFilterDataNotifier extends AsyncNotifier<MacFilterData> {
  Timer? _debounce;

  /// Bumped by every rebuild and every push read, so a push read that started
  /// earlier and finishes later is discarded instead of overwriting newer data.
  int _pushGeneration = 0;

  @override
  Future<MacFilterData> build() async {
    // A rebuild (the pages' save) supersedes any push read in flight, and a
    // timer armed before it would only re-read what the rebuild just read.
    _pushGeneration++;
    _debounce?.cancel();

    // Firmware without the filter (#1635) has nothing to read, and the
    // orchestrator's retry builds this provider whether or not the menu watches
    // it. No filter is in effect there, which is what Disabled with no list says;
    // the menu is gated on the same capability and never shows it.
    if (!ref
        .watch(deviceCapabilitiesProvider)
        .has(DeviceCapability.wifiMacFilter)) {
      return const MacFilterData(mode: MacFilterMode.disabled, macs: []);
    }

    ref.listen(sseInvalidationProvider, (prev, next) {
      if (next.valueOrNull?.domain == InvalidationDomain.macFilter) {
        _debouncedRefresh();
      }
    });

    ref.onDispose(() => _debounce?.cancel());

    return _fetch();
  }

  Future<MacFilterData> _fetch({bool fresh = false}) =>
      ref.read(uspMacFilterDataServiceProvider).fetch(fresh: fresh);

  void _debouncedRefresh() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _refreshFromPush());
  }

  Future<void> _refreshFromPush() async {
    final generation = ++_pushGeneration;
    try {
      // Fresh: the change was made on the router, so a cached read from before
      // it would replay the old mode (#1755).
      final data = await _fetch(fresh: true);
      if (generation != _pushGeneration) return;
      state = AsyncData(data);
    } on ServiceError catch (e, st) {
      logger.w(
          '[MacFilter] push-triggered refetch failed, keeping previous value',
          error: e,
          stackTrace: st);
    }
  }
}
