import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_quick_setup_network.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspWifiSettingsProvider =
    AutoDisposeNotifierProvider<UspWifiSettingsNotifier, UspWifiSettingsState>(
  UspWifiSettingsNotifier.new,
);

/// Route-level dirty proxy — aggregates both WiFi tabs' dirty state.
/// Only isDirty() and revert() are invoked by LinksysRoute.onExit.
final preservableUspWifiPageProvider = AutoDisposeProvider<
    PreservableContract<WifiSettingsSettings, WifiSettingsStatus>>(
  (ref) => _WifiPageDirtyProxy(
    ref.watch(uspWifiSettingsProvider.notifier),
    ref.watch(uspWifiAdvancedProvider.notifier),
  ),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspWifiSettingsNotifier extends AutoDisposeNotifier<UspWifiSettingsState>
    with
        PreservableAutoDisposeNotifierMixin<WifiSettingsSettings,
            WifiSettingsStatus, UspWifiSettingsState> {
  UspWifiSettingsService get _svc => ref.read(uspWifiSettingsServiceProvider);

  @override
  UspWifiSettingsState build() {
    // SSE: when WiFi data provider updates, trigger dirty guard
    ref.listen(wifiDataProvider, (_, next) {
      if (next.hasValue) onSseInvalidation();
    });
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
        WifiSettingsStatus(errorMessage: 'USP service not available')
      );
    }

    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) {
        return (
          null,
          WifiSettingsStatus(errorMessage: 'USP not authenticated')
        );
      }
    }

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
        WifiSettingsStatus(errorMessage: '$e'),
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

  @override
  Future<UspWifiSettingsState> save() async {
    state = state.copyWith(
      status: state.status.copyWith(isSaving: true),
    );
    try {
      final result = await super.save();
      return result;
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
    await ref.read(uspMutationLockProvider).withLock(() async {
      final current = state.settings.current;
      if (current.quickSetupEnabled) {
        await _svc.saveQuickSetup(
          original: state.settings.original,
          current: current,
          status: state.status,
        );
      } else {
        await _svc.saveAdvanced(
          original: state.settings.original.networks,
          current: current.networks,
        );
      }
    });
    // Refresh Layer 1 cache so post-save fetch() reads fresh data.
    // Using refresh() instead of invalidate() because the latter only marks
    // the provider dirty — without an active subscriber it won't rebuild,
    // and the subsequent .future call would return stale data.
    final _ = await ref.refresh(wifiDataProvider.future);
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

  /// Toggles a WiFi radio on/off. Called from Dashboard card.
  Future<void> toggleRadio(String instancePath, bool enable) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.toggleRadio(instancePath, enable);
      });
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi]: Toggle radio failed', error: e);
      rethrow;
    }
    ref.invalidate(wifiDataProvider);
  }

  /// Updates a WiFi radio's channel. Called from Dashboard card.
  Future<void> updateRadioChannel(
    String instancePath, {
    required int channel,
    required bool autoChannel,
  }) async {
    try {
      await ref.read(uspMutationLockProvider).withLock(() async {
        await _svc.updateRadioChannel(
          instancePath,
          channel: channel,
          autoChannel: autoChannel,
        );
      });
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi]: Update radio channel failed', error: e);
      rethrow;
    }
    ref.invalidate(wifiDataProvider);
  }

  /// Toggles all SSIDs with a given name on/off across all bands.
  /// Called from Dashboard WiFi Networks card.
  Future<void> toggleSsidsByName(String ssidName, bool enable) async {
    final wifiData = await ref.read(wifiDataProvider.future);
    final ssids = wifiData.codegenContext.raw.ssids;

    try {
      final count = await ref.read(uspMutationLockProvider).withLock(() async {
        return _svc.toggleSsidsByName(ssids, ssidName, enable);
      });
      if (count == 0) {
        logger.w('[USP][WiFi]: No SSIDs found matching the requested name');
        throw const InvalidInputError(
            detail: 'No matching WiFi networks found');
      }
      logger.d('[USP][WiFi]: Toggled $count SSIDs to $enable');
    } on ServiceError catch (e) {
      logger.e('[USP][WiFi]: Toggle SSIDs by name failed', error: e);
      rethrow;
    }
    ref.invalidate(wifiDataProvider);
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
  final UspWifiSettingsNotifier _wifiList;
  final UspWifiAdvancedNotifier _advanced;

  _WifiPageDirtyProxy(this._wifiList, this._advanced);

  @override
  bool isDirty() => _wifiList.isDirty() || _advanced.isDirty();

  @override
  void revert() {
    if (_wifiList.isDirty()) _wifiList.revert();
    if (_advanced.isDirty()) _advanced.revert();
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
