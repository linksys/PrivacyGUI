import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/framework/preservable_notifier_mixin.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_quick_setup_network.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspWifiSettingsProvider =
    AutoDisposeNotifierProvider<UspWifiSettingsNotifier, UspWifiSettingsState>(
  UspWifiSettingsNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspWifiSettingsProvider = AutoDisposeProvider<
    PreservableContract<WifiSettingsSettings, WifiSettingsStatus>>(
  (ref) => ref.watch(uspWifiSettingsProvider.notifier),
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
    final usp = ref.read(uspServiceProvider);
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

    logger.d('[USP][WiFi]Fetching WiFi data...');

    // Read from WiFi Data Provider (Layer 1) to avoid duplicate fetch.
    // wifiDataProvider may throw (e.g. TimeoutException when the bridge is
    // temporarily unavailable). Catch and return error status so the UI exits
    // loading and displays the error instead of hanging.
    final WifiData wifiData;
    try {
      wifiData = await ref.read(wifiDataProvider.future);
    } catch (e) {
      logger.w('[USP][WiFi] WiFi data fetch failed: $e');
      return (
        null,
        WifiSettingsStatus(errorMessage: 'WiFi data unavailable'),
      );
    }
    final (:radios, :ssids, :accessPoints) = wifiData.codegenContext.raw;

    final networks = _svc.buildWifiNetworks(
      ssids: ssids,
      accessPoints: accessPoints,
      radios: radios,
    );

    final quickSetup = _svc.buildQuickSetupNetworks(networks);

    logger.d('[USP][WiFi]Loaded ${networks.length} networks, '
        'isQuickSetup=${quickSetup.isQuickSetup}');

    // Preserve the current quickSetupEnabled flag across re-fetches so the
    // user's mode selection is not reset by background refreshes.
    final currentQsEnabled = state.settings.current.quickSetupEnabled;
    final effectiveQsEnabled = quickSetup.isQuickSetup || currentQsEnabled;

    WifiQuickSetupSettings? qsMain;
    WifiQuickSetupSettings? qsGuest;

    if (effectiveQsEnabled) {
      qsMain = quickSetup.main != null
          ? _buildQsSettings(quickSetup.main!, isGuest: false)
          : null;
      qsGuest = quickSetup.guest != null
          ? _buildQsSettings(quickSetup.guest!, isGuest: true)
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
      return await super.save();
      // super.save() calls performSave() → markAsSaved() → fetch().
      // fetch() rebuilds status with a fresh WifiSettingsStatus (isSaving = false).
    } catch (e) {
      logger.e('[USP][WiFi] Save failed', error: e);
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
        await _svc.saveQuickSetup(current: current, status: state.status);
      } else {
        await _svc.saveAdvanced(
          original: state.settings.original.networks,
          current: current.networks,
        );
      }
    });
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
      state = state.copyWith(
        settings: state.settings.update(
          current.copyWith(
            quickSetupEnabled: true,
            quickSetupMain: mainAgg != null
                ? _buildQsSettings(mainAgg, isGuest: false)
                : null,
            quickSetupGuest: guestAgg != null
                ? _buildQsSettings(guestAgg, isGuest: true)
                : null,
          ),
        ),
      );
    } else {
      state = state.copyWith(
        settings: state.settings.update(
          current.copyWith(
            quickSetupEnabled: false,
            clearQuickSetupMain: true,
            clearQuickSetupGuest: true,
          ),
        ),
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
  // Helpers
  // ---------------------------------------------------------------------------

  WifiQuickSetupSettings _buildQsSettings(
    WifiQuickSetupNetwork aggregate, {
    required bool isGuest,
  }) {
    // enabled = true only when ALL networks in the group are currently enabled.
    final allEnabled = state.settings.current.networks
        .where((n) => n.isGuest == isGuest)
        .every((n) => n.enabled);

    return WifiQuickSetupSettings(
      isGuest: isGuest,
      enabled: allEnabled,
      ssid: aggregate.ssid,
      password: '',
      securityMode: aggregate.supportedSecurityModes.isNotEmpty
          ? aggregate.supportedSecurityModes.first
          : aggregate.securityMode,
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
