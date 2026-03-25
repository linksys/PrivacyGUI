import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

void main() {
  group('UspWanConnectionType', () {
    group('fromRawFields', () {
      test('returns dhcp for addressingType DHCP', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'DHCP',
            bridgeEnabled: false,
          ),
          UspWanConnectionType.dhcp,
        );
      });

      test('returns dhcp for addressingType DHCP even when bridgeEnabled', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'DHCP',
            bridgeEnabled: true,
          ),
          UspWanConnectionType.dhcp,
        );
      });

      test('returns staticIp for addressingType Static', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'Static',
            bridgeEnabled: false,
          ),
          UspWanConnectionType.staticIp,
        );
      });

      test('returns pppoe for addressingType IPCP', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'IPCP',
            bridgeEnabled: false,
          ),
          UspWanConnectionType.pppoe,
        );
      });

      test('returns bridge when addressingType is empty and bridgeEnabled', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: '',
            bridgeEnabled: true,
          ),
          UspWanConnectionType.bridge,
        );
      });

      test('returns dhcp when addressingType is empty and bridgeEnabled false',
          () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: '',
            bridgeEnabled: false,
          ),
          UspWanConnectionType.dhcp,
        );
      });

      test('returns dhcp for unknown addressingType without bridgeEnabled', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'Unknown',
            bridgeEnabled: false,
          ),
          UspWanConnectionType.dhcp,
        );
      });

      test('returns dhcp for unknown addressingType even with bridgeEnabled',
          () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'Unknown',
            bridgeEnabled: true,
          ),
          UspWanConnectionType.dhcp,
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

      test('bridge returns DHCP', () {
        expect(UspWanConnectionType.bridge.addressingTypeValue, 'DHCP');
      });
    });
  });
}
