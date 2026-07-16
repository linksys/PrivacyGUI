import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/wifi_channel.dart';

void main() {
  // ---------------------------------------------------------------------------
  // parsePossibleChannels — range notation, sentinels, malformed tokens
  // ---------------------------------------------------------------------------

  group('parsePossibleChannels', () {
    test('empty string returns empty list', () {
      expect(parsePossibleChannels(''), isEmpty);
    });

    test('parses comma-separated single values ("1,6,11")', () {
      expect(parsePossibleChannels('1,6,11'), [1, 6, 11]);
    });

    test('expands mixed range + single notation ("1-3,6")', () {
      expect(parsePossibleChannels('1-3,6'), [1, 2, 3, 6]);
    });

    test('expands full range notation ("1-13")', () {
      expect(
        parsePossibleChannels('1-13'),
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13],
      );
    });

    test('sorts unordered input', () {
      expect(parsePossibleChannels('11,1,6'), [1, 6, 11]);
    });

    test('inverted range ("11-1") degrades to empty without throwing', () {
      expect(parsePossibleChannels('11-1'), isEmpty);
    });

    test('filters out TR-181 "0" auto/any sentinel ("0,1,6,11")', () {
      expect(parsePossibleChannels('0,1,6,11'), [1, 6, 11]);
    });

    test('drops non-positive channels from a range ("0-2")', () {
      expect(parsePossibleChannels('0-2'), [1, 2]);
    });

    test('skips malformed range token ("1-2-3") without throwing', () {
      expect(parsePossibleChannels('1-2-3'), isEmpty);
    });

    test('ignores whitespace around tokens (" 1 , 6 , 11 ")', () {
      expect(parsePossibleChannels(' 1 , 6 , 11 '), [1, 6, 11]);
    });
  });

  // ---------------------------------------------------------------------------
  // isDfsChannel — 5 GHz DFS classification
  // ---------------------------------------------------------------------------

  group('isDfsChannel', () {
    test('5 GHz DFS channels are DFS (52, 64, 100, 144)', () {
      for (final ch in [52, 56, 60, 64, 100, 140, 144]) {
        expect(isDfsChannel(ch, band: '5GHz'), isTrue, reason: 'channel $ch');
      }
    });

    test('5 GHz non-DFS channels are not DFS (36, 40, 44, 48, 149)', () {
      for (final ch in [36, 40, 44, 48, 149]) {
        expect(isDfsChannel(ch, band: '5GHz'), isFalse, reason: 'channel $ch');
      }
    });

    test('2.4 GHz channels are never DFS', () {
      for (final ch in [1, 6, 11, 52, 100]) {
        expect(isDfsChannel(ch, band: '2.4GHz'), isFalse);
      }
    });

    test('6 GHz channels are never DFS', () {
      expect(isDfsChannel(52, band: '6GHz'), isFalse);
      expect(isDfsChannel(100, band: '6GHz'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // filterDfsChannels — hide DFS channels when DFS disabled
  // ---------------------------------------------------------------------------

  group('filterDfsChannels', () {
    const fiveGhzAll = [
      36, 40, 44, 48, //
      52, 56, 60, 64, //
      100, 104, 108, 112, 116, 120, 124, 128, 132, 136, 140,
    ];

    test('DFS disabled on 5 GHz drops DFS channels', () {
      expect(
        filterDfsChannels(fiveGhzAll, band: '5GHz', dfsEnabled: false),
        [36, 40, 44, 48],
      );
    });

    test('DFS enabled on 5 GHz keeps all channels', () {
      expect(
        filterDfsChannels(fiveGhzAll, band: '5GHz', dfsEnabled: true),
        fiveGhzAll,
      );
    });

    test('2.4 GHz is untouched regardless of DFS state', () {
      const ch = [1, 6, 11];
      expect(filterDfsChannels(ch, band: '2.4GHz', dfsEnabled: false), ch);
      expect(filterDfsChannels(ch, band: '2.4GHz', dfsEnabled: true), ch);
    });

    test('6 GHz is untouched regardless of DFS state', () {
      const ch = [1, 5, 9, 213];
      expect(filterDfsChannels(ch, band: '6GHz', dfsEnabled: false), ch);
    });

    test('empty list stays empty', () {
      expect(filterDfsChannels(const [], band: '5GHz', dfsEnabled: false),
          isEmpty);
    });
  });
}
