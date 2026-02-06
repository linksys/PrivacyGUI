import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/jnap_device_info_raw.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/models/set_lan_settings.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';

/// Riverpod provider for InstantSafetyService
final instantSafetyServiceProvider = Provider<InstantSafetyService>((ref) {
  return InstantSafetyService(ref.watch(routerRepositoryProvider));
});

/// Helper provider to get deviceInfo from polling data
/// This keeps JNAP result handling in the service layer
final instantSafetyDeviceInfoProvider = Provider<Map<String, dynamic>?>((ref) {
  final pollingData = ref.watch(pollingProvider).value;
  return (pollingData?.data[JNAPAction.getDeviceInfo] as JNAPSuccess?)?.output;
});

/// Result of fetching instant safety settings
class InstantSafetyFetchResult {
  final InstantSafetyType safeBrowsingType;
  final bool hasFortinet;

  const InstantSafetyFetchResult({
    required this.safeBrowsingType,
    required this.hasFortinet,
  });
}

/// Stateless service for instant safety (safe browsing) operations
///
/// Encapsulates JNAP communication for DNS-based parental control settings,
/// separating business logic from state management (InstantSafetyNotifier).
class InstantSafetyService {
  /// Constructor injection of dependencies
  InstantSafetyService(this._routerRepository);

  final RouterRepository _routerRepository;

  // Internal cache for LAN settings (used in save operation)
  RouterLANSettings? _cachedLanSettings;

  // DNS Configuration Constants
  static const _fortinetDns1 = '208.91.114.155';
  // NOW-713: Updated OpenDNS Family Shield IPs
  static const _openDnsDns1 = '208.67.222.222';
  static const _openDnsDns2 = '208.67.220.220';

  /// Fetches current safe browsing configuration from router.
  ///
  /// [deviceInfo] - Device info from polling provider for Fortinet compatibility check
  /// [forceRemote] - Force fresh fetch from router (default: false)
  ///
  /// Returns [InstantSafetyFetchResult] containing safe browsing type and Fortinet availability.
  /// Throws [ServiceError] on JNAP communication failure.
  Future<InstantSafetyFetchResult> fetchSettings({
    required Map<String, dynamic>? deviceInfo,
    bool forceRemote = false,
  }) async {
    try {
      final response = await _routerRepository.send(
        JNAPAction.getLANSettings,
        fetchRemote: forceRemote,
        auth: true,
      );

      final lanSettings = RouterLANSettings.fromMap(response.output);

      // Cache for later save operation
      _cachedLanSettings = lanSettings;

      final safeBrowsingType = _determineSafeBrowsingType(lanSettings);
      final hasFortinet = _checkFortinetCompatibility(deviceInfo);

      return InstantSafetyFetchResult(
        safeBrowsingType: safeBrowsingType,
        hasFortinet: hasFortinet,
      );
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Saves safe browsing configuration to router.
  ///
  /// [safeBrowsingType] - Selected safe browsing provider
  ///
  /// Throws [InvalidInputError] if cached LAN settings not available (fetch not called).
  /// Throws [ServiceError] on JNAP communication failure.
  Future<void> saveSettings(InstantSafetyType safeBrowsingType) async {
    final lanSettings = _cachedLanSettings;

    if (lanSettings == null) {
      throw const InvalidInputError(
        field: 'lanSettings',
        message: 'LAN settings not available. Call fetchSettings first.',
      );
    }

    final DHCPSettings dhcpSettings = switch (safeBrowsingType) {
      InstantSafetyType.fortinet => lanSettings.dhcpSettings.copyWith(
          dnsServer1: _fortinetDns1,
          dnsServer2: null,
          dnsServer3: null,
        ),
      InstantSafetyType.openDNS => lanSettings.dhcpSettings.copyWith(
          dnsServer1: _openDnsDns1,
          dnsServer2: _openDnsDns2,
          dnsServer3: null,
        ),
      InstantSafetyType.off => DHCPSettings(
          lastClientIPAddress: lanSettings.dhcpSettings.lastClientIPAddress,
          leaseMinutes: lanSettings.dhcpSettings.leaseMinutes,
          reservations: lanSettings.dhcpSettings.reservations,
          firstClientIPAddress: lanSettings.dhcpSettings.firstClientIPAddress,
        ),
    };

    final setLanSettings = SetRouterLANSettings(
      ipAddress: lanSettings.ipAddress,
      networkPrefixLength: lanSettings.networkPrefixLength,
      hostName: lanSettings.hostName,
      isDHCPEnabled: lanSettings.isDHCPEnabled,
      dhcpSettings: dhcpSettings,
    );

    try {
      await _routerRepository.send(
        JNAPAction.setLANSettings,
        auth: true,
        cacheLevel: CacheLevel.noCache,
        data: setLanSettings.toMap(),
      );
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Determines current safe browsing type from DNS configuration.
  InstantSafetyType _determineSafeBrowsingType(RouterLANSettings lanSettings) {
    final dnsServer1 = lanSettings.dhcpSettings.dnsServer1;
    if (dnsServer1 == _fortinetDns1) {
      return InstantSafetyType.fortinet;
    } else if (dnsServer1 == _openDnsDns1) {
      return InstantSafetyType.openDNS;
    } else {
      return InstantSafetyType.off;
    }
  }

  /// Checks if device supports Fortinet safe browsing.
  bool _checkFortinetCompatibility(Map<String, dynamic>? deviceInfo) {
    if (deviceInfo == null) {
      return false;
    }

    try {
      final info = JnapDeviceInfoRaw.fromJson(deviceInfo).toUIModel();
      final compatibilityItems = _compatibilityMap.where((e) {
        final regex = RegExp(e.modelRegExp, caseSensitive: false);
        return regex.hasMatch(info.modelNumber);
      }).toList();

      if (compatibilityItems.isEmpty) return false;

      final compatibleFW = compatibilityItems.first.compatibleFW;
      if (compatibleFW != null) {
        if (info.firmwareVersion.compareToVersion(compatibleFW.min) >= 0) {
          final max = compatibleFW.max;
          if (max != null) {
            return info.firmwareVersion.compareToVersion(max) <= 0;
          }
          return true;
        }
        return false;
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Maps JNAP errors to ServiceError types.
  ServiceError _mapJnapError(JNAPError error) {
    return UnexpectedError(
      originalError: error,
      message: error.error,
    );
  }

  // Compatibility map for Fortinet support (currently empty - no devices support Fortinet)
  static const List<_CompatibilityItem> _compatibilityMap = [];
}

/// Helper class for device compatibility checking
class _CompatibilityItem {
  final String modelRegExp;
  final _CompatibilityFW? compatibleFW;

  const _CompatibilityItem({
    required this.modelRegExp,
    // ignore: unused_element_parameter
    this.compatibleFW,
  });
}

/// Helper class for firmware version compatibility
class _CompatibilityFW {
  final String min;
  final String? max;

  const _CompatibilityFW({
    required this.min,
    // ignore: unused_element_parameter
    this.max,
  });
}
