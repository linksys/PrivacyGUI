// Unit tests for the Auto Master methods on the real [PnpNotifier].
//
// These bypass the widget layer entirely: a ProviderContainer hosts the real
// notifier with routerRepositoryProvider overridden by a MockRouterRepository,
// so we can assert exactly how each JNAP result is translated:
//   - checkAutoMasterStatus()      : Future<AutoMasterStatus?>, 401 -> throw
//   - pollAutoMasterStatus()       : Stream, terminal statuses, 401 -> stream error
//   - pollAutoMasterUntilRunning() : Stream, running/complete/failed, 401 -> error
//   - testConnectionReconnected()  : SN match -> ok, mismatch/send-fail -> throw
//
// This is the layer the widget/flow tests mock out, so it is the only place the
// JNAP-result-to-status mapping (including the first-401 terminator that the
// #1180 fix hinges on) is exercised against the real code.

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

/// Builds a getAutoMasterStatus JNAPSuccess with the given raw status string
/// (matching the firmware's `{ "autoMasterStatus": "Running" }` shape).
JNAPSuccess _statusSuccess(String? raw) => JNAPSuccess(
      result: 'OK',
      output: {if (raw != null) 'autoMasterStatus': raw},
    );

JNAPError _unauthorized() => const JNAPError(result: errorJNAPUnauthorized);

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

    test('401 throws ExceptionAutoMasterUnauthorized', () async {
      whenSend(() async => throw _unauthorized());
      expect(
        () => notifier.checkAutoMasterStatus(),
        throwsA(isA<ExceptionAutoMasterUnauthorized>()),
      );
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

    test('terminates on the FIRST 401 (make-Master rotated the credential)',
        () async {
      // The first-401 fix: a 401 in the stream must surface as an error the
      // consumer's await-for catches, NOT be flattened to null and re-polled.
      whenScheduled(Stream.fromIterable([_unauthorized()]));
      expect(
        notifier.pollAutoMasterStatus(),
        emitsInOrder([emitsError(isA<ExceptionAutoMasterUnauthorized>())]),
      );
    });

    test('a Running before a 401 is emitted, then the stream errors', () async {
      whenScheduled(Stream.fromIterable([
        _statusSuccess('Running'),
        _unauthorized(),
      ]));
      expect(
        notifier.pollAutoMasterStatus(),
        emitsInOrder([
          AutoMasterStatus.running,
          emitsError(isA<ExceptionAutoMasterUnauthorized>()),
        ]),
      );
    });

    test('non-success / non-401 results flatten to null', () async {
      whenScheduled(Stream.fromIterable([
        const JNAPError(result: '_SomethingElse'),
      ]));
      expect(await notifier.pollAutoMasterStatus().toList(), [null]);
    });
  });

  group('pollAutoMasterUntilRunning', () {
    test('maps running/complete/failed through the stream', () async {
      whenScheduled(Stream.fromIterable([_statusSuccess('Running')]));
      expect(await notifier.pollAutoMasterUntilRunning().toList(),
          [AutoMasterStatus.running]);
    });

    test('terminates on the first 401', () async {
      whenScheduled(Stream.fromIterable([_unauthorized()]));
      expect(
        notifier.pollAutoMasterUntilRunning(),
        emitsInOrder([emitsError(isA<ExceptionAutoMasterUnauthorized>())]),
      );
    });

    test('non-success / non-401 results flatten to null', () async {
      whenScheduled(Stream.fromIterable([
        const JNAPError(result: '_SomethingElse'),
      ]));
      expect(await notifier.pollAutoMasterUntilRunning().toList(), [null]);
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
