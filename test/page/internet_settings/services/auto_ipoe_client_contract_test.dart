import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:logger/logger.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/usp/transport/usp_transport.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/services/auto_ipoe_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockTransport extends Mock implements UspTransport {}

void main() {
  const secret = 'synthetic-private-operation-value';
  const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
  final errorCases = jsonDecode(
    File('test/web/usp_operate_errors.json').readAsStringSync(),
  ) as List<dynamic>;

  for (final name in ['Apply', 'Reset', 'ResolvePending']) {
    group('Auto-IPoE $name through the shared client', () {
      late MockTransport transport;
      late AutoIPoEService service;
      late List<String> logs;
      void capture(LogEvent event) => logs.add(event.message.toString());
      final command = '${AutoIPoEService.object}$name()';

      Future<AutoIPoEReceipt> invoke() => name == 'ResolvePending'
          ? service.resolvePending(submission)
          : service.submit(
              AutoIPoESubmission(AutoIPoETestData.id, reset: name == 'Reset'),
              settings: AutoIPoETestData.settings.copyWith(
                selectedMode: AutoIPoEMode.biglobeStaticIp,
                biglobeStaticIpSettings: const BiglobeStaticIPSettings(
                  userPassword: AutoIPoESecret(value: secret),
                ),
              ),
            );

      setUp(() {
        SharedPreferences.setMockInitialValues({});
        transport = MockTransport();
        service = AutoIPoEService(UspClient.withTransport(transport));
        logs = [];
        Logger.addLogListener(capture);
      });
      tearDown(() => Logger.removeLogListener(capture));

      test('reads the receipt and suppresses request and response arguments',
          () async {
        when(() => transport.operate(command, args: any(named: 'args')))
            .thenAnswer((_) async => {
                  'success': true,
                  'result': {
                    'data': {
                      'commandKey': 'synthetic-command-key',
                      'outputArgs': {
                        'Result': jsonEncode({
                          'accepted': name != 'ResolvePending',
                          'cancelled': name == 'ResolvePending',
                          'requestId': AutoIPoETestData.id,
                          'operationId': AutoIPoETestData.id,
                          'privateResponseValue': secret,
                        }),
                      },
                    },
                  },
                });
        final receipt = await invoke();
        expect(receipt.accepted, name != 'ResolvePending');
        expect(receipt.cancelled, name == 'ResolvePending');
        expect(receipt.requestId, AutoIPoETestData.id);
        final sent = verify(
          () => transport.operate(command, args: captureAny(named: 'args')),
        ).captured.single as Map<String, String>;
        expect(sent['RequestId'], AutoIPoETestData.id);
        if (name == 'Apply') expect(sent['Settings'], contains(secret));
        expect(logs.join('\n'), contains('[redacted]'));
        expect(logs.join('\n'), isNot(contains(secret)));
        verifyNever(() => transport.refreshToken(token: any(named: 'token')));
      });

      for (final data in [
        {'commandKey': 'key', 'requestPath': 'Device.LocalAgent.Request.41.'},
        {'commandKey': 'key', 'noMatch': true},
      ]) {
        test('does not accept an outcome without a synchronous Result: $data',
            () async {
          when(() => transport.operate(command, args: any(named: 'args')))
              .thenAnswer((_) async => {
                    'success': true,
                    'result': {'data': data},
                  });
          await expectLater(invoke(), throwsA(isA<ServiceError>()));
          verify(() => transport.operate(command, args: any(named: 'args')))
              .called(1);
          verifyNever(() => transport.refreshToken(token: any(named: 'token')));
        });
      }

      for (final entry in errorCases) {
        final fixture = entry as Map<String, dynamic>;
        test('${fixture['name']} keeps its category without replay', () async {
          when(() => transport.operate(command, args: any(named: 'args')))
              .thenAnswer((_) async => {
                    'success': false,
                    'result': {
                      'data': <String, dynamic>{},
                      'error': {
                        command: {
                          'errorCode': fixture['errorCode'],
                          'errorMessage': fixture['errorMessage'],
                        },
                      },
                    },
                  });
          await expectLater(
            invoke(),
            throwsA(isA<ServiceError>().having(
              (error) => error.runtimeType.toString(),
              'service error category',
              fixture['serviceError'],
            )),
          );
          verify(() => transport.operate(command, args: any(named: 'args')))
              .called(1);
          verifyNever(() => transport.refreshToken(token: any(named: 'token')));
        });
      }
    });
  }
}
