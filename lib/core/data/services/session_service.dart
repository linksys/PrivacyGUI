import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/jnap/models/jnap_device_info_raw.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

final sessionServiceProvider = Provider<SessionService>((ref) {
  return SessionService(
    ref.watch(routerRepositoryProvider),
    ref.watch(uspServiceProvider),
  );
});

/// Service for session management operations.
///
/// Handles JNAP communication for:
/// - Router connectivity validation and serial number verification
/// - Device info retrieval with caching support
///
/// This service is used by SessionProvider to manage the current router session.
class SessionService {
  final RouterRepository _routerRepository;
  final UspService? _usp;

  SessionService(this._routerRepository, this._usp);

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
      final nodeDeviceInfo =
          JnapDeviceInfoRaw.fromJson(result.output).toUIModel();

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
      return JnapDeviceInfoRaw.fromJson(result.output).toUIModel();
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

  // === Force Fetch Device Info ===

  /// Force fetches device info from router, bypassing all caches.
  ///
  /// Unlike [checkDeviceInfo], this method always makes an API call
  /// regardless of cached values. Use this when you need guaranteed
  /// fresh data, such as during initial session setup or after
  /// configuration changes.
  ///
  /// Returns: Fresh [NodeDeviceInfo] from router API call
  ///
  /// Throws: [ServiceError] on API failure
  Future<NodeDeviceInfo> forceFetchDeviceInfo() async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getDeviceInfo,
        fetchRemote: true,
      );
      return JnapDeviceInfoRaw.fromJson(result.output).toUIModel();
    } on JNAPError catch (e) {
      final uspResult = await _tryUspDeviceInfo();
      if (uspResult != null) return uspResult;
      throw _mapJnapError(e);
    } catch (e) {
      final uspResult = await _tryUspDeviceInfo();
      if (uspResult != null) return uspResult;
      rethrow;
    }
  }

  // === Session Initialization ===

  /// Fetches device info and initializes router services.
  ///
  /// This method:
  /// 1. Fetches fresh device info from router
  /// 2. Calls [buildBetterActions] with the services list
  /// 3. Returns the UI model for display
  ///
  /// Use this method during login/session initialization to ensure
  /// the JNAP action system is properly configured for the connected router.
  ///
  /// Returns: [NodeDeviceInfo] UI model
  ///
  /// Throws: [ServiceError] on API failure
  Future<NodeDeviceInfo> fetchDeviceInfoAndInitializeServices() async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getDeviceInfo,
        retries: 0,
        timeoutMs: 3000,
      );
      final rawInfo = JnapDeviceInfoRaw.fromJson(result.output);

      // Initialize better actions with router's supported services
      buildBetterActions(rawInfo.services);

      return rawInfo.toUIModel();
    } on JNAPError catch (e) {
      // Try USP fallback before throwing
      final uspResult = await _tryUspDeviceInfo();
      if (uspResult != null) return uspResult;
      throw _mapJnapError(e);
    } catch (e) {
      // JNAP completely unavailable (e.g., disabled firmware) — try USP
      final uspResult = await _tryUspDeviceInfo();
      if (uspResult != null) return uspResult;
      rethrow;
    }
  }

  /// Attempts to fetch device info via USP as fallback.
  ///
  /// Returns null if USP is unavailable or not authenticated.
  /// When USP succeeds, [buildBetterActions] is skipped since JNAP
  /// action routing is irrelevant when JNAP is disabled.
  Future<NodeDeviceInfo?> _tryUspDeviceInfo() async {
    if (_usp == null) {
      logger.d('[SessionService] USP fallback skipped: UspService is null');
      return null;
    }
    if (!_usp.isAuthenticated) {
      logger.d('[SessionService] USP fallback skipped: USP not authenticated');
      return null;
    }
    if (BuildConfig.protocolPreference == ProtocolPreference.jnapOnly) {
      logger.d('[SessionService] USP fallback skipped: protocol=jnapOnly');
      return null;
    }
    try {
      final systemInfo = await SystemInfo.fetch(_usp);
      logger.d('[SessionService] USP fallback: DeviceInfo fetched via USP');
      return NodeDeviceInfo.fromUsp(systemInfo);
    } catch (e) {
      logger.w('[SessionService] USP fallback failed: $e');
      return null;
    }
  }
}
