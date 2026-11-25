// The speed test's state as JSON and as a value: the shape test/test_data
// gives the views, and what the state writes.

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';

import '../../../test_data/health_check_state_data.dart';

const _server = HealthCheckServer(
  serverID: '3967',
  serverName: 'Speedtest Taipei',
  serverLocation: 'Taipei',
  serverCountry: 'TW',
  serverHostname: 'speedtest.example.net',
  serverPort: 8080,
);

const _serverMap = <String, dynamic>{
  'serverID': '3967',
  'serverName': 'Speedtest Taipei',
  'serverLocation': 'Taipei',
  'serverCountry': 'TW',
  'serverHostname': 'speedtest.example.net',
  'serverPort': 8080,
};

void main() {
  test('starts idle with no step, result, servers or error', () {
    final state = HealthCheckState.init();

    expect(state.status, 'IDLE');
    expect(state.step, '');
    expect(state.result, isEmpty);
    expect(state.servers, isEmpty);
    expect(state.selectedServer, isNull);
    expect(state.error, isNull);
    expect(state.serversError, isFalse);
  });

  test('reads a finished test as the test data writes it', () {
    final state = HealthCheckState.fromJson(healthCheckStateSuccessGood);

    expect(state.status, 'COMPLETE');
    expect(state.step, 'uploadBandwidth');
    expect(state.timestamp, '2024-06-24T09:20:09Z');
    expect(state.result.single.speedTestResult?.uploadBandwidth, 91267);
    expect(state.result.single.speedTestResult?.downloadBandwidth, 97412);
    expect(state.servers, isEmpty);
    expect(state.serversError, isFalse);
  });

  test('reads a failed test with its error', () {
    final state = HealthCheckState.fromJson(healthCheckStateError);

    expect(state.step, 'error');
    expect(state.error, const JNAPError(result: 'Empty resultID'));
  });

  test('writes the JSON it was read from, with the server fields added since',
      () {
    final state = HealthCheckState.fromJson(healthCheckStateSuccessGood);

    expect(jsonDecode(state.toJson()), {
      ...jsonDecode(healthCheckStateSuccessGood) as Map<String, dynamic>,
      'servers': <Object>[],
      'serversError': false,
    });
  });

  test('writes and reads back the servers and the one chosen', () {
    final state = HealthCheckState.init()
        .copyWith(servers: [_server], selectedServer: _server);

    final json = jsonDecode(state.toJson()) as Map<String, dynamic>;
    expect(json['servers'], [_serverMap]);
    expect(json['selectedServer'], _serverMap);
    expect(HealthCheckState.fromJson(state.toJson()), state);
  });

  test('a state read twice is the same state; a change to any field is not',
      () {
    final state = HealthCheckState.fromJson(healthCheckStateSuccessGood);

    expect(HealthCheckState.fromJson(healthCheckStateSuccessGood), state);
    for (final edited in [
      state.copyWith(step: 'latency'),
      state.copyWith(status: 'RUNNING'),
      state.copyWith(result: []),
      state.copyWith(meterValue: 50.0),
      state.copyWith(randomValue: 0.5),
      state.copyWith(error: const JNAPError(result: 'ErrorUnknown')),
      state.copyWith(servers: [_server]),
      state.copyWith(selectedServer: _server),
      state.copyWith(serversError: true),
    ]) {
      expect(edited, isNot(state));
    }
  });

  test('an edit keeps the fields it does not name, and can drop the server',
      () {
    final state = HealthCheckState.fromJson(healthCheckStateSuccessGood)
        .copyWith(selectedServer: _server);

    final running = state.copyWith(status: 'RUNNING');
    expect(running.selectedServer, _server);
    expect(running.timestamp, '2024-06-24T09:20:09Z');
    expect(running.result, same(state.result));

    expect(state.copyWith(clearSelectedServer: true).selectedServer, isNull);
  });
}
