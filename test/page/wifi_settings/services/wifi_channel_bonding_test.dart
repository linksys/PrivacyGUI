import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/services/wifi_channel_bonding.dart';

void main() {
  // ---------------------------------------------------------------------------
  // bandwidthIndex
  // ---------------------------------------------------------------------------

  group('bandwidthIndex', () {
    test('returns ordered indices for known bandwidths', () {
      expect(bandwidthIndex('20MHz'), 0);
      expect(bandwidthIndex('40MHz'), 1);
      expect(bandwidthIndex('80MHz'), 2);
      expect(bandwidthIndex('160MHz'), 3);
      expect(bandwidthIndex('320MHz'), 4);
    });

    test('Auto returns highest index (no constraint)', () {
      expect(bandwidthIndex('Auto'), 5);
    });

    test('unknown bandwidth returns -1', () {
      expect(bandwidthIndex('10MHz'), -1);
      expect(bandwidthIndex(''), -1);
    });
  });

  // ---------------------------------------------------------------------------
  // maxBandwidthForStandards
  // ---------------------------------------------------------------------------

  group('maxBandwidthForStandards', () {
    test('empty string returns 320MHz (mixed/no limit)', () {
      expect(maxBandwidthForStandards(''), '320MHz');
    });

    test('802.11b → 20MHz', () {
      expect(maxBandwidthForStandards('b'), '20MHz');
    });

    test('802.11n → 40MHz', () {
      expect(maxBandwidthForStandards('n'), '40MHz');
    });

    test('802.11ac → 160MHz', () {
      expect(maxBandwidthForStandards('ac'), '160MHz');
    });

    test('802.11ax → 160MHz', () {
      expect(maxBandwidthForStandards('ax'), '160MHz');
    });

    test('802.11be → 320MHz', () {
      expect(maxBandwidthForStandards('be'), '320MHz');
    });

    test('comma-separated takes maximum', () {
      expect(maxBandwidthForStandards('a,n,ac'), '160MHz');
    });

    test('concatenated format parsed correctly', () {
      expect(maxBandwidthForStandards('anacax'), '160MHz');
    });

    test('mixed keyword returns all standards (320MHz)', () {
      expect(maxBandwidthForStandards('mixed'), '320MHz');
    });

    test('unknown standard alone defaults to 20MHz', () {
      expect(maxBandwidthForStandards('xyz'), '20MHz');
    });
  });

  // ---------------------------------------------------------------------------
  // minStandardForBandwidth
  // ---------------------------------------------------------------------------

  group('minStandardForBandwidth', () {
    test('Auto returns null', () {
      expect(minStandardForBandwidth('Auto'), isNull);
    });

    test('empty returns null', () {
      expect(minStandardForBandwidth(''), isNull);
    });

    test('20MHz returns null (any standard)', () {
      expect(minStandardForBandwidth('20MHz'), isNull);
    });

    test('40MHz requires n', () {
      expect(minStandardForBandwidth('40MHz'), 'n');
    });

    test('80MHz requires ac', () {
      expect(minStandardForBandwidth('80MHz'), 'ac');
    });

    test('160MHz requires ac', () {
      expect(minStandardForBandwidth('160MHz'), 'ac');
    });

    test('320MHz requires be', () {
      expect(minStandardForBandwidth('320MHz'), 'be');
    });

    test('unknown bandwidth returns null', () {
      expect(minStandardForBandwidth('10MHz'), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // computeChannelsPerBandwidth
  // ---------------------------------------------------------------------------

  group('computeChannelsPerBandwidth', () {
    test('empty possibleChannels returns empty map', () {
      final result = computeChannelsPerBandwidth(
        band: '2.4GHz',
        possibleChannels: [],
        supportedBandwidths: ['20MHz'],
      );
      expect(result, isEmpty);
    });

    test('Auto key always includes all possible channels', () {
      final result = computeChannelsPerBandwidth(
        band: '2.4GHz',
        possibleChannels: [1, 6, 11],
        supportedBandwidths: ['20MHz'],
      );
      expect(result['Auto'], [1, 6, 11]);
    });

    test('2.4GHz 20MHz returns all possible channels sorted', () {
      final result = computeChannelsPerBandwidth(
        band: '2.4GHz',
        possibleChannels: [11, 1, 6],
        supportedBandwidths: ['20MHz'],
      );
      expect(result['20MHz'], [1, 6, 11]);
    });

    test('2.4GHz 40MHz filters by HT40+ bonding pairs', () {
      // Channels 1,5,6,11 — only pair [1,5] is complete
      final result = computeChannelsPerBandwidth(
        band: '2.4GHz',
        possibleChannels: [1, 5, 6, 11],
        supportedBandwidths: ['40MHz'],
      );
      // Pair [1,5] is complete → channels 1,5 valid
      // Pair [2,6] needs 2 → incomplete; pair [6,10] needs 10 → incomplete
      // Pair [7,11] needs 7 → incomplete
      expect(result['40MHz'], [1, 5]);
    });

    test('5GHz 40MHz filters by bonding pairs', () {
      final result = computeChannelsPerBandwidth(
        band: '5GHz',
        possibleChannels: [36, 40, 44, 48, 149, 153],
        supportedBandwidths: ['40MHz'],
      );
      // Pairs: [36,40], [44,48], [149,153] — all complete
      expect(result['40MHz'], [36, 40, 44, 48, 149, 153]);
    });

    test('5GHz 80MHz requires all 4 group members', () {
      final result = computeChannelsPerBandwidth(
        band: '5GHz',
        possibleChannels: [36, 40, 44, 48, 52, 56],
        supportedBandwidths: ['80MHz'],
      );
      // Group [36,40,44,48] complete → all valid
      // Group [52,56,60,64] incomplete (missing 60,64)
      expect(result['80MHz'], [36, 40, 44, 48]);
    });

    test('5GHz 160MHz requires all 8 group members', () {
      final result = computeChannelsPerBandwidth(
        band: '5GHz',
        possibleChannels: [36, 40, 44, 48, 52, 56, 60, 64],
        supportedBandwidths: ['160MHz'],
      );
      // Group [36..64] complete
      expect(result['160MHz'], [36, 40, 44, 48, 52, 56, 60, 64]);
    });

    test('6GHz 40MHz uses dynamically built groups', () {
      final result = computeChannelsPerBandwidth(
        band: '6GHz',
        possibleChannels: [1, 5, 9, 13],
        supportedBandwidths: ['40MHz'],
      );
      // Groups of 2: [1,5], [9,13] — both complete
      expect(result['40MHz'], [1, 5, 9, 13]);
    });

    test('6GHz 320MHz requires 16 consecutive channels', () {
      // First 16 channels: 1,5,9,...,61
      final channels = List.generate(16, (i) => 1 + i * 4);
      final result = computeChannelsPerBandwidth(
        band: '6GHz',
        possibleChannels: channels,
        supportedBandwidths: ['320MHz'],
      );
      expect(result['320MHz'], channels);
    });

    test('uses default widths when supportedBandwidths empty', () {
      final result = computeChannelsPerBandwidth(
        band: '2.4GHz',
        possibleChannels: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],
        supportedBandwidths: [],
      );
      // Default 2.4GHz widths: 20MHz, 40MHz
      expect(result.containsKey('20MHz'), isTrue);
      expect(result.containsKey('40MHz'), isTrue);
      expect(result.containsKey('80MHz'), isFalse);
    });

    test('unknown band returns all channels for all widths', () {
      final result = computeChannelsPerBandwidth(
        band: 'unknown',
        possibleChannels: [1, 2, 3],
        supportedBandwidths: ['20MHz'],
      );
      expect(result['20MHz'], [1, 2, 3]);
    });

    test('incomplete groups are excluded from results', () {
      // Only channel 36 available — no complete pair
      final result = computeChannelsPerBandwidth(
        band: '5GHz',
        possibleChannels: [36],
        supportedBandwidths: ['40MHz'],
      );
      expect(result.containsKey('40MHz'), isFalse);
    });
  });
}
