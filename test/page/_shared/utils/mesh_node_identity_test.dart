import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/utils/mesh_node_identity.dart';

void main() {
  // ---------------------------------------------------------------------------
  // meshNodeMacSet — the node IDs DataElements reports, normalized (#1688)
  // ---------------------------------------------------------------------------

  group('meshNodeMacSet', () {
    test('normalizes each ID to upper-case hex with no separators', () {
      expect(
        meshNodeMacSet(['74:12:13:21:56:3a', 'aa-bb-cc-dd-ee-02']),
        {'74121321563A', 'AABBCCDDEE02'},
      );
    });

    test('drops a blank ID', () {
      expect(meshNodeMacSet(['', '   ']), isEmpty);
    });

    // MeshTopologyBuilder uses the instance path as the device ID of a node
    // whose `ID` is empty. Normalized, that path keeps a few hex letters (the
    // "DE" of DataElements and so on), and it must not become a set member that
    // a Hosts MAC could ever match.
    test('drops the instance-path fallback for a node with no ID', () {
      expect(
        meshNodeMacSet(['Device.WiFi.DataElements.Network.Device.1.']),
        isEmpty,
      );
    });

    test('drops a value that is not a full 48-bit MAC', () {
      expect(
          meshNodeMacSet(['74:12:13:21:56', '74:12:13:21:56:3a:00']), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // isMeshNodeHost — FWDEV#208's rule: PhysAddress == a node's Device.{i}.ID
  // ---------------------------------------------------------------------------

  group('isMeshNodeHost', () {
    final nodes = meshNodeMacSet(['74:12:13:21:56:3a', 'AA:BB:CC:DD:EE:02']);

    test('a Hosts row whose PhysAddress is a node ID is that node', () {
      expect(isMeshNodeHost('AA:BB:CC:DD:EE:02', nodes), isTrue);
    });

    // Hosts and DataElements both write lower-case colon form on
    // 2.0.3.26101482, but the two are separate producers. A spelling drift on
    // either side must not turn every node back into a client.
    test('case and separators do not change the answer', () {
      for (final spelling in [
        '74:12:13:21:56:3a',
        '74:12:13:21:56:3A',
        '74-12-13-21-56-3A',
        '74121321563a',
        ' 74:12:13:21:56:3a ',
      ]) {
        expect(isMeshNodeHost(spelling, nodes), isTrue,
            reason: '"$spelling" must match the node');
      }
    });

    test('a client MAC is not a node', () {
      expect(isMeshNodeHost('dc:52:85:5d:d0:7c', nodes), isFalse);
    });

    test('an empty PhysAddress is never a node', () {
      expect(isMeshNodeHost('', nodes), isFalse);
      expect(isMeshNodeHost('', {''}), isFalse);
    });

    test('nothing is a node when DataElements reported no node', () {
      expect(isMeshNodeHost('AA:BB:CC:DD:EE:02', meshNodeMacSet([])), isFalse);
    });
  });
}
