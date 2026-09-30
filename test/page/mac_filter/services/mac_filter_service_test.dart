import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/mac_filter/services/mac_filter_service.dart';

class MockUspClient extends Mock implements UspClient {}

const _modePath = 'Device.WiFi.DataElements.Network.X_LINKSYS_MACFilterMode';
const _listPath = 'Device.WiFi.DataElements.Network.X_LINKSYS_MACFilterList';
const _cmdPath = 'Device.WiFi.DataElements.Network.X_LINKSYS_SetMACFilter()';

void main() {
  late MockUspClient usp;
  late UspMacFilterService service;

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    registerFallbackValue(<List<Map<String, String>>>[]);
  });

  setUp(() {
    usp = MockUspClient();
    service = UspMacFilterService(usp);
  });

  void stubGet(String mode, String list) {
    when(() => usp.get(any())).thenAnswer((_) async => {
          _modePath: mode,
          _listPath: list,
        });
  }

  void stubOperateOk() {
    when(() => usp.operate(any(), args: any(named: 'args')))
        .thenAnswer((_) async => {
              'success': true,
              'result': {
                'data': {'commandKey': 'k'}
              }
            });
  }

  // ---------------------------------------------------------------------------
  // static validation helpers
  // ---------------------------------------------------------------------------

  group('validateMac', () {
    test('accepts colon and dash forms, rejects garbage', () {
      expect(UspMacFilterService.validateMac('AA:BB:CC:DD:EE:01'), isTrue);
      expect(UspMacFilterService.validateMac('aa-bb-cc-dd-ee-01'), isTrue);
      expect(UspMacFilterService.validateMac('  AA:BB:CC:DD:EE:01  '), isTrue);
      expect(UspMacFilterService.validateMac('zz:zz:zz:zz:zz:zz'), isFalse);
      expect(UspMacFilterService.validateMac('AA:BB:CC'), isFalse);
      expect(UspMacFilterService.validateMac(''), isFalse);
    });
  });

  group('normalizeMac', () {
    test('uppercases and colon-separates', () {
      expect(UspMacFilterService.normalizeMac('aa-bb-cc-dd-ee-01'),
          'AA:BB:CC:DD:EE:01');
      expect(UspMacFilterService.normalizeMac('  aa:bb:cc:dd:ee:01 '),
          'AA:BB:CC:DD:EE:01');
    });
  });

  // ---------------------------------------------------------------------------
  // fetch — read side (comma-split, mode parse)
  // ---------------------------------------------------------------------------

  group('fetch', () {
    test('parses mode and comma-joined list', () async {
      stubGet('Deny', 'AA:BB:CC:DD:EE:01,AA:BB:CC:DD:EE:02');

      final data = await service.fetch();

      expect(data.mode, MacFilterMode.deny);
      expect(data.macs, ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']);
    });

    test('empty list string yields empty macs (no phantom "")', () async {
      stubGet('Disabled', '');

      final data = await service.fetch();

      expect(data.mode, MacFilterMode.disabled);
      expect(data.macs, isEmpty);
    });

    test('Allow mode parses', () async {
      stubGet('Allow', 'AA:BB:CC:DD:EE:01');

      final data = await service.fetch();

      expect(data.mode, MacFilterMode.allow);
      expect(data.macs, ['AA:BB:CC:DD:EE:01']);
    });

    test('unknown mode string falls back to Disabled (defensive)', () async {
      stubGet('Weird', '');

      final data = await service.fetch();

      expect(data.mode, MacFilterMode.disabled);
    });

    test('maps a thrown USP error to ServiceError', () async {
      when(() => usp.get(any())).thenThrow(Exception('boom'));

      expect(() => service.fetch(), throwsA(isA<ServiceError>()));
    });
  });

  // ---------------------------------------------------------------------------
  // fetchAll — the online devices the pages offer
  //
  // The MAC filter applies to Wi-Fi only (fronthaul BSSes, linksys/FWDEV#194): a
  // wired client is never blocked or admitted by it. So only wireless clients are
  // offered — Instant Privacy's pre-fill and both pages' Add picker. Host shapes
  // below are as the bench returns them: Wi-Fi via `Device.WiFi.Radio.N` and
  // `InterfaceType: Wi-Fi`; every wired client via `Device.Ethernet.Interface.1`.
  // ---------------------------------------------------------------------------

  group('fetchAll', () {
    Map<String, dynamic> host(int i, String mac,
            {required String layer1, String? type, String active = '1'}) =>
        {
          'Device.Hosts.Host.$i.PhysAddress': mac,
          'Device.Hosts.Host.$i.IPAddress': '192.168.1.${100 + i}',
          'Device.Hosts.Host.$i.HostName': 'host$i',
          'Device.Hosts.Host.$i.Active': active,
          'Device.Hosts.Host.$i.Layer1Interface': layer1,
          if (type != null) 'Device.Hosts.Host.$i.InterfaceType': type,
        };

    void stubHosts(Map<String, dynamic> hosts) {
      when(() => usp.get(any())).thenAnswer((inv) async {
        final paths = inv.positionalArguments.first as List<String>;
        return paths.first.startsWith('Device.Hosts.')
            ? hosts
            : {_modePath: 'Disabled', _listPath: ''};
      });
    }

    test('offers online wireless clients only, never wired ones', () async {
      stubHosts({
        ...host(1, 'ee:52:09:f8:2e:95',
            layer1: 'Device.WiFi.Radio.2', type: 'Wi-Fi'),
        ...host(2, 'aa:bb:cc:00:00:02',
            layer1: 'Device.Ethernet.Interface.1', type: 'Ethernet'),
        // No InterfaceType at all: Layer1Interface alone decides.
        ...host(3, 'aa:bb:cc:00:00:03', layer1: 'Device.Ethernet.Interface.1'),
        ...host(4, 'aa:bb:cc:00:00:04', layer1: 'Device.WiFi.Radio.1'),
      });

      final result = await service.fetchAll();

      expect(result.connectedDevices.map((d) => d.mac),
          ['EE:52:09:F8:2E:95', 'AA:BB:CC:00:00:04']);
    });

    test('an offline Wi-Fi client is not offered', () async {
      stubHosts({
        ...host(1, 'ce:dc:79:1d:0c:ab', layer1: '', type: 'Wi-Fi', active: '0'),
      });

      final result = await service.fetchAll();

      expect(result.connectedDevices, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // setMacFilter — write side (validate, JSON-encode, operate)
  // ---------------------------------------------------------------------------

  group('setMacFilter', () {
    test('sends Mode and a JSON-array MACAddressList (not comma)', () async {
      stubOperateOk();

      await service.setMacFilter(
          MacFilterMode.deny, ['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']);

      final captured =
          verify(() => usp.operate(_cmdPath, args: captureAny(named: 'args')))
              .captured
              .single as Map;
      expect(captured['Mode'], 'Deny');
      expect(captured['MACAddressList'],
          jsonEncode(['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']));
    });

    test('normalizes and de-duplicates before sending', () async {
      stubOperateOk();

      await service.setMacFilter(MacFilterMode.deny,
          ['aa-bb-cc-dd-ee-01', 'AA:BB:CC:DD:EE:01', 'aa:bb:cc:dd:ee:02']);

      final captured =
          verify(() => usp.operate(_cmdPath, args: captureAny(named: 'args')))
              .captured
              .single as Map;
      expect(captured['MACAddressList'],
          jsonEncode(['AA:BB:CC:DD:EE:01', 'AA:BB:CC:DD:EE:02']));
    });

    test('Disabled omits the list entirely', () async {
      stubOperateOk();

      await service.setMacFilter(MacFilterMode.disabled, []);

      final captured =
          verify(() => usp.operate(_cmdPath, args: captureAny(named: 'args')))
              .captured
              .single as Map;
      expect(captured['Mode'], 'Disabled');
      expect(captured.containsKey('MACAddressList'), isFalse);
    });

    test('rejects a list over the 64 limit before sending', () async {
      stubOperateOk();
      final tooMany = List.generate(
          65,
          (i) =>
              '02:00:00:00:${(i ~/ 256).toRadixString(16).padLeft(2, '0')}:${(i % 256).toRadixString(16).padLeft(2, '0')}');

      expect(
        () => service.setMacFilter(MacFilterMode.deny, tooMany),
        throwsA(isA<InvalidInputError>()),
      );
      verifyNever(() => usp.operate(any(), args: any(named: 'args')));
    });

    test('exactly 64 is allowed', () async {
      stubOperateOk();
      final max = List.generate(
          64,
          (i) =>
              '02:00:00:00:${(i ~/ 256).toRadixString(16).padLeft(2, '0')}:${(i % 256).toRadixString(16).padLeft(2, '0')}');

      await service.setMacFilter(MacFilterMode.deny, max);

      verify(() => usp.operate(any(), args: any(named: 'args'))).called(1);
    });

    test('rejects a malformed MAC before sending', () async {
      stubOperateOk();

      expect(
        () => service.setMacFilter(MacFilterMode.deny, ['zz:zz:zz:zz:zz:zz']),
        throwsA(isA<InvalidInputError>()),
      );
      verifyNever(() => usp.operate(any(), args: any(named: 'args')));
    });

    test('Allow with an empty list is rejected before sending', () async {
      stubOperateOk();

      expect(
        () => service.setMacFilter(MacFilterMode.allow, []),
        throwsA(isA<InvalidInputError>()),
      );
      verifyNever(() => usp.operate(any(), args: any(named: 'args')));
    });

    test('de-dup counts toward the limit AFTER dedupe (65 dups of 1 → ok)',
        () async {
      stubOperateOk();

      await service.setMacFilter(
          MacFilterMode.deny, List.filled(65, 'AA:BB:CC:DD:EE:01'));

      final captured =
          verify(() => usp.operate(_cmdPath, args: captureAny(named: 'args')))
              .captured
              .single as Map;
      expect(captured['MACAddressList'], jsonEncode(['AA:BB:CC:DD:EE:01']));
    });

    test('maps a thrown operate error to ServiceError', () async {
      when(() => usp.operate(any(), args: any(named: 'args')))
          .thenThrow(const ConnectivityError(detail: 'down'));

      expect(
        () => service.setMacFilter(MacFilterMode.deny, ['AA:BB:CC:DD:EE:01']),
        throwsA(isA<ConnectivityError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // #1636: Instant Privacy used to write `Device.WiFi.AccessPoint.*
  // .MACAddressControlEnabled` / `AllowedMACAddress`, which FLWRT 2.0 refuses on
  // an EasyMesh node. It now writes through this service, so the claim "it no
  // longer writes the AccessPoint path" is a claim about every call this service
  // makes to the client — asserted over a whole read-then-save round trip in the
  // mode Instant Privacy uses.
  // ---------------------------------------------------------------------------

  group('the AccessPoint write path is gone', () {
    test('an Allow round trip reads DataElements and writes only SetMACFilter',
        () async {
      final paths = <String>[];
      when(() => usp.get(any())).thenAnswer((inv) async {
        paths.addAll(inv.positionalArguments.first as List<String>);
        return {_modePath: 'Disabled', _listPath: ''};
      });
      stubOperateOk();

      await service.fetch();
      await service.setMacFilter(MacFilterMode.allow, ['AA:BB:CC:DD:EE:01']);

      expect(paths, isNot(contains(contains('AccessPoint'))));
      verify(() => usp.operate(_cmdPath, args: any(named: 'args'))).called(1);
      verifyNever(() => usp.set(any(),
          singleValue: any(named: 'singleValue'),
          allowPartial: any(named: 'allowPartial')));
      verifyNever(() =>
          usp.setOrdered(any(), allowPartial: any(named: 'allowPartial')));
    });
  });
}
