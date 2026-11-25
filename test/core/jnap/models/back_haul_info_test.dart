import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';

/// A satellite's entry in `GetBackhaulInfo2` output, as JSON text: over the
/// air, from test/test_data/core_transaction.dart.
const _wirelessText = '''
{
  "deviceUUID": "2fce469a-2d48-6cf2-8b86-3023032ea4ea",
  "ipAddress": "192.168.1.194",
  "parentIPAddress": "192.168.1.1",
  "connectionType": "Wireless",
  "wirelessConnectionInfo": {
    "radioID": "5GL",
    "channel": 44,
    "apRSSI": -23,
    "stationRSSI": -14,
    "apBSSID": "30:23:03:2E:AF:F0",
    "stationBSSID": "3A:23:03:2E:A4:EC",
    "txRate": 866,
    "rxRate": 780,
    "isMultiLinkOperation": false
  },
  "speedMbps": "143.553",
  "timestamp": "2023-09-23T05:13:09Z"
}
''';

/// The same, for a satellite on a cable.
const _wiredText = '''
{
  "deviceUUID": "5391a1d4-12fa-95c6-0b68-30230335e007",
  "ipAddress": "192.168.1.195",
  "parentIPAddress": "192.168.1.1",
  "connectionType": "Wired",
  "speedMbps": "940.112",
  "timestamp": "2023-09-23T05:13:09Z"
}
''';

void main() {
  group('BackHaulInfoData', () {
    test('reads a satellite on a wireless backhaul', () {
      final backhaul = BackHaulInfoData.fromJson(_wirelessText);

      expect(backhaul.deviceUUID, '2fce469a-2d48-6cf2-8b86-3023032ea4ea');
      expect(backhaul.ipAddress, '192.168.1.194');
      expect(backhaul.parentIPAddress, '192.168.1.1');
      expect(backhaul.connectionType, 'Wireless');
      expect(backhaul.speedMbps, '143.553');
      final link = backhaul.wirelessConnectionInfo!;
      expect((link.radioID, link.channel), ('5GL', 44));
      expect((link.apRSSI, link.stationRSSI), (-23, -14));
      expect(link.stationBSSID, '3A:23:03:2E:A4:EC');
      expect((link.txRate, link.rxRate, link.isMultiLinkOperation),
          (866, 780, false));
    });

    test('writes back a wired satellite as it read it', () {
      final backhaul = BackHaulInfoData.fromJson(_wiredText);

      expect(backhaul.wirelessConnectionInfo, isNull);
      expect(backhaul.toMap(), {
        'deviceUUID': '5391a1d4-12fa-95c6-0b68-30230335e007',
        'ipAddress': '192.168.1.195',
        'parentIPAddress': '192.168.1.1',
        'connectionType': 'Wired',
        'wirelessConnectionInfo': null,
        'speedMbps': '940.112',
        'timestamp': '2023-09-23T05:13:09Z',
      });
    });

    test('survives a trip through JSON text', () {
      final wireless = BackHaulInfoData.fromJson(_wirelessText);
      final wired = BackHaulInfoData.fromJson(_wiredText);

      expect(BackHaulInfoData.fromJson(wireless.toJson()), wireless);
      expect(BackHaulInfoData.fromJson(wired.toJson()), wired);
      expect(wired, isNot(wireless));
    });

    test('copyWith changes only what it names', () {
      final backhaul = BackHaulInfoData.fromJson(_wirelessText);

      final faster = backhaul.copyWith(speedMbps: '480.000');

      expect(faster.speedMbps, '480.000');
      expect(faster.wirelessConnectionInfo, backhaul.wirelessConnectionInfo);
      expect(faster.copyWith(speedMbps: '143.553'), backhaul);
    });
  });

  group('WirelessConnectionInfo', () {
    test('reads a link the router reports only in part', () {
      final link = WirelessConnectionInfo.fromMap(const {
        'radioID': '5GH',
        'stationRSSI': -61,
      });

      expect(link.radioID, '5GH');
      expect(link.stationRSSI, -61);
      expect((link.channel, link.apRSSI), (0, 0));
      expect((link.apBSSID, link.stationBSSID), ('', ''));
      expect((link.txRate, link.rxRate, link.isMultiLinkOperation),
          (null, null, null));
    });

    test('survives a trip through JSON text', () {
      final link =
          BackHaulInfoData.fromJson(_wirelessText).wirelessConnectionInfo!;

      expect(WirelessConnectionInfo.fromJson(link.toJson()), link);
      expect(link.toString(), contains('stationRSSI: -14'));
    });

    test('copyWith can clear the optional rates', () {
      final link =
          BackHaulInfoData.fromJson(_wirelessText).wirelessConnectionInfo!;

      final moved = link.copyWith(channel: 149, txRate: () => null);

      expect(moved.channel, 149);
      expect(moved.txRate, isNull);
      expect(moved.rxRate, 780);
      expect(
          link.copyWith(isMultiLinkOperation: () => true).isMultiLinkOperation,
          isTrue);
      expect(link.copyWith(rxRate: () => 1201).rxRate, 1201);
    });
  });
}
