import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_refusal_reason.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/services/usp_dmz_service.dart';

import '../../../mocks/test_data/usp_refusal_test_data.dart';
import '../../../mocks/test_data/usp_add_refusal_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient mockUsp;
  late UspDmzService service;

  setUp(() {
    mockUsp = MockUspClient();
    service = UspDmzService(mockUsp);
  });

  // ---------------------------------------------------------------------------
  // buildUIModel — pure transform
  // ---------------------------------------------------------------------------

  group('UspDmzService — buildUIModel', () {
    DmzEntry entry({String destIp = '', String? destMacAddress}) => DmzEntry(
          instancePath: 'Device.Firewall.DMZ.1.',
          enable: true,
          destIp: destIp,
          destMacAddress: destMacAddress,
          sourcePrefix: '0.0.0.0/0',
          interface_: '',
          description: 'DMZ',
          status: 'Enabled',
        );

    // FWDEV#204: only one of DestIP and X_LINKSYS_DestMACAddress is set, and
    // the non-empty one is the host.
    test('a router that reports a MAC opens in MAC mode, showing that MAC', () {
      final model = service.buildUIModel(
          Dmz(items: [entry(destMacAddress: 'aa:bb:cc:dd:ee:ff')]));

      expect(model.destinationType, DmzDestinationType.mac);
      expect(model.destMac, 'aa:bb:cc:dd:ee:ff');
    });

    test('a router that reports an IP opens in IP mode', () {
      final model = service.buildUIModel(
          Dmz(items: [entry(destIp: '192.168.1.50', destMacAddress: '')]));

      expect(model.destinationType, DmzDestinationType.ip);
      expect(model.destIp, '192.168.1.50');
      expect(model.destMac, '');
    });

    test('returns disabled model when items list is empty', () {
      const data = Dmz(items: []);

      final model = service.buildUIModel(data);

      expect(model.isEnabled, isFalse);
      expect(model.destIp, '');
      expect(model.sourceType, DmzSourceType.any);
      expect(model.sourcePrefix, '');
    });

    test('maps single enabled entry correctly', () {
      final data = Dmz(items: [
        DmzEntry(
          instancePath: 'Device.Firewall.DMZ.1.',
          enable: true,
          destIp: '192.168.1.50',
          sourcePrefix: '0.0.0.0/0',
          interface_: '',
          description: 'DMZ',
          status: 'Enabled',
        ),
      ]);

      final model = service.buildUIModel(data);

      expect(model.isEnabled, isTrue);
      expect(model.destIp, '192.168.1.50');
      expect(model.sourceType, DmzSourceType.any);
      expect(model.sourcePrefix, '0.0.0.0/0');
    });

    test('detects CIDR source type for non-any prefix', () {
      final data = Dmz(items: [
        DmzEntry(
          instancePath: 'Device.Firewall.DMZ.1.',
          enable: true,
          destIp: '192.168.1.50',
          sourcePrefix: '10.0.0.0/8',
          interface_: '',
          description: 'DMZ',
          status: 'Enabled',
        ),
      ]);

      final model = service.buildUIModel(data);

      expect(model.sourceType, DmzSourceType.cidr);
      expect(model.sourcePrefix, '10.0.0.0/8');
    });

    test('detects any source type for empty prefix', () {
      final data = Dmz(items: [
        DmzEntry(
          instancePath: 'Device.Firewall.DMZ.1.',
          enable: false,
          destIp: '192.168.1.50',
          sourcePrefix: '',
          interface_: '',
          description: 'DMZ',
          status: 'Disabled',
        ),
      ]);

      final model = service.buildUIModel(data);

      expect(model.sourceType, DmzSourceType.any);
      expect(model.isEnabled, isFalse);
    });

    test('uses only the first entry when multiple exist', () {
      final data = Dmz(items: [
        DmzEntry(
          instancePath: 'Device.Firewall.DMZ.1.',
          enable: true,
          destIp: '192.168.1.10',
          sourcePrefix: '0.0.0.0/0',
          interface_: '',
          description: 'DMZ',
          status: 'Enabled',
        ),
        DmzEntry(
          instancePath: 'Device.Firewall.DMZ.2.',
          enable: true,
          destIp: '192.168.1.20',
          sourcePrefix: '0.0.0.0/0',
          interface_: '',
          description: 'DMZ2',
          status: 'Enabled',
        ),
      ]);

      final model = service.buildUIModel(data);

      expect(model.destIp, '192.168.1.10');
    });
  });

  // ---------------------------------------------------------------------------
  // validateForm — pure validation
  // ---------------------------------------------------------------------------

  group('UspDmzService — validateForm', () {
    test('returns no errors when disabled', () {
      const model = DmzUIModel(
        isEnabled: false,
        destIp: '',
        sourceType: DmzSourceType.any,
        sourcePrefix: '',
      );

      final errors = service.validateForm(model);

      expect(errors, isEmpty);
    });

    test('returns error when enabled with empty destIp', () {
      const model = DmzUIModel(
        isEnabled: true,
        destIp: '',
        sourceType: DmzSourceType.any,
        sourcePrefix: '',
      );

      final errors = service.validateForm(model);

      expect(errors, contains('destIp'));
      expect(errors['destIp'], DmzErrorKeys.destIpRequired);
    });

    test('returns error when destIp is invalid', () {
      const model = DmzUIModel(
        isEnabled: true,
        destIp: 'not-an-ip',
        sourceType: DmzSourceType.any,
        sourcePrefix: '',
      );

      final errors = service.validateForm(model);

      expect(errors, contains('destIp'));
      expect(errors['destIp'], DmzErrorKeys.invalidIpAddress);
    });

    test('returns no errors for valid enabled configuration', () {
      const model = DmzUIModel(
        isEnabled: true,
        destIp: '192.168.1.50',
        sourceType: DmzSourceType.any,
        sourcePrefix: '',
      );

      final errors = service.validateForm(model);

      expect(errors, isEmpty);
    });

    test('returns error when sourceType is cidr with empty prefix', () {
      const model = DmzUIModel(
        isEnabled: true,
        destIp: '192.168.1.50',
        sourceType: DmzSourceType.cidr,
        sourcePrefix: '',
      );

      final errors = service.validateForm(model);

      expect(errors, contains('sourcePrefix'));
      expect(errors['sourcePrefix'], DmzErrorKeys.cidrRequired);
    });

    test('returns no error when sourceType is cidr with valid prefix', () {
      const model = DmzUIModel(
        isEnabled: true,
        destIp: '192.168.1.50',
        sourceType: DmzSourceType.cidr,
        sourcePrefix: '10.0.0.0/8',
      );

      final errors = service.validateForm(model);

      expect(errors, isEmpty);
    });

    // #1775: the DMZ host by MAC.
    DmzUIModel form({
      DmzDestinationType type = DmzDestinationType.ip,
      String destIp = '',
      String destMac = '',
      bool isEnabled = true,
    }) =>
        DmzUIModel(
          isEnabled: isEnabled,
          destinationType: type,
          destIp: destIp,
          destMac: destMac,
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        );

    test('a malformed MAC is an error, by MACAddressRule', () {
      expect(
          service.validateForm(
              form(type: DmzDestinationType.mac, destMac: 'zz:zz:zz:zz:zz:zz')),
          {'destMac': DmzErrorKeys.invalidMacAddress});
      expect(
          service.validateForm(
              form(type: DmzDestinationType.mac, destMac: 'aa:bb:cc:dd:ee')),
          {'destMac': DmzErrorKeys.invalidMacAddress});
    });

    // Bench, 2.0.4.26103108 (2026-11-09): FW refuses both with
    // ErrorInvalidDestinationMACAddress on a Set; a refused Add answers
    // success with the host emptied (Status Error_Misconfigured), so on a
    // first save only this check stops it. A DMZ host is one device, never a
    // group: the multicast bit (the first octet's lowest) covers both.
    test('a broadcast or multicast MAC is invalid', () {
      for (final mac in [
        'ff:ff:ff:ff:ff:ff',
        '01:00:5e:00:00:01',
        '33-33-00-00-00-01'
      ]) {
        expect(
            service
                .validateForm(form(type: DmzDestinationType.mac, destMac: mac)),
            {'destMac': DmzErrorKeys.invalidMacAddress},
            reason: mac);
      }
      // A locally administered unicast MAC (a phone's private address) is a
      // host; the bench accepted this one.
      expect(
          service.validateForm(
              form(type: DmzDestinationType.mac, destMac: 'aa:c8:bf:74:39:f6')),
          isEmpty);
    });

    test('an empty MAC in MAC mode is required', () {
      expect(service.validateForm(form(type: DmzDestinationType.mac)),
          {'destMac': DmzErrorKeys.destMacRequired});
    });

    test('a well-formed MAC passes, with : or - separators', () {
      for (final mac in ['aa:bb:cc:dd:ee:ff', 'AA-BB-CC-DD-EE-FF']) {
        expect(
            service
                .validateForm(form(type: DmzDestinationType.mac, destMac: mac)),
            isEmpty,
            reason: mac);
      }
    });

    test('only the field the type names is checked', () {
      // An IP left over from IP mode is not saved, so it is not an error.
      expect(
          service.validateForm(form(
              type: DmzDestinationType.mac,
              destIp: 'not-an-ip',
              destMac: 'aa:bb:cc:dd:ee:ff')),
          isEmpty);
      expect(service.validateForm(form(destIp: '192.168.1.50', destMac: 'zz')),
          isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // fetch — async with mock
  // ---------------------------------------------------------------------------

  group('UspDmzService — fetch', () {
    test('returns settings with instancePath when entry exists', () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            'Device.Firewall.DMZ.1.Enable': true,
            'Device.Firewall.DMZ.1.DestIP': '192.168.1.50',
            'Device.Firewall.DMZ.1.SourcePrefix': '0.0.0.0/0',
            'Device.Firewall.DMZ.1.Interface': '',
            'Device.Firewall.DMZ.1.Description': 'DMZ',
            'Device.Firewall.DMZ.1.Status': 'Enabled',
          });

      final (settings, status) = await service.fetch();

      expect(settings.instancePath, 'Device.Firewall.DMZ.1.');
      expect(settings.model.isEnabled, isTrue);
      expect(settings.model.destIp, '192.168.1.50');
      expect(settings.isNewEntry, isFalse);
      expect(status.isLoading, isFalse);
    });

    test('a DMZ row with every value blank is no entry: a save adds', () async {
      // usp-codegen 0.18 returns such a row where 0.17 dropped it (#1654).
      // Taken as the entry, a save would update it instead of adding one.
      when(() => mockUsp.get(any())).thenAnswer((_) async => {
            for (final leaf in [
              'Enable',
              'DestIP',
              'SourcePrefix',
              'Interface',
              'Description',
              'Status',
            ])
              'Device.Firewall.DMZ.4.$leaf': '',
          });

      final (settings, _) = await service.fetch();

      expect(settings.instancePath, isNull);
      expect(settings.isNewEntry, isTrue);
      expect(settings.model.isEnabled, isFalse);
    });

    test('returns settings with null instancePath when empty', () async {
      when(() => mockUsp.get(any()))
          .thenAnswer((_) async => <String, dynamic>{});

      final (settings, status) = await service.fetch();

      expect(settings.instancePath, isNull);
      expect(settings.isNewEntry, isTrue);
      expect(settings.model.isEnabled, isFalse);
      expect(status.isLoading, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // add / update — async with mock
  // ---------------------------------------------------------------------------

  group('UspDmzService — add', () {
    test('add with sourceType.any sends 0.0.0.0/0', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'instances': ['Device.Firewall.DMZ.1.'],
              },
            },
          });

      await service.add(
        model: DmzUIModel(
          isEnabled: true,
          destIp: '192.168.1.50',
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        ),
      );

      final captured = verify(() => mockUsp.add(captureAny())).captured;
      final items = captured[0] as List;
      final firstItem = items.first as Map<String, dynamic>;
      final params = firstItem['params'] as Map<String, dynamic>;
      expect(params['SourcePrefix'], '0.0.0.0/0');
      expect(params['DestIP'], '192.168.1.50');
    });

    test('add by MAC sends the MAC and no DestIP', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'instances': ['Device.Firewall.DMZ.1.'],
              },
            },
          });

      await service.add(
        model: DmzUIModel(
          isEnabled: true,
          destinationType: DmzDestinationType.mac,
          // Left over from IP mode: not the host, so not written.
          destIp: '192.168.1.50',
          destMac: 'aa:bb:cc:dd:ee:ff',
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        ),
      );

      final items =
          verify(() => mockUsp.add(captureAny())).captured.single as List;
      final params = (items.single as Map<String, dynamic>)['params']
          as Map<String, dynamic>;
      expect(params['X_LINKSYS_DestMACAddress'], 'aa:bb:cc:dd:ee:ff');
      expect(params.containsKey('DestIP'), isFalse);
    });

    test('add by IP sends DestIP and no MAC', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'instances': ['Device.Firewall.DMZ.1.'],
              },
            },
          });

      await service.add(
        model: DmzUIModel(
          isEnabled: true,
          destIp: '192.168.1.50',
          destMac: 'aa:bb:cc:dd:ee:ff',
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        ),
      );

      final items =
          verify(() => mockUsp.add(captureAny())).captured.single as List;
      final params = (items.single as Map<String, dynamic>)['params']
          as Map<String, dynamic>;
      expect(params['DestIP'], '192.168.1.50');
      expect(params.containsKey('X_LINKSYS_DestMACAddress'), isFalse);
    });

    test('add with sourceType.cidr sends the CIDR value', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'success': true,
            'result': {
              'data': {
                'instances': ['Device.Firewall.DMZ.1.'],
              },
            },
          });

      await service.add(
        model: DmzUIModel(
          isEnabled: true,
          destIp: '192.168.1.50',
          sourceType: DmzSourceType.cidr,
          sourcePrefix: '10.0.0.0/8',
        ),
      );

      final captured = verify(() => mockUsp.add(captureAny())).captured;
      final items = captured[0] as List;
      final firstItem = items.first as Map<String, dynamic>;
      final params = firstItem['params'] as Map<String, dynamic>;
      expect(params['SourcePrefix'], '10.0.0.0/8');
    });
  });

  group('UspDmzService — update', () {
    test('update with sourceType.any sends 0.0.0.0/0', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.update(
        instancePath: 'Device.Firewall.DMZ.1.',
        savedType: DmzDestinationType.ip,
        model: DmzUIModel(
          isEnabled: false,
          destIp: '192.168.1.100',
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        ),
      );

      final captured = verify(() => mockUsp.set(captureAny())).captured;
      expect(captured, hasLength(1));
    });

    test('update with sourceType.cidr sends the CIDR value', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => {
            'success': true,
            'result': {'data': <String, dynamic>{}},
          });

      await service.update(
        instancePath: 'Device.Firewall.DMZ.1.',
        savedType: DmzDestinationType.ip,
        model: DmzUIModel(
          isEnabled: true,
          destIp: '192.168.1.100',
          sourceType: DmzSourceType.cidr,
          sourcePrefix: '10.0.0.0/8',
        ),
      );

      verify(() => mockUsp.set(captureAny())).called(1);
    });
  });

  // FWDEV#204: only one of DestIP and X_LINKSYS_DestMACAddress may be set,
  // so a switch sets the other one to "" first. Its checks run per field in
  // write order, so the clear goes in a Set of its own and nothing depends
  // on how the router orders the leaves of one Set.
  group('UspDmzService — update across host types', () {
    const p = 'Device.Firewall.DMZ.1.';
    const ok = {
      'success': true,
      'result': {'data': <String, dynamic>{}},
    };
    DmzUIModel model(DmzDestinationType type) => DmzUIModel(
          isEnabled: true,
          destinationType: type,
          destIp: '192.168.1.50',
          destMac: 'aa:bb:cc:dd:ee:ff',
          sourceType: DmzSourceType.any,
          sourcePrefix: '',
        );
    List<Map<String, dynamic>> sets() => verify(() => mockUsp.set(captureAny()))
        .captured
        .cast<Map<String, dynamic>>();

    test('unchanged: one Set, writing only the leaf that names the host',
        () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => ok);

      await service.update(
          instancePath: p,
          savedType: DmzDestinationType.mac,
          model: model(DmzDestinationType.mac));

      final writes = sets();
      expect(writes, hasLength(1));
      expect(
          writes.single['${p}X_LINKSYS_DestMACAddress'], 'aa:bb:cc:dd:ee:ff');
      expect(writes.single.containsKey('${p}DestIP'), isFalse);
    });

    test('IP to MAC: DestIP is cleared in its own Set, then the MAC is set',
        () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => ok);

      await service.update(
          instancePath: p,
          savedType: DmzDestinationType.ip,
          model: model(DmzDestinationType.mac));

      final writes = sets();
      expect(writes, hasLength(2));
      expect(writes.first, {'${p}DestIP': ''});
      expect(writes.last['${p}X_LINKSYS_DestMACAddress'], 'aa:bb:cc:dd:ee:ff');
      expect(writes.last.containsKey('${p}DestIP'), isFalse);
    });

    test('MAC to IP: the MAC is cleared in its own Set, then DestIP is set',
        () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => ok);

      await service.update(
          instancePath: p,
          savedType: DmzDestinationType.mac,
          model: model(DmzDestinationType.ip));

      final writes = sets();
      expect(writes, hasLength(2));
      expect(writes.first, {'${p}X_LINKSYS_DestMACAddress': ''});
      expect(writes.last['${p}DestIP'], '192.168.1.50');
      expect(writes.last.containsKey('${p}X_LINKSYS_DestMACAddress'), isFalse);
    });

    test(
        'a refused new host after an accepted clear is a partial failure: '
        'the router now holds neither', () async {
      var call = 0;
      when(() => mockUsp.set(any())).thenAnswer((_) async => call++ == 0
          ? ok
          : refusedSetEnvelope(
              instancePath: p,
              refusedLeaf: 'X_LINKSYS_DestMACAddress',
              message: 'ErrorInvalidDestinationMACAddress: x'));

      await expectLater(
        service.update(
            instancePath: p,
            savedType: DmzDestinationType.ip,
            model: model(DmzDestinationType.mac)),
        throwsA(isA<UspPartialFailureError>().having(
            (e) => e.failures.map((f) => f.refusalReason),
            'refusal reasons',
            contains(UspRefusalReason.invalidDestinationMacAddress))),
      );
      expect(sets(), hasLength(2));
    });

    test('a MAC typed with - separators is written with :', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => ok);

      await service.update(
          instancePath: p,
          savedType: DmzDestinationType.mac,
          model: model(DmzDestinationType.mac)
              .copyWith(destMac: ' aa-bb-cc-dd-ee-ff '));

      expect(
          sets().single['${p}X_LINKSYS_DestMACAddress'], 'aa:bb:cc:dd:ee:ff');
    });

    test('a refused clear stops the save before the new host is written',
        () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => refusedSetEnvelope(
          instancePath: p,
          refusedLeaf: 'DestIP',
          message: 'ErrorMultipleDestinations: x'));

      await expectLater(
        service.update(
            instancePath: p,
            savedType: DmzDestinationType.ip,
            model: model(DmzDestinationType.mac)),
        throwsA(carriesRefusalReason(UspRefusalReason.multipleDestinations)),
      );
      expect(sets(), hasLength(1));
    });
  });

  // FWDEV#204's DMZ errors (#1775). The message is the bench's (2.0.4.26103108,
  // 2026-11-09): a refused DMZ Set comes back per leaf under 7012, as on the
  // NAT tables. A refused Add's reason arrives since usp-client 0.14.0; that
  // case is in the group below, with the row it leaves.
  group('UspDmzService — a refused save keeps the router reason', () {
    const p = 'Device.Firewall.DMZ.1.';

    test('an update the router refuses names its reason', () async {
      when(() => mockUsp.set(any())).thenAnswer((_) async => refusedSetEnvelope(
            instancePath: p,
            refusedLeaf: 'DestIP',
            message: "ErrorInvalidDestinationIPAddress: '192.168.1.1' is not "
                'a LAN host address.',
            otherLeaves: ['Enable'],
          ));

      await expectLater(
        service.update(
          instancePath: p,
          savedType: DmzDestinationType.ip,
          model: DmzUIModel(
            isEnabled: true,
            destIp: '192.168.1.1',
            sourceType: DmzSourceType.any,
            sourcePrefix: '',
          ),
        ),
        throwsA(
            carriesRefusalReason(UspRefusalReason.invalidDestinationIpAddress)),
      );
    });
  });

  // usp-client 0.14.0 (linksys/usp_framework#114): a first save is an Add, and
  // a refused one creates the row with the host emptied (bench 2.0.4,
  // Error_Misconfigured). The row is deleted, so a retry adds one DMZ row.
  group('UspDmzService — a refused Add is undone', () {
    test(
        'the row is deleted, the save wrote nothing, and the reason reaches '
        'the page', () async {
      const row = 'Device.Firewall.DMZ.1.';
      when(() => mockUsp.add(any())).thenAnswer((_) async =>
          UspAddRefusalTestData.refusedAdd(
              instances: [row],
              refusedRow: row,
              refusedParam: 'DestIP',
              message:
                  "ErrorInvalidDestinationIPAddress: '192.168.1.1' is not a "
                  'LAN host address.'));
      when(() => mockUsp.delete(any()))
          .thenAnswer((_) async => UspAddRefusalTestData.accepted);

      await expectLater(
        service.add(
          model: DmzUIModel(
            isEnabled: true,
            destIp: '192.168.1.1',
            sourceType: DmzSourceType.any,
            sourcePrefix: '',
          ),
        ),
        throwsA(allOf(
          isA<UspCompleteFailureError>(),
          carriesRefusalReason(UspRefusalReason.invalidDestinationIpAddress),
        )),
      );
      verify(() => mockUsp.delete([row])).called(1);
    });
  });
}
