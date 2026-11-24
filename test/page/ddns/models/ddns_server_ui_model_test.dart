import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ddns/models/ddns_server_ui_model.dart';

void main() {
  group('DdnsServerUIModel - identifierKey', () {
    test('is a slug of the name', () {
      expect(
        const DdnsServerUIModel(
                path: 'Device.DynamicDNS.Server.2', name: 'No-IP')
            .identifierKey,
        'no-ip',
      );
      expect(
        const DdnsServerUIModel(
                path: 'Device.DynamicDNS.Server.1', name: 'DynDNS')
            .identifierKey,
        'dyndns',
      );
    });

    test('falls back to the instance number when the name has no slug', () {
      expect(
        const DdnsServerUIModel(path: 'Device.DynamicDNS.Server.3', name: '')
            .identifierKey,
        '3',
      );
    });
  });

  group('DdnsServerUIModel - equality', () {
    test('compares by path and name', () {
      expect(
        const DdnsServerUIModel(path: 'Device.DynamicDNS.Server.1', name: 'A'),
        const DdnsServerUIModel(path: 'Device.DynamicDNS.Server.1', name: 'A'),
      );
      expect(
        const DdnsServerUIModel(path: 'Device.DynamicDNS.Server.1', name: 'A'),
        isNot(const DdnsServerUIModel(
            path: 'Device.DynamicDNS.Server.2', name: 'A')),
      );
    });
  });
}
