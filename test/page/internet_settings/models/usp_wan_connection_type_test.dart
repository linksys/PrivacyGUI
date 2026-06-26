import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

void main() {
  group('UspWanConnectionType', () {
    group('fromRawFields', () {
      test('returns dhcp for addressingType DHCP', () {
        expect(
          UspWanConnectionType.fromRawFields(addressingType: 'DHCP'),
          UspWanConnectionType.dhcp,
        );
      });

      test('returns staticIp for addressingType Static', () {
        expect(
          UspWanConnectionType.fromRawFields(addressingType: 'Static'),
          UspWanConnectionType.staticIp,
        );
      });

      test('returns pppoe for addressingType IPCP', () {
        expect(
          UspWanConnectionType.fromRawFields(addressingType: 'IPCP'),
          UspWanConnectionType.pppoe,
        );
      });

      test('returns bridge for empty addressingType', () {
        expect(
          UspWanConnectionType.fromRawFields(addressingType: ''),
          UspWanConnectionType.bridge,
        );
      });

      test('returns bridge for unknown addressingType', () {
        expect(
          UspWanConnectionType.fromRawFields(addressingType: 'Something'),
          UspWanConnectionType.bridge,
        );
      });
    });

    group('label', () {
      test('dhcp label', () {
        expect(
            UspWanConnectionType.dhcp.label, 'Automatic Configuration - DHCP');
      });

      test('staticIp label', () {
        expect(UspWanConnectionType.staticIp.label, 'Static IP');
      });

      test('pppoe label', () {
        expect(UspWanConnectionType.pppoe.label, 'PPPoE');
      });

      test('bridge label', () {
        expect(UspWanConnectionType.bridge.label, 'Bridge Mode');
      });
    });

    group('addressingTypeValue', () {
      test('dhcp returns DHCP', () {
        expect(UspWanConnectionType.dhcp.addressingTypeValue, 'DHCP');
      });

      test('staticIp returns Static', () {
        expect(UspWanConnectionType.staticIp.addressingTypeValue, 'Static');
      });

      test('pppoe returns IPCP', () {
        expect(UspWanConnectionType.pppoe.addressingTypeValue, 'IPCP');
      });

      test('bridge returns empty string', () {
        expect(UspWanConnectionType.bridge.addressingTypeValue, '');
      });
    });
  });
}
