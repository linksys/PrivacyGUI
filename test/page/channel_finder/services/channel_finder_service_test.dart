import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/services/channel_finder_service.dart';

import '../../../mocks/test_data/channel_finder_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

class MockSseOperationAwaiter extends Mock implements SseOperationAwaiter {}

typedef _Data = ChannelFinderTestData;

/// Earlier scans already stored on the router, older than any new one.
final _earlier = {
  ..._Data.scanResultRows(
      radioPath: _Data.dataElements5,
      instance: 1,
      timeStamp: '2026-11-26T10:00:00.000000000Z',
      utilization: {36: 200, 40: 200, 44: 200, 48: 200, 149: 200}),
};

/// What the two channel scans leave behind: new results on both radios.
final _afterBoth = {
  ..._earlier,
  ..._Data.scanResultRows(
      radioPath: _Data.dataElements5,
      instance: 2,
      timeStamp: '2026-11-26T10:54:36.854579844Z',
      utilization: {36: 10, 40: 2, 44: 10, 48: 11, 149: 10}),
  ..._Data.scanResultRows(
      radioPath: _Data.dataElements24,
      instance: 1,
      timeStamp: '2026-11-26T10:56:44.90625725Z',
      utilization: {1: 60, 6: 84, 11: 52}),
};

const _fast = ChannelFinderTimings(
  neighborScanTimeout: Duration(seconds: 90),
  channelScanFirstRead: Duration.zero,
  channelScanReadInterval: Duration.zero,
  channelScanTimeout: Duration.zero,
);

void main() {
  late MockUspClient usp;
  late MockSseOperationAwaiter awaiter;
  late bool sseConnected;
  late Map<String, dynamic> radios;
  late Map<String, dynamic> dataElements;
  late List<Map<String, dynamic>> scanReads;
  late int scanReadCount;
  late List<({String command, Map<String, String> args})> operates;
  late Object? operateError;

  setUpAll(() {
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    usp = MockUspClient();
    awaiter = MockSseOperationAwaiter();
    sseConnected = true;
    radios = _Data.radiosRows();
    dataElements = _Data.dataElementsRows();
    scanReads = [_earlier, _afterBoth];
    scanReadCount = 0;
    operates = [];
    operateError = null;

    when(() => usp.get(any(), priority: any(named: 'priority')))
        .thenAnswer((invocation) async {
      final paths = invocation.positionalArguments[0] as List<String>;
      final first = paths.first;
      if (first.startsWith('Device.WiFi.Radio.')) return radios;
      if (first.startsWith('Device.WiFi.SSID.')) return _Data.ssidsRows();
      if (paths.any((p) => p.contains('.ScanResult.'))) {
        final read = scanReads[scanReadCount.clamp(0, scanReads.length - 1)];
        scanReadCount++;
        return read;
      }
      if (paths.any((p) => p.endsWith('ControllerID'))) {
        return _Data.networkInfoRows();
      }
      return dataElements;
    });
    when(() => usp.operate(any(), args: any(named: 'args')))
        .thenAnswer((invocation) async {
      operates.add((
        command: invocation.positionalArguments[0] as String,
        args: invocation.namedArguments[#args] as Map<String, String>,
      ));
      if (operateError != null) throw operateError!;
      return {};
    });
    when(() => awaiter.execute(
          operateCommand: any(named: 'operateCommand'),
          referencePath: any(named: 'referencePath'),
          timeout: any(named: 'timeout'),
        )).thenAnswer((_) async => _Data.neighborScanResult([
          _Data.neighbor(channel: 48, ssid: 'Lobby', signal: -45),
          _Data.neighbor(channel: 36, ssid: 'Upstairs', signal: -29),
          _Data.neighbor(
              channel: 48, ssid: '', bssid: 'aa:bb:cc:00:00:02', signal: -89),
          _Data.neighbor(
              radio: 'Device.WiFi.Radio.1',
              channel: 1,
              ssid: 'Cafe',
              signal: -52),
        ]));
  });

  ChannelFinderService service({ChannelFinderTimings timings = _fast}) =>
      ChannelFinderService(usp, awaiter,
          isLiveUpdatesConnected: () => sseConnected, timings: timings);

  group('scan', () {
    test('returns each band in order, with busyness from the new channel scan',
        () async {
      final result = await service().scan();

      expect(result.bands.map((b) => b.band), ['2.4GHz', '5GHz']);
      final band5 = result.bands.last;
      expect(band5.channelInUse, 48);
      expect(band5.channels.map((c) => c.channel), [36, 40, 44, 48, 149]);
      expect(band5.channels.map((c) => c.utilization), [10, 2, 10, 11, 10]);
      expect(band5.inUse?.channel, 48);
      final band24 = result.bands.first;
      expect(band24.channels.map((c) => c.channel),
          [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]);
      expect(band24.channels.first.utilization, 60);
      expect(band24.channels[1].utilization, isNull,
          reason: 'channel 2 was scanned but the result has no row for it');
      expect(result.bands.map((b) => b.measurement),
          everyElement(ChannelBandMeasurement.measured));
    });

    test('puts each network on its radio and channel, strongest first',
        () async {
      final result = await service().scan();

      final channel48 =
          result.bands.last.channels.firstWhere((c) => c.channel == 48);
      expect(channel48.neighbors.map((n) => n.signalDbm), [-45, -89]);
      expect(channel48.strongestSignalDbm, -45);
      expect(channel48.neighbors.last.ssid, isEmpty);
      expect(result.bands.first.channels.first.neighbors.single.ssid, 'Cafe');
      expect(
          result.bands.last.channels
              .firstWhere((c) => c.channel == 40)
              .neighbors,
          isEmpty);
    });

    test(
        'scans each radio on its DataElements row, without DFS channels when '
        'DFS is off', () async {
      await service().scan();

      expect(operates.map((o) => o.command), [
        'Device.WiFi.DataElements.Network.Device.1.Radio.2.ChannelScanRequest()',
        'Device.WiFi.DataElements.Network.Device.1.Radio.1.ChannelScanRequest()',
      ]);
      expect(operates.first.args,
          {'channels_list': '1,2,3,4,5,6,7,8,9,10,11', 'dwell_time_ms': '100'});
      expect(operates.last.args['channels_list'], '36,40,44,48,149');
    });

    test('keeps DFS channels when DFS is on', () async {
      radios = _Data.radiosRows(dfsEnabled: true);
      await service().scan();
      expect(operates.last.args['channels_list'], '36,40,44,48,52,149');
    });

    test('runs the neighbour scan before the channel scans, and says so',
        () async {
      final stages = <ChannelFinderScanStage>[];
      await service().scan(onStage: stages.add);

      expect(stages,
          [ChannelFinderScanStage.neighbors, ChannelFinderScanStage.channels]);
      verify(() => awaiter.execute(
            operateCommand: 'Device.WiFi.NeighboringWiFiDiagnostic()',
            referencePath: 'Device.WiFi.NeighboringWiFiDiagnostic()',
            timeout: const Duration(seconds: 90),
          )).called(1);
    });

    test('takes only a result newer than the one stored before the scan',
        () async {
      // Only the 5 GHz radio is scanned, and the first read after its scan
      // still holds only the earlier result.
      dataElements =
          _Data.dataElementsRows(bssid24OnDataElements: '72:12:13:21:55:03');
      scanReads = [_earlier, _earlier, _afterBoth];
      final result = await service(
              timings: const ChannelFinderTimings(
                  channelScanFirstRead: Duration.zero,
                  channelScanReadInterval: Duration.zero,
                  channelScanTimeout: Duration(seconds: 5)))
          .scan();

      expect(result.bands.last.channels.first.utilization, 10,
          reason: 'not 200 from the earlier scan');
    });

    test(
        'takes a new result by its instance number, so one without a '
        'TimeStamp still counts', () async {
      // Instance numbers only go up and are never reused (FW on #1778), so
      // the highest is the newest whatever its TimeStamp says.
      dataElements =
          _Data.dataElementsRows(bssid24OnDataElements: '72:12:13:21:55:03');
      scanReads = [
        _earlier,
        {
          ..._earlier,
          ..._Data.scanResultRows(
              radioPath: _Data.dataElements5,
              instance: 2,
              timeStamp: null,
              utilization: {36: 10, 40: 2, 44: 10, 48: 11, 149: 10}),
        },
      ];
      final result = await service().scan();

      expect(result.bands.last.channels.first.utilization, 10);
      expect(result.bands.last.measurement, ChannelBandMeasurement.measured);
    });

    test('leaves a band unmeasured when no new result arrives in time',
        () async {
      scanReads = [_earlier];
      final result = await service().scan();

      expect(result.bands.last.channels.map((c) => c.utilization),
          everyElement(isNull));
      expect(result.bands.map((b) => b.measurement),
          everyElement(ChannelBandMeasurement.unanswered));
      expect(
          result.bands.last.channels
              .firstWhere((c) => c.channel == 36)
              .neighbors,
          isNotEmpty);
    });

    test('leaves a band unmeasured when the router refuses its channel scan',
        () async {
      operateError = 'Operate failed: Invalid arguments (code: 7004)';
      final result = await service().scan();

      expect(result.bands.expand((b) => b.channels).map((c) => c.utilization),
          everyElement(isNull));
      expect(result.bands.map((b) => b.measurement),
          everyElement(ChannelBandMeasurement.refused));
      expect(result.bands.first.channels.first.neighbors, isNotEmpty);
    });

    test('measures nothing when the earlier scan results cannot be read',
        () async {
      var scanRead = 0;
      when(() => usp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.first.startsWith('Device.WiFi.Radio.')) return radios;
        if (paths.first.startsWith('Device.WiFi.SSID.')) {
          return _Data.ssidsRows();
        }
        if (paths.any((p) => p.contains('.ScanResult.'))) {
          scanRead++;
          throw 'Get failed: Request timed out (code: 9999)';
        }
        if (paths.any((p) => p.endsWith('ControllerID'))) {
          return _Data.networkInfoRows();
        }
        return dataElements;
      });
      final result = await service().scan();

      expect(scanRead, 1);
      expect(operates, isEmpty);
      expect(result.bands.expand((b) => b.channels).map((c) => c.utilization),
          everyElement(isNull));
      expect(result.bands.map((b) => b.measurement),
          everyElement(ChannelBandMeasurement.unanswered));
    });

    test(
        'does not channel-scan a radio no controller radio shares a BSSID with',
        () async {
      dataElements =
          _Data.dataElementsRows(bssid24OnDataElements: '72:12:13:21:55:03');
      final result = await service().scan();

      expect(operates.single.command, contains('Device.1.Radio.1.'));
      expect(result.bands.first.channels.map((c) => c.utilization),
          everyElement(isNull));
      expect(result.bands.first.channels.first.neighbors, isNotEmpty);
      expect(result.bands.map((b) => b.measurement), [
        ChannelBandMeasurement.refused,
        ChannelBandMeasurement.measured,
      ]);
    });

    test('channel-scans nothing when the controller is not in DataElements',
        () async {
      when(() => usp.get(any(), priority: any(named: 'priority')))
          .thenAnswer((invocation) async {
        final paths = invocation.positionalArguments[0] as List<String>;
        if (paths.first.startsWith('Device.WiFi.Radio.')) return radios;
        if (paths.first.startsWith('Device.WiFi.SSID.')) {
          return _Data.ssidsRows();
        }
        if (paths.any((p) => p.contains('.ScanResult.'))) return _earlier;
        if (paths.any((p) => p.endsWith('ControllerID'))) {
          return _Data.networkInfoRows(id: '00:00:00:00:00:99');
        }
        return dataElements;
      });
      final result = await service().scan();

      expect(operates, isEmpty);
      expect(result.bands, hasLength(2));
      expect(result.bands.map((b) => b.measurement),
          everyElement(ChannelBandMeasurement.refused));
    });

    test('leaves out a radio that is off', () async {
      radios = _Data.radiosRows(radio24Enabled: false);
      final result = await service().scan();

      expect(result.bands.map((b) => b.band), ['5GHz']);
      expect(operates.single.command, contains('Device.1.Radio.1.'));
    });

    test('marks no channel in use when the router does not say', () async {
      radios = _Data.radiosRows(channelsInUse5: '');
      final result = await service().scan();

      expect(result.bands.last.channelInUse, isNull);
      expect(result.bands.last.channels.where((c) => c.isInUse), isEmpty);
    });
  });

  group('scan failures', () {
    test('starts nothing when live updates are not connected', () async {
      sseConnected = false;

      await expectLater(service().scan(), throwsA(isA<NetworkError>()));
      verifyNever(() => usp.get(any(), priority: any(named: 'priority')));
      verifyNever(() => awaiter.execute(
            operateCommand: any(named: 'operateCommand'),
            referencePath: any(named: 'referencePath'),
            timeout: any(named: 'timeout'),
          ));
    });

    test('starts nothing when there is no operation awaiter', () async {
      final scan = ChannelFinderService(usp, null,
              isLiveUpdatesConnected: () => true, timings: _fast)
          .scan();

      await expectLater(scan, throwsA(isA<NetworkError>()));
      expect(operates, isEmpty);
    });

    test('maps a failed radio read', () async {
      when(() => usp.get(any(), priority: any(named: 'priority')))
          .thenThrow('Get failed: Request timed out (code: 9999)');

      await expectLater(service().scan(), throwsA(isA<ServiceError>()));
    });

    test('throws when no radio is on', () async {
      radios = {
        ..._Data.radiosRows(radio24Enabled: false),
        'Device.WiFi.Radio.2.Enable': false,
      };

      await expectLater(
          service().scan(), throwsA(isA<ResourceNotFoundError>()));
    });

    test('turns a neighbour scan that never completes into a TimeoutError',
        () async {
      when(() => awaiter.execute(
            operateCommand: any(named: 'operateCommand'),
            referencePath: any(named: 'referencePath'),
            timeout: any(named: 'timeout'),
          )).thenThrow(TimeoutException('OperationComplete not received'));

      await expectLater(service().scan(), throwsA(isA<TimeoutError>()));
      expect(operates, isEmpty);
    });

    test('reports a refused neighbour scan with the router code', () async {
      when(() => awaiter.execute(
            operateCommand: any(named: 'operateCommand'),
            referencePath: any(named: 'referencePath'),
            timeout: any(named: 'timeout'),
          )).thenAnswer((_) async => const OperateResult(
            commandName: 'NeighboringWiFiDiagnostic()',
            commandKey: 'ck-1778',
            status: 'Error',
            outputArgs: {},
            errorCode: '7022',
            errorMessage: 'Command failed',
          ));

      await expectLater(
        service().scan(),
        throwsA(isA<UspCompleteFailureError>()
            .having((e) => e.code, 'code', 7022)
            .having((e) => e.failures.single.requestedPath, 'path',
                ChannelFinderService.neighborScanCommand)),
      );
    });

    test('fails a neighbour scan that ends with another status', () async {
      when(() => awaiter.execute(
                operateCommand: any(named: 'operateCommand'),
                referencePath: any(named: 'referencePath'),
                timeout: any(named: 'timeout'),
              ))
          .thenAnswer((_) async =>
              _Data.neighborScanResult(const [], status: 'Error_Internal'));

      await expectLater(service().scan(), throwsA(isA<UnexpectedError>()));
    });
  });

  group('groupNeighborScanResults', () {
    test('groups by radio path with a trailing dot, then channel', () {
      final grouped = ChannelFinderService.groupNeighborScanResults(
          _Data.neighborScanResult([
        _Data.neighbor(channel: 36, signal: -70),
        _Data.neighbor(channel: 36, bssid: 'aa:bb:cc:00:00:02', signal: -40),
        _Data.neighbor(radio: 'Device.WiFi.Radio.1.', channel: 6, signal: -60),
      ]).outputArgs);

      expect(grouped.keys, ['Device.WiFi.Radio.2.', 'Device.WiFi.Radio.1.']);
      expect(grouped['Device.WiFi.Radio.2.']![36]!.map((n) => n.signalDbm),
          [-40, -70]);
      expect(grouped['Device.WiFi.Radio.1.']![6]!.single.signalDbm, -60);
    });

    test('leaves out a result without a radio, a channel or a signal', () {
      final grouped = ChannelFinderService.groupNeighborScanResults(const {
        'Status': 'Complete',
        'Result.1.Radio': '',
        'Result.1.Channel': '36',
        'Result.1.SignalStrength': '-50',
        'Result.2.Radio': 'Device.WiFi.Radio.2',
        'Result.2.SignalStrength': '-50',
        'Result.3.Radio': 'Device.WiFi.Radio.2',
        'Result.3.Channel': '40',
        'Result.3.SignalStrength': 'n/a',
        'Result.4.Radio': 'Device.WiFi.Radio.2',
        'Result.4.Channel': '44',
        'Result.4.SignalStrength': '-61',
      });

      expect(grouped['Device.WiFi.Radio.2.']!.keys, [44]);
    });
  });
}
