import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/guest_radio_settings.dart';
import 'package:privacy_gui/core/jnap/models/radio_info.dart';
import 'package:privacy_gui/core/jnap/models/soft_sku_settings.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

final dashboardManagerServiceProvider =
    Provider<DashboardManagerService>((ref) {
  return DashboardManagerService(ref.watch(routerRepositoryProvider));
});

/// Service for dashboard management operations.
///
/// Handles JNAP communication and transforms raw API responses
/// into DashboardManagerState. This isolates JNAP protocol details
/// from the DashboardManagerNotifier.
class DashboardManagerService {
  final RouterRepository _routerRepository;

  DashboardManagerService(this._routerRepository);

  // === Data Transformation ===

  /// Transforms polling data into DashboardManagerState.
  ///
  /// [pollingResult] - Raw JNAP transaction data from pollingProvider.
  ///                   Can be null during initial load.
  ///
  /// Returns: Complete DashboardManagerState with all dashboard information.
  ///
  /// Behavior:
  /// - If [pollingResult] is null, returns empty default state
  /// - Processes all available JNAP action results
  /// - Skips failed actions gracefully (partial state)
  /// - Never throws - always returns valid state
  DashboardManagerState transformPollingData(
      CoreTransactionData? pollingResult) {
    Map<String, dynamic>? getDeviceInfoData;
    Map<String, dynamic>? getRadioInfoData;
    Map<String, dynamic>? getGuestRadioSettingsData;
    Map<String, dynamic>? getSystemStats;
    Map<String, dynamic>? getEthernetPortConnections;
    Map<String, dynamic>? getLocalTime;

    final result = pollingResult?.data;
    if (result != null) {
      // Safely extract output only from successful results
      JNAPSuccess? getSuccess(JNAPAction action) {
        final r = result[action];
        return r is JNAPSuccess ? r : null;
      }

      getDeviceInfoData = getSuccess(JNAPAction.getDeviceInfo)?.output;
      getRadioInfoData = getSuccess(JNAPAction.getRadioInfo)?.output;
      getGuestRadioSettingsData =
          getSuccess(JNAPAction.getGuestRadioSettings)?.output;
      getSystemStats = getSuccess(JNAPAction.getSystemStats)?.output;
      getEthernetPortConnections =
          getSuccess(JNAPAction.getEthernetPortConnections)?.output;
      getLocalTime = getSuccess(JNAPAction.getLocalTime)?.output;
    }

    var newState = const DashboardManagerState();
    if (getDeviceInfoData != null) {
      newState = newState.copyWith(
          deviceInfo: NodeDeviceInfo.fromJson(getDeviceInfoData));
    }
    if (getRadioInfoData != null) {
      newState = _getMainRadioList(newState, getRadioInfoData);
    }
    if (getGuestRadioSettingsData != null) {
      newState = _getGuestRadioList(newState, getGuestRadioSettingsData);
    }

    if (getSystemStats != null) {
      final uptimeSeconds = getSystemStats['uptimeSeconds'];
      final cpuLoad = getSystemStats['CPULoad'];
      final memoryLoad = getSystemStats['MemoryLoad'];
      newState = newState.copyWith(
          uptimes: uptimeSeconds, cpuLoad: cpuLoad, memoryLoad: memoryLoad);
    }

    if (getEthernetPortConnections != null) {
      final lanPortConnections =
          List<String>.from(getEthernetPortConnections['lanPortConnections']);
      final wanPortConnection = getEthernetPortConnections['wanPortConnection'];
      newState = newState.copyWith(
          lanConnections: lanPortConnections, wanConnection: wanPortConnection);
    }

    String? timeString;
    if (getLocalTime != null) {
      timeString = getLocalTime['currentTime'];
    }

    // Try to parse the time string, fallback to current time if parsing fails
    DateTime? parsedTime;
    if (timeString != null) {
      parsedTime = DateFormat("yyyy-MM-ddThh:mm:ssZ").tryParse(timeString);
    }
    final localTime = (parsedTime ?? DateTime.now()).millisecondsSinceEpoch;
    newState = newState.copyWith(localTime: localTime);

    final softSKUSettings = JNAPTransactionSuccessWrap.getResult(
        JNAPAction.getSoftSKUSettings, result ?? {});
    if (softSKUSettings != null) {
      final settings = SoftSKUSettings.fromMap(softSKUSettings.output);
      newState = newState.copyWith(skuModelNumber: settings.modelNumber);
    }

    return newState;
  }

  /// Extract main radio list from radio info data.
  DashboardManagerState _getMainRadioList(
      DashboardManagerState state, Map<String, dynamic> data) {
    final getRadioInfoData = GetRadioInfo.fromMap(data);
    return state.copyWith(mainRadios: getRadioInfoData.radios);
  }

  /// Extract guest radio list from guest radio settings data.
  DashboardManagerState _getGuestRadioList(
      DashboardManagerState state, Map<String, dynamic> data) {
    final guestRadioSettings = GuestRadioSettings.fromMap(data);
    return state.copyWith(
        guestRadios: guestRadioSettings.radios,
        isGuestNetworkEnabled: guestRadioSettings.isGuestNetworkEnabled);
  }

  // === Router Connectivity ===

  /// Checks if the router is accessible and matches expected serial number.
  ///
  /// [expectedSerialNumber] - The serial number to verify against
  ///
  /// Returns: NodeDeviceInfo if router is reachable and SN matches
  ///
  /// Throws:
  /// - [SerialNumberMismatchError] if connected router has different SN
  /// - [ConnectivityError] if router is unreachable
  Future<NodeDeviceInfo> checkRouterIsBack(String expectedSerialNumber) async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getDeviceInfo,
        fetchRemote: true,
        retries: 0,
      );
      final nodeDeviceInfo = NodeDeviceInfo.fromJson(result.output);

      if (expectedSerialNumber.isNotEmpty &&
          expectedSerialNumber != nodeDeviceInfo.serialNumber) {
        throw SerialNumberMismatchError(
          expected: expectedSerialNumber,
          actual: nodeDeviceInfo.serialNumber,
        );
      }

      return nodeDeviceInfo;
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    } on SerialNumberMismatchError {
      rethrow;
    } catch (e) {
      throw ConnectivityError(message: e.toString());
    }
  }

  // === Device Info ===

  /// Retrieves device info, using cached value if available.
  ///
  /// [cachedDeviceInfo] - Previously cached device info (from state)
  ///
  /// Returns: NodeDeviceInfo from cache or fresh API call
  ///
  /// Throws: [ServiceError] on API failure when cache is unavailable
  Future<NodeDeviceInfo> checkDeviceInfo(
      NodeDeviceInfo? cachedDeviceInfo) async {
    if (cachedDeviceInfo != null) {
      return cachedDeviceInfo;
    }

    try {
      final result = await _routerRepository.send(
        JNAPAction.getDeviceInfo,
        retries: 0,
        timeoutMs: 3000,
      );
      return NodeDeviceInfo.fromJson(result.output);
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Maps JNAP errors to ServiceError types
  ServiceError _mapJnapError(JNAPError error) {
    return switch (error.result) {
      '_ErrorUnauthorized' => const UnauthorizedError(),
      'ErrorDeviceNotFound' => const ResourceNotFoundError(),
      'ErrorInvalidInput' => InvalidInputError(message: error.error),
      _ => UnexpectedError(originalError: error, message: error.result),
    };
  }
}
