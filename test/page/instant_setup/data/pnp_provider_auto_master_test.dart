// Unit tests for the Auto Master methods on the real [PnpNotifier].
//
// These bypass the widget layer entirely: a ProviderContainer hosts the real
// notifier with routerRepositoryProvider overridden by a MockRouterRepository,
// so we can assert exactly how each JNAP result is translated:
//   - checkAutoMasterStatus()      : Future<AutoMasterStatus?>, 401 -> null
//   - pollAutoMasterStatus()       : Stream, terminal statuses, 401 -> null
//   - pollAutoMasterUntilRunning() : Stream, running/complete/failed, 401 -> null
//   - testConnectionReconnected()  : SN match -> ok, mismatch/send-fail -> throw
//
// This is the layer the widget/flow tests mock out, so it is the only place the
// JNAP-result-to-status mapping is exercised against the real code. All three
// Auto Master calls send `auth: false`, so an unauthorized result means the
// firmware still requires auth for GetAutoMasterStatus — indistinguishable from
// the action being unsupported, and mapped to null like any other failure.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';

import '../../../mocks/router_repository_mocks.dart';

/// Builds a getAutoMasterStatus JNAPSuccess with the given raw status payload
/// (matching the firmware's `{ "autoMasterStatus": "Running" }` shape).
///
/// [raw] is [Object?] so tests can feed a non-String payload and prove the
/// parse degrades to null instead of throwing a TypeError.
JNAPSuccess _statusSuccess(Object? raw) => JNAPSuccess(
      result: 'OK',
      output: {if (raw != null) 'autoMasterStatus': raw},
    );

JNAPError _unauthorized() => const JNAPError(result: errorJNAPUnauthorized);

/// The `auth` value the notifier passed to the last `scheduledCommand` call.
bool _capturedScheduledAuth(MockRouterRepository repo) => verify(
      repo.scheduledCommand(
        action: anyNamed('action'),
        retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
        maxRetry: anyNamed('maxRetry'),
        firstDelayInMilliSec: anyNamed('firstDelayInMilliSec'),
        data: anyNamed('data'),
        condition: anyNamed('condition'),
        onCompleted: anyNamed('onCompleted'),
        requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
        auth: captureAnyNamed('auth'),
      ),
    ).captured.single as bool;

void main() {
  late MockRouterRepository mockRepo;
  late ProviderContainer container;
  late PnpNotifier notifier;

  setUp(() {
    mockRepo = MockRouterRepository();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(mockRepo),
    ]);
    // pnpProvider default factory is PnpNotifier (the real one) — read it so we
    // exercise real code, not the MockPnpNotifier used by the widget tests.
    notifier = container.read(pnpProvider.notifier) as PnpNotifier;
  });

  tearDown(() {
    container.dispose();
  });

  // Stubs RouterRepository.send(...) (used by checkAutoMasterStatus and
  // testConnectionReconnected). All named args are matchers so the stub is hit
  // regardless of the exact auth/timeout/retries values the notifier passes.
  void whenSend(Future<JNAPSuccess> Function() answer) {
    when(mockRepo.send(
      any,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((_) => answer());
  }

  // Stubs RouterRepository.scheduledCommand(...) (the polling streams).
  void whenScheduled(Stream<JNAPResult> stream) {
    when(mockRepo.scheduledCommand(
      action: anyNamed('action'),
      retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
      maxRetry: anyNamed('maxRetry'),
      firstDelayInMilliSec: anyNamed('firstDelayInMilliSec'),
      data: anyNamed('data'),
      condition: anyNamed('condition'),
      onCompleted: anyNamed('onCompleted'),
      requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
      auth: anyNamed('auth'),
    )).thenAnswer((_) => stream);
  }

  group('checkAutoMasterStatus', () {
    test('maps each firmware status string to the enum', () async {
      for (final entry in {
        'Idle': AutoMasterStatus.idle,
        'Running': AutoMasterStatus.running,
        'Complete': AutoMasterStatus.complete,
        'Failed': AutoMasterStatus.failed,
      }.entries) {
        whenSend(() async => _statusSuccess(entry.key));
        expect(await notifier.checkAutoMasterStatus(), entry.value,
            reason: 'status "${entry.key}" should map to ${entry.value}');
      }
    });

    test('401 maps to null (firmware still requires auth)', () async {
      // The request is sent unauthed, so a 401 cannot mean make-Master rotated
      // the password — it means this firmware has not moved
      // GetAutoMasterStatus to no-auth yet. Same degradation as unsupported.
      whenSend(() async => throw _unauthorized());
      expect(await notifier.checkAutoMasterStatus(), isNull);
    });

    test('non-401 JNAPError is swallowed to null (feature unsupported)',
        () async {
      whenSend(() async => throw const JNAPError(result: '_ErrorUnknownAction'));
      expect(await notifier.checkAutoMasterStatus(), isNull);
    });

    test('generic (non-JNAP) error is swallowed to null', () async {
      whenSend(() async => throw Exception('timeout'));
      expect(await notifier.checkAutoMasterStatus(), isNull);
    });

    test('unrecognized status string maps to null', () async {
      whenSend(() async => _statusSuccess('SomethingNew'));
      expect(await notifier.checkAutoMasterStatus(), isNull);
    });

    test('non-String status payload maps to null instead of throwing',
        () async {
      // The parse takes Object? rather than casting to String?. A cast would
      // raise a TypeError, which scheduledCommand does not catch — it would
      // escape the polling stream and strand the waiting spinner.
      whenSend(() async => _statusSuccess(42));
      expect(await notifier.checkAutoMasterStatus(), isNull);
    });

    test('sends the request unauthed', () async {
      // Load-bearing: sending a credential here is what let a mid-flow
      // rotation burn the CGI auth-attempt budget and lock the user out.
      whenSend(() async => _statusSuccess('Idle'));
      await notifier.checkAutoMasterStatus();
      expect(
        verify(mockRepo.send(
          any,
          data: anyNamed('data'),
          extraHeaders: anyNamed('extraHeaders'),
          auth: captureAnyNamed('auth'),
          type: anyNamed('type'),
          fetchRemote: anyNamed('fetchRemote'),
          cacheLevel: anyNamed('cacheLevel'),
          timeoutMs: anyNamed('timeoutMs'),
          retries: anyNamed('retries'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).captured.single,
        isFalse,
      );
    });
  });

  group('pollAutoMasterStatus', () {
    test('maps JNAPSuccess statuses through the stream', () async {
      whenScheduled(Stream.fromIterable([
        _statusSuccess('Running'),
        _statusSuccess('Complete'),
      ]));
      expect(
        await notifier.pollAutoMasterStatus().toList(),
        [AutoMasterStatus.running, AutoMasterStatus.complete],
      );
    });

    test('401 flattens to null and the stream keeps going', () async {
      // No credential is sent, so a 401 is not a rotation signal and cannot
      // burn the CGI auth-attempt budget — it needs no early terminator.
      whenScheduled(Stream.fromIterable([_unauthorized()]));
      expect(await notifier.pollAutoMasterStatus().toList(), [null]);
    });

    test('a Running before a 401 keeps both in the stream', () async {
      whenScheduled(Stream.fromIterable([
        _statusSuccess('Running'),
        _unauthorized(),
      ]));
      expect(
        await notifier.pollAutoMasterStatus().toList(),
        [AutoMasterStatus.running, null],
      );
    });

    test('non-success / non-401 results flatten to null', () async {
      whenScheduled(Stream.fromIterable([
        const JNAPError(result: '_SomethingElse'),
      ]));
      expect(await notifier.pollAutoMasterStatus().toList(), [null]);
    });

    test('polls unauthed', () async {
      whenScheduled(Stream.fromIterable([_statusSuccess('Complete')]));
      await notifier.pollAutoMasterStatus().toList();
      expect(_capturedScheduledAuth(mockRepo), isFalse);
    });

    test('non-String status payload flattens to null, stream survives',
        () async {
      // A TypeError from casting the payload would escape the stream (
      // scheduledCommand catches JNAPError/TimeoutException, not TypeError) and
      // leave the caller's waiting spinner up forever. It must degrade to null
      // and keep delivering.
      whenScheduled(Stream.fromIterable([
        _statusSuccess(42),
        _statusSuccess('Complete'),
      ]));
      expect(
        await notifier.pollAutoMasterStatus().toList(),
        [null, AutoMasterStatus.complete],
      );
    });
  });

  group('pollAutoMasterUntilRunning', () {
    test('maps running/complete/failed through the stream', () async {
      whenScheduled(Stream.fromIterable([_statusSuccess('Running')]));
      expect(await notifier.pollAutoMasterUntilRunning().toList(),
          [AutoMasterStatus.running]);
    });

    test('401 flattens to null', () async {
      whenScheduled(Stream.fromIterable([_unauthorized()]));
      expect(await notifier.pollAutoMasterUntilRunning().toList(), [null]);
    });

    test('non-success / non-401 results flatten to null', () async {
      whenScheduled(Stream.fromIterable([
        const JNAPError(result: '_SomethingElse'),
      ]));
      expect(await notifier.pollAutoMasterUntilRunning().toList(), [null]);
    });

    test('polls unauthed', () async {
      whenScheduled(Stream.fromIterable([_statusSuccess('Running')]));
      await notifier.pollAutoMasterUntilRunning().toList();
      expect(_capturedScheduledAuth(mockRepo), isFalse);
    });
  });

  group('testConnectionReconnected', () {
    // The notifier compares the freshly-fetched device SN against the SN it
    // already holds in state. Seed state with a known SN via fetchDeviceInfo's
    // sibling path: set it directly through a device-info success.
    const knownSn = 'SN-ALIVE-001';

    JNAPSuccess deviceInfoSuccess(String sn) => JNAPSuccess(
          result: 'OK',
          output: <String, dynamic>{
            'manufacturer': 'Linksys',
            'modelNumber': 'MBE70',
            'hardwareVersion': '1',
            'description': 'Linksys Velop',
            'serialNumber': sn,
            'firmwareVersion': '1.0.0',
            'firmwareDate': '2024-01-01T00:00:00Z',
            'services': const <String>[],
          },
        );

    // Puts a device with [knownSn] into state so the SN comparison has a
    // baseline. testConnectionReconnected re-sends getDeviceInfo and compares
    // the returned SN against this one.
    void seedStateSn() {
      notifier.state = PnpState(
        deviceInfo: NodeDeviceInfo.fromJson(deviceInfoSuccess(knownSn).output),
      );
    }

    test('same SN returned -> completes without throwing', () async {
      seedStateSn();
      whenSend(() async => deviceInfoSuccess(knownSn));
      await expectLater(notifier.testConnectionReconnected(), completes);
    });

    test('different SN returned -> ExceptionNeedToReconnect', () async {
      seedStateSn();
      whenSend(() async => deviceInfoSuccess('SN-DIFFERENT-999'));
      expect(
        () => notifier.testConnectionReconnected(),
        throwsA(isA<ExceptionNeedToReconnect>()),
      );
    });

    test('send failure -> ExceptionNeedToReconnect', () async {
      seedStateSn();
      whenSend(() async => throw Exception('unreachable'));
      expect(
        () => notifier.testConnectionReconnected(),
        throwsA(isA<ExceptionNeedToReconnect>()),
      );
    });
  });
}
