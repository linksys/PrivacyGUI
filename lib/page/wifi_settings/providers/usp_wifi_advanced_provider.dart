import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/tr181_path.dart';
import 'package:privacy_gui/core/utils/wifi_channel.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_feature_state.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_advanced_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspWifiAdvancedProvider = AutoDisposeNotifierProvider<
    UspWifiAdvancedNotifier, WifiAdvancedFeatureState>(
  UspWifiAdvancedNotifier.new,
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

      logger.d('[USP][WiFi][Advanced]: Fetched — radios=${ieee80211h.length}, '
          'clientSteering=${steering.clientSteering}, '
          'nodeSteering=${steering.nodeSteering}');

      return (
        WifiAdvancedSettings(
          ieee80211hByRadio: ieee80211h,
          clientSteering: steering.clientSteering,
          nodeSteering: steering.nodeSteering,
        ),
        const WifiAdvancedStatus(),
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
    // Steering first, and only the switches that changed (#1661). It is applied
    // at once with no radio reload, so it is sent before the DFS write rather
    // than into the reload that write starts.
    await _saveSteering();
    if (!state.changesDfs) return;
    await _saveIeee80211h();
  }

  /// Writes the changed steering switches, then makes them the saved values.
  ///
  /// Marked saved here, before the DFS write, because the two are separate Sets:
  /// a DFS failure after this one landed must not leave a written switch reading
  /// as an unsaved edit. A refused Set re-reads the device so the switches show
  /// what it holds, then rethrows. A refused DFS write is left as it was before
  /// #1661 — its error and read-back belong to #1499/#1460.
  Future<void> _saveSteering() async {
    final original = state.settings.original;
    final current = state.settings.current;
    final client = current.clientSteering != original.clientSteering
        ? current.clientSteering
        : null;
    final node = current.nodeSteering != original.nodeSteering
        ? current.nodeSteering
        : null;
    if (client == null && node == null) return;

    try {
      try {
        await ref.read(uspMutationLockProvider).withLock(() async {
          await _svc.setSteering(clientSteering: client, nodeSteering: node);
        });
      } on TimeoutException catch (e) {
        // The lock's own window, which the service never sees to map. Folded
        // so it reaches the re-read below and the view as a timeout; same fold
        // as `firmware_auto_update_data_provider.dart`.
        throw TimeoutError(
          detail: 'the steering write was not answered (${e.message ?? '30s'})',
        );
      }
    } on ServiceError {
      await _rereadSteering();
      rethrow;
    }

    logger.d('[USP][WiFi][Advanced]: Steering saved — '
        'client=$client, node=$node');
    state = state.copyWith(
      settings: state.settings.copyWith(
        original: state.settings.original.copyWith(
          clientSteering: current.clientSteering,
          nodeSteering: current.nodeSteering,
        ),
      ),
    );
  }

  /// Puts the device's steering values into both sides of the working copy, so
  /// a refused write leaves the switches at what the router still holds. If the
  /// re-read fails too, the edit stays pending and the caller's error stands.
  Future<void> _rereadSteering() async {
    try {
      final now = await _svc.fetchSteering();
      WifiAdvancedSettings apply(WifiAdvancedSettings s) => s.copyWith(
            clientSteering: now.clientSteering,
            nodeSteering: now.nodeSteering,
          );
      state = state.copyWith(
        settings: state.settings.copyWith(
          original: apply(state.settings.original),
          current: apply(state.settings.current),
        ),
      );
    } on ServiceError catch (e) {
      logger.w(
          '[USP][WiFi][Advanced]: Steering re-read after a failed write '
          'also failed',
          error: e);
    }
  }

  Future<void> _saveIeee80211h() async {
    // THIS SAVE WRITES TWO NAMED FIELDS, not the whole object. `setIeee80211hEnabled`
    // sets `IEEE80211hEnabled` on the listed radios plus `AutoChannelEnable` on the
    // remediated ones, so a value the device changed elsewhere while this page was open
    // is not overwritten by saving here. The #1587 Phase 3 gap — comparing the draft
    // against the page-entry snapshot rather than the device — still applies to the two
    // fields this page owns, and nothing more.
    final current = state.settings.current;
    final radioPaths = current.ieee80211hByRadio.keys.toList();
    final enabled = current.isDfsEnabled;

    // When DFS is being disabled, any radio parked on a DFS channel must be
    // moved off it — the firmware leaves the channel set on its own
    // (SSH-verified). Force AutoChannelEnable on those radios so the firmware
    // reselects a legal non-DFS channel. Only radios being turned off and
    // currently sitting on a manual DFS channel are affected.
    final forceAutoChannelPaths = <String>[];
    if (!enabled) {
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
      final radios = wifiData.radioModels;
      final radioByPath = {
        for (final r in radios) ensureTrailingDot(r.instancePath): r,
      };
      for (final path in radioPaths) {
        // Radios staying on DFS need no channel remediation.
        if (current.ieee80211hByRadio[path] == true) continue;
        final radio = radioByPath[ensureTrailingDot(path)];
        if (radio == null || radio.autoChannelEnable) continue;
        if (isDfsChannel(radio.channel, band: radio.band)) {
          forceAutoChannelPaths.add(path);
        }
      }
    }

    await ref.read(uspMutationLockProvider).withLock(() async {
      await _svc.setIeee80211hEnabled(
        radioPaths: radioPaths,
        enabled: enabled,
        forceAutoChannelPaths: forceAutoChannelPaths,
      );
    });

    logger.d('[USP][WiFi][Advanced]: Save succeeded — '
        'radios=${radioPaths.length}, enabled=$enabled, '
        'forcedAutoChannel=${forceAutoChannelPaths.length}');
    // Refresh Layer 1 cache so post-save fetch() reads fresh data.
    // Using refresh() instead of invalidate() because the latter only marks
    // the provider dirty — without an active subscriber it won't rebuild,
    // and the subsequent .future call would return stale data.
    final _ = await ref.refresh(wifiDataProvider.future);
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
}
