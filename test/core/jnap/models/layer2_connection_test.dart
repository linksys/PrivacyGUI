import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/layer2_connection.dart';

/// Two entries of `GetNetworkConnections2` output, as JSON text: a guest
/// phone on 5 GHz and a wired desktop. From test/test_data/core_transaction.dart.
const _phoneText = '''
{
  "macAddress": "D2:60:CB:A0:3D:17",
  "negotiatedMbps": 780,
  "wireless": {
    "bssid": "36:23:03:2E:AF:F0",
    "isGuest": true,
    "radioID": "RADIO_5GHz",
    "band": "5GHz",
    "signalDecibels": -47
  }
}
''';
const _desktopText =
    '{"macAddress": "80:1F:02:73:C5:D4", "negotiatedMbps": 100}';

/// An entry of `GetNodesWirelessNetworkConnections` output: the same kind of
/// link, stamped with when the node saw it.
const _nodeLinkText = '''
{
  "macAddress": "4A:2D:59:25:67:D7",
  "negotiatedMbps": 6,
  "timestamp": "2023-09-04T02:34:37Z",
  "wireless": {
    "bssid": "30:23:03:35:E0:09",
    "isGuest": false,
    "radioID": "RADIO_5GHz",
    "band": "5GHz",
    "signalDecibels": -84
  }
}
''';

void main() {
  group('Layer2Connection', () {
    test('reads a wireless client and a wired one', () {
      final phone = Layer2Connection.fromJson(_phoneText);
      final desktop = Layer2Connection.fromJson(_desktopText);

      expect(phone.macAddress, 'D2:60:CB:A0:3D:17');
      expect(phone.negotiatedMbps, 780);
      expect(phone.wireless?.isGuest, isTrue);
      expect(phone.wireless?.signalDecibels, -47);
      expect(desktop.negotiatedMbps, 100);
      expect(desktop.wireless, isNull);
    });

    test('writes back what it read, with no wireless part for a cable', () {
      expect(Layer2Connection.fromJson(_desktopText).toMap(),
          {'macAddress': '80:1F:02:73:C5:D4', 'negotiatedMbps': 100});
      expect(Layer2Connection.fromJson(_phoneText).toMap()['wireless'], {
        'bssid': '36:23:03:2E:AF:F0',
        'isGuest': true,
        'radioID': 'RADIO_5GHz',
        'band': '5GHz',
        'signalDecibels': -47,
      });
    });

    test('survives a trip through JSON text', () {
      final phone = Layer2Connection.fromJson(_phoneText);

      expect(Layer2Connection.fromJson(phone.toJson()), phone);
      expect(phone, isNot(Layer2Connection.fromJson(_desktopText)));
    });

    test('copyWith changes only what it names', () {
      final phone = Layer2Connection.fromJson(_phoneText);

      final slower = phone.copyWith(negotiatedMbps: 390);

      expect(slower.negotiatedMbps, 390);
      expect(slower.wireless, phone.wireless);
      expect(slower.copyWith(negotiatedMbps: 780), phone);
    });
  });

  group('NodeWirelessLayer2Connections', () {
    test('reads the link and when the node saw it', () {
      final link = NodeWirelessLayer2Connections.fromJson(_nodeLinkText);

      expect(link.timestamp, '2023-09-04T02:34:37Z');
      expect(link.wireless?.signalDecibels, -84);
      expect(link.toMap()['timestamp'], '2023-09-04T02:34:37Z');
      expect(link.toMap()['negotiatedMbps'], 6);
    });

    test('survives a trip through JSON text', () {
      final link = NodeWirelessLayer2Connections.fromJson(_nodeLinkText);

      expect(NodeWirelessLayer2Connections.fromJson(link.toJson()), link);
    });

    test('copyWith changes only what it names', () {
      final link = NodeWirelessLayer2Connections.fromJson(_nodeLinkText);

      final later = link.copyWith(timestamp: '2023-09-04T02:40:00Z');

      expect(later.timestamp, '2023-09-04T02:40:00Z');
      expect(later.macAddress, link.macAddress);
      expect(later, isNot(link));
    });
  });
}
