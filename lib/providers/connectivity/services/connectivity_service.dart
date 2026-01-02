import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/errors/jnap_error_mapper.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/extensions/_extensions.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_info.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Riverpod provider for ConnectivityService
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for connectivity-related operations
///
/// Encapsulates JNAP communication for router type detection and
/// configuration status checking, separating business logic from
/// state management (ConnectivityNotifier).
///
/// Reference: constitution.md Article VI (Service Layer Principle)
class ConnectivityService {
  /// Constructor injection of dependencies
  ConnectivityService(this._routerRepository);

  final RouterRepository _routerRepository;

  /// Tests the type of router connection based on device serial number.
  ///
  /// Calls JNAP `getDeviceInfo` to retrieve the router's serial number,
  /// then compares it with the stored serial number in SharedPreferences.
  ///
  /// Returns:
  /// - [RouterType.behindManaged]: Connected to the managed router (serial numbers match)
  /// - [RouterType.behind]: Connected to a different Linksys router
  /// - [RouterType.others]: Not connected to a Linksys router or unreachable
  ///
  /// This method **never throws**. On any JNAP error, SharedPreferences error,
  /// or empty serial number, it returns [RouterType.others] gracefully.
  Future<RouterType> testRouterType(String? gatewayIp) async {
    final routerSN = await _routerRepository
        .send(
          JNAPAction.getDeviceInfo,
          type: CommandType.local,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )
        .then<String>(
            (value) => NodeDeviceInfo.fromJson(value.output).serialNumber)
        .onError((error, stackTrace) => '');

    if (routerSN.isEmpty) {
      return RouterType.others;
    }

    final prefs = await SharedPreferences.getInstance();
    final currentSN = prefs.get(pCurrentSN);

    if (routerSN.isNotEmpty && routerSN == currentSN) {
      return RouterType.behindManaged;
    }
    return RouterType.behind;
  }

  /// Fetches router configuration status (password default/set by user).
  ///
  /// Calls JNAP `fetchIsConfigured` to determine if the router has been
  /// configured (password changed from factory default).
  ///
  /// Returns: [RouterConfiguredData] with password configuration status
  /// - `isDefaultPassword`: true if password is factory default
  /// - `isSetByUser`: true if password was set by user
  ///
  /// Throws: [ServiceError] on JNAP failure
  /// - Uses `mapJnapErrorToServiceError()` for error conversion per Article XIII
  Future<RouterConfiguredData> fetchRouterConfiguredData() async {
    try {
      final results = await _routerRepository.fetchIsConfigured();

      final bool isDefaultPassword = JNAPTransactionSuccessWrap.getResult(
                  JNAPAction.isAdminPasswordDefault, Map.fromEntries(results))
              ?.output['isAdminPasswordDefault'] ??
          false;

      final bool isSetByUser = JNAPTransactionSuccessWrap.getResult(
                  JNAPAction.isAdminPasswordDefault, Map.fromEntries(results))
              ?.output['isAdminPasswordSetByUser'] ??
          false;

      return RouterConfiguredData(
        isDefaultPassword: isDefaultPassword,
        isSetByUser: isSetByUser,
      );
    } on JNAPError catch (e) {
      throw mapJnapErrorToServiceError(e);
    }
  }
}
