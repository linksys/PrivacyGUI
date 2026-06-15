import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(ref.watch(uspClientProvider));
});

/// Service for session management operations.
///
/// Handles USP communication for:
/// - Router connectivity validation and serial number verification
/// - Device info retrieval with caching support
class SessionService {
  final UspClient? _usp;

  SessionService(this._usp);

  // === Router Connectivity ===

  /// Checks if the router is accessible and matches expected serial number.
  Future<NodeDeviceInfo> checkRouterIsBack(String expectedSerialNumber) async {
    final nodeDeviceInfo = await _fetchUspDeviceInfo();

    if (expectedSerialNumber.isNotEmpty &&
        expectedSerialNumber != nodeDeviceInfo.serialNumber) {
      throw SerialNumberMismatchError(
        expected: expectedSerialNumber,
        actual: nodeDeviceInfo.serialNumber,
      );
    }

    return nodeDeviceInfo;
  }

  // === Device Info ===

  /// Retrieves device info, using cached value if available.
  Future<NodeDeviceInfo> checkDeviceInfo(
      NodeDeviceInfo? cachedDeviceInfo) async {
    if (cachedDeviceInfo != null) {
      return cachedDeviceInfo;
    }
    return _fetchUspDeviceInfo();
  }

  /// Force fetches device info from router, bypassing all caches.
  Future<NodeDeviceInfo> forceFetchDeviceInfo() async {
    return _fetchUspDeviceInfo();
  }

  /// Fetches device info and initializes router services.
  Future<NodeDeviceInfo> fetchDeviceInfoAndInitializeServices() async {
    return _fetchUspDeviceInfo();
  }

  /// Fetches device info via USP.
  Future<NodeDeviceInfo> _fetchUspDeviceInfo() async {
    if (_usp == null) {
      logger.e('[SessionService]: USP not available');
      throw const ServiceNotInitializedError(
          detail: 'USP service not available');
    }
    if (!_usp.isAuthenticated) {
      logger.d('[SessionService]: USP not authenticated');
      throw const ConnectivityError(detail: 'USP not authenticated');
    }
    try {
      final systemInfo = await SystemInfo.fetch(_usp);
      logger.d('[SessionService]: DeviceInfo fetched via USP');
      return NodeDeviceInfo.fromUsp(systemInfo);
    } catch (e) {
      logger.e('[SessionService]: USP device info fetch failed: $e');
      throw ConnectivityError(detail: e.toString());
    }
  }
}
