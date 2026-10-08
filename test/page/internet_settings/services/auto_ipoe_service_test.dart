import 'dart:convert';
import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';

import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockClient extends Mock implements UspClient {}

class MockTransport extends Mock implements UspTransport {}

void main() {
  group('Auto-IPoE supported device', _supportedDeviceTests);
}

void _supportedDeviceTests() {
  late MockClient client;
  late AutoIPoEService service;
  const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockClient();
    service = AutoIPoEService(client);
    when(() => client.baseUrl).thenReturn('http://router.test');
    when(() => client.get(any(), fresh: true))
        .thenAnswer((_) async => AutoIPoETestData.wire());
  });
  test(
    'reads the native adapter version and preserves supported modes',
    () async {
      final state = await service.fetch();
      expect(state.capabilities.isSupported, true);
      expect(state.settings.selectedMode, AutoIPoEMode.auto);
      expect(state.exitCode, isNull);
    },
  );
  for (final invalid in [
    '',
    '[]',
    '{',
    '{}',
    '{"error":"ErrorStateUnavailable"}',
    '{"isSupported":"true","supportedModes":[]}',
    'x' * 131073
  ]) {
    test('invalid capabilities preserve valid ownership: ${invalid.length}',
        () async {
      final raw = AutoIPoETestData.wire();
      raw['${AutoIPoEService.object}Capabilities'] = invalid;
      when(() => client.get(any(), fresh: true)).thenAnswer((_) async => raw);
      final snapshot = await service.fetch();
      expect(snapshot.capabilitiesAvailable, false);
      expect(snapshot.capabilities.isSupported, false);
      expect(snapshot.capabilities.supportedModes, isEmpty);
      expect(snapshot.settings.isEnabled, true);
      expect(
          snapshot.runtime,
          AutoIPoEStatus.fromMap(AutoIPoEService.decodeObject(
              raw['${AutoIPoEService.object}Status'])));
      expect(
          snapshot.withRuntime(snapshot.runtime).capabilitiesAvailable, false);
      when(() => client.get(any(), fresh: true))
          .thenAnswer((_) async => AutoIPoETestData.wire());
      expect((await service.fetch()).capabilitiesAvailable, true);
    });
  }
  test('UI disabled is valid capabilities even with managed settings',
      () async {
    final raw = AutoIPoETestData.wire();
    raw['${AutoIPoEService.object}Capabilities'] =
        jsonEncode({'isSupported': false, 'supportedModes': []});
    when(() => client.get(any(), fresh: true)).thenAnswer((_) async => raw);
    final snapshot = await service.fetch();
    expect(snapshot.capabilitiesAvailable, true);
    expect(snapshot.capabilities.isSupported, false);
    expect(snapshot.settings.isEnabled, true);
  });
  test('invalid mandatory status is not treated as a valid idle snapshot',
      () async {
    final raw = AutoIPoETestData.wire();
    raw['${AutoIPoEService.object}Status'] = '';
    when(() => client.get(any(), fresh: true)).thenAnswer((_) async => raw);
    await expectLater(service.fetch(), throwsA(isA<ServiceError>()));
  });
  test('Auto-IPoE status bypasses five-second completed GET cache', () async {
    final transport = MockTransport();
    final throttler = BridgeRequestThrottler(staggerDelay: Duration.zero);
    final core = UspClient.withTransport(transport)..throttler = throttler;
    const path = 'Device.X_LINKSYS_AutoIPoE.Status';
    var value = 'before';
    when(() => transport.get(any())).thenAnswer((_) async => {path: value});
    expect((await core.get([path]))[path], 'before');
    value = 'after-reset';
    expect((await core.get([path]))[path], 'before');
    expect((await core.get([path], fresh: true))[path], 'after-reset');
    value = 'next-read';
    expect((await core.get([path], fresh: true))[path], 'next-read');
    verify(() => transport.get(any())).called(3);
  });

  test('unsupported version and malformed bounded JSON fail closed', () async {
    when(() => client.get(any(), fresh: true))
        .thenAnswer((_) async => AutoIPoETestData.wire(apiVersion: '2'));
    await expectLater(service.fetch(), throwsA(isA<ResourceNotFoundError>()));
    expect(
      () => AutoIPoEService.decodeObject('[]'),
      throwsA(isA<InvalidInputError>()),
    );
    expect(
      () => AutoIPoEService.decodeObject('x' * 131073),
      throwsA(isA<InvalidInputError>()),
    );
  });
  test(
      'Apply sends a UUID once with redacted arguments and no automatic auth replay',
      () async {
    Map<String, String>? sent;
    when(
      () => client.operate(
        any(),
        args: any(named: 'args'),
        retryOnAuthFailure: false,
        redactArguments: true,
      ),
    ).thenAnswer((inv) async {
      sent = inv.namedArguments[#args] as Map<String, String>;
      return {
        'Result': jsonEncode({
          'accepted': true,
          'requestId': AutoIPoETestData.id,
          'operationId': AutoIPoETestData.id,
        }),
      };
    });
    final ok = await service.submit(
      submission,
      settings: AutoIPoETestData.settings,
    );
    expect(ok.accepted, true);
    expect(sent!['RequestId'], AutoIPoETestData.id);
    expect(jsonDecode(sent!['Settings']!), {
      'isEnabled': true,
      'selectedMode': 'Auto',
    });
    verify(
      () => client.operate(
        'Device.X_LINKSYS_AutoIPoE.Apply()',
        args: any(named: 'args'),
        retryOnAuthFailure: false,
        redactArguments: true,
      ),
    ).called(1);
  });
  for (final mode in [
    AutoIPoEMode.standardIpip,
    AutoIPoEMode.ocnVirtualConnectStaticIp,
    AutoIPoEMode.ocxHikariV6ixStaticIp,
  ]) {
    test('Apply sends only native arguments for ${mode.value}', () async {
      Map<String, String>? sent;
      when(
        () => client.operate(
          any(),
          args: any(named: 'args'),
          retryOnAuthFailure: false,
          redactArguments: true,
        ),
      ).thenAnswer((inv) async {
        sent = inv.namedArguments[#args] as Map<String, String>;
        return {
          'Result': jsonEncode({
            'accepted': true,
            'requestId': AutoIPoETestData.id,
            'operationId': AutoIPoETestData.id,
          }),
        };
      });
      await service.submit(
        submission,
        settings: AutoIPoETestData.settings.copyWith(
          selectedMode: mode,
          standardIpipSettings: const StandardIPIPSettings(
            ipv6Remote: '2001:db8::1',
            ipv6InterfaceId: '::2',
            ipv4Address: '192.0.2.2',
          ),
          biglobeStaticIpSettings: const BiglobeStaticIPSettings(
            userId: AutoIPoESecret(value: 'inactive-profile-secret'),
          ),
        ),
      );
      expect(jsonDecode(sent!['Settings']!), {
        'isEnabled': true,
        'selectedMode': mode.value,
        if (mode == AutoIPoEMode.standardIpip)
          'standardIpipSettings': {
            'ipv6Remote': '2001:db8::1',
            'ipv6InterfaceId': '::2',
            'ipv4Address': '192.0.2.2',
          },
      });
      expect(sent!['Settings'], isNot(contains('inactive-profile-secret')));
    });
  }
  test(
    'mismatched command acknowledgement is uncertain and not accepted',
    () async {
      when(
        () => client.operate(
          any(),
          args: any(named: 'args'),
          retryOnAuthFailure: false,
          redactArguments: true,
        ),
      ).thenAnswer(
        (_) async => {
          'Result': jsonEncode({
            'accepted': true,
            'requestId': 'other',
            'operationId': 'other',
          }),
        },
      );
      await expectLater(
        service.submit(submission),
        throwsA(isA<UnexpectedError>()),
      );
    },
  );
  test(
    'only correlation metadata is persisted and scoped to the router',
    () async {
      await service.storeSubmission(submission);
      expect(await service.loadSubmission(), submission);
      final prefs = await SharedPreferences.getInstance();
      final value = jsonDecode(
        prefs.getString('auto-ipoe-submission:http://router.test')!,
      );
      expect(value.keys.toSet(), {'requestId', 'reset'});
      await service.clearSubmission();
      expect(await service.loadSubmission(), isNull);
    },
  );
  test(
    'core transport dispatches once on authentication failure when requested',
    () async {
      final transport = MockTransport();
      when(() => transport.operate(any(), args: any(named: 'args')))
          .thenThrow(const NotAuthenticatedError());
      final core = UspClient.withTransport(transport);
      await expectLater(
        core.operate(
          'Device.X_LINKSYS_AutoIPoE.Apply()',
          args: {'Settings': 'private-value'},
          retryOnAuthFailure: false,
          redactArguments: true,
        ),
        throwsA(isA<NotAuthenticatedError>()),
      );
      verify(() => transport.operate(any(), args: any(named: 'args')))
          .called(1);
      verifyNever(() => transport.refreshToken(token: any(named: 'token')));
    },
  );
  test(
    'explicit recovery requires a matching durable cancellation receipt',
    () async {
      when(
        () => client.operate(
          any(),
          args: any(named: 'args'),
          retryOnAuthFailure: false,
          redactArguments: true,
        ),
      ).thenAnswer(
        (_) async => {
          'Result': jsonEncode({
            'accepted': false,
            'cancelled': true,
            'requestId': AutoIPoETestData.id,
            'operationId': AutoIPoETestData.id,
          }),
        },
      );
      expect((await service.resolvePending(submission)).cancelled, true);
      verify(
        () => client.operate(
          'Device.X_LINKSYS_AutoIPoE.ResolvePending()',
          args: {'RequestId': AutoIPoETestData.id},
          retryOnAuthFailure: false,
          redactArguments: true,
        ),
      ).called(1);
      when(
        () => client.operate(
          any(),
          args: any(named: 'args'),
          retryOnAuthFailure: false,
          redactArguments: true,
        ),
      ).thenAnswer(
        (_) async => {
          'Result': jsonEncode({
            'accepted': false,
            'cancelled': true,
            'requestId': 'other',
            'operationId': 'other',
          }),
        },
      );
      await expectLater(
        service.resolvePending(submission),
        throwsA(isA<UnexpectedError>()),
      );
    },
  );

  test('both accepted identifiers must match the caller UUID', () async {
    when(
      () => client.operate(
        any(),
        args: any(named: 'args'),
        retryOnAuthFailure: false,
        redactArguments: true,
      ),
    ).thenAnswer(
      (_) async => {
        'Result': jsonEncode({
          'accepted': true,
          'requestId': AutoIPoETestData.id,
          'operationId': 'other-job',
        }),
      },
    );
    await expectLater(
      service.submit(submission),
      throwsA(isA<UnexpectedError>()),
    );
  });
  test('receipt error is separate from another latest job status', () async {
    final other = AutoIPoETestData.snapshot(
      requestId: 'other',
      exitCode: 1,
      phase: 'failed',
    ).runtime.toMap()
      ..['lastError'] = 'ErrorProviderUnavailable';
    when(
      () => client.operate(
        any(),
        args: any(named: 'args'),
        retryOnAuthFailure: false,
        redactArguments: true,
      ),
    ).thenAnswer(
      (_) async => {
        'Result': jsonEncode({
          'accepted': false,
          'requestId': '',
          'operationId': '',
          'error': 'ErrorMissingStandardIPIPSettings',
          'status': other,
        }),
      },
    );
    final receipt = await service.submit(submission);
    expect(receipt.error, 'ErrorMissingStandardIPIPSettings');
    expect(receipt.status.lastError, 'ErrorProviderUnavailable');
    expect(receipt.accepted, false);
  });
  test(
    'direct reload waits for session restoration before capability GET',
    () async {
      final ready = Completer<void>();
      service = AutoIPoEService(client, ensureSession: () => ready.future);
      final fetching = service.fetch();
      verifyNever(() => client.get(any(), fresh: true));
      ready.complete();
      expect((await fetching).capabilities.isSupported, true);
      verify(() => client.get(any(), fresh: true)).called(1);
    },
  );

  test(
    'failed session restoration never becomes unsupported capabilities',
    () async {
      service = AutoIPoEService(
        client,
        ensureSession: () async {
          throw const NotAuthenticatedError();
        },
      );
      await expectLater(service.fetch(), throwsA(isA<NotAuthenticatedError>()));
      verifyNever(() => client.get(any(), fresh: true));
      verifyNever(
        () => client.operate(
          any(),
          args: any(named: 'args'),
          retryOnAuthFailure: any(named: 'retryOnAuthFailure'),
          redactArguments: any(named: 'redactArguments'),
        ),
      );
    },
  );
}
