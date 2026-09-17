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
      // `_fetchRouterIdentity` swallows its own errors — do not unwrap it into
      // this `try`. The outer `catch` turns anything thrown here into a
      // `ConnectivityError` that fails the login, and a router that cannot answer
      // the two identity leaves must still be able to log in.
      final identity = await _fetchRouterIdentity(_usp);
      return NodeDeviceInfo.fromUsp(systemInfo).copyWith(
        baseMacAddress: identity.baseMacAddress,
        deviceUuid: identity.deviceUuid,
      );
    } catch (e) {
      logger.e('[SessionService]: USP device info fetch failed: $e');
      throw ConnectivityError(detail: e.toString());
    }
  }

  /// The two identity leaves the `system_info` definition does not cover.
  ///
  /// Remote Assistance needs three values to reach Guardian — serial, MAC and the
  /// cloud's device UUID — and only the serial is in `system_info`, whose
  /// definition is `Device.DeviceInfo.*`. The UUID lives under
  /// `Device.LocalAgent.`, so it cannot join that definition; one extra Get here
  /// is the cheapest honest place, and it rides the same login the serial already
  /// costs. See PrivacyGUI#1582.
  ///
  /// **Best-effort on purpose.** A firmware that serves neither leaf must still
  /// log in; Remote Assistance then reports itself unavailable, which is a far
  /// better failure than a session that cannot start. So this swallows its own
  /// errors rather than joining the `ConnectivityError` above.
  ///
  /// That is also why it does **not** map through `mapUspErrorToServiceError`
  /// (constitution Article XIII): there is no caller to hand a `ServiceError` to —
  /// the result is two nullable strings, and the absence *is* the outcome. The
  /// cause is kept in the log line rather than in a type.
  Future<({String? baseMacAddress, String? deviceUuid})> _fetchRouterIdentity(
      UspClient usp) async {
    try {
      final response = await usp.get([_kBaseMacPath, _kEndpointIdPath]);
      return (
        baseMacAddress: _nonEmptyUpper(response[_kBaseMacPath]),
        deviceUuid:
            _stripUuidPrefix(_nonEmptyUpper(response[_kEndpointIdPath])),
      );
    } catch (e) {
      logger.w('[SessionService]: router identity read failed: $e '
          '— Remote Assistance will report itself unavailable');
      return (baseMacAddress: null, deviceUuid: null);
    }
  }

  /// Upper case is not cosmetic: measured 2026-09-17, Guardian's device-token
  /// endpoint answers `403` for the correct UUID sent in lower case.
  static String? _nonEmptyUpper(Object? value) {
    final text = value?.toString().trim().toUpperCase();
    return (text == null || text.isEmpty) ? null : text;
  }

  /// `Device.LocalAgent.EndpointID` reads `uuid::<UUID>`. The prefix is part of
  /// the USP endpoint identifier and must not reach Guardian — but it must stay
  /// on the value the firmware WebSocket upload uses as its `toId`, which is why
  /// that call site keeps its own read.
  /// Case-insensitive on purpose: this must not depend on [_nonEmptyUpper]
  /// having run first, or one edit there silently changes two properties.
  static String? _stripUuidPrefix(String? value) {
    if (value == null) return null;
    const prefix = 'uuid::';
    if (!value.toLowerCase().startsWith(prefix)) return value;
    final stripped = value.substring(prefix.length);
    return stripped.isEmpty ? null : stripped;
  }
}

const _kBaseMacPath = 'Device.DeviceInfo.X_LINKSYS_BaseMACAddress';
const _kEndpointIdPath = 'Device.LocalAgent.EndpointID';
