import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/data/providers/device_info_provider.dart';
import 'package:privacy_gui/core/data/services/session_service.dart';
import 'package:privacy_gui/core/utils/bench_mark.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Session state containing device info for the current session.
///
/// This state is updated when device info is fetched during session initialization
/// and provides reactive access to device information including model number.
class SessionState extends Equatable {
  final NodeDeviceInfo? deviceInfo;

  const SessionState({this.deviceInfo});

  /// Returns the model number with suffix (e.g., 'M60DU-EU').
  /// Format: {Model}{SP suffix}-{Region suffix}
  String get modelNumber => deviceInfo?.modelNumber ?? '';

  SessionState copyWith({NodeDeviceInfo? deviceInfo}) {
    return SessionState(deviceInfo: deviceInfo ?? this.deviceInfo);
  }

  @override
  List<Object?> get props => [deviceInfo];
}

/// Session Provider
///
/// Provides session management operations and maintains device info state.
/// Uses Notifier<SessionState> for reactive access to session data.
///
/// This provider handles:
/// - Device info storage and reactive access (including model number)
/// - Selected network (serialNumber, networkId) persistence to SharedPreferences
/// - Router connectivity validation and serial number verification
/// - Device info retrieval with caching support
///
/// This provider serves as the central point for managing which router/network
/// the user is currently connected to, and provides methods to verify connectivity
/// and retrieve router information during session initialization.

final sessionProvider = NotifierProvider<SessionNotifier, SessionState>(
  () => SessionNotifier(),
);

class SessionNotifier extends Notifier<SessionState> {
  @override
  SessionState build() {
    return const SessionState();
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
  /// Updates the session state with the fetched device info.
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
    state = state.copyWith(deviceInfo: nodeDeviceInfo);
    logger.d(
        '[Session]: checkDeviceInfo - modelNumber: ${nodeDeviceInfo.modelNumber}');
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
  /// Updates the session state with the fetched device info.
  ///
  /// Returns: Fresh [NodeDeviceInfo] from router
  ///
  /// Throws: [ServiceError] on API failure
  Future<NodeDeviceInfo> forceFetchDeviceInfo() async {
    final benchMark = BenchMarkLogger(name: 'forceFetchDeviceInfo');
    benchMark.start();
    final service = ref.read(sessionServiceProvider);
    final nodeDeviceInfo = await service.forceFetchDeviceInfo();
    state = state.copyWith(deviceInfo: nodeDeviceInfo);
    logger.d(
        '[Session]: forceFetchDeviceInfo - modelNumber: ${nodeDeviceInfo.modelNumber}');
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
  /// Updates the session state with the fetched device info.
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
    state = state.copyWith(deviceInfo: nodeDeviceInfo);
    logger.d(
        '[Session]: fetchDeviceInfoAndInitializeServices - modelNumber: ${nodeDeviceInfo.modelNumber}');
    benchMark.end();
    return nodeDeviceInfo;
  }

  /// Clears the session state.
  ///
  /// This should be called during logout to reset the session.
  void clear() {
    state = const SessionState();
    logger.d('[Session]: Session state cleared');
  }
}

/// State provider for the currently selected network ID.
///
/// This is updated by [SessionNotifier.saveSelectedNetwork] and used
/// throughout the app to track which cloud network is active.
final selectedNetworkIdProvider = StateProvider<String?>((ref) {
  return null;
});
