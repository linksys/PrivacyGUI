// What an HTTP command does with the router's answer: it retries the one error
// the app treats as passing (_ErrorUnexpected) once, after 3 s, and hands
// every other answer on as it came.
//
// The wait is a real timer, so the retry tests run on testWidgets' fake clock
// and read the outcome after pumping.

import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/core/cache/linksys_cache_manager.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

const _getDeviceInfo = 'http://linksys.com/jnap/core/GetDeviceInfo';

Response _answer(Map<String, dynamic> body) => Response(jsonEncode(body), 200);

final _unexpected = _answer({'result': '_ErrorUnexpected'});
final _unauthorized = _answer({'result': '_ErrorUnauthorized'});
final _ok = _answer({
  'result': 'OK',
  'output': {'serialNumber': '20J2060A839173'},
});

/// An executor standing in for the HTTP client: hands back each answer in
/// turn, the last from then on.
class _ScriptedExecutor with JNAPCommandExecutor<Response> {
  _ScriptedExecutor(this.answers);

  final List<Response> answers;
  final List<BaseCommand> executed = [];

  @override
  Future<Response> execute(BaseCommand command) async {
    executed.add(command);
    return answers.length > 1 ? answers.removeAt(0) : answers.single;
  }

  @override
  void dropCommand(String id) {}
}

class _Outcome {
  Object? value;
  Object? error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // A command reads the response cache, which reaches for the temp directory.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.path,
  );

  // The cache is a singleton; built here, on the real clock, its file work
  // stays out of the tests' fake clock.
  setUpAll(() async {
    // A transaction names itself by the transaction action.
    initBetterActions();
    LinksysCacheManager();
    await pumpEventQueue();
  });

  JNAPHttpCommand command(_ScriptedExecutor executor) => JNAPHttpCommand(
        url: 'https://192.168.1.1/JNAP/',
        executor: executor,
        action: _getDeviceInfo,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );

  _Outcome publish(BaseHttpCommand command) {
    final outcome = _Outcome();
    command.publish().then(
          (value) => outcome.value = value,
          onError: (Object error) => outcome.error = error,
        );
    return outcome;
  }

  testWidgets(
      'retries an unexpected error once, 3 s later, and answers with '
      'the retry', (tester) async {
    final executor = _ScriptedExecutor([_unexpected, _ok]);

    final outcome = publish(command(executor));
    await tester.pump(const Duration(milliseconds: 2999));
    expect(executor.executed, hasLength(1));
    expect(outcome.value, isNull);
    await tester.pump(const Duration(milliseconds: 1));

    expect(executor.executed, hasLength(2));
    expect((outcome.value as JNAPSuccess).output['serialNumber'],
        '20J2060A839173');
  });

  testWidgets('gives up with the error when the retry fails too',
      (tester) async {
    final executor = _ScriptedExecutor([_unexpected]);

    final outcome = publish(command(executor));
    await tester.pump(const Duration(seconds: 3));

    expect(executor.executed, hasLength(2));
    expect((outcome.error as JNAPError).result, '_ErrorUnexpected');
  });

  testWidgets('passes any other error on at once', (tester) async {
    final executor = _ScriptedExecutor([_unauthorized, _ok]);

    final outcome = publish(command(executor));
    await tester.pump();

    expect(executor.executed, hasLength(1));
    expect((outcome.error as JNAPError).result, '_ErrorUnauthorized');
    await tester.pump(const Duration(seconds: 3));
    expect(executor.executed, hasLength(1));
  });

  testWidgets('retries a transaction the same way', (tester) async {
    final executor = _ScriptedExecutor([
      _unexpected,
      _answer({
        'result': 'OK',
        'responses': [
          {
            'result': 'OK',
            'output': {'isAdminPasswordDefault': false}
          },
        ],
      }),
    ]);
    final transaction = TransactionHttpCommand(
      url: 'https://192.168.1.1/JNAP/',
      executor: executor,
      payload: [
        {
          'action': 'http://linksys.com/jnap/core/IsAdminPasswordDefault',
          'request': <String, dynamic>{},
        }
      ],
      actions: [JNAPAction.isAdminPasswordDefault],
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );

    final outcome = publish(transaction);
    await tester.pump(const Duration(seconds: 3));

    expect(executor.executed, hasLength(2));
    final result = outcome.value as JNAPTransactionSuccessWrap;
    expect((result.data.single.value as JNAPSuccess).output,
        {'isAdminPasswordDefault': false});
  });

  test('sends the action and its headers, with the data as JSON', () async {
    final executor = _ScriptedExecutor([_ok]);
    final sent = JNAPHttpCommand(
      url: 'https://192.168.1.1/JNAP/',
      executor: executor,
      action: 'http://linksys.com/jnap/devicelist/SetDeviceProperties',
      data: {'deviceID': 'tablet-id'},
      extraHeader: {
        'X-JNAP-Authorization': 'Basic YWRtaW46YWRtaW4=',
        'X-Empty': ''
      },
      fetchRemote: true,
      cacheLevel: CacheLevel.noCache,
    );

    await sent.publish();

    expect(sent.header, {
      'X-JNAP-Action': 'http://linksys.com/jnap/devicelist/SetDeviceProperties',
      'content-type': 'application/json',
      'X-JNAP-Authorization': 'Basic YWRtaW46YWRtaW4=',
    });
    expect(jsonDecode(sent.data), {'deviceID': 'tablet-id'});
  });
}
