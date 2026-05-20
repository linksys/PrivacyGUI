import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
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

  // ─── Factory Default Detection ───────────────────────────

  /// Fetch device info for PnP flow.
  /// Must be called AFTER successful login.
  ///
  /// Note: Factory default detection is now handled by the
  /// `/api/v1/setup/status` API endpoint. This method only
  /// fetches device metadata (serialNumber, modelName).
  Future<FactoryDefaultCheckResult> checkFactoryDefault() async {
    final info = await SystemInfo.fetch(_usp);
    return FactoryDefaultCheckResult(
      isFactoryDefault: false,
      serialNumber: info.serialNumber,
      modelName: info.modelName,
    );
  }

  // ─── Internet Check ──────────────────────────────────────

  /// Returns true if WAN is up with a valid IP address.
  Future<bool> checkInternetConnected() async {
    final wan = await WanStatus.fetch(_usp);
    return wan.status == 'Up' && wan.ipAddress.isNotEmpty;
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
  /// Separates main vs guest SSIDs by detecting shared radios:
  /// - First SSID per radio = main network
  /// - Additional SSIDs sharing a radio = guest network
  Future<PnpWizardFetchResult> fetchWizardData() async {
    final results = await Future.wait([
      WiFiSsids.fetch(_usp),
      WiFiAccessPoints.fetch(_usp),
    ]);

    final ssids = results[0] as WiFiSsids;
    final aps = results[1] as WiFiAccessPoints;

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

    // Separate main vs guest SSIDs by radio occupancy.
    // First SSID per radio is "main", subsequent SSIDs on the same radio
    // are "guest" (they share the radio via virtual AP).
    final seenRadios = <String>{};
    final mainSsids = <WiFiSsid>[];
    final guestSsids = <WiFiSsid>[];

    for (final ssid in ssids.items) {
      if (seenRadios.contains(ssid.lowerLayers)) {
        guestSsids.add(ssid);
      } else {
        seenRadios.add(ssid.lowerLayers);
        mainSsids.add(ssid);
      }
    }

    // Primary SSID = first enabled main SSID
    final primarySsid = mainSsids.firstWhere(
      (s) => s.enable,
      orElse: () => mainSsids.first,
    );
    final primaryAp = apForSsid(primarySsid);

    // Main network paths (all main bands)
    final ssidPaths = <String>[];
    final apPaths = <String>[];
    for (final ssid in mainSsids) {
      ssidPaths.add(ssid.instancePath);
      final ap = apForSsid(ssid);
      if (ap != null) apPaths.add(ap.instancePath);
    }

    // Guest network — first guest SSID (if any)
    final guestSsid = guestSsids.isNotEmpty ? guestSsids.first : null;
    final guestAp = guestSsid != null ? apForSsid(guestSsid) : null;
    final guestSsidPaths = <String>[];
    final guestApPaths = <String>[];
    for (final ssid in guestSsids) {
      guestSsidPaths.add(ssid.instancePath);
      final ap = apForSsid(ssid);
      if (ap != null) guestApPaths.add(ap.instancePath);
    }

    final wifiConfig = PnpWifiConfig(
      ssid: primarySsid.ssid,
      password: primaryAp?.keyPassphrase ?? '',
      originalSsid: primarySsid.ssid,
      originalPassword: primaryAp?.keyPassphrase ?? '',
      ssidInstancePaths: ssidPaths,
      accessPointInstancePaths: apPaths,
      guestEnabled: guestSsid?.enable ?? false,
      guestSsid: guestSsid?.ssid ?? '',
      guestPassword: guestAp?.keyPassphrase ?? '',
      originalGuestEnabled: guestSsid?.enable ?? false,
      originalGuestSsid: guestSsid?.ssid ?? '',
      originalGuestPassword: guestAp?.keyPassphrase ?? '',
      guestSsidInstancePaths: guestSsidPaths,
      guestAccessPointInstancePaths: guestApPaths,
    );

    return PnpWizardFetchResult(wifiConfig: wifiConfig);
  }

  // ─── Wizard Save ─────────────────────────────────────────

  /// Save WiFi SSID + password changes across all enabled bands.
  Future<void> saveWifi(PnpWifiConfig config) async {
    // ── Main WiFi ──
    if (config.isSsidChanged) {
      final ssidUpdates = config.ssidInstancePaths
          .map((path) => WiFiSsidUpdate(instancePath: path, ssid: config.ssid))
          .toList();
      await WiFiSsids.update(_usp, ssidUpdates);
    }

    if (config.isPasswordChanged) {
      final apUpdates = config.accessPointInstancePaths
          .map((path) => WiFiAccessPointUpdate(
                instancePath: path,
                keyPassphrase: config.password,
              ))
          .toList();
      await WiFiAccessPoints.update(_usp, apUpdates);
    }

    // ── Guest WiFi ──
    if (config.isGuestDirty && config.guestSsidInstancePaths.isNotEmpty) {
      // Enable/disable + SSID
      if (config.isGuestEnabledChanged || config.isGuestSsidChanged) {
        final guestSsidUpdates = config.guestSsidInstancePaths
            .map((path) => WiFiSsidUpdate(
                  instancePath: path,
                  ssid: config.guestSsid,
                  enable: config.guestEnabled,
                ))
            .toList();
        await WiFiSsids.update(_usp, guestSsidUpdates);
      }

      // Password
      if (config.isGuestPasswordChanged) {
        final guestApUpdates = config.guestAccessPointInstancePaths
            .map((path) => WiFiAccessPointUpdate(
                  instancePath: path,
                  keyPassphrase: config.guestPassword,
                ))
            .toList();
        await WiFiAccessPoints.update(_usp, guestApUpdates);
      }
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
    final edited = config.applyTo(original);

    await internetSettingsService.saveAll(
      original,
      edited,
      pppInstancePath: fetchResult.pppInstancePath,
      vlanInstancePath: fetchResult.vlanInstancePath,
    );
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
    await DeviceOperations.reboot(_usp);
  }

  /// Check if the router is back by fetching SystemInfo.
  /// Returns serial number on success, throws on failure.
  Future<String> checkRouterIsBack() async {
    final info = await SystemInfo.fetch(_usp);
    return info.serialNumber;
  }
}
