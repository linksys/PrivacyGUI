import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/mac_filter_settings.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/utils/extension.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/util/extensions.dart';

/// Riverpod provider for InstantPrivacyService
final instantPrivacyServiceProvider = Provider<InstantPrivacyService>((ref) {
  return InstantPrivacyService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for MAC filtering (Instant Privacy) operations.
///
/// Encapsulates all JNAP communication for:
/// - getMACFilterSettings / setMACFilterSettings
/// - getSTABSSIDs
/// - getLocalDevice (for current device MAC)
///
/// Reference: constitution.md Article VI
class InstantPrivacyService {
  /// Constructor injection of RouterRepository dependency
  InstantPrivacyService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Fetches MAC filter settings and status from JNAP.
  ///
  /// Parameters:
  ///   - forceRemote: If true, bypasses cache (default: false)
  ///   - updateStatusOnly: If true, returns only status without full settings
  ///
  /// Returns: Tuple of (InstantPrivacySettings?, InstantPrivacyStatus?)
  ///   - If updateStatusOnly is true, first element is null
  ///
  /// Throws: [ServiceError] on JNAP failure
  Future<(InstantPrivacySettings?, InstantPrivacyStatus?)>
      fetchMacFilterSettings({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async {
    try {
      final settings = await _routerRepository
          .send(
            JNAPAction.getMACFilterSettings,
            fetchRemote: forceRemote,
            auth: true,
          )
          .then((result) => MACFilterSettings.fromMap(result.output));

      final mode = MacFilterMode.reslove(settings.macFilterMode);
      final newStatus = InstantPrivacyStatus(mode: mode);

      // Return status only if requested
      if (updateStatusOnly) {
        return (null, newStatus);
      }

      // Fetch STA BSSIDs if supported
      final List<String> staBssids = await fetchStaBssids();

      final macAddresses =
          settings.macAddresses.map((e) => e.toUpperCase()).toList();
      final InstantPrivacySettings newSettings = InstantPrivacySettings(
        mode: mode,
        macAddresses: mode == MacFilterMode.allow ? macAddresses : [],
        denyMacAddresses: mode == MacFilterMode.deny ? macAddresses : [],
        maxMacAddresses: settings.maxMACAddresses,
        bssids: staBssids,
      );
      return (newSettings, newStatus);
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Saves MAC filter settings to JNAP.
  ///
  /// Parameters:
  ///   - settings: The InstantPrivacySettings to save
  ///   - nodesMacAddresses: MAC addresses of mesh nodes (to include in allow list)
  ///
  /// Throws: [ServiceError] on JNAP failure
  Future<void> saveMacFilterSettings(
    InstantPrivacySettings settings,
    List<String> nodesMacAddresses,
  ) async {
    try {
      var macAddresses = <String>[];
      if (settings.mode == MacFilterMode.allow) {
        macAddresses = [
          ...settings.macAddresses,
          ...nodesMacAddresses,
          ...settings.bssids,
        ].unique();
      } else if (settings.mode == MacFilterMode.deny) {
        macAddresses = [
          ...settings.denyMacAddresses,
        ];
      }

      await _routerRepository.send(
        JNAPAction.setMACFilterSettings,
        data: {
          'macFilterMode': settings.mode.name.capitalize(),
          'macAddresses': macAddresses,
        },
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Fetches STA BSSIDs from the router.
  ///
  /// Returns: List of BSSID strings (uppercase), or empty list if not supported
  ///
  /// Note: Gracefully returns empty list if router doesn't support getSTABSSIDs
  Future<List<String>> fetchStaBssids() async {
    if (!serviceHelper.isSupportGetSTABSSID()) {
      return [];
    }

    return _routerRepository
        .send(
      JNAPAction.getSTABSSIDs,
      fetchRemote: true,
      auth: true,
    )
        .then((result) {
      return List<String>.from(result.output['staBSSIDS'])
          .map((e) => e.toUpperCase())
          .toList();
    }).onError((error, _) {
      logger.d('Not able to get STA BSSIDs');
      return <String>[];
    });
  }

  /// Fetches the MAC address of the current device.
  ///
  /// Parameters:
  ///   - deviceList: List of known devices to search
  ///
  /// Returns: MAC address string or null if not found
  ///
  /// Note: Uses getLocalDevice to find deviceID, then looks up MAC in deviceList
  Future<String?> fetchMyMacAddress(List<LinksysDevice> deviceList) {
    return _routerRepository
        .send(JNAPAction.getLocalDevice, auth: true, fetchRemote: true)
        .then((result) {
      final deviceID = result.output['deviceID'];
      return deviceList
          .firstWhereOrNull((device) => device.deviceID == deviceID)
          ?.getMacAddress();
    }).onError((_, __) {
      return null;
    });
  }

  /// Maps JNAP errors to ServiceError.
  ///
  /// Uses the centralized mapper from `jnap_error_mapper.dart` for consistent
  /// error handling across all services.
  ServiceError _mapJnapError(JNAPError error) {
    return mapJnapErrorToServiceError(error);
  }
}
