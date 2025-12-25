/// USP Mapper Repository
///
/// A RouterRepository implementation that uses USP Services.
library;

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:usp_client_core/usp_client_core.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/demo/jnap/jnap_mock_registry.dart';

/// RouterRepository implementation that uses USP Services.
///
/// This repository:
/// 1. Receives JNAP-style requests
/// 2. Delegates to appropriate USP Service
/// 3. Returns JNAP-formatted responses
class UspMapperRepository extends RouterRepository {
  final UspGrpcClientService _grpcService;

  // USP Services
  late final UspDeviceService _deviceService;
  late final UspWifiService _wifiService;
  late final UspNetworkService _networkService;
  late final UspTopologyService _topologyService;
  late final UspDiagnosticsService _diagnosticsService;

  /// Creates a new [UspMapperRepository].
  UspMapperRepository(
    Ref ref,
    this._grpcService,
  ) : super(ref) {
    _deviceService = UspDeviceService(_grpcService);
    _wifiService = UspWifiService(_grpcService);
    _networkService = UspNetworkService(_grpcService);
    _topologyService = UspTopologyService(_grpcService);
    _diagnosticsService = UspDiagnosticsService(_grpcService);
  }

  @override
  Future<JNAPSuccess> send(
    JNAPAction action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool auth = false,
    CommandType? type,
    bool fetchRemote = false,
    CacheLevel? cacheLevel,
    int timeoutMs = 10000,
    int retries = 1,
    JNAPSideEffectOverrides? sideEffectOverrides,
  }) async {
    final actionName = _extractActionName(action.actionValue);
    final baseName = _stripVersionSuffix(actionName);
    logger.d('🔵 UspMapperRepository.send: $actionName (base: $baseName)');

    try {
      final output = await _dispatchToService(baseName);
      if (output != null) {
        logger.d('✅ Service response for $actionName');
        return JNAPSuccess(result: 'OK', output: output);
      }

      // Fallback to mock registry for unsupported actions
      logger.w('⚠️ No Service mapping for: $actionName, using mock');
      return JNAPSuccess(
        result: 'OK',
        output: JnapMockRegistry.getResponse(action),
      );
    } catch (e) {
      logger.e('❌ USP request failed: $e');
      // Fallback to mock on error
      return JNAPSuccess(
        result: 'OK',
        output: JnapMockRegistry.getResponse(action),
      );
    }
  }

  /// Dispatches to the appropriate Service based on action name.
  Future<Map<String, dynamic>?> _dispatchToService(String baseName) async {
    switch (baseName) {
      // Device Service
      case 'GetDeviceInfo':
        return _deviceService.getDeviceInfo();
      case 'GetSystemStats':
        return _deviceService.getSystemStats();

      // WiFi Service
      case 'GetRadioInfo':
        return _wifiService.getRadioInfo();
      case 'GetGuestRadioSettings':
        return _wifiService.getGuestRadioSettings();
      case 'GetMACFilterSettings':
        return _wifiService.getMACFilterSettings();

      // Network Service
      case 'GetWANStatus':
      case 'GetWANSettings':
        return _networkService.getWANStatus();
      case 'GetLANSettings':
        return _networkService.getLANSettings();
      case 'GetLocalTime':
      case 'GetTimeSettings':
        return _networkService.getTimeSettings();

      // Topology Service
      case 'GetDevices':
        return _topologyService.getDevices();
      case 'GetBackhaulInfo':
        return _topologyService.getBackhaulInfo();
      case 'GetNetworkConnections':
        return _topologyService.getNetworkConnections();
      case 'GetNodesWirelessNetworkConnections':
        return _topologyService.getNodesWirelessNetworkConnections();

      // Diagnostics Service
      case 'GetInternetConnectionStatus':
        return _diagnosticsService.getInternetConnectionStatus();
      case 'GetEthernetPortConnections':
        return _diagnosticsService.getEthernetPortConnections();

      default:
        return null; // Not handled by services
    }
  }

  @override
  Future<JNAPTransactionSuccessWrap> transaction(
    JNAPTransactionBuilder builder, {
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
    int timeoutMs = 10000,
    int retries = 1,
    JNAPSideEffectOverrides? sideEffectOverrides,
  }) async {
    final actionNames =
        builder.commands.map((e) => e.key.actionValue.split('/').last).toList();
    logger.d('🔵 UspMapperRepository.transaction: $actionNames');

    // Process each action in the transaction
    final results = <MapEntry<JNAPAction, JNAPResult>>[];

    for (final entry in builder.commands) {
      final action = entry.key;
      try {
        final result = await send(action);
        results.add(MapEntry(action, result));
      } catch (e) {
        results.add(MapEntry(
          action,
          JNAPSuccess(result: 'OK', output: const {}),
        ));
      }
    }

    return JNAPTransactionSuccessWrap(result: 'OK', data: results);
  }

  @override
  Stream<JNAPResult> scheduledCommand({
    required JNAPAction action,
    int retryDelayInMilliSec = 5000,
    int maxRetry = 10,
    int firstDelayInMilliSec = 3000,
    Map<String, dynamic> data = const {},
    bool Function(JNAPResult)? condition,
    Function(bool exceedMaxRetry)? onCompleted,
    int? requestTimeoutOverride,
    bool auth = false,
  }) async* {
    // For now, just return a single result
    await Future.delayed(Duration(milliseconds: firstDelayInMilliSec ~/ 10));

    final result = await send(action, data: data);
    yield result;

    onCompleted?.call(false);
  }

  // ===========================================================================
  // Helper Methods
  // ===========================================================================

  /// Extracts the action name from a JNAP action URL.
  String _extractActionName(String actionUrl) {
    return actionUrl.split('/').last;
  }

  /// Strips version suffix from action name.
  /// e.g., "GetRadioInfo3" → "GetRadioInfo"
  String _stripVersionSuffix(String actionName) {
    final regex = RegExp(r'[2-9]+$');
    return actionName.replaceFirst(regex, '');
  }
}
