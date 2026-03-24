import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/models/operate_result.dart';

void main() {
  // ---------------------------------------------------------------------------
  // OperateResult
  // ---------------------------------------------------------------------------
  group('OperateResult', () {
    test('constructor stores fields', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: 'abc-123',
        status: 'Complete',
        outputArgs: {'SuccessCount': '5'},
      );
      expect(result.commandName, 'IPPing()');
      expect(result.commandKey, 'abc-123');
      expect(result.status, 'Complete');
      expect(result.outputArgs, {'SuccessCount': '5'});
    });

    test('isComplete true when status=Complete', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {},
      );
      expect(result.isComplete, isTrue);
    });

    test('isComplete false when status=Error', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Error',
        outputArgs: {},
      );
      expect(result.isComplete, isFalse);
    });

    test('isError true when status=Error', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Error',
        outputArgs: {},
      );
      expect(result.isError, isTrue);
    });

    test('isError false when status=Complete', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {},
      );
      expect(result.isError, isFalse);
    });

    test('toString contains commandName and status', () {
      final result = OperateResult(
        commandName: 'TraceRoute()',
        commandKey: 'key-1',
        status: 'Complete',
        outputArgs: {'a': '1', 'b': '2'},
      );
      final str = result.toString();
      expect(str, contains('TraceRoute()'));
      expect(str, contains('Complete'));
      expect(str, contains('2 params'));
    });

    test('empty outputArgs works', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {},
      );
      expect(result.outputArgs.length, 0);
    });

    test('const constructor works', () {
      const result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {},
      );
      expect(result.commandName, 'IPPing()');
    });
  });

  // ---------------------------------------------------------------------------
  // PingResult
  // ---------------------------------------------------------------------------
  group('PingResult', () {
    test('constructor stores all fields', () {
      final ping = PingResult(
        host: '8.8.8.8',
        successCount: 5,
        failureCount: 1,
        avgResponseTime: 20,
        minResponseTime: 10,
        maxResponseTime: 30,
        status: 'Complete',
      );
      expect(ping.host, '8.8.8.8');
      expect(ping.successCount, 5);
      expect(ping.failureCount, 1);
      expect(ping.avgResponseTime, 20);
      expect(ping.minResponseTime, 10);
      expect(ping.maxResponseTime, 30);
      expect(ping.status, 'Complete');
    });

    test('isComplete when status=Complete', () {
      final ping = PingResult(
        host: '8.8.8.8',
        successCount: 5,
        failureCount: 0,
        avgResponseTime: 20,
        minResponseTime: 10,
        maxResponseTime: 30,
        status: 'Complete',
      );
      expect(ping.isComplete, isTrue);
    });

    test('totalCount = success + failure', () {
      final ping = PingResult(
        host: '8.8.8.8',
        successCount: 7,
        failureCount: 3,
        avgResponseTime: 0,
        minResponseTime: 0,
        maxResponseTime: 0,
        status: 'Complete',
      );
      expect(ping.totalCount, 10);
    });

    test('successRate calculation', () {
      final ping = PingResult(
        host: '8.8.8.8',
        successCount: 5,
        failureCount: 5,
        avgResponseTime: 0,
        minResponseTime: 0,
        maxResponseTime: 0,
        status: 'Complete',
      );
      expect(ping.successRate, 50.0);
    });

    test('successRate zero when totalCount=0', () {
      final ping = PingResult(
        host: '8.8.8.8',
        successCount: 0,
        failureCount: 0,
        avgResponseTime: 0,
        minResponseTime: 0,
        maxResponseTime: 0,
        status: 'Complete',
      );
      expect(ping.successRate, 0);
    });

    test('fromOperateResult parses all fields', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: 'key-1',
        status: 'Complete',
        outputArgs: {
          'SuccessCount': '10',
          'FailureCount': '2',
          'AverageResponseTime': '25',
          'MinimumResponseTime': '5',
          'MaximumResponseTime': '50',
        },
      );
      final ping = PingResult.fromOperateResult(result, '8.8.8.8');
      expect(ping.successCount, 10);
      expect(ping.failureCount, 2);
      expect(ping.avgResponseTime, 25);
      expect(ping.minResponseTime, 5);
      expect(ping.maxResponseTime, 50);
    });

    test('fromOperateResult handles missing keys', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {},
      );
      final ping = PingResult.fromOperateResult(result, '1.1.1.1');
      expect(ping.successCount, 0);
      expect(ping.failureCount, 0);
      expect(ping.avgResponseTime, 0);
    });

    test('fromOperateResult handles non-numeric values', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {
          'SuccessCount': 'abc',
          'FailureCount': '',
          'AverageResponseTime': 'NaN',
        },
      );
      final ping = PingResult.fromOperateResult(result, '8.8.8.8');
      expect(ping.successCount, 0);
      expect(ping.failureCount, 0);
      expect(ping.avgResponseTime, 0);
    });

    test('fromOperateResult uses host parameter', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {},
      );
      final ping = PingResult.fromOperateResult(result, 'google.com');
      expect(ping.host, 'google.com');
    });

    test('fromOperateResult preserves status', () {
      final result = OperateResult(
        commandName: 'IPPing()',
        commandKey: '',
        status: 'Error',
        outputArgs: {},
      );
      final ping = PingResult.fromOperateResult(result, '8.8.8.8');
      expect(ping.status, 'Error');
      expect(ping.isComplete, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // TracerouteHop
  // ---------------------------------------------------------------------------
  group('TracerouteHop', () {
    test('constructor stores fields', () {
      final hop = TracerouteHop(
        hopNumber: 3,
        host: 'router.local',
        hostAddress: '192.168.1.1',
        rtTimes: [10, 20, 30],
      );
      expect(hop.hopNumber, 3);
      expect(hop.host, 'router.local');
      expect(hop.hostAddress, '192.168.1.1');
      expect(hop.rtTimes, [10, 20, 30]);
    });

    test('avgRoundTrip calculation', () {
      final hop = TracerouteHop(
        hopNumber: 1,
        host: '',
        hostAddress: '',
        rtTimes: [10, 20, 30],
      );
      expect(hop.avgRoundTrip, 20); // (10+20+30)/3 = 20
    });

    test('avgRoundTrip empty list returns 0', () {
      final hop = TracerouteHop(
        hopNumber: 1,
        host: '',
        hostAddress: '',
        rtTimes: [],
      );
      expect(hop.avgRoundTrip, 0);
    });

    test('avgRoundTrip rounds correctly', () {
      final hop = TracerouteHop(
        hopNumber: 1,
        host: '',
        hostAddress: '',
        rtTimes: [10, 11], // avg = 10.5 → round to 11
      );
      expect(hop.avgRoundTrip, 11);
    });
  });

  // ---------------------------------------------------------------------------
  // TracerouteResult
  // ---------------------------------------------------------------------------
  group('TracerouteResult', () {
    test('constructor stores fields', () {
      final result = TracerouteResult(
        host: '8.8.8.8',
        status: 'Complete',
        hops: [
          TracerouteHop(
            hopNumber: 1,
            host: 'gw',
            hostAddress: '192.168.1.1',
            rtTimes: [5],
          ),
        ],
      );
      expect(result.host, '8.8.8.8');
      expect(result.status, 'Complete');
      expect(result.hops.length, 1);
    });

    test('isComplete when status=Complete', () {
      final result = TracerouteResult(
        host: '8.8.8.8',
        status: 'Complete',
        hops: [],
      );
      expect(result.isComplete, isTrue);
    });

    test('fromOperateResult parses hops', () {
      final operateResult = OperateResult(
        commandName: 'TraceRoute()',
        commandKey: 'key-1',
        status: 'Complete',
        outputArgs: {
          'RouteHops.1.Host': 'gw.local',
          'RouteHops.1.HostAddress': '192.168.1.1',
          'RouteHops.1.RTTimes': '5,10,15',
          'RouteHops.2.Host': 'isp.node',
          'RouteHops.2.HostAddress': '10.0.0.1',
          'RouteHops.2.RTTimes': '20,25,30',
          'RouteHops.3.Host': 'target',
          'RouteHops.3.HostAddress': '8.8.8.8',
          'RouteHops.3.RTTimes': '35,40',
        },
      );
      final result =
          TracerouteResult.fromOperateResult(operateResult, '8.8.8.8');
      expect(result.hops.length, 3);
      expect(result.hops[0].hopNumber, 1);
      expect(result.hops[0].host, 'gw.local');
      expect(result.hops[0].rtTimes, [5, 10, 15]);
      expect(result.hops[1].hopNumber, 2);
      expect(result.hops[2].hopNumber, 3);
    });

    test('fromOperateResult sorts by hopNumber', () {
      final operateResult = OperateResult(
        commandName: 'TraceRoute()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {
          'RouteHops.3.Host': 'c',
          'RouteHops.3.HostAddress': '3.3.3.3',
          'RouteHops.3.RTTimes': '30',
          'RouteHops.1.Host': 'a',
          'RouteHops.1.HostAddress': '1.1.1.1',
          'RouteHops.1.RTTimes': '10',
        },
      );
      final result =
          TracerouteResult.fromOperateResult(operateResult, 'target');
      expect(result.hops.first.hopNumber, 1);
      expect(result.hops.last.hopNumber, 3);
    });

    test('fromOperateResult handles empty RTTimes', () {
      final operateResult = OperateResult(
        commandName: 'TraceRoute()',
        commandKey: '',
        status: 'Complete',
        outputArgs: {
          'RouteHops.1.Host': 'gw',
          'RouteHops.1.HostAddress': '192.168.1.1',
          'RouteHops.1.RTTimes': '',
        },
      );
      final result = TracerouteResult.fromOperateResult(operateResult, 'host');
      expect(result.hops[0].rtTimes, isEmpty);
    });

    test('fromOperateResult handles no hops', () {
      final operateResult = OperateResult(
        commandName: 'TraceRoute()',
        commandKey: '',
        status: 'Error',
        outputArgs: {
          'Status': 'Error',
        },
      );
      final result = TracerouteResult.fromOperateResult(operateResult, 'host');
      expect(result.hops, isEmpty);
      expect(result.isComplete, isFalse);
    });
  });
}
