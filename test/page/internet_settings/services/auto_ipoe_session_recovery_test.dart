import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockGetTransport extends Mock implements UspTransport {}

void main() {
  group('Auto-IPoE supported device', _supportedDeviceTests);
}

void _supportedDeviceTests() {
  late MockGetTransport transport;
  late UspClient client;
  late AutoIPoEService service;
  var expired = true;
  var status = 401;
  const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    expired = true;
    status = 401;
    transport = MockGetTransport();
    client = UspClient.withTransport(transport);
    service = AutoIPoEService(client);
    when(() => transport.get(any())).thenAnswer((_) async {
      if (expired) {
        // What the WASM client really does with a 401 or a 503: it resolves
        // with a 9999 in the envelope, it does not throw (#1212).
        return {
          'success': false,
          'result': {
            'data': <String, dynamic>{},
            'error': {
              '${AutoIPoEService.object}APIVersion': {
                'errorCode': 9999,
                'errorMessage': 'Transport error: Transport error: HTTP error: '
                    'HTTP $status',
              },
            },
          },
        };
      }
      final completed = AutoIPoETestData.snapshot(
          requestId: AutoIPoETestData.id, exitCode: 0, verified: true);
      final wire = AutoIPoETestData.wire();
      wire['${AutoIPoEService.object}Status'] = jsonEncode({
        ...completed.runtime.toMap(),
        'requestId': completed.requestId,
        'operationId': completed.operationId,
        'exitCode': 0,
        'accepted': true,
      });
      return {
        'success': true,
        'result': {'data': Map<String, String>.from(wire)},
      };
    });
  });

  test('rejected 401 refreshes then reads the existing completed operation',
      () async {
    await service.storeSubmission(submission);
    when(() => transport.refreshToken()).thenAnswer((_) async {
      expired = false;
    });
    final result = await service.fetch();
    expect(result.outcomeFor(await service.loadSubmission()),
        AutoIPoEOutcome.succeeded);
    verify(() => transport.refreshToken()).called(1);
    verify(() => transport.get(any())).called(2);
    verifyNoMoreInteractions(transport);
  });

  test('rejected GET with failed refresh preserves the request', () async {
    await service.storeSubmission(submission);
    when(() => transport.refreshToken()).thenThrow(
        'RefreshToken failed: Transport error: HTTP error: HTTP 401');
    client.onReauthRequired = () async {};

    await expectLater(service.fetch(), throwsA(isA<NotAuthenticatedError>()));
    expect((await service.loadSubmission())!.requestId, submission.requestId);
    verify(() => transport.refreshToken()).called(1);
    verify(() => transport.get(any())).called(2);
    verifyNoMoreInteractions(transport);

    // A fresh login reconciles status without another Apply or Reset.
    expired = false;
    final result = await service.fetch();
    expect(result.outcomeFor(await service.loadSubmission()),
        AutoIPoEOutcome.succeeded);
    verify(() => transport.get(any())).called(1);
    verifyNoMoreInteractions(transport);
  });

  test('remote rejected GET ends once without local refresh', () async {
    client.authBehavior = AuthBehavior.remote;
    var ended = 0;
    client.onForceLogout = () => ended++;
    await expectLater(service.fetch(), throwsA(isA<NotAuthenticatedError>()));
    expect(ended, 1);
    verify(() => transport.get(any())).called(1);
    verifyNoMoreInteractions(transport);
  });

  test('rejected network request is not missing settings or an auth retry',
      () async {
    status = 503;
    await expectLater(service.fetch(), throwsA(isA<NetworkError>()));
    verify(() => transport.get(any())).called(1);
    verifyNoMoreInteractions(transport);
  });
}
