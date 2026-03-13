import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/providers/preservable_contract.dart';
import 'package:privacy_gui/providers/preservable_notifier_mixin.dart';
import 'package:privacy_gui/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_network_ui_model.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_quick_setup_network.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_settings_settings.dart';
import 'package:privacy_gui/usp_page/wifi_settings/models/wifi_settings_status.dart';
import 'package:privacy_gui/usp_page/wifi_settings/providers/usp_wifi_settings_state.dart';
import 'package:privacy_gui/usp_page/wifi_settings/services/usp_wifi_settings_service.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final uspWifiSettingsProvider = AutoDisposeNotifierProvider<
    UspWifiSettingsNotifier, UspWifiSettingsState>(
  UspWifiSettingsNotifier.new,
);

/// Exposes the notifier as a [PreservableContract] for [LinksysRoute]
/// dirty-check integration.
final preservableUspWifiSettingsProvider =
    AutoDisposeProvider<PreservableContract<WifiSettingsSettings, WifiSettingsStatus>>(
  (ref) => ref.watch(uspWifiSettingsProvider.notifier),
);

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class UspWifiSettingsNotifier extends AutoDisposeNotifier<UspWifiSettingsState>
    with
        PreservableAutoDisposeNotifierMixin<WifiSettingsSettings,
            WifiSettingsStatus, UspWifiSettingsState> {
  UspService get _usp {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) throw StateError('USP service not available');
    return usp;
  }

  UspWifiSettingsService get _svc => ref.read(uspWifiSettingsServiceProvider);

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
    final usp = ref.read(uspServiceProvider);
    if (usp == null) {
      return (null, WifiSettingsStatus(errorMessage: 'USP service not available'));
    }

    if (!usp.isAuthenticated) {
      await ref.read(uspAuthCoordinatorProvider).restoreSession();
      if (!usp.isAuthenticated) {
        return (null, WifiSettingsStatus(errorMessage: 'USP not authenticated'));
      }
    }

    logger.d('[WiFiSettings] Fetching WiFi data...');

    final results = await Future.wait([
      WiFiSsids.fetch(usp),
      WiFiAccessPoints.fetch(usp),
      WiFiRadios.fetch(usp),
    ]);

    final ssids = results[0] as WiFiSsids;
    final accessPoints = results[1] as WiFiAccessPoints;
    final radios = results[2] as WiFiRadios;

    final networks = _svc.buildWifiNetworks(
      ssids: ssids,
      accessPoints: accessPoints,
      radios: radios,
    );

    final quickSetup = _svc.buildQuickSetupNetworks(networks);

    logger.d('[WiFiSettings] Loaded ${networks.length} networks, '
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
      state = state.copyWith(
        status: state.status.copyWith(isSaving: false),
      );
      rethrow;
    }
  }

  // ---------------------------------------------------------------------------
  // performSave — required by PreservableAutoDisposeNotifierMixin
  // ---------------------------------------------------------------------------

  @override
  Future<void> performSave() async {
    final current = state.settings.current;
    if (current.quickSetupEnabled) {
      await _saveQuickSetup(current);
    } else {
      await _saveAdvanced(current);
    }
  }

  Future<void> _saveQuickSetup(WifiSettingsSettings current) async {
    for (final pending in [current.quickSetupMain, current.quickSetupGuest]) {
      if (pending == null || !pending.isValid) continue;

      final aggregate = pending.isGuest
          ? state.status.quickSetupGuestAggregate
          : state.status.quickSetupMainAggregate;
      if (aggregate == null) continue;

      if (aggregate.ssidInstancePaths.isNotEmpty) {
        await WiFiSsids.updateMany(
          _usp,
          aggregate.ssidInstancePaths
              .map((p) => WiFiSsidUpdate(
                    instancePath: p,
                    ssid: pending.ssid,
                    enable: pending.enabled,
                  ))
              .toList(),
        );
      }
      if (aggregate.apInstancePaths.isNotEmpty) {
        // Build a band lookup: AP instance path → band string.
        // Used to apply the 6 GHz security override (Wi-Fi 6E mandates WPA3).
        final bandByApPath = <String, String>{};
        for (final n in state.settings.current.networks) {
          if (n.accessPointInstancePath != null) {
            bandByApPath[n.accessPointInstancePath!] = n.band;
          }
        }

        await WiFiAccessPoints.updateMany(
          _usp,
          aggregate.apInstancePaths
              .map((p) {
                final band = bandByApPath[p] ?? '';
                final securityMode = _securityModeFor6GHz(
                  band: band,
                  selectedMode: pending.securityMode,
                );
                return WiFiAccessPointUpdate(
                  instancePath: p,
                  keyPassphrase: pending.password,
                  securityModeEnabled: securityMode,
                );
              })
              .toList(),
        );
      }
    }
  }

  /// Returns the effective security mode to apply to a given band.
  ///
  /// 6 GHz (Wi-Fi 6E) mandates WPA3 — mirrors the old JNAP mapper logic:
  ///   - Open / Enhanced-Open selected → send "Enhanced-Open"
  ///   - Any other mode               → send "WPA3-Personal"
  ///
  /// All other bands: return [selectedMode] unchanged.
  String _securityModeFor6GHz({
    required String band,
    required String selectedMode,
  }) {
    if (!band.contains('6')) return selectedMode;
    const openModes = {'None', 'Enhanced-Open', ''};
    return openModes.contains(selectedMode)
        ? 'Enhanced-Open'
        : 'WPA3-Personal';
  }

  Future<void> _saveAdvanced(WifiSettingsSettings current) async {
    final originalNetworks = state.settings.original.networks;

    for (var i = 0; i < current.networks.length; i++) {
      final curr = current.networks[i];
      final orig = originalNetworks.length > i ? originalNetworks[i] : null;

      // Skip unchanged networks.
      if (orig != null && orig == curr) continue;

      // ── SSID layer ─────────────────────────────────────────────────────
      if (orig == null ||
          orig.enabled != curr.enabled ||
          orig.ssid != curr.ssid) {
        await WiFiSsids.update(
          _usp,
          WiFiSsidUpdate(
            instancePath: curr.ssidInstancePath,
            enable: curr.enabled,
            ssid: curr.ssid,
          ),
        );
      }

      // ── AccessPoint layer ───────────────────────────────────────────────
      final ap = curr.accessPointInstancePath;
      if (ap != null &&
          (orig == null ||
              orig.keyPassphrase != curr.keyPassphrase ||
              orig.securityMode != curr.securityMode ||
              orig.ssidAdvertisementEnabled != curr.ssidAdvertisementEnabled)) {
        await WiFiAccessPoints.update(
          _usp,
          WiFiAccessPointUpdate(
            instancePath: ap,
            keyPassphrase: curr.keyPassphrase.isNotEmpty
                ? curr.keyPassphrase
                : null,
            securityModeEnabled: curr.securityMode.isNotEmpty
                ? curr.securityMode
                : null,
            ssidAdvertisementEnabled: curr.ssidAdvertisementEnabled,
          ),
        );
      }

      // ── Radio layer ─────────────────────────────────────────────────────
      final radio = curr.radioInstancePath;
      if (radio != null &&
          (orig == null ||
              orig.operatingStandards != curr.operatingStandards ||
              orig.channelBandwidth != curr.channelBandwidth ||
              orig.channel != curr.channel ||
              orig.autoChannelEnable != curr.autoChannelEnable)) {
        await WiFiRadios.update(
          _usp,
          WiFiRadioUpdate(
            instancePath: radio,
            operatingStandards: curr.operatingStandards.isNotEmpty
                ? curr.operatingStandards
                : null,
            operatingChannelBandwidth: curr.channelBandwidth.isNotEmpty
                ? curr.channelBandwidth
                : null,
            autoChannelEnable: curr.autoChannelEnable,
            channel: curr.autoChannelEnable ? null : curr.channel,
          ),
        );
      }
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
      return n.copyWith(
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
          settings: state.settings
              .update(current.copyWith(quickSetupGuest: updated)),
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
          settings: state.settings
              .update(current.copyWith(quickSetupMain: updated)),
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
