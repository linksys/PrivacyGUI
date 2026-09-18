import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';

class _RecordedCall {
  const _RecordedCall({
    required this.action,
    required this.data,
    required this.auth,
    required this.fetchRemote,
    required this.cacheLevel,
    required this.timeoutMs,
    required this.retries,
  });

  final JNAPAction action;
  final Map<String, dynamic> data;
  final bool auth;
  final bool fetchRemote;
  final CacheLevel? cacheLevel;
  final int timeoutMs;
  final int retries;
}

class _PingRouterRepository extends Fake implements RouterRepository {
  _PingRouterRepository({
    this.stopFails = false,
    required List<Map<String, dynamic>> statuses,
  }) : statuses = List.of(statuses);

  final bool stopFails;
  final List<Map<String, dynamic>> statuses;
  final calls = <_RecordedCall>[];

  @override
  Future<JNAPSuccess> send(
    JNAPAction action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool auth = false,
    CommandType? type,
    bool fetchRemote = false,
    CacheLevel? cacheLevel,
    int timeoutMs = 10000,
    int retries = 1,
    JNAPSideEffectOverrides? sideEffectOverrides,
  }) async {
    calls.add(
      _RecordedCall(
        action: action,
        data: data,
        auth: auth,
        fetchRemote: fetchRemote,
        cacheLevel: cacheLevel,
        timeoutMs: timeoutMs,
        retries: retries,
      ),
    );

    if (action == JNAPAction.stopPing && stopFails) {
      throw StateError('No previous ping is running');
    }
    if (action == JNAPAction.getPingStatus) {
      return JNAPSuccess(
        result: 'OK',
        output: statuses.removeAt(0),
      );
    }
    return const JNAPSuccess(result: 'OK', output: {});
  }
}

Map<String, dynamic> _pingStatus({
  required bool isRunning,
  required String pingLog,
}) {
  return {
    'isRunning': isRunning,
    'pingLog': pingLog,
  };
}

void main() {
  group('AutoIPoEService.probeInternet', () {
    test('stops any old probe, starts 1.1.1.1, and accepts a reply', () async {
      final repository = _PingRouterRepository(
        stopFails: true,
        statuses: [
          _pingStatus(isRunning: true, pingLog: ''),
          _pingStatus(
            isRunning: false,
            pingLog: '64 bytes from 1.1.1.1: seq=0 ttl=57 time=8.2 ms',
          ),
        ],
      );
      final service = AutoIPoEService(repository);

      final connected = await service.probeInternet(
        pollDelay: Duration.zero,
      );

      expect(connected, isTrue);
      expect(repository.calls.map((call) => call.action), [
        JNAPAction.stopPing,
        JNAPAction.startPing,
        JNAPAction.getPingStatus,
        JNAPAction.getPingStatus,
      ]);
      expect(repository.calls[1].data, {
        'host': '1.1.1.1',
        'packetSizeBytes': 32,
        'pingCount': 3,
      });
      for (final call in repository.calls) {
        expect(call.auth, isTrue);
        expect(call.fetchRemote, isTrue);
        expect(call.cacheLevel, CacheLevel.noCache);
        expect(call.retries, 0);
      }
      expect(repository.calls.first.timeoutMs, 3000);
      expect(repository.calls.skip(1).map((call) => call.timeoutMs), [
        5000,
        5000,
        5000,
      ]);
    });

    test('accepts a completed summary with received packets', () async {
      final repository = _PingRouterRepository(
        statuses: [
          _pingStatus(
            isRunning: false,
            pingLog:
                '3 packets transmitted\n2 packets received\n33% packet loss',
          ),
        ],
      );

      final connected = await AutoIPoEService(repository).probeInternet(
        maxPoll: 1,
        pollDelay: Duration.zero,
      );

      expect(connected, isTrue);
    });

    test('does not mistake 100% packet loss for 0% packet loss', () async {
      final repository = _PingRouterRepository(
        statuses: [
          _pingStatus(
            isRunning: false,
            pingLog:
                '3 packets transmitted, 0 packets received, 100% packet loss',
          ),
        ],
      );

      final connected = await AutoIPoEService(repository).probeInternet(
        maxPoll: 5,
        pollDelay: Duration.zero,
      );

      expect(connected, isFalse);
      expect(
        repository.calls
            .where((call) => call.action == JNAPAction.getPingStatus),
        hasLength(1),
      );
    });

    test('does not mistake decimal 100.0% loss for decimal 0.0% loss',
        () async {
      final repository = _PingRouterRepository(
        statuses: [
          _pingStatus(
            isRunning: false,
            pingLog: '3 packets transmitted, 100.0% packet loss',
          ),
        ],
      );

      final connected = await AutoIPoEService(repository).probeInternet(
        maxPoll: 5,
        pollDelay: Duration.zero,
      );

      expect(connected, isFalse);
      expect(
        repository.calls
            .where((call) => call.action == JNAPAction.getPingStatus),
        hasLength(1),
      );
    });

    test('bounds status polling while the ping remains in progress', () async {
      final repository = _PingRouterRepository(
        statuses: List.generate(
          3,
          (_) => _pingStatus(isRunning: true, pingLog: 'PING 1.1.1.1'),
        ),
      );

      final connected = await AutoIPoEService(repository).probeInternet(
        maxPoll: 3,
        pollDelay: Duration.zero,
      );

      expect(connected, isFalse);
      expect(
        repository.calls
            .where((call) => call.action == JNAPAction.getPingStatus),
        hasLength(3),
      );
    });

    test('cancels before starting another diagnostic ping', () async {
      final repository = _PingRouterRepository(statuses: const []);

      final connected = await AutoIPoEService(repository).probeInternet(
        shouldContinue: () => false,
      );

      expect(connected, isFalse);
      expect(
          repository.calls.map((call) => call.action), [JNAPAction.stopPing]);
    });
  });
}
