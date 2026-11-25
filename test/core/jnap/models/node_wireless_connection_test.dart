import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/node_wireless_connection.dart';

/// A node's entry in `GetNodesWirelessNetworkConnections` output, as JSON
/// text, from test/test_data/core_transaction.dart.
const _masterText = '''
{
  "deviceID": "0b447477-5693-2b7e-8bbd-3023032eafee",
  "connections": [
    {
      "macAddress": "12:7D:2A:77:4A:0D",
      "negotiatedMbps": 6,
      "timestamp": "2023-09-22T03:19:56Z",
      "wireless": {"bssid": "36:23:03:2E:AF:F0", "isGuest": true, "radioID": "RADIO_5GHz", "band": "5GHz", "signalDecibels": -50}
    },
    {
      "macAddress": "D2:60:CB:A0:3D:17",
      "negotiatedMbps": 780,
      "timestamp": "2023-09-23T03:21:47Z",
      "wireless": {"bssid": "36:23:03:2E:AF:F0", "isGuest": true, "radioID": "RADIO_5GHz", "band": "5GHz", "signalDecibels": -45}
    }
  ]
}
''';

void main() {
  test('reads the clients a node holds, each with its link', () {
    final node = NodeWirelessConnections.fromJson(_masterText);

    expect(node.deviceID, '0b447477-5693-2b7e-8bbd-3023032eafee');
    expect(node.connections.map((link) => link.macAddress),
        ['12:7D:2A:77:4A:0D', 'D2:60:CB:A0:3D:17']);
    expect(node.connections.last.wireless?.signalDecibels, -45);
  });

  test('writes back the node and each of its links', () {
    final map = NodeWirelessConnections.fromJson(_masterText).toMap();

    expect(map['deviceID'], '0b447477-5693-2b7e-8bbd-3023032eafee');
    expect((map['connections'] as List).first, {
      'macAddress': '12:7D:2A:77:4A:0D',
      'negotiatedMbps': 6,
      'timestamp': '2023-09-22T03:19:56Z',
      'wireless': {
        'bssid': '36:23:03:2E:AF:F0',
        'isGuest': true,
        'radioID': 'RADIO_5GHz',
        'band': '5GHz',
        'signalDecibels': -50,
      },
    });
  });

  test('survives a trip through JSON text', () {
    final node = NodeWirelessConnections.fromJson(_masterText);

    expect(NodeWirelessConnections.fromJson(node.toJson()), node);
  });

  test('copyWith changes only what it names', () {
    final node = NodeWirelessConnections.fromJson(_masterText);

    final emptied = node.copyWith(connections: []);

    expect(emptied.connections, isEmpty);
    expect(emptied.deviceID, node.deviceID);
    expect(emptied.copyWith(connections: node.connections), node);
  });
}
