import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';
import 'package:privacy_gui/core/utils/wifi_channel.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_feature_state.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspWifiAdvancedProvider = AutoDisposeNotifierProvider<
    UspWifiAdvancedNotifier, WifiAdvancedFeatureState>(
  UspWifiAdvancedNotifier.new,
);

/// How long after the Set an MLO save waits before it reads the router back.
///
/// FWDEV#201's contract: an MLO change restarts Wi-Fi, clients reconnect
/// within about 60 s, and `MLOStatus` is read again after that. The router
/// answers the Set before the restart (166 ms on the bench, FW 2.0.3.26101472,
/// 2026-10-15) and nothing it serves says when the restart is over — the radios
/// have no `LastChange` — so the save waits the contract's 60 s instead.
final mloRestartSettleProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 60),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspWifiAdvancedNotifier
    extends AutoDisposeNotifier<WifiAdvancedFeatureState>
    with
        PreservableAutoDisposeNotifierMixin<WifiAdvancedSettings,
            WifiAdvancedStatus, WifiAdvancedFeatureState> {
  UspWifiAdvancedService get _svc => ref.read(uspWifiAdvancedServiceProvider);

  bool get _offersMlo =>
      ref.read(deviceCapabilitiesProvider).has(DeviceCapability.wifiMlo);

  @override
  WifiAdvancedFeatureState build() {
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return WifiAdvancedFeatureState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(WifiAdvancedSettings?, WifiAdvancedStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final ieee80211h = await _svc.fetchIeee80211h();
      final steering = await _svc.fetchSteering();
      // Only where the router offers it: firmware without FWDEV#201 has no
      // such leaves, and the tab must still read steering and DFS there.
      final mlo = _offersMlo ? await _svc.fetchMlo() : null;

      logger.d('[USP][WiFi][Advanced]: Fetched — radios=${ieee80211h.length}, '
          'clientSteering=${steering.clientSteering}, '
          'nodeSteering=${steering.nodeSteering}, '
          'mlo=${mlo?.enabled} (${mlo?.status.name})');

      return (
        WifiAdvancedSettings(
          ieee80211hByRadio: ieee80211h,
          clientSteering: steering.clientSteering,
          nodeSteering: steering.nodeSteering,
          mloEnabled: mlo?.enabled,
        ),
        WifiAdvancedStatus(mloStatus: mlo?.status),
      );
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi][Advanced]: Fetch failed', error: e);
      return (
        null,
        WifiAdvancedStatus(error: e),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // save — override to manage isSaving flag
  // ---------------------------------------------------------------------------

  @override
  Future<WifiAdvancedFeatureState> save() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );
    try {
      return await super.save();
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi][Advanced]: Save failed', error: e);
      rethrow;
    } finally {
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    // THIS SAVE WRITES THE SWITCHES THAT CHANGED, not the whole tab. A value
    // the router changed elsewhere while the page was open is overwritten only
    // if this page changed it too. The #1587 Phase 3 gap — comparing the draft
    // against the page-entry snapshot rather than the device — still applies to
    // those, and nothing more.
    final original = state.settings.original;
    final current = state.settings.current;

    // One Set for the whole tab (#1692): steering, MLO and DFS together, so an
    // MLO and DFS change restarts Wi-Fi once. Then the router is read back,
    // even when it answered: with `allowPartial` one part can be refused on its
    // own, and an MLO restart comes after the answer. See
    // [wifiWriteConfirmProvider].
    //
    // The remediation read is outside the `try`: when it fails nothing has
    // been sent, so there is nothing to re-read and the edit stays pending.
    final plan = _svc.planSave(
      original: original,
      current: current,
      forceAutoChannelPaths:
          state.changesDfs ? await _dfsRemediationPaths(current) : const [],
    );
    try {
      await ref.read(wifiWriteConfirmProvider)(
        plan,
        isApplied: _svc.isApplied,
        readBackAfter: state.changesMlo
            ? ref.read(mloRestartSettleProvider)
            : Duration.zero,
      );
    } on ServiceError {
      await _rereadAfterFailure();
      rethrow;
    }

    logger.d('[USP][WiFi][Advanced]: Save confirmed — '
        'dfs=${state.changesDfs}, mlo=${state.changesMlo}');
    if (state.restartsWifi) await _refreshL1AfterWrite();
  }

  /// The radios to force onto auto-channel in the save's Set: those DFS turns
  /// off while they sit on a manual DFS channel.
  ///
  /// The firmware leaves such a radio where it is (SSH-verified), so forcing
  /// `AutoChannelEnable` makes it pick a legal non-DFS channel. Radios keeping
  /// DFS on, and radios already on auto-channel, are left alone.
  Future<List<String>> _dfsRemediationPaths(
      WifiAdvancedSettings current) async {
    if (current.isDfsEnabled) return const [];
    // `await …future`, not `ref.read(...).valueOrNull`. This worked before only
    // because the `onSseInvalidation()` wiring held a `ref.listen` on
    // `wifiDataProvider`, which kept it initialised and settled for this notifier's
    // whole lifetime. That wiring was deleted in #1587 Phase 1, and a bare `ref.read`
    // then returned `AsyncLoading` with no value — so `radioModels` was empty, no radio
    // was recognised as parked on a DFS channel, and the remediation silently did
    // nothing.
    //
    // Awaiting the future is the fix rather than re-adding a listener: this is a
    // one-shot read at save time and it needs the value to EXIST, not to be watched.
    //
    // ONE RETRY, BECAUSE `.future` REPLAYS A CACHED FAILURE. `wifiDataProvider` is not
    // autoDispose and has no retry of its own, so if its `build()` ever threw, every
    // later `.future` rethrows that same error — and DFS-disable saves would keep
    // failing until something else happened to invalidate L1. `refresh` forces one
    // real re-read. If the retry also fails it propagates, which is correct — the
    // remediation cannot be skipped silently, and skipping it leaves a radio parked on
    // a DFS channel with DFS off.
    // `catch (e)`, not `on ServiceError`: today both paths into L1 throw a
    // `ServiceError` — the service maps USP errors and its provider throws
    // `ServiceNotInitializedError` — but that is what the current implementation
    // happens to do, not something the type signature promises. A narrower catch
    // would turn the day that changes into a save that fails without retrying, which
    // is the failure this block exists to prevent.
    WifiData wifiData;
    try {
      wifiData = await ref.read(wifiDataProvider.future);
    } catch (e) {
      logger.w(
          '[USP][WiFi][Advanced]: L1 read failed before DFS remediation, '
          'retrying once',
          error: e);
      wifiData = await ref.refresh(wifiDataProvider.future);
    }
    final radioByPath = {
      for (final r in wifiData.radioModels)
        ensureTrailingDot(r.instancePath): r,
    };
    return [
      for (final MapEntry(key: path, value: on)
          in current.ieee80211hByRadio.entries)
        if (!on)
          if (radioByPath[ensureTrailingDot(path)] case final radio?
              when !radio.autoChannelEnable &&
                  isDfsChannel(radio.channel, band: radio.band))
            path,
    ];
  }

  /// Puts what the router now holds into both sides of the working copy, so a
  /// failed save — a part refused, or nothing confirmed — leaves every switch
  /// at the router's value: a part that landed shows as landed, a refused one
  /// at its old value. If the re-read fails too, the edit stays pending and the
  /// caller's error stands.
  Future<void> _rereadAfterFailure() async {
    final (settings, status) = await performFetch(forceRemote: true);
    if (settings == null) {
      logger.w('[USP][WiFi][Advanced]: re-read after a failed save also '
          'failed — the edit stays pending');
      return;
    }
    state = state.copyWith(
      settings: Preservable(original: settings, current: settings),
      status: state.status.copyWith(mloStatus: status?.mloStatus),
    );
  }

  /// Re-reads L1 after a write that restarted Wi-Fi, so other pages read the
  /// new radios. Using refresh() instead of invalidate() because the latter
  /// only marks the provider dirty — without an active subscriber it won't
  /// rebuild, and the subsequent .future call would return stale data.
  ///
  /// Its failure is logged, not thrown: the write is settled by now, and the
  /// radios it reloaded can still time this read out on the 15 s throttler —
  /// the same way #1499's confirmed save was reported as a failure.
  Future<void> _refreshL1AfterWrite() async {
    try {
      final _ = await ref.refresh(wifiDataProvider.future);
    } on ServiceError catch (e) {
      logger.w(
          '[USP][WiFi][Advanced]: L1 refresh after the write failed — '
          'the write itself is settled',
          error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // UI Mutation (synchronous — buffers, no network call)
  // ---------------------------------------------------------------------------

  /// Toggle DFS/802.11h on or off for all radios.
  /// Updates [settings.current] only — does NOT call the service.
  /// User must call save() to persist the change.
  void setDfsEnabled(bool enabled) {
    final original = state.settings.original;

    final current = state.settings.current;

    // When the user toggles back to the original effective DFS state, restore
    // the original per-radio map so the dirty flag clears correctly. Without
    // this, mixed per-radio values (e.g. 2.4 GHz=false, 5 GHz=true) would
    // never match after a uniform set-all toggle. Only the map: a pending
    // steering edit is not DFS's to undo.
    if (enabled == original.isDfsEnabled) {
      state = state.copyWith(
        settings: state.settings.update(
          current.copyWith(ieee80211hByRadio: original.ieee80211hByRadio),
        ),
      );
      return;
    }

    final updated = current.copyWith(
      ieee80211hByRadio: {
        for (final path in current.ieee80211hByRadio.keys) path: enabled,
      },
    );

    state = state.copyWith(
      settings: state.settings.update(updated),
    );
  }

  /// Toggle client steering. Buffered like [setDfsEnabled]; save() writes it.
  void setClientSteering(bool enabled) {
    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(clientSteering: enabled),
      ),
    );
  }

  /// Toggle node steering. Buffered like [setDfsEnabled]; save() writes it.
  void setNodeSteering(bool enabled) {
    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(nodeSteering: enabled),
      ),
    );
  }

  /// Toggle MLO. Buffered like [setDfsEnabled]; save() writes it.
  void setMloEnabled(bool enabled) {
    state = state.copyWith(
      settings: state.settings.update(
        state.settings.current.copyWith(mloEnabled: enabled),
      ),
    );
  }
}
