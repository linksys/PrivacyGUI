import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_notifier.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_quick_setup_network.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/mlo_status_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspWifiSettingsProvider =
    AutoDisposeNotifierProvider<UspWifiSettingsNotifier, UspWifiSettingsState>(
  UspWifiSettingsNotifier.new,
);

/// Route-level dirty proxy — aggregates every WiFi tab's dirty state.
/// Only isDirty() and revert() are invoked by LinksysRoute.onExit.
final preservableUspWifiPageProvider = AutoDisposeProvider<
    PreservableContract<WifiSettingsSettings, WifiSettingsStatus>>(
  (ref) => _WifiPageDirtyProxy([
    ref.watch(uspWifiSettingsProvider.notifier),
    ref.watch(uspWifiAdvancedProvider.notifier),
    // The MAC Filtering tab (#1636). Watched unconditionally: on firmware without
    // the tab the notifier is never edited, so it is never dirty.
    ref.watch(uspMacFilterProvider.notifier),
  ]),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspWifiSettingsNotifier extends AutoDisposeNotifier<UspWifiSettingsState>
    with
        PreservableAutoDisposeNotifierMixin<WifiSettingsSettings,
            WifiSettingsStatus, UspWifiSettingsState> {
  UspWifiSettingsService get _svc => ref.read(uspWifiSettingsServiceProvider);

  /// What the last page save wrote, held while the router is away.
  ///
  /// Set when [performSave] gets [WifiRouterAway]: a rename took the browser
  /// off the network and no read-back reached the router by the deadline. The
  /// view then waits for the router (the natural recovery, no time limit) and
  /// calls [confirmAfterRecovery] to settle it. Not part of the state: it is a
  /// hand-off between one save and the view that started it, not something any
  /// widget renders.
  Map<String, dynamic>? _proofAwaitingRecovery;

  /// The page as last read, before the save that is awaiting recovery marked
  /// it saved: restored if the router turns out not to have taken the write
  /// and cannot be read either, so the edit stays pending rather than reading
  /// as what the router holds.
  WifiSettingsSettings? _baselineAwaitingRecovery;

  /// Whether the last save is waiting for the router to come back before it
  /// can be confirmed. See [confirmAfterRecovery].
  bool get awaitsRouterRecovery => _proofAwaitingRecovery != null;

  /// Settles a save that ended [awaitsRouterRecovery], once the router is back.
  ///
  /// Reads the router back until it answers: applied is done; not applied
  /// throws, so a rename the router refused is reported rather than taken as
  /// success. A read that fails is retried a few times, one read-back interval
  /// apart — the recovery probe passing says the router answers, not that its
  /// radios have settled, and mid-reload it answers a WiFi GET with no rows.
  /// Either way nothing is left pending, and the form is then read back from
  /// the router by [readBackAfterRecovery]. A no-op when nothing is pending.
  Future<void> confirmAfterRecovery() async {
    final proof = _proofAwaitingRecovery;
    if (proof == null) return;
    _proofAwaitingRecovery = null;
    const attempts = wifiReadBackAfterRecoveryAttempts;
    final interval = ref.read(wifiReadBackIntervalProvider);
    try {
      for (var attempt = 1;; attempt++) {
        final bool applied;
        try {
          applied = await _svc.isApplied(proof);
        } on ServiceError catch (e) {
          if (attempt == attempts) rethrow;
          logger.d('[USP][WiFi]: router back, read-back not answered yet: $e');
          await Future<void>.delayed(interval);
          continue;
        }
        if (!applied) {
          logger.w('[USP][WiFi]: router back, but the save did not apply');
          throw const UnexpectedError();
        }
        logger.i('[USP][WiFi]: router back, save read back as applied');
        break;
      }
    } on ServiceError {
      // Not applied, or never answered: that is the error to report. The form
      // is still re-read so it shows what the router holds, but its outcome
      // must not replace this one.
      final baseline = _baselineAwaitingRecovery;
      _baselineAwaitingRecovery = null;
      try {
        await readBackAfterRecovery();
      } on ServiceError catch (e) {
        logger.w('[USP][WiFi]: form read-back after a failed confirm failed',
            error: e);
        // The read-back kept what was written, clean — the rule for a write
        // that landed. This one did not land, so put the last-read values
        // back as the baseline and leave the edit pending.
        if (baseline != null) {
          state = state.copyWith(
            settings: state.settings.copyWith(original: baseline),
          );
        }
      }
      rethrow;
    }
    _baselineAwaitingRecovery = null;
    await readBackAfterRecovery();
  }

  /// Reads the page back once the router is back, after a write that landed.
  ///
  /// **When, not just how (#1212).** Every Wi-Fi write reloads all the radios,
  /// so a read straight after it is #1499's 15 s throttler timeout or an empty
  /// table. [save] therefore stops at the write; the caller runs this once its
  /// recovery has ended — `runWifiWriteWithRecovery` does — and only then
  /// reports the save.
  ///
  /// Retried a few times, one read-back interval apart, as
  /// [confirmAfterRecovery]'s read-back is: the probe passing says the router
  /// answers, not that its radios have settled, and mid-reload a Wi-Fi GET
  /// comes back with no rows (L1 throws on that). If every read fails the
  /// framework's rule applies: the form keeps what was written and this throws
  /// [SavedButUnconfirmedError].
  Future<void> readBackAfterRecovery() => confirmSavedRetrying(
        attempts: wifiReadBackAfterRecoveryAttempts,
        interval: ref.read(wifiReadBackIntervalProvider),
        before: _refreshL1AfterWrite,
      );

  @override
  UspWifiSettingsState build() {
    // Synchronous build with loading state; async fetch follows immediately.
    Future.microtask(() => fetch());
    return UspWifiSettingsState.initial();
  }

  // ---------------------------------------------------------------------------
  // performFetch — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<(WifiSettingsSettings?, WifiSettingsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    final usp = ref.read(uspClientProvider);
    if (usp == null) {
      return (
        null,
        WifiSettingsStatus(
          error: const ServiceNotInitializedError(
              detail: 'USP service not available'),
        )
      );
    }

    // No auth gate here: the router already guards all /usp routes on
    // loginType (RA-aware), and the WiFi data layer surfaces real errors. The
    // raw usp.isAuthenticated flag is a WASM transport signal that stays false
    // in Remote Assistance (authToken bypass), so gating on it here wrongly
    // blocked RA sessions (issue #1119). The usp == null gate above still
    // covers the "USP unavailable" case.
    logger.d('[USP][WiFi]: Fetching WiFi data...');

    // Read from WiFi Data Provider (Layer 1) to avoid duplicate fetch.
    // wifiDataProvider may throw (e.g. TimeoutException when the bridge is
    // temporarily unavailable). Catch and return error status so the UI exits
    // loading and displays the error instead of hanging.
    final WifiData wifiData;
    try {
      wifiData = await ref.read(wifiDataProvider.future);
    } on ServiceError catch (e) {
      logger.w('[USP][WiFi]: WiFi data fetch failed: $e');
      return (
        null,
        WifiSettingsStatus(error: e),
      );
    }
    final (:radios, :ssids, :accessPoints) = wifiData.codegenContext.raw;

    final networks = _svc.buildWifiNetworks(
      ssids: ssids,
      accessPoints: accessPoints,
      radios: radios,
    );

    final quickSetup = _svc.buildQuickSetupNetworks(networks);

    logger.d('[USP][WiFi]: Loaded ${networks.length} networks, '
        'isQuickSetup=${quickSetup.isQuickSetup}');

    // Preserve the current quickSetupEnabled flag across re-fetches so the
    // user's mode selection is not reset by background refreshes.
    final currentQsEnabled = state.settings.current.quickSetupEnabled;
    final effectiveQsEnabled = quickSetup.isQuickSetup || currentQsEnabled;

    WifiQuickSetupSettings? qsMain;
    WifiQuickSetupSettings? qsGuest;

    if (effectiveQsEnabled) {
      qsMain = quickSetup.main != null
          ? _buildQsSettings(quickSetup.main!,
              isGuest: false, networks: networks)
          : null;
      qsGuest = quickSetup.guest != null
          ? _buildQsSettings(quickSetup.guest!,
              isGuest: true, networks: networks)
          : null;
    }

    final newSettings = WifiSettingsSettings(
      networks: networks,
      quickSetupEnabled: effectiveQsEnabled,
      quickSetupMain: qsMain,
      quickSetupGuest: qsGuest,
    );

    final newStatus = WifiSettingsStatus(
      quickSetupMainAggregate: quickSetup.main,
      quickSetupGuestAggregate: quickSetup.guest,
    );

    return (newSettings, newStatus);
  }

  // ---------------------------------------------------------------------------
  // save — override to manage isSaving flag
  // ---------------------------------------------------------------------------

  /// Writes and marks the page saved; **does not read it back**.
  ///
  /// The radios are reloading once the write has landed, so the read-back
  /// belongs after the recovery the caller runs around this — see
  /// [readBackAfterRecovery] (#1212). The router-away case hands over to
  /// [confirmAfterRecovery] as before.
  @override
  Future<UspWifiSettingsState> save() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );
    try {
      final baseline = state.settings.original;
      await performSave();
      if (awaitsRouterRecovery) _baselineAwaitingRecovery = baseline;
      markAsSaved();
      return state;
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi]: Save failed', error: e);
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
    _proofAwaitingRecovery = null;
    // One SET, then — if its reply is lost to the WiFi reload — a read-back
    // before success or failure is reported (#1499, #1460; see
    // [wifiWriteConfirmProvider]).
    final current = state.settings.current;
    final WifiConfirmResult result;
    try {
      final plan = current.quickSetupEnabled
          ? _svc.saveQuickSetup(
              original: state.settings.original,
              current: current,
              status: state.status,
            )
          : _svc.saveAdvanced(
              original: state.settings.original.networks,
              current: current.networks,
            );
      result = await ref.read(wifiWriteConfirmProvider)(
        plan,
        isApplied: _svc.isApplied,
        // Only the page save: a rename moves the browser off the network it is
        // on, and only the user can bring it back. See [WifiRouterAway].
        allowRouterAway: true,
      );
    } catch (_) {
      // Keep the UI in sync even when the write failed.
      await _refreshL1AfterWrite();
      rethrow;
    }

    // Router away: [confirmAfterRecovery] reads it back once it is back.
    // Otherwise the write is confirmed and L1 is refreshed, with the form, by
    // [readBackAfterRecovery] — not here, while the radios reload.
    if (result case WifiRouterAway(:final proof)) {
      _proofAwaitingRecovery = proof;
    }
  }

  /// Re-reads L1 after a write, without letting the re-read decide the save.
  ///
  /// The write's outcome is already settled when this runs, so a failed
  /// refresh is logged, not thrown: on the save path it now runs after the
  /// recovery ([readBackAfterRecovery]), and #1499's failure — this read
  /// timing out on the 15 s throttler mid-reload and turning a landed save
  /// into "Something went wrong" — is what that ordering exists to avoid. The
  /// form read that follows is what reports a read that still fails.
  ///
  /// It also has MLO's status read again (#1692): MLO needs the main bands'
  /// SSID, password and security to match, which is what this page edits.
  Future<void> _refreshL1AfterWrite() async {
    ref.invalidate(mloStatusProvider);
    try {
      final _ = await ref.refresh(wifiDataProvider.future);
    } on ServiceError catch (e) {
      // L1 maps every USP failure to a ServiceError (usp_wifi_data_service),
      // so this is its whole failure surface; anything else is a bug and
      // propagates (constitution §13.4).
      logger.w(
          '[USP][WiFi]: L1 refresh after the write failed — the write '
          'itself is settled',
          error: e);
    }
  }

  // ---------------------------------------------------------------------------
  // UI setter methods — all update settings.current via Preservable.update()
  // ---------------------------------------------------------------------------

  /// Updates one or more writable fields for the network at [ssidInstancePath].
  void updateNetworkField(
    String ssidInstancePath, {
    bool? enabled,
    String? ssid,
    String? password,
    String? securityMode,
    bool? broadcastSsid,
    String? operatingStandards,
    String? channelBandwidth,
    int? channel,
    bool? autoChannel,
  }) {
    final current = state.settings.current;
    final updatedNetworks = current.networks.map((n) {
      if (n.ssidInstancePath != ssidInstancePath) return n;
      var updated = n.copyWith(
        enabled: enabled,
        ssid: ssid,
        keyPassphrase: password,
        securityMode: securityMode,
        ssidAdvertisementEnabled: broadcastSsid,
        operatingStandards: operatingStandards,
        channelBandwidth: channelBandwidth,
        channel: autoChannel == true ? n.channel : (channel ?? n.channel),
        autoChannelEnable: autoChannel,
      );

      // Auto-reset channel to Auto when bandwidth changes and the current
      // manual channel is no longer valid for the new bandwidth.
      if (channelBandwidth != null && !updated.autoChannelEnable) {
        final validChannels =
            updated.availableChannelsPerBandwidth[channelBandwidth];
        if (validChannels != null &&
            validChannels.isNotEmpty &&
            !validChannels.contains(updated.channel)) {
          updated = updated.copyWith(autoChannelEnable: true);
        }
      }

      return updated;
    }).toList();

    state = state.copyWith(
      settings: state.settings.update(
        current.copyWith(networks: updatedNetworks),
      ),
    );
  }

  /// Toggles Quick Setup mode ON or OFF.
  ///
  /// **Call it on a clean form.** It makes the current settings the new
  /// baseline, so unsaved per-network edits would be carried in silently —
  /// hidden by Quick Setup, and read later as if the router held them (#1499
  /// review round 2). The WiFi tab asks the user and reverts first; any new
  /// caller must do the same.
  ///
  /// When enabling, initialises [WifiQuickSetupSettings] from the current
  /// server-side aggregate data (password starts empty — TR-181 cannot return it).
  /// When disabling, clears the pending Quick Setup settings.
  void setQuickSetupEnabled(bool enabled) {
    final current = state.settings.current;
    if (enabled) {
      final mainAgg = state.status.quickSetupMainAggregate;
      final guestAgg = state.status.quickSetupGuestAggregate;
      final newSettings = current.copyWith(
        quickSetupEnabled: true,
        quickSetupMain:
            mainAgg != null ? _buildQsSettings(mainAgg, isGuest: false) : null,
        quickSetupGuest:
            guestAgg != null ? _buildQsSettings(guestAgg, isGuest: true) : null,
      );
      state = state.copyWith(
        settings: Preservable(original: newSettings, current: newSettings),
      );
    } else {
      final newSettings = current.copyWith(
        quickSetupEnabled: false,
        clearQuickSetupMain: true,
        clearQuickSetupGuest: true,
      );
      state = state.copyWith(
        settings: Preservable(original: newSettings, current: newSettings),
      );
    }
  }

  /// Updates one or more fields in the Quick Setup pending state for [isGuest].
  void updateQuickSetupField({
    required bool isGuest,
    bool? enabled,
    String? ssid,
    String? password,
    String? securityMode,
  }) {
    final current = state.settings.current;
    if (isGuest) {
      final updated = current.quickSetupGuest?.copyWith(
        enabled: enabled,
        ssid: ssid,
        password: password,
        securityMode: securityMode,
      );
      if (updated != null) {
        state = state.copyWith(
          settings:
              state.settings.update(current.copyWith(quickSetupGuest: updated)),
        );
      }
    } else {
      final updated = current.quickSetupMain?.copyWith(
        enabled: enabled,
        ssid: ssid,
        password: password,
        securityMode: securityMode,
      );
      if (updated != null) {
        state = state.copyWith(
          settings:
              state.settings.update(current.copyWith(quickSetupMain: updated)),
        );
      }
    }
  }

  // ---------------------------------------------------------------------------
  // Dashboard quick actions — delegate to Service, then invalidate L1
  // ---------------------------------------------------------------------------

  /// Updates a WiFi radio's channel. Called from Dashboard card.
  Future<void> updateRadioChannel(
    String instancePath, {
    required int channel,
    required bool autoChannel,
  }) async {
    try {
      await ref.read(wifiWriteConfirmProvider)(
        _svc.updateRadioChannel(
          instancePath,
          channel: channel,
          autoChannel: autoChannel,
        ),
        isApplied: _svc.isApplied,
      );
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi]: Update radio channel failed', error: e);
      rethrow;
    } finally {
      ref.invalidate(wifiDataProvider);
      // MLO needs both main bands on with matching settings (#1692).
      ref.invalidate(mloStatusProvider);
    }
  }

  /// Toggles all SSIDs with a given name on/off across all bands.
  /// Called from Dashboard WiFi Networks card.
  Future<void> toggleSsidsByName(String ssidName, bool enable) async {
    try {
      // The paths are read from L1 BEFORE the lock, not inside it as they used
      // to be: the read-back needs the planned params up front, so they must
      // exist before the write is sent (see WifiWritePlan), and the lock is not
      // re-entrant. The window this opens is narrow and its worst case is a
      // toggle of paths valid a moment earlier, which the read-back then
      // reports truthfully. The write itself is still serialised by the lock.
      final wifiData = await ref.read(wifiDataProvider.future);
      final result = await ref.read(wifiWriteConfirmProvider)(
        _svc.toggleSsidsByName(
          wifiData.codegenContext.raw.ssids,
          wifiData.codegenContext.raw.accessPoints,
          ssidName,
          enable,
        ),
        isApplied: _svc.isApplied,
      );
      // A toggle does not rename the network the browser is on, so it never
      // asks for allowRouterAway: an unreachable router by the deadline is a
      // failure, and only WifiConfirmed comes back.
      final count = switch (result) {
        WifiConfirmed(:final count) => count,
        WifiRouterAway() => throw const UnexpectedError(),
      };
      if (count == 0) {
        logger.w('[USP][WiFi]: No SSIDs found matching the requested name');
        throw const InvalidInputError(
            detail: 'No matching WiFi networks found');
      }
      logger.d('[USP][WiFi]: Toggled $count SSIDs to $enable');
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi]: Toggle SSIDs by name failed', error: e);
      rethrow;
    } finally {
      ref.invalidate(wifiDataProvider);
      // MLO needs both main bands on with matching settings (#1692).
      ref.invalidate(mloStatusProvider);
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  WifiQuickSetupSettings _buildQsSettings(
    WifiQuickSetupNetwork aggregate, {
    required bool isGuest,
    List<WifiNetworkUIModel>? networks,
  }) {
    // enabled = true only when ALL networks in the group are currently enabled.
    // Use the explicit [networks] list when called from performFetch (the new
    // networks haven't been written to state yet at that point).
    final effectiveNetworks = networks ?? state.settings.current.networks;
    final allEnabled = effectiveNetworks
        .where((n) => n.isGuest == isGuest)
        .every((n) => n.enabled);

    return WifiQuickSetupSettings(
      isGuest: isGuest,
      enabled: allEnabled,
      ssid: aggregate.ssid,
      password: '',
      securityMode: aggregate.securityMode,
      supportedSecurityModes: aggregate.supportedSecurityModes,
    );
  }

  // ---------------------------------------------------------------------------
  // Convenience accessor for the effective (displayed) network model
  // ---------------------------------------------------------------------------

  /// Returns the network model for [ssidInstancePath] from [settings.current].
  WifiNetworkUIModel? effectiveNetwork(String ssidInstancePath) {
    try {
      return state.settings.current.networks.firstWhere(
        (n) => n.ssidInstancePath == ssidInstancePath,
      );
    } catch (_) {
      return null;
    }
  }
}

// ---------------------------------------------------------------------------
// Route-level Dirty Proxy
// ---------------------------------------------------------------------------

/// Aggregates dirty state from both WiFi tabs for the route's onExit guard.
class _WifiPageDirtyProxy
    implements PreservableContract<WifiSettingsSettings, WifiSettingsStatus> {
  final List<PreservableContract> _tabs;

  _WifiPageDirtyProxy(this._tabs);

  @override
  bool isDirty() => _tabs.any((t) => t.isDirty());

  @override
  void revert() {
    for (final t in _tabs) {
      if (t.isDirty()) t.revert();
    }
  }

  @override
  Future<(WifiSettingsSettings?, WifiSettingsStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) =>
      throw UnsupportedError('Route proxy — not callable');

  @override
  Future<void> performSave() =>
      throw UnsupportedError('Route proxy — not callable');
}
