import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/topology/helpers/node_identifier.dart';

void main() {
  group('normalizeMac', () {
    test('strips colons and uppercases', () {
      expect(normalizeMac('aa:bb:cc:dd:ee:ff'), 'AABBCCDDEEFF');
    });

    test('strips dashes, dots and whitespace', () {
      expect(normalizeMac('aa-bb-cc-dd-ee-ff'), 'AABBCCDDEEFF');
      expect(normalizeMac('aabb.ccdd.eeff'), 'AABBCCDDEEFF');
      expect(normalizeMac(' AA BB CC DD EE FF '), 'AABBCCDDEEFF');
    });

    test('drops any non-hex character', () {
      expect(normalizeMac('AA:BB:CC:DD:EE:ZZ'), 'AABBCCDDEE');
    });

    test('empty input yields empty', () {
      expect(normalizeMac(''), '');
    });
  });

  group('identifier composers', () {
    test('master identifier is a fixed, key-less string', () {
      expect(kTopologyMasterIdentifier, 'topology-node-master');
    });

    test('slave / client composers prepend the correct prefix', () {
      expect(topologySlaveIdentifier('EEFF'), 'topology-node-slave-EEFF');
      expect(topologyClientIdentifier('9C1D'), 'topology-node-client-9C1D');
    });
  });

  group('shortestUniqueMacSuffixes', () {
    test('empty input yields empty map', () {
      expect(shortestUniqueMacSuffixes(const []), isEmpty);
    });

    test('uses the last 4 hex chars when that is already unique', () {
      final result = shortestUniqueMacSuffixes([
        'AA:BB:CC:DD:E1:11',
        'AA:BB:CC:DD:E2:22',
      ]);
      expect(result['AA:BB:CC:DD:E1:11'], 'E111');
      expect(result['AA:BB:CC:DD:E2:22'], 'E222');
    });

    test('map is keyed by the original (un-normalized) input', () {
      const input = 'aa:bb:cc:dd:ee:ff';
      final result = shortestUniqueMacSuffixes([input]);
      expect(result.containsKey(input), isTrue);
      expect(result[input], 'EEFF');
    });

    test('extends suffix length group-wide on last-4 collision', () {
      // Both share suffix "EEFF" at length 4 → must grow to length 6.
      final result = shortestUniqueMacSuffixes([
        'AA:BB:CC:11:EE:FF',
        'AA:BB:CC:22:EE:FF',
      ]);
      expect(result['AA:BB:CC:11:EE:FF'], '11EEFF');
      expect(result['AA:BB:CC:22:EE:FF'], '22EEFF');
      // Single shared length: every suffix has the same length.
      final lengths = result.values.map((s) => s.length).toSet();
      expect(lengths, {6});
    });

    test('all resulting suffixes are unique for distinct inputs', () {
      final macs = [
        'AA:BB:CC:DD:EE:01',
        'AA:BB:CC:DD:EE:02',
        'AA:BB:CC:DD:EE:03',
        '11:22:33:44:55:66',
      ];
      final result = shortestUniqueMacSuffixes(macs);
      expect(result.length, macs.length);
      expect(result.values.toSet().length, macs.length);
    });

    test('genuine duplicates collapse to the full normalized value', () {
      final result = shortestUniqueMacSuffixes([
        'AA:BB:CC:DD:EE:FF',
        'aa-bb-cc-dd-ee-ff', // same MAC, different formatting
      ]);
      // Cannot be disambiguated → both fall back to full normalized value.
      expect(result['AA:BB:CC:DD:EE:FF'], 'AABBCCDDEEFF');
      expect(result['aa-bb-cc-dd-ee-ff'], 'AABBCCDDEEFF');
    });

    test('result is independent of input order', () {
      final a = shortestUniqueMacSuffixes([
        'AA:BB:CC:11:EE:FF',
        'AA:BB:CC:22:EE:FF',
      ]);
      final b = shortestUniqueMacSuffixes([
        'AA:BB:CC:22:EE:FF',
        'AA:BB:CC:11:EE:FF',
      ]);
      expect(a['AA:BB:CC:11:EE:FF'], b['AA:BB:CC:11:EE:FF']);
      expect(a['AA:BB:CC:22:EE:FF'], b['AA:BB:CC:22:EE:FF']);
    });

    test('MAC shorter than min length is returned whole', () {
      final result = shortestUniqueMacSuffixes(['A:B']); // normalizes to "AB"
      expect(result['A:B'], 'AB');
    });
  });
}
