import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/generated/device_operations.g.dart';
import 'package:privacy_gui/generated/network_diagnostics.g.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/generated/wan_operations.g.dart';
import 'package:privacy_gui/generated/wan_settings.g.dart';
import 'package:privacy_gui/generated/wan_status.g.dart';
import 'package:privacy_gui/generated/wi_fi_access_points.g.dart';
import 'package:privacy_gui/generated/wi_fi_ssids.g.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';

final pnpServiceProvider = Provider<PnpService>(
  (ref) => PnpService(ref.read(uspServiceProvider)!),
);

/// Result of factory-default detection.
class FactoryDefaultCheckResult {
  final bool isFactoryDefault;
  final String serialNumber;
  final String modelName;
  final String firstUseDate;

  const FactoryDefaultCheckResult({
    required this.isFactoryDefault,
    required this.serialNumber,
    required this.modelName,
    required this.firstUseDate,
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
class PnpService {
  final UspService _usp;

  PnpService(this._usp);

  static const defaultPassword = 'admin';

  // ─── Auth ────────────────────────────────────────────────

  /// Attempt login with default password. Returns true if successful.
  Future<bool> tryDefaultLogin() async {
    try {
      await _usp.login(defaultPassword);
      return _usp.isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  /// Login with user-provided password. Throws on failure.
  Future<void> login(String password) async {
    await _usp.login(password);
  }

  // ─── Factory Default Detection ───────────────────────────

  /// Check if router is factory default.
  /// Must be called AFTER successful login.
  ///
  /// Logic: FirstUseDate is "0001-01-01T00:00:00Z" or empty → unconfigured.
  Future<FactoryDefaultCheckResult> checkFactoryDefault() async {
    final info = await SystemInfo.fetch(_usp);
    final isDefault =
        info.firstUseDate.isEmpty || info.firstUseDate.startsWith('0001-01-01');
    return FactoryDefaultCheckResult(
      isFactoryDefault: isDefault,
      serialNumber: info.serialNumber,
      modelName: info.modelName,
      firstUseDate: info.firstUseDate,
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
      await WiFiSsids.updateMany(_usp, ssidUpdates);
    }

    if (config.isPasswordChanged) {
      final apUpdates = config.accessPointInstancePaths
          .map((path) => WiFiAccessPointUpdate(
                instancePath: path,
                keyPassphrase: config.password,
              ))
          .toList();
      await WiFiAccessPoints.updateMany(_usp, apUpdates);
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
        await WiFiSsids.updateMany(_usp, guestSsidUpdates);
      }

      // Password
      if (config.isGuestPasswordChanged) {
        final guestApUpdates = config.guestAccessPointInstancePaths
            .map((path) => WiFiAccessPointUpdate(
                  instancePath: path,
                  keyPassphrase: config.guestPassword,
                ))
            .toList();
        await WiFiAccessPoints.updateMany(_usp, guestApUpdates);
      }
    }
  }

  // ─── ISP/WAN Save ───────────────────────────────────────

  /// Save ISP settings (PPPoE, Static IP, DHCP renewal).
  Future<void> saveIspSettings(PnpIspConfig config) async {
    switch (config.type) {
      case IspConnectionType.dhcp:
        await WanOperations.renewDhcpLease(_usp);
      case IspConnectionType.pppoe:
        await WanSettings.save(
          _usp,
          pppUsername: config.pppUsername,
          pppPassword: config.pppPassword,
          pppoeServiceName: config.pppoeServiceName,
        );
      case IspConnectionType.pppoeVlan:
        await WanSettings.save(
          _usp,
          pppUsername: config.pppUsername,
          pppPassword: config.pppPassword,
          pppoeServiceName: config.pppoeServiceName,
          vlanEnabled: true,
          vlanId: config.vlanId,
        );
      case IspConnectionType.staticIp:
        await WanSettings.save(
          _usp,
          staticIpAddress: config.staticIpAddress,
          subnetMask: config.subnetMask,
          defaultGateway: config.defaultGateway,
          dnsServer1: config.dnsServer1,
          dnsServer2: config.dnsServer2,
        );
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
