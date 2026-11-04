import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_mode.dart';
import 'package:privacy_gui/page/mac_filter/services/usp_mac_filter_data_service.dart';

const _modePath = 'Device.WiFi.DataElements.Network.X_LINKSYS_MACFilterMode';
const _listPath = 'Device.WiFi.DataElements.Network.X_LINKSYS_MACFilterList';

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockUspClient usp;
  late UspMacFilterDataService service;

  setUp(() {
    usp = MockUspClient();
    service = UspMacFilterDataService(usp);
  });

  void stubGet(String mode, String list) {
    when(() => usp.get(any())).thenAnswer((_) async => {
          _modePath: mode,
          _listPath: list,
        });
  }

  group('UspMacFilterDataService — fetch', () {
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
}
