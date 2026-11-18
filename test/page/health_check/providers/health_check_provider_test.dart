import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/health_check/models/health_check_server.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_state.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';

/// `GetHealthCheckStatus` output part way through a speed test.
Map<String, dynamic> _status({
  int latency = 0,
  int download = 0,
  int upload = 0,
  String exitCode = 'Unavailable',
  String running = 'SpeedTest',
}) =>
    {
      'healthCheckModuleCurrentlyRunning': running,
      'speedTestResult': {
        'resultID': 7,
        'exitCode': exitCode,
        'serverID': '3967',
        'latency': latency,
        'downloadBandwidth': download,
        'uploadBandwidth': upload,
      },
    };

/// The status polls of a whole run, 100 ms apart: 1.2 s each of latency,
/// download and upload, then done at 3.6 s. Each phase outlasts the second
/// for which the meter shows the download result once upload starts.
final _run = [
  for (var i = 0; i < 12; i++) _status(),
  for (var i = 0; i < 12; i++) _status(latency: 12),
  for (var i = 0; i < 12; i++) _status(latency: 12, download: 317412),
  _status(
      latency: 12,
      download: 317412,
      upload: 321267,
      exitCode: 'Success',
      running: 'None'),
];

Map<String, dynamic> _results({String exitCode = 'Success'}) => {
      'healthCheckResults': [
        {
          'resultID': 7,
          'timestamp': '2026-11-18T12:00:00Z',
          'healthCheckModulesRequested': ['SpeedTest'],
          'speedTestResult': {
            'resultID': 7,
            'exitCode': exitCode,
            'serverID': '3967',
            'latency': 12,
            'downloadBandwidth': 317412,
            'uploadBandwidth': 321267,
          },
        },
      ],
    };

const _taipei = HealthCheckServer(
  serverID: '3967',
  serverName: 'Chunghwa',
  serverLocation: 'Taipei',
  serverCountry: 'TW',
  serverHostname: 'speed.example',
  serverPort: 8080,
);

void main() {
  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;

  HealthCheckProvider notifier() =>
      container.read(healthCheckProvider.notifier);
  HealthCheckState page() => container.read(healthCheckProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.runHealthCheck, {'resultID': 7})
      ..holdsInTurn(JNAPAction.getHealthCheckStatus, _run)
      ..holds(JNAPAction.getHealthCheckResults, _results())
      ..holds(JNAPAction.getCloseHealthCheckServers, {
        'healthCheckServers': [_taipei.toJson()],
      });
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
  });

  tearDown(() => container.dispose());

  /// Lets every status poll and the delayed meter updates run out.
  Future<void> finish(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 6));

  group('starting a speed test', () {
    testWidgets('tests against the server picked', (tester) async {
      notifier().setSelectedServer(_taipei);

      await notifier().runHealthCheck(Module.speedtest);
      await finish(tester);

      expect(router.payloadsOf(JNAPAction.runHealthCheck).first,
          {'runHealthCheckModule': 'SpeedTest', 'targetServerID': '3967'});
    });

    testWidgets('tests against the server it is handed over the one picked',
        (tester) async {
      notifier().setSelectedServer(_taipei);

      await notifier().runHealthCheck(Module.speedtest, serverId: 42);
      await finish(tester);

      expect(router.payloadsOf(JNAPAction.runHealthCheck).first,
          {'runHealthCheckModule': 'SpeedTest', 'targetServerID': '42'});
    });

    testWidgets('leaves the server to the router when none is picked',
        (tester) async {
      await notifier().runHealthCheck(Module.speedtest);
      await finish(tester);

      expect(router.payloadsOf(JNAPAction.runHealthCheck).first,
          {'runHealthCheckModule': 'SpeedTest'});
    });

    test('reports a run the router gives no result for, and follows nothing',
        () async {
      router.holds(JNAPAction.runHealthCheck, const {});

      await notifier().runHealthCheck(Module.speedtest);

      expect(page().step, 'error');
      expect(page().error?.result, 'Empty resultID');
      expect(router.polls, isEmpty);
    });

    test('reports a run the router refuses', () async {
      router.refuses(JNAPAction.runHealthCheck);

      await expectLater(notifier().runHealthCheck(Module.speedtest),
          throwsA(isA<JNAPError>()));
      expect(router.polls, isEmpty);
    });
  });

  group('following a speed test', () {
    setUp(() => router.honorsPollDelays = true);

    testWidgets('moves through latency, download and upload', (tester) async {
      await notifier().runHealthCheck(Module.speedtest);

      await tester.pump(const Duration(milliseconds: 1));
      expect((page().step, page().status), ('latency', 'RUNNING'));
      expect(page().meterValue, 0);

      await tester.pump(const Duration(milliseconds: 1200));
      expect(page().step, 'downloadBandwidth');

      await tester.pump(const Duration(milliseconds: 1200));
      expect(page().step, 'uploadBandwidth');
      // Upload starts by showing the download result.
      expect(page().meterValue, 317412);

      await finish(tester);
    });

    testWidgets('reports the result once the test is done', (tester) async {
      await notifier().runHealthCheck(Module.speedtest);

      // The last poll, at 3.6 s, finds the test done.
      await tester.pump(const Duration(milliseconds: 3601));

      expect((page().step, page().status), ('success', 'COMPLETE'));
      expect(page().meterValue, 321267);
      expect(page().timestamp, '2026-11-18T12:00:00Z');
      expect(router.payloadsOf(JNAPAction.getHealthCheckResults).single, {
        'includeModuleResults': true,
        'healthCheckModule': 'SpeedTest',
        'lastNumberOfResults': 1,
        'resultIDs': [7],
      });
      // The results changed the router's own figures; poll them now.
      expect(polling.forced, 1);

      // What the in-progress polls scheduled still fires after this, and
      // must leave the result alone.
      await finish(tester);
      final result = page().result.single;
      expect(result.timestamp, '2026-11-18T12:00:00Z');
      expect(result.speedTestResult?.exitCode, 'Success');
      expect(result.speedTestResult?.uploadBandwidth, 321267);
      expect(page().meterValue, 321267);
    });

    testWidgets('reports a test that ended in an error', (tester) async {
      router
        ..holdsInTurn(JNAPAction.getHealthCheckStatus, [
          _status(),
          _status(exitCode: 'SpeedTestServerUnreachable', running: 'None'),
        ])
        ..holds(JNAPAction.getHealthCheckResults,
            _results(exitCode: 'SpeedTestServerUnreachable'));

      await notifier().runHealthCheck(Module.speedtest);
      await finish(tester);

      expect((page().step, page().status), ('error', 'COMPLETE'));
      expect(page().error?.result, 'SpeedTestServerUnreachable');
      expect(polling.forced, 0);
    });

    testWidgets('reports a result the router cannot give', (tester) async {
      router.refuses(JNAPAction.getHealthCheckResults);

      await notifier().runHealthCheck(Module.speedtest);
      await finish(tester);

      expect((page().step, page().status), ('error', 'COMPLETE'));
      expect(page().error, isA<JNAPError>());
    });

    testWidgets('ends in an error when a status cannot be read',
        (tester) async {
      router.holdsInTurn(JNAPAction.getHealthCheckStatus, [
        _status(),
        const JNAPError(result: 'ErrorUnknown'),
      ]);

      await notifier().runHealthCheck(Module.speedtest);
      await finish(tester);

      expect(router.payloadsOf(JNAPAction.getHealthCheckStatus), hasLength(2));
      expect((page().step, page().status), ('error', 'COMPLETE'));
      expect(page().error?.result, 'ErrorUnknown');
      // This run has no result to show, so none is fetched.
      expect(router.payloadsOf(JNAPAction.getHealthCheckResults), isEmpty);
    });
  });

  group('the other calls', () {
    test('updateServers lists the servers near the router', () async {
      final servers = await notifier().updateServers();

      expect(servers, [_taipei]);
      expect(page().servers, [_taipei]);
      expect(page().serversError, isFalse);
    });

    test('updateServers marks a list the router cannot give', () async {
      router.refuses(JNAPAction.getCloseHealthCheckServers);

      expect(await notifier().updateServers(), isEmpty);
      expect(page().serversError, isTrue);
    });

    test('getHealthCheckResults keeps the results of the run asked for',
        () async {
      final result =
          await notifier().getHealthCheckResults(Module.speedtest, 5, null);

      expect(result, isA<JNAPSuccess>());
      expect(router.payloadsOf(JNAPAction.getHealthCheckResults).single, {
        'includeModuleResults': true,
        'healthCheckModule': 'SpeedTest',
        'lastNumberOfResults': 5,
      });
      expect(page().result.single.speedTestResult?.downloadBandwidth, 317412);
    });

    test('setSelectedServer picks a server and clears the pick', () {
      notifier().setSelectedServer(_taipei);
      expect(page().selectedServer, _taipei);

      notifier().setSelectedServer(null);
      expect(page().selectedServer, isNull);
    });

    test('resetState starts over but keeps the server list', () async {
      await notifier().updateServers();
      await notifier().getHealthCheckResults(Module.speedtest, 1, 7);

      notifier().resetState();

      expect(page().result, isEmpty);
      expect(page().servers, [_taipei]);
      expect(page().status, 'IDLE');
    });
  });
}
