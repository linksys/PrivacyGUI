/// Demo Router Repository
///
/// A mock implementation of RouterRepository for the Demo App.
/// Intercepts all JNAP requests and returns mock data from JnapMockRegistry.
library;

import 'package:flutter/foundation.dart';
import 'package:privacy_gui/core/data/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/demo/jnap/jnap_mock_registry.dart';

/// Demo implementation of RouterRepository that returns mock data
class DemoRouterRepository extends RouterRepository {
  DemoRouterRepository(super.ref);

  /// Simulated network delay in milliseconds
  static const _mockDelayMs = 50;

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
    SideEffectPollConfig? pollConfig,
  }) async {
    // Debug: log when this is called
    debugPrint('🔵 DemoRouterRepository.send: ${action.actionValue}');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: _mockDelayMs));

    // Return mock response
    final output = JnapMockRegistry.getResponse(action);
    return JNAPSuccess(result: 'OK', output: output);
  }

  @override
  Future<JNAPTransactionSuccessWrap> transaction(
    JNAPTransactionBuilder builder, {
    bool fetchRemote = false,
    CacheLevel cacheLevel = CacheLevel.localCached,
    int timeoutMs = 10000,
    int retries = 1,
    SideEffectPollConfig? pollConfig,
  }) async {
    // Debug: log when this is called
    final actionNames =
        builder.commands.map((e) => e.key.actionValue.split('/').last).toList();
    debugPrint('🔵 DemoRouterRepository.transaction: $actionNames');

    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: _mockDelayMs * 2));

    // Build results for each action in the transaction
    final results = <MapEntry<JNAPAction, JNAPResult>>[];
    for (final entry in builder.commands) {
      final action = entry.key;
      final output = JnapMockRegistry.getResponse(action);
      results.add(MapEntry(action, JNAPSuccess(result: 'OK', output: output)));
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
    // For demo, return single result immediately without polling
    await Future.delayed(Duration(milliseconds: firstDelayInMilliSec ~/ 10));

    final output = JnapMockRegistry.getResponse(action);
    yield JNAPSuccess(result: 'OK', output: output);

    // Mark as completed (not exceeded)
    onCompleted?.call(false);
  }
}
