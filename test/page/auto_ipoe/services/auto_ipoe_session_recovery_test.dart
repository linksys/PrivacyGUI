import 'package:privacy_gui/constants/build_config.dart';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_strategy.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_get_response.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/services/auto_ipoe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockGetTransport extends Mock implements UspTransport {}

void main() {
  // Run this integration suite with --dart-define=auto-ipoe=y.
  group('Auto-IPoE enabled build', _enabledBuildTests,
      skip: !BuildConfig.autoIPoEEnabled);
}

void _enabledBuildTests() {
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
    when(() => transport.get(any())).thenAnswer((call) async {
      final paths = call.positionalArguments.single as List<String>;
      if (expired) {
        return decodeUspGetResponse({
          'success': false,
          'result': {
            'data': <String, String>{},
            'error': {
              for (final path in paths)
                path: {
                  'errorCode': 9999,
                  'errorMessage': 'Transport error: HTTP error: HTTP $status',
                },
            },
          },
        });
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
      return decodeUspGetResponse({
        'success': true,
        'result': {'data': wire},
      });
    });
  });

  test('fulfilled 401 refreshes then reads the existing completed operation',
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

  test('clock-expired token remains an auth error and preserves the request',
      () async {
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

  test('remote rejected credential ends once without local refresh', () async {
    client.authBehavior = AuthBehavior.remote;
    var ended = 0;
    client.onForceLogout = () => ended++;
    await expectLater(service.fetch(), throwsA(isA<NotAuthenticatedError>()));
    expect(ended, 1);
    verify(() => transport.get(any())).called(1);
    verifyNoMoreInteractions(transport);
  });

  test('temporary network failure is not missing settings or an auth retry',
      () async {
    status = 503;
    await expectLater(service.fetch(), throwsA(isA<NetworkError>()));
    verify(() => transport.get(any())).called(1);
    verifyNoMoreInteractions(transport);
  });
}
