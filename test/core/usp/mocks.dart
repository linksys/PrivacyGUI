import 'dart:async';

import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/models/sse_subscription_record.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';

import '../../mocks/test_data/usp_envelope_test_data.dart';

class MockUspBridgeClient extends Mock implements UspBridgeClient {}

class MockUspClient extends Mock implements UspClient {}

class MockSseManager extends Mock implements SseManager {}

class MockSseOperationStrategy extends Mock implements SseOperationStrategy {}

/// Fake strategy for testing that behaves like LocalSseStrategy.
class FakeSseOperationStrategy implements SseOperationStrategy {
  final UspBridgeClient bridge;

  FakeSseOperationStrategy(this.bridge);

  @override
  HeartbeatConfig get heartbeatConfig => HeartbeatConfig.local;

  @override
  AuthBehavior get authBehavior => AuthBehavior.local;

  @override
  Future<List<SseSubscriptionRecord>> registerSubscriptions(
    List<SubscriptionDef> subscriptions,
  ) async {
    final records = <SseSubscriptionRecord>[];
    for (final sub in subscriptions) {
      try {
        await bridge.subscribe(
          subscriptionId: sub.subscriptionId,
          path: sub.referenceList,
          notifType: _notifTypeToInt(sub.notifType),
        );
        records.add(SseSubscriptionRecord(
          subscriptionId: sub.subscriptionId,
          notifType: sub.notifType,
          referenceList: sub.referenceList,
          createdAt: DateTime.now(),
        ));
      } catch (_) {
        // Log and continue (matches real strategy behavior)
      }
    }
    return records;
  }

  @override
  Future<void> unregisterSubscriptions(List<String> subscriptionIds) async {
    for (final id in subscriptionIds) {
      await bridge.unsubscribe(subscriptionId: id);
    }
  }

  @override
  Future<void> onSseStreamOpened(
      List<SseSubscriptionRecord> existingRecords) async {
    // No-op, like LocalSseStrategy: this fake stands in for the local arm, which
    // resubscribes on the `connected` edge below because its bridge heartbeats.
  }

  @override
  Future<void> onSseConnected(
      List<SseSubscriptionRecord> existingRecords) async {
    for (final record in existingRecords) {
      await bridge.subscribe(
        subscriptionId: record.subscriptionId,
        path: record.referenceList,
        notifType: _notifTypeToInt(record.notifType),
      );
    }
  }

  @override
  Future<void> onSseDisconnected({required bool intentional}) async {}

  @override
  void dispose() {}

  int _notifTypeToInt(String notifType) {
    const mapping = {
      'ValueChange': 1,
      'ObjectCreation': 2,
      'ObjectDeletion': 3,
      'OperationComplete': 4,
      'Event': 5,
    };
    return mapping[notifType] ?? 1;
  }
}

/// The WASM client's text for a 401: its transport prefixes and the status.
///
/// Get, Set, setOrdered, Add, Delete and Operate carry it inside a resolved
/// failure envelope (see [UnauthenticatedTransport._failed]); only
/// `listSubscriptions` still throws it here, a verb nobody has measured.
Exception unauthenticatedError() =>
    Exception('Transport error: HTTP error: HTTP 401');

/// A [UspTransport] that rejects its first [rejections] requests with a 401 and
/// answers the rest, counting both.
class UnauthenticatedTransport implements UspTransport {
  UnauthenticatedTransport({this.rejections = 1});

  /// How many requests still get a 401 before the transport starts answering.
  int rejections;

  /// Every request this transport was handed, answered or not.
  int requests = 0;

  /// `refreshToken()` calls — reauth Stage 1, the call a Guardian token cannot
  /// honour.
  int refreshCalls = 0;

  /// Lets a test hold a request open so it can outlive a rebind.
  Completer<void>? requestGate;

  /// A non-auth failure, to show the gate is about 401s and nothing else.
  Object? failWith;

  Future<void> _request() async {
    requests++;
    final gate = requestGate;
    if (gate != null) await gate.future;
    final failure = failWith;
    if (failure != null) throw failure;
    if (rejections > 0) {
      rejections--;
      throw unauthenticatedError();
    }
  }

  static const _ok = {
    'success': true,
    'result': {'data': <String, dynamic>{}}
  };

  @override
  bool get isAuthenticated => true;

  @override
  String? get sessionToken => 'token';

  @override
  Future<void> login(String password) async {}

  @override
  Future<void> logout() async {}

  /// What [refreshToken] throws, when set: a router that will not refresh the
  /// session (#1666 AC4 measured the text).
  Object? refreshFailure;

  @override
  Future<void> refreshToken({String? token}) async {
    refreshCalls++;
    final failure = refreshFailure;
    if (failure != null) throw failure;
  }

  /// Counts the request, holds it on [requestGate], and returns the envelope a
  /// failed one resolves with — a 401 while [rejections] last, [failWith]
  /// always — or null when it is answered.
  ///
  /// Every verb here reports a failed request the way the WASM client does: it
  /// **resolves** with a `kind: request` 9999 entry per requested path, it does
  /// not throw. Get measured 2026-10-07 (#1212); Set, setOrdered, Add, Delete
  /// and Operate on usp-client 0.16.0, 2026-11-25 (#1666) — setOrdered's entry
  /// carries no path. A transport that threw here instead is why #1627's tests
  /// stayed green for the verbs whose 401 never reached `_withAuthRetry`.
  Future<Map<String, dynamic>?> _failed(List<String> paths) async {
    requests++;
    final gate = requestGate;
    if (gate != null) await gate.future;
    final failure =
        failWith ?? (rejections > 0 ? unauthenticatedError() : null);
    if (failure == null) return null;
    if (failWith == null) rejections--;
    return UspEnvelopeTestData.failedAsAWhole(
      paths,
      errorCode: 9999,
      errorMessage: failure is Exception
          ? failure.toString().replaceFirst('Exception: ', '')
          : '$failure',
    );
  }

  @override
  Future<Map<String, dynamic>> get(List<String> paths) async =>
      await _failed(paths) ??
      {
        'success': true,
        'result': {
          'data': {for (final p in paths) p: 'value'}
        },
      };

  @override
  Future<Map<String, dynamic>> set(
    Map<String, String> parameters, {
    bool allowPartial = false,
  }) async =>
      await _failed(parameters.keys.toList()) ?? _ok;

  @override
  Future<Map<String, dynamic>> setOrdered(
    List<List<Map<String, String>>> parameterGroups, {
    bool allowPartial = false,
  }) async =>
      await _failed(const []) ?? _ok;

  @override
  Future<Map<String, dynamic>> add(
    List<Map<String, dynamic>> items, {
    bool allowPartial = false,
  }) async =>
      await _failed([for (final i in items) '${i['path']}']) ?? _ok;

  @override
  Future<Map<String, dynamic>> delete(
    List<String> paths, {
    bool allowPartial = false,
  }) async =>
      await _failed(paths) ?? _ok;

  @override
  Future<Map<String, dynamic>> operate(
    String command, {
    Map<String, String> args = const {},
  }) async =>
      await _failed([command]) ?? _ok;

  @override
  Future<List<Map<String, dynamic>>> listSubscriptions() async {
    await _request();
    return const [];
  }

  @override
  void dispose() {}
}
