import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/data/providers/device_info_provider.dart';
import 'package:privacy_gui/core/data/services/session_service.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session Provider
///
/// Provides session management operations without managing state.
/// Uses Notifier<void> for convenient access to ref and other providers.
///
/// This is a stateless notifier that serves as a collection of session-related
/// operations rather than managing reactive state. It handles:
/// - Selected network (serialNumber, networkId) persistence to SharedPreferences
/// - Router connectivity validation and serial number verification
/// - Device info retrieval with caching support
///
/// This provider serves as the central point for managing which router/network
/// the user is currently connected to, and provides methods to verify connectivity
/// and retrieve router information during session initialization.
///
/// Note: While this uses NotifierProvider, it doesn't manage any reactive state.
/// The Notifier pattern is used purely for accessing ref and organizing related
/// operations in a single class.

final sessionProvider = NotifierProvider<SessionNotifier, void>(
  () => SessionNotifier(),
);

class SessionNotifier extends Notifier<void> {
  @override
  void build() {
    // No state management needed - this is a utility notifier
  }

  /// Checks if the router is accessible and matches the expected serial number.
  ///
  /// This method retrieves the expected serial number from SharedPreferences
  /// (prioritizing [pCurrentSN] over [pPnpConfiguredSN]) and validates that
  /// the router is reachable with matching serial number.
  ///
  /// Returns: [NodeDeviceInfo] if router is accessible and SN matches
  ///
  /// Throws:
  /// - [SerialNumberMismatchError] if connected router has different SN
  /// - [ConnectivityError] if router is unreachable
  Future<NodeDeviceInfo> checkRouterIsBack() async {
    final service = ref.read(sessionServiceProvider);
    final prefs = await SharedPreferences.getInstance();
    final currentSN =
        prefs.getString(pCurrentSN) ?? prefs.getString(pPnpConfiguredSN);
    return service.checkRouterIsBack(currentSN ?? '');
  }

  /// Retrieves device info, using cached value if available.
  ///
  /// This method first checks [deviceInfoProvider] for cached data.
  /// If cache is unavailable, it fetches fresh data from the router.
  ///
  /// [serialNumber] - Currently unused, kept for API compatibility
  ///
  /// Returns: [NodeDeviceInfo] from cache or fresh API call
  ///
  /// Throws: [ServiceError] on API failure when cache is unavailable
  Future<NodeDeviceInfo> checkDeviceInfo(String? serialNumber) async {
    final benchMark = BenchMarkLogger(name: 'checkDeviceInfo');
    benchMark.start();
    final service = ref.read(sessionServiceProvider);
    final cachedDeviceInfo = ref.read(deviceInfoProvider).deviceInfo;
    final nodeDeviceInfo = await service.checkDeviceInfo(cachedDeviceInfo);
    benchMark.end();
    return nodeDeviceInfo;
  }

  /// Saves the selected network and serial number to SharedPreferences.
  ///
  /// This method persists the current session information and updates the
  /// [selectedNetworkIdProvider] state.
  ///
  /// [serialNumber] - The router's serial number
  /// [networkId] - The network ID (cloud-based) or empty string for local sessions
  Future<void> saveSelectedNetwork(
      String serialNumber, String networkId) async {
    logger.i('[Session]: saveSelectedNetwork - $networkId, $serialNumber');
    final pref = await SharedPreferences.getInstance();
    logger.d('[Session]: save selected network - $serialNumber, $networkId');
    await pref.setString(pCurrentSN, serialNumber);
    await pref.setString(pSelectedNetworkId, networkId);
    ref.read(selectedNetworkIdProvider.notifier).state = networkId;
  }

  /// Force fetches device info from router, bypassing all caches.
  ///
  /// This method always makes an API call to get fresh device info,
  /// regardless of any cached values. Use this when you need guaranteed
  /// fresh data, such as:
  /// - During initial session setup (prepare dashboard)
  /// - After configuration changes
  /// - When validating router connectivity
  ///
  /// Returns: Fresh [NodeDeviceInfo] from router
  ///
  /// Throws: [ServiceError] on API failure
  Future<NodeDeviceInfo> forceFetchDeviceInfo() async {
    final benchMark = BenchMarkLogger(name: 'forceFetchDeviceInfo');
    benchMark.start();
    final service = ref.read(sessionServiceProvider);
    final nodeDeviceInfo = await service.forceFetchDeviceInfo();
    benchMark.end();
    return nodeDeviceInfo;
  }

  /// Fetches device info and initializes router services (better actions).
  ///
  /// This method should be called during login/session initialization to:
  /// 1. Fetch fresh device info from router
  /// 2. Configure the JNAP action system for the connected router
  /// 3. Return device info for UI display
  ///
  /// Use this instead of [checkDeviceInfo] when you need to ensure
  /// buildBetterActions is called with the current router's services.
  ///
  /// Returns: [NodeDeviceInfo] UI model
  ///
  /// Throws: [ServiceError] on API failure
  Future<NodeDeviceInfo> fetchDeviceInfoAndInitializeServices() async {
    final benchMark =
        BenchMarkLogger(name: 'fetchDeviceInfoAndInitializeServices');
    benchMark.start();
    final service = ref.read(sessionServiceProvider);
    final nodeDeviceInfo = await service.fetchDeviceInfoAndInitializeServices();
    benchMark.end();
    return nodeDeviceInfo;
  }
}

/// State provider for the currently selected network ID.
///
/// This is updated by [SessionNotifier.saveSelectedNetwork] and used
/// throughout the app to track which cloud network is active.
final selectedNetworkIdProvider = StateProvider<String?>((ref) {
  return null;
});
