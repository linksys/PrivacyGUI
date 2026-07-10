import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/data_elements_network.g.dart';
import 'package:privacy_gui/generated/device_operations.g.dart';
import 'package:privacy_gui/generated/network_diagnostics.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/page/_shared/models/mesh_topology_info.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_topology_builder.dart';
import 'package:privacy_gui/page/_shared/utils/wifi_guest_detection.dart';
import 'package:privacy_gui/generated/wi_fi_radios.g.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

final pnpServiceProvider = Provider<PnpService>(
  (ref) => PnpService(ref.read(uspClientProvider)!),
);

/// Result of factory-default detection.
class FactoryDefaultCheckResult {
  final bool isFactoryDefault;
  final String serialNumber;
  final String modelName;

  const FactoryDefaultCheckResult({
    required this.isFactoryDefault,
    required this.serialNumber,
    required this.modelName,
  });
}

/// Result of fetching current WiFi config for the wizard.
class PnpWizardFetchResult {
  final PnpWifiConfig wifiConfig;

  const PnpWizardFetchResult({required this.wifiConfig});
}

/// Stateless service encapsulating ALL USP operations for PnP.
///
/// This is the only class that imports codegen generated files.
/// The notifier and views interact exclusively through this service.
///
/// Note: Authentication is now handled by LoginLocalView before PnP starts.
/// This service assumes the user is already authenticated.
class PnpService {
  final UspClient _usp;

  PnpService(this._usp);

  /// Expose UspClient for UspInternetSettingsService instantiation.
  UspClient get usp => _usp;

  // ─── Factory Default Detection ───────────────────────────

  /// Fetch device info for PnP flow.
  /// Must be called AFTER successful login.
  ///
  /// Note: Factory default detection is now handled by the
  /// `/api/v1/setup/status` API endpoint. This method only
  /// fetches device metadata (serialNumber, modelName).
  Future<FactoryDefaultCheckResult> checkFactoryDefault() async {
    try {
      final info = await SystemInfo.fetch(_usp);
      return FactoryDefaultCheckResult(
        isFactoryDefault: false,
        serialNumber: info.serialNumber,
        modelName: info.modelName,
      );
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ─── Internet Check ──────────────────────────────────────

  /// Returns true if WAN is up with a valid IP address.
  Future<bool> checkInternetConnected() async {
    try {
      final wan = await WanStatus.fetch(_usp);
      return wan.status == 'Up' && wan.ipAddress.isNotEmpty;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Ping 8.8.8.8 to verify actual internet connectivity.
  Future<bool> pingTest() async {
    try {
      await NetworkDiagnostics.ping(_usp, host: '8.8.8.8');
      return true;
    } catch (_) {
      return checkInternetConnected();
    }
  }

  // ─── Wizard Fetch ────────────────────────────────────────

  /// Fetch current WiFi SSIDs + Access Points and return structured results.
  ///
  /// Separates main vs guest SSIDs via the canonical alias rule: an SSID whose
  /// `Alias` ends with `-guest` is a guest network (see wifi_guest_detection).
  ///
  /// Supports both unified mode (all bands share SSID) and split mode
  /// (each band has different SSID, e.g. Du ISP routers).
  Future<PnpWizardFetchResult> fetchWizardData() async {
    final List<Object> results;
    try {
      results = await Future.wait([
        WiFiSsids.fetch(_usp),
        WiFiAccessPoints.fetch(_usp),
        WiFiRadios.fetch(_usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }

    final ssids = results[0] as WiFiSsids;
    final aps = results[1] as WiFiAccessPoints;
    final radios = results[2] as WiFiRadios;

    // Helper: find AP for a given SSID
    WiFiAccessPoint? apForSsid(WiFiSsid ssid) {
      for (final ap in aps.items) {
        final ref = ap.ssidReference.endsWith('.')
            ? ap.ssidReference
            : '${ap.ssidReference}.';
        if (ref == ssid.instancePath) return ap;
      }
      return null;
    }

    // Helper: find Radio for a given SSID (via LowerLayers)
    WiFiRadio? radioForSsid(WiFiSsid ssid) {
      final radioPath = ssid.lowerLayers.endsWith('.')
          ? ssid.lowerLayers
          : '${ssid.lowerLayers}.';
      return radios.items.where((r) => r.instancePath == radioPath).firstOrNull;
    }

    // Separate main vs guest SSIDs via the canonical alias rule (see
    // wifi_guest_detection). Single source of truth shared across the app.
    final mainSsids = <WiFiSsid>[];
    final guestSsids = <WiFiSsid>[];

    for (final ssid in ssids.items) {
      if (isGuestSsid(ssid)) {
        guestSsids.add(ssid);
      } else {
        mainSsids.add(ssid);
      }
    }

    // Diagnostic: multiple SSIDs but none matched the `-guest` alias rule
    // usually means firmware did not provision guest aliases (see
    // wifi_guest_detection). Guest/main split degrades silently otherwise.
    if (guestSsids.isEmpty && ssids.items.length > 1) {
      logger.w('[PnP] No SSID matched the "-guest" alias rule; '
          'guest network will be treated as main. Aliases: '
          '${ssids.items.map((s) => s.alias ?? "null").toList()}');
    }

    // Primary SSID = first enabled main SSID
    if (mainSsids.isEmpty) {
      logger.e('[PnP] No main WiFi SSIDs found on router');
      throw mapUspErrorToServiceError(
          StateError('No main WiFi SSIDs found on router'));
    }
    final primarySsid = mainSsids.firstWhere(
      (s) => s.enable,
      orElse: () => mainSsids.first,
    );
    final primaryAp = apForSsid(primarySsid);

    // Main network paths (all main bands) — for unified mode
    final ssidPaths = <String>[];
    final apPaths = <String>[];
    for (final ssid in mainSsids) {
      ssidPaths.add(ssid.instancePath);
      final ap = apForSsid(ssid);
      if (ap != null) apPaths.add(ap.instancePath);
    }

    // Build per-band list for split mode detection and UI
    final mainBands = mainSsids.map((ssid) {
      final ap = apForSsid(ssid);
      final radio = radioForSsid(ssid);
      final freq = radio?.operatingFrequencyBand ?? '';
      return PnpWifiBand(
        bandName: bandNameFromFrequency(freq),
        frequency: freq,
        ssid: ssid.ssid,
        password: ap?.keyPassphrase ?? '',
        originalSsid: ssid.ssid,
        originalPassword: ap?.keyPassphrase ?? '',
        ssidInstancePath: ssid.instancePath,
        accessPointInstancePath: ap?.instancePath ?? '',
        radioPath: ssid.lowerLayers,
      );
    }).toList()
      ..sort((a, b) => frequencySortKey(a.frequency)
          .compareTo(frequencySortKey(b.frequency)));

    // Guest network — for unified mode
    final guestSsid = guestSsids.isNotEmpty ? guestSsids.first : null;
    final guestAp = guestSsid != null ? apForSsid(guestSsid) : null;
    final guestSsidPaths = <String>[];
    final guestApPaths = <String>[];
    for (final ssid in guestSsids) {
      guestSsidPaths.add(ssid.instancePath);
      final ap = apForSsid(ssid);
      if (ap != null) guestApPaths.add(ap.instancePath);
    }

    // Build per-band list for guest split mode
    final guestBands = guestSsids.map((ssid) {
      final ap = apForSsid(ssid);
      final radio = radioForSsid(ssid);
      final freq = radio?.operatingFrequencyBand ?? '';
      return PnpWifiBand(
        bandName: bandNameFromFrequency(freq),
        frequency: freq,
        ssid: ssid.ssid,
        password: ap?.keyPassphrase ?? '',
        originalSsid: ssid.ssid,
        originalPassword: ap?.keyPassphrase ?? '',
        ssidInstancePath: ssid.instancePath,
        accessPointInstancePath: ap?.instancePath ?? '',
        radioPath: ssid.lowerLayers,
      );
    }).toList()
      ..sort((a, b) => frequencySortKey(a.frequency)
          .compareTo(frequencySortKey(b.frequency)));

    final wifiConfig = PnpWifiConfig(
      // Unified mode fields
      ssid: primarySsid.ssid,
      password: primaryAp?.keyPassphrase ?? '',
      originalSsid: primarySsid.ssid,
      originalPassword: primaryAp?.keyPassphrase ?? '',
      ssidInstancePaths: ssidPaths,
      accessPointInstancePaths: apPaths,
      // Split mode fields
      mainBands: mainBands,
      // Guest unified mode fields
      guestEnabled: guestSsid?.enable ?? false,
      guestSsid: guestSsid?.ssid ?? '',
      guestPassword: guestAp?.keyPassphrase ?? '',
      originalGuestEnabled: guestSsid?.enable ?? false,
      originalGuestSsid: guestSsid?.ssid ?? '',
      originalGuestPassword: guestAp?.keyPassphrase ?? '',
      guestSsidInstancePaths: guestSsidPaths,
      guestAccessPointInstancePaths: guestApPaths,
      // Guest split mode fields
      guestBands: guestBands,
    );

    return PnpWizardFetchResult(wifiConfig: wifiConfig);
  }

  // ─── Wizard Save ─────────────────────────────────────────

  /// Save WiFi SSID + password changes.
  ///
  /// Handles both unified mode (all bands share SSID) and split mode
  /// (each band has different SSID).
  Future<void> saveWifi(PnpWifiConfig config) async {
    try {
      // ── Main WiFi ──
      if (config.isSplitMode) {
        // Split mode: save per-band changes
        await _saveMainWifiSplitMode(config);
      } else {
        // Unified mode: apply same SSID/password to all bands
        await _saveMainWifiUnifiedMode(config);
      }

      // ── Guest WiFi ──
      if (config.isGuestDirty) {
        if (config.isGuestSplitMode) {
          // Split mode: save per-band changes
          await _saveGuestWifiSplitMode(config);
        } else if (config.guestSsidInstancePaths.isNotEmpty) {
          // Unified mode: apply same SSID/password to all bands
          await _saveGuestWifiUnifiedMode(config);
        }
      }
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  Future<void> _saveMainWifiUnifiedMode(PnpWifiConfig config) async {
    if (config.isSsidChanged) {
      final ssidUpdates = config.ssidInstancePaths
          .map((path) => WiFiSsidUpdate(instancePath: path, ssid: config.ssid))
          .toList();
      final ssidResult = await WiFiSsids.update(_usp, ssidUpdates);
      _throwIfNotSuccess(ssidResult, 'Main WiFi SSID update');
    }

    if (config.isPasswordChanged) {
      final apUpdates = config.accessPointInstancePaths
          .map((path) => WiFiAccessPointUpdate(
                instancePath: path,
                keyPassphrase: config.password,
              ))
          .toList();
      final apResult = await WiFiAccessPoints.update(_usp, apUpdates);
      _throwIfNotSuccess(apResult, 'Main WiFi password update');
    }
  }

  Future<void> _saveMainWifiSplitMode(PnpWifiConfig config) async {
    // Collect all bands that have changes
    final ssidUpdates = <WiFiSsidUpdate>[];
    final apUpdates = <WiFiAccessPointUpdate>[];

    for (final band in config.mainBands) {
      if (band.isSsidChanged) {
        ssidUpdates.add(WiFiSsidUpdate(
          instancePath: band.ssidInstancePath,
          ssid: band.ssid,
        ));
      }
      if (band.isPasswordChanged && band.accessPointInstancePath.isNotEmpty) {
        apUpdates.add(WiFiAccessPointUpdate(
          instancePath: band.accessPointInstancePath,
          keyPassphrase: band.password,
        ));
      }
    }

    if (ssidUpdates.isNotEmpty) {
      final ssidResult = await WiFiSsids.update(_usp, ssidUpdates);
      _throwIfNotSuccess(ssidResult, 'Main WiFi SSID update');
    }
    if (apUpdates.isNotEmpty) {
      final apResult = await WiFiAccessPoints.update(_usp, apUpdates);
      _throwIfNotSuccess(apResult, 'Main WiFi password update');
    }
  }

  Future<void> _saveGuestWifiUnifiedMode(PnpWifiConfig config) async {
    // Enable/disable + SSID
    if (config.isGuestEnabledChanged || config.isGuestSsidChanged) {
      final guestSsidUpdates = config.guestSsidInstancePaths
          .map((path) => WiFiSsidUpdate(
                instancePath: path,
                ssid: config.guestSsid,
                enable: config.guestEnabled,
              ))
          .toList();
      final ssidResult = await WiFiSsids.update(_usp, guestSsidUpdates);
      _throwIfNotSuccess(ssidResult, 'Guest WiFi SSID update');

      // Mirror enable state to AccessPoint layer (#972: SSID.Enable alone
      // does not stop the AP broadcasting on this firmware).
      if (config.isGuestEnabledChanged) {
        final apEnableUpdates = config.guestAccessPointInstancePaths
            .map((path) => WiFiAccessPointUpdate(
                  instancePath: path,
                  enable: config.guestEnabled,
                ))
            .toList();
        final apResult = await WiFiAccessPoints.update(_usp, apEnableUpdates);
        _throwIfNotSuccess(apResult, 'Guest WiFi AP enable update');
      }
    }

    // Password
    if (config.isGuestPasswordChanged) {
      final guestApUpdates = config.guestAccessPointInstancePaths
          .map((path) => WiFiAccessPointUpdate(
                instancePath: path,
                keyPassphrase: config.guestPassword,
              ))
          .toList();
      final apResult = await WiFiAccessPoints.update(_usp, guestApUpdates);
      _throwIfNotSuccess(apResult, 'Guest WiFi password update');
    }
  }

  Future<void> _saveGuestWifiSplitMode(PnpWifiConfig config) async {
    // Collect all bands that have changes
    final ssidUpdates = <WiFiSsidUpdate>[];
    final apUpdates = <WiFiAccessPointUpdate>[];
    final apEnableUpdates = <WiFiAccessPointUpdate>[];

    for (final band in config.guestBands) {
      // Always include enable state for guest bands
      if (band.isSsidChanged || config.isGuestEnabledChanged) {
        ssidUpdates.add(WiFiSsidUpdate(
          instancePath: band.ssidInstancePath,
          ssid: band.ssid,
          enable: config.guestEnabled,
        ));
        // Mirror enable state to AccessPoint layer (#972)
        if (config.isGuestEnabledChanged &&
            band.accessPointInstancePath.isNotEmpty) {
          apEnableUpdates.add(WiFiAccessPointUpdate(
            instancePath: band.accessPointInstancePath,
            enable: config.guestEnabled,
          ));
        }
      }
      if (band.isPasswordChanged && band.accessPointInstancePath.isNotEmpty) {
        apUpdates.add(WiFiAccessPointUpdate(
          instancePath: band.accessPointInstancePath,
          keyPassphrase: band.password,
        ));
      }
    }

    // If only enabling/disabling without SSID changes, still need to update enable state
    if (ssidUpdates.isEmpty && config.isGuestEnabledChanged) {
      for (final band in config.guestBands) {
        ssidUpdates.add(WiFiSsidUpdate(
          instancePath: band.ssidInstancePath,
          enable: config.guestEnabled,
        ));
        // Mirror enable state to AccessPoint layer (#972)
        if (band.accessPointInstancePath.isNotEmpty) {
          apEnableUpdates.add(WiFiAccessPointUpdate(
            instancePath: band.accessPointInstancePath,
            enable: config.guestEnabled,
          ));
        }
      }
    }

    if (ssidUpdates.isNotEmpty) {
      final ssidResult = await WiFiSsids.update(_usp, ssidUpdates);
      _throwIfNotSuccess(ssidResult, 'Guest WiFi SSID update');
    }
    // Write AP enable state before password updates (enable first, then configure)
    if (apEnableUpdates.isNotEmpty) {
      final apEnableResult =
          await WiFiAccessPoints.update(_usp, apEnableUpdates);
      _throwIfNotSuccess(apEnableResult, 'Guest WiFi AP enable update');
    }
    if (apUpdates.isNotEmpty) {
      final apResult = await WiFiAccessPoints.update(_usp, apUpdates);
      _throwIfNotSuccess(apResult, 'Guest WiFi password update');
    }
  }

  // ─── ISP/WAN Save ───────────────────────────────────────

  /// Save ISP settings by delegating to [UspInternetSettingsService].
  ///
  /// This ensures PNP uses the same save logic as Advanced Settings,
  /// including PPP/VLAN instance lifecycle, result validation, and
  /// allowPartial handling.
  Future<void> saveIspSettings(PnpIspConfig config) async {
    if (config.type == IspConnectionType.dhcp) {
      await WanOperations.renewDhcpLease(_usp);
      return;
    }

    final internetSettingsService = UspInternetSettingsService(_usp);
    final fetchResult = await internetSettingsService.fetchSettings();

    final original = fetchResult.form;
    final edited = _applyIspConfigToForm(config, original);

    await internetSettingsService.saveAll(
      original,
      edited,
      pppInstancePath: fetchResult.pppInstancePath,
      vlanInstancePath: fetchResult.vlanInstancePath,
    );
  }

  /// Map [PnpIspConfig] to [UspInternetSettingsForm].
  ///
  /// UI pre-fills fields from router's current settings, so submitted values
  /// represent the user's final intent — no need to preserve original on empty.
  UspInternetSettingsForm _applyIspConfigToForm(
    PnpIspConfig config,
    UspInternetSettingsForm original,
  ) {
    // dnsServer3 intentionally omitted — PNP has no UI for it, preserve original
    return original.copyWith(
      connectionType: _mapConnectionType(config.type),
      staticIpAddress: config.staticIpAddress,
      subnetMask: config.subnetMask,
      defaultGateway: config.defaultGateway,
      dnsServer1: config.dnsServer1,
      dnsServer2: config.dnsServer2,
      pppUsername: config.pppUsername,
      pppPassword: config.pppPassword,
      vlanEnabled: config.type == IspConnectionType.pppoeVlan,
      vlanId: config.vlanId,
    );
  }

  UspWanConnectionType _mapConnectionType(IspConnectionType type) {
    return switch (type) {
      IspConnectionType.dhcp => UspWanConnectionType.dhcp,
      IspConnectionType.pppoe => UspWanConnectionType.pppoe,
      IspConnectionType.pppoeVlan => UspWanConnectionType.pppoe,
      IspConnectionType.staticIp => UspWanConnectionType.staticIp,
    };
  }

  // ─── Mesh ──────────────────────────────────────────────

  /// Fetch mesh node list via DataElements (returns empty if non-mesh).
  Future<MeshTopologyInfo> fetchMeshTopology() async {
    try {
      final network = await DataElementsNetwork.fetch(_usp);
      if (network.items.isEmpty) {
        logger.d('[PnP] DataElements empty — not a mesh or unsupported');
        return MeshTopologyInfo.empty;
      }
      return _buildTopologyInfo(network);
    } catch (e) {
      logger.d('[PnP] DataElements not supported or fetch failed: $e');
      return MeshTopologyInfo.empty;
    }
  }

  MeshTopologyInfo _buildTopologyInfo(DataElementsNetwork network) {
    // PnP doesn't need backhaul stats — only node discovery for mesh setup
    final result =
        MeshTopologyBuilder.build(network, includeBackhaulStats: false);
    logger.d('[PnP] Mesh nodes: ${result.nodes.length}, '
        'client→node mappings: ${result.clientToNodeMap.length}');
    return result;
  }

  // ─── Utility ────────────────────────────────────────────

  /// Fetch the primary WiFi SSID name (for display in no-internet view).
  Future<String?> fetchCurrentSsid() async {
    try {
      final ssids = await WiFiSsids.fetch(_usp);
      return ssids.items.isNotEmpty ? ssids.items.first.ssid : null;
    } catch (_) {
      return null;
    }
  }

  // ─── Reboot & Reconnect ──────────────────────────────────

  /// Reboot the router. Connection will be lost.
  Future<void> reboot() async {
    try {
      await DeviceOperations.reboot(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Check if the router is back by fetching SystemInfo.
  /// Returns serial number on success, throws on failure.
  Future<String> checkRouterIsBack() async {
    try {
      final info = await SystemInfo.fetch(_usp);
      return info.serialNumber;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Throws [UspPartialFailureError] or [UspCompleteFailureError] if [result]
  /// is not a complete success. [label] prefixes the error summary.
  void _throwIfNotSuccess(Map<String, dynamic> result, String label) {
    final parsed = UspResultParser.parseSetResult(result);
    switch (parsed) {
      case UspSuccess():
        return;
      case UspPartialSuccess(failures: final f):
        throw UspPartialFailureError(
          summary: '$label partial failure: ${f.first.errorMessage}',
          successPaths: [],
          failures: f,
        );
      case UspFailure(errors: final e):
        throw UspCompleteFailureError(
          summary: '$label failed: ${e.first.errorMessage}',
          failures: e,
        );
    }
  }
}
