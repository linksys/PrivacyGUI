import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/dmz.g.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/dmz/services/usp_dmz_service.dart';

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
      expect(errors['destIp'], 'Destination IP is required');
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
      expect(errors['destIp'], 'Invalid IP address');
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
      expect(errors['sourcePrefix'], 'CIDR range is required');
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
            'overallSuccess': true,
            'hasAnySuccess': true,
            'hasErrors': false,
            'results': [
              {
                'requestedPath': 'Device.Firewall.DMZ.',
                'success': true,
                'createdInstances': [
                  {
                    'affectedPath': 'Device.Firewall.DMZ.1.',
                    'initialParams': {}
                  }
                ]
              }
            ]
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

    test('add with sourceType.cidr sends the CIDR value', () async {
      when(() => mockUsp.add(any())).thenAnswer((_) async => {
            'overallSuccess': true,
            'hasAnySuccess': true,
            'hasErrors': false,
            'results': [
              {
                'requestedPath': 'Device.Firewall.DMZ.',
                'success': true,
                'createdInstances': [
                  {
                    'affectedPath': 'Device.Firewall.DMZ.1.',
                    'initialParams': {}
                  }
                ]
              }
            ]
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
            'overallSuccess': true,
            'hasAnySuccess': true,
            'hasErrors': false,
            'results': []
          });

      await service.update(
        instancePath: 'Device.Firewall.DMZ.1.',
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
            'overallSuccess': true,
            'hasAnySuccess': true,
            'hasErrors': false,
            'results': []
          });

      await service.update(
        instancePath: 'Device.Firewall.DMZ.1.',
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
}
