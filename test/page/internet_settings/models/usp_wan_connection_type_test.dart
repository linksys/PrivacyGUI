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

      test('returns pppoe for addressingType IPCP with no lowerLayers', () {
        expect(
          UspWanConnectionType.fromRawFields(addressingType: 'IPCP'),
          UspWanConnectionType.pppoe,
        );
      });

      test('returns pppoe for IPCP with Ethernet lowerLayers', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'IPCP',
            lowerLayers: 'Device.Ethernet.Link.2',
          ),
          UspWanConnectionType.pppoe,
        );
      });

      test('returns pptp for IPCP with GRE.Tunnel lowerLayers', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'IPCP',
            lowerLayers: 'Device.GRE.Tunnel.1.Interface.1',
          ),
          UspWanConnectionType.pptp,
        );
      });

      test('returns l2tp for IPCP with L2TPv2.Tunnel lowerLayers', () {
        expect(
          UspWanConnectionType.fromRawFields(
            addressingType: 'IPCP',
            lowerLayers: 'Device.L2TPv2.Tunnel.1.Interface.1',
          ),
          UspWanConnectionType.l2tp,
        );
      });

      test('returns bridge for empty addressingType', () {
        expect(
          UspWanConnectionType.fromRawFields(addressingType: ''),
          UspWanConnectionType.bridge,
        );
      });

      test('returns dhcp for unknown non-empty addressingType', () {
        // Only an explicitly empty AddressingType signals bridge; any other
        // unrecognised value (future firmware, transient) falls back to DHCP
        // rather than being misclassified as bridge.
        expect(
          UspWanConnectionType.fromRawFields(addressingType: 'Something'),
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

      test('pptp label', () {
        expect(UspWanConnectionType.pptp.label, 'PPTP');
      });

      test('l2tp label', () {
        expect(UspWanConnectionType.l2tp.label, 'L2TP');
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

      test('pptp returns IPCP', () {
        expect(UspWanConnectionType.pptp.addressingTypeValue, 'IPCP');
      });

      test('l2tp returns IPCP', () {
        expect(UspWanConnectionType.l2tp.addressingTypeValue, 'IPCP');
      });

      test('bridge returns empty string', () {
        expect(UspWanConnectionType.bridge.addressingTypeValue, '');
      });
    });

    group('isPppBased', () {
      test('pppoe is PPP-based', () {
        expect(UspWanConnectionType.pppoe.isPppBased, isTrue);
      });

      test('pptp is PPP-based', () {
        expect(UspWanConnectionType.pptp.isPppBased, isTrue);
      });

      test('l2tp is PPP-based', () {
        expect(UspWanConnectionType.l2tp.isPppBased, isTrue);
      });

      test('dhcp is not PPP-based', () {
        expect(UspWanConnectionType.dhcp.isPppBased, isFalse);
      });

      test('staticIp is not PPP-based', () {
        expect(UspWanConnectionType.staticIp.isPppBased, isFalse);
      });

      test('bridge is not PPP-based', () {
        expect(UspWanConnectionType.bridge.isPppBased, isFalse);
      });
    });

    group('pppLowerLayers', () {
      test('pppoe returns Ethernet.Link.2', () {
        expect(UspWanConnectionType.pppoe.pppLowerLayers,
            'Device.Ethernet.Link.2');
      });

      test('pptp returns GRE.Tunnel.1.Interface.1', () {
        expect(UspWanConnectionType.pptp.pppLowerLayers,
            'Device.GRE.Tunnel.1.Interface.1');
      });

      test('l2tp returns L2TPv2.Tunnel.1.Interface.1', () {
        expect(UspWanConnectionType.l2tp.pppLowerLayers,
            'Device.L2TPv2.Tunnel.1.Interface.1');
      });

      test('dhcp returns null', () {
        expect(UspWanConnectionType.dhcp.pppLowerLayers, isNull);
      });
    });

    group('mtuMax', () {
      test('pppoe reserves 8 bytes (1492)', () {
        expect(UspWanConnectionType.pppoe.mtuMax, 1492);
      });

      test('pptp reserves tunnel overhead (1460)', () {
        expect(UspWanConnectionType.pptp.mtuMax, 1460);
      });

      test('l2tp reserves tunnel overhead (1460)', () {
        expect(UspWanConnectionType.l2tp.mtuMax, 1460);
      });

      test('dhcp uses Ethernet standard (1500)', () {
        expect(UspWanConnectionType.dhcp.mtuMax, 1500);
      });

      test('staticIp uses Ethernet standard (1500)', () {
        expect(UspWanConnectionType.staticIp.mtuMax, 1500);
      });

      test('bridge uses Ethernet standard (1500)', () {
        expect(UspWanConnectionType.bridge.mtuMax, 1500);
      });
    });

    group('mtuMin', () {
      test('is 576 for every type', () {
        for (final type in UspWanConnectionType.values) {
          expect(type.mtuMin, 576, reason: '${type.name} mtuMin');
        }
      });
    });

    group('clampMtu', () {
      test('keeps an in-range value unchanged', () {
        expect(UspWanConnectionType.pppoe.clampMtu(789), 789);
        expect(UspWanConnectionType.dhcp.clampMtu(1500), 1500);
        expect(UspWanConnectionType.pptp.clampMtu(1460), 1460);
      });

      test('resets an over-max value to the type max', () {
        expect(UspWanConnectionType.pppoe.clampMtu(1500), 1492);
        expect(UspWanConnectionType.pptp.clampMtu(1500), 1460);
      });

      test('resets a below-min value to the type max', () {
        // 0 (auto, e.g. after leaving bridge) and any sub-576 value fall back
        // to the max rather than an invalid low value.
        expect(UspWanConnectionType.dhcp.clampMtu(0), 1500);
        expect(UspWanConnectionType.pppoe.clampMtu(100), 1492);
      });

      test('keeps the min boundary value', () {
        expect(UspWanConnectionType.dhcp.clampMtu(576), 576);
      });
    });
  });
}
