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

/// What the router said about the WiFi write.
///
/// [unanswered] is the ordinary outcome on FLWRT 2.0, not a fault: a WiFi write
/// restarts the network the browser is connected through, so its response has
/// nowhere to arrive. Measured on 2.0.1 RC3 (#1490): the SET came back 161–288 s
/// later as a `9999` transport failure, while the new SSID was already
/// broadcasting.
enum PnpWifiWriteOutcome { confirmed, unanswered }

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

  /// Save the whole WiFi form — guest and main — **in one SET**.
  ///
  /// One, because any WiFi write restarts every radio, main network included.
  /// Measured on FLWRT 2.0.2 (bench, 2026-10-05): a guest-only SET (turning guest
  /// off, or on) set off `bbf.config.wifi.reload`, the main 2.4/5 GHz VAPs were
  /// reconfigured ~14 s later, and the browser on the main network was dropped.
  /// So a save split into several SETs only ever has its first one on a live
  /// connection: the rest go out over a network that is restarting, and stall
  /// until the browser gives up — which is #1000, #1490 and #1491 alike. Sent
  /// together, the router applies everything and restarts once.
  ///
  /// **`allowPartial: true`, and it has to be.** The OBUSPA broker refuses an
  /// atomic SET that spans more than one USP Service with 7005, and this one
  /// does — bench-measured, the first try of this fix was refused that way and
  /// nothing was written. `wifidmd` registers both tables, so the second service
  /// is not visible from its registration; `_saveIpv6Settings` in
  /// `usp_internet_settings_service.dart` hit the same wall. A per-leaf failure
  /// the router does report still throws.
  ///
  /// **No ordering inside it.** The former split mode wrote `AccessPoint.Enable`
  /// before the passphrase ("enable first, then configure"), a rule that arrived
  /// without a reason in the 2.6.0 squash. One SET gives the router all of it at
  /// once; whether the guest passphrase takes is what the bench run of this
  /// change checks.
  ///
  /// `Enable` is written on both the SSID and the AccessPoint rows because
  /// `SSID.Enable` alone does not stop the AP broadcasting (#972).
  ///
  /// The params are built by hand because `WiFiSsids.update` and
  /// `WiFiAccessPoints.update` each send their own SET.
  ///
  /// Returns [PnpWifiWriteOutcome.unanswered] when the response was lost to the
  /// restart — the ordinary outcome when the browser is on the WiFi it changed.
  /// A refusal from the router throws, because a router that answered applied
  /// nothing — and the two cannot be told apart by `errorCode`: the WASM client
  /// stamps `9999` on both, and only the message says whether the router
  /// answered (see [isUnansweredTransportFailure]).
  Future<PnpWifiWriteOutcome> saveWifi(PnpWifiConfig config) async {
    final params = {..._guestParams(config), ..._mainParams(config)};
    if (params.isEmpty) return PnpWifiWriteOutcome.confirmed;

    try {
      final result = await _usp.set(params, allowPartial: true);
      final parsed = UspResultParser.parseSetResult(result);
      if (parsed is UspFailure &&
          parsed.errors
              .every((e) => isUnansweredTransportFailure(e.errorMessage))) {
        logger.i('[PnP] WiFi write unanswered — the network restarted under '
            'the request');
        return PnpWifiWriteOutcome.unanswered;
      }
      _throwIfParsedNotSuccess(parsed, 'WiFi update');
      return PnpWifiWriteOutcome.confirmed;
    } catch (e) {
      if (e is ServiceError) rethrow;
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Whether the router now carries what [config] asked for.
  ///
  /// Read once the router answers again, for a write whose own answer never
  /// arrived. It compares what the router reads back: main and guest SSID names,
  /// and the guest `Enable` on both the SSID and the AccessPoint row. The
  /// passphrases are not compared — they went out in the same SET as the rest,
  /// so the rest landing means they did. A save with nothing readable to compare
  /// reads as applied.
  Future<bool> isWifiApplied(PnpWifiConfig config) async {
    final expectedSsid = <String, String>{};
    final expectedSsidEnable = <String, bool>{};
    final expectedApEnable = <String, bool>{};

    if (config.isSplitMode) {
      for (final band in config.mainBands) {
        if (band.isSsidChanged) expectedSsid[band.ssidInstancePath] = band.ssid;
      }
    } else if (config.isSsidChanged) {
      for (final path in config.ssidInstancePaths) {
        expectedSsid[path] = config.ssid;
      }
    }
    if (config.isGuestSplitMode) {
      for (final band in config.guestBands) {
        if (band.isSsidChanged) expectedSsid[band.ssidInstancePath] = band.ssid;
      }
    } else if (config.isGuestSsidChanged) {
      for (final path in config.guestSsidInstancePaths) {
        expectedSsid[path] = config.guestSsid;
      }
    }
    if (config.isGuestEnabledChanged) {
      final ssidPaths = config.isGuestSplitMode
          ? config.guestBands.map((b) => b.ssidInstancePath)
          : config.guestSsidInstancePaths;
      final apPaths = config.isGuestSplitMode
          ? config.guestBands
              .map((b) => b.accessPointInstancePath)
              .where((p) => p.isNotEmpty)
          : config.guestAccessPointInstancePaths;
      for (final path in ssidPaths) {
        expectedSsidEnable[path] = config.guestEnabled;
      }
      for (final path in apPaths) {
        expectedApEnable[path] = config.guestEnabled;
      }
    }
    if (expectedSsid.isEmpty &&
        expectedSsidEnable.isEmpty &&
        expectedApEnable.isEmpty) {
      return true;
    }

    final List<Object> results;
    try {
      results = await Future.wait([
        WiFiSsids.fetch(_usp),
        if (expectedApEnable.isNotEmpty) WiFiAccessPoints.fetch(_usp),
      ]);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    final ssids = {
      for (final s in (results[0] as WiFiSsids).items) s.instancePath: s,
    };
    final aps = expectedApEnable.isEmpty
        ? const <String, WiFiAccessPoint>{}
        : {
            for (final a in (results[1] as WiFiAccessPoints).items)
              a.instancePath: a,
          };

    return expectedSsid.entries.every((e) => ssids[e.key]?.ssid == e.value) &&
        expectedSsidEnable.entries
            .every((e) => ssids[e.key]?.enable == e.value) &&
        expectedApEnable.entries.every((e) => aps[e.key]?.enable == e.value);
  }

  Map<String, dynamic> _mainParams(PnpWifiConfig config) {
    final params = <String, dynamic>{};
    if (config.isSplitMode) {
      for (final band in config.mainBands) {
        if (band.isSsidChanged) {
          params['${band.ssidInstancePath}SSID'] = band.ssid;
        }
        if (band.isPasswordChanged && band.accessPointInstancePath.isNotEmpty) {
          params['${band.accessPointInstancePath}Security.KeyPassphrase'] =
              band.password;
        }
      }
    } else {
      if (config.isSsidChanged) {
        for (final path in config.ssidInstancePaths) {
          params['${path}SSID'] = config.ssid;
        }
      }
      if (config.isPasswordChanged) {
        for (final path in config.accessPointInstancePaths) {
          params['${path}Security.KeyPassphrase'] = config.password;
        }
      }
    }
    return params;
  }

  Map<String, dynamic> _guestParams(PnpWifiConfig config) {
    final params = <String, dynamic>{};
    if (!config.isGuestDirty) return params;

    if (config.isGuestSplitMode) {
      for (final band in config.guestBands) {
        if (band.isSsidChanged) {
          params['${band.ssidInstancePath}SSID'] = band.ssid;
        }
        if (config.isGuestEnabledChanged) {
          params['${band.ssidInstancePath}Enable'] = config.guestEnabled;
          if (band.accessPointInstancePath.isNotEmpty) {
            params['${band.accessPointInstancePath}Enable'] =
                config.guestEnabled;
          }
        }
        if (band.isPasswordChanged && band.accessPointInstancePath.isNotEmpty) {
          params['${band.accessPointInstancePath}Security.KeyPassphrase'] =
              band.password;
        }
      }
      return params;
    }

    if (config.guestSsidInstancePaths.isEmpty) return params;
    if (config.isGuestSsidChanged || config.isGuestEnabledChanged) {
      for (final path in config.guestSsidInstancePaths) {
        params['${path}SSID'] = config.guestSsid;
        params['${path}Enable'] = config.guestEnabled;
      }
    }
    if (config.isGuestEnabledChanged) {
      for (final path in config.guestAccessPointInstancePaths) {
        params['${path}Enable'] = config.guestEnabled;
      }
    }
    if (config.isGuestPasswordChanged) {
      for (final path in config.guestAccessPointInstancePaths) {
        params['${path}Security.KeyPassphrase'] = config.guestPassword;
      }
    }
    return params;
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
      // `w`, not `d` — see the same distinction in
      // `UspDevicesDataService.fetchMeshTopology`. An empty subtree is a
      // legitimate single-router answer; a fault is the question going
      // unanswered, and logging both at `d` is what hid #1555's schema mismatch
      // for a whole firmware generation.
      logger.w('[PnP] DataElements fetch faulted, treating the network as '
          'non-mesh: $e');
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

  /// Throws [UspPartialFailureError] or [UspCompleteFailureError] if [parsed]
  /// is not a complete success. [label] prefixes the error summary.
  void _throwIfParsedNotSuccess(UspSetResult parsed, String label) {
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
