import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/usp_page/wifi_settings/services/wifi_channel_bonding.dart';

void main() {
  group('computeChannelsPerBandwidth', () {
    // -----------------------------------------------------------------------
    // Edge cases
    // -----------------------------------------------------------------------

    test('returns empty map when possibleChannels is empty', () {
      final result = computeChannelsPerBandwidth(
        band: '5GHz',
        possibleChannels: [],
        supportedBandwidths: ['Auto', '20MHz', '40MHz'],
      );
      expect(result, isEmpty);
    });

    test('always includes Auto key with all possibleChannels', () {
      final channels = [36, 40, 44, 48];
      final result = computeChannelsPerBandwidth(
        band: '5GHz',
        possibleChannels: channels,
        supportedBandwidths: ['Auto', '20MHz'],
      );
      expect(result['Auto'], channels);
    });

    // -----------------------------------------------------------------------
    // 2.4 GHz
    // -----------------------------------------------------------------------

    group('2.4 GHz', () {
      test('20MHz returns all possible channels', () {
        final channels = List.generate(13, (i) => i + 1); // 1-13
        final result = computeChannelsPerBandwidth(
          band: '2.4GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz', '40MHz'],
        );
        expect(result['20MHz'], channels);
      });

      test('40MHz returns valid HT40 primary channels', () {
        final channels = List.generate(13, (i) => i + 1); // 1-13
        final result = computeChannelsPerBandwidth(
          band: '2.4GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz', '40MHz'],
        );
        // All channels 1-13 should be present since every pair (c, c+4)
        // has both members in the 1-13 set.
        final fortyMhz = result['40MHz']!;
        expect(fortyMhz, isNotEmpty);
        // Channels 1-9 can bond with +4 partner, channels 5-13 can bond with -4.
        // Union of all valid pairs covers 1-13.
        expect(fortyMhz, channels);
      });

      test('40MHz with limited channels filters correctly', () {
        // Only channels 1 and 5 available — valid pair (1,5)
        final result = computeChannelsPerBandwidth(
          band: '2.4GHz',
          possibleChannels: [1, 5],
          supportedBandwidths: ['Auto', '20MHz', '40MHz'],
        );
        expect(result['40MHz'], [1, 5]);
      });

      test('40MHz with no valid pairs returns empty', () {
        // Only channels 1 and 3 — not a valid 40MHz pair
        final result = computeChannelsPerBandwidth(
          band: '2.4GHz',
          possibleChannels: [1, 3],
          supportedBandwidths: ['Auto', '20MHz', '40MHz'],
        );
        expect(result.containsKey('40MHz'), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // 5 GHz
    // -----------------------------------------------------------------------

    group('5 GHz', () {
      test('20MHz returns all possible channels', () {
        final channels = [36, 40, 44, 48, 52, 56, 60, 64];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz', '40MHz', '80MHz', '160MHz'],
        );
        expect(result['20MHz'], channels);
      });

      test('40MHz returns channels with valid bonding partner', () {
        final channels = [36, 40, 44, 48];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz', '40MHz'],
        );
        // Two pairs: (36,40), (44,48) — all channels present
        expect(result['40MHz'], [36, 40, 44, 48]);
      });

      test('40MHz with incomplete pair filters out orphan', () {
        // Channel 36 without its partner 40
        final channels = [36, 44, 48];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz', '40MHz'],
        );
        // Only pair (44,48) is complete
        expect(result['40MHz'], [44, 48]);
      });

      test('80MHz with full UNII-1 group', () {
        final channels = [36, 40, 44, 48];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz', '40MHz', '80MHz'],
        );
        expect(result['80MHz'], [36, 40, 44, 48]);
      });

      test('80MHz with incomplete group returns empty', () {
        // Only 3 of 4 channels in the group
        final channels = [36, 40, 44];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz', '80MHz'],
        );
        expect(result.containsKey('80MHz'), isFalse);
      });

      test('160MHz with full 36-64 group', () {
        final channels = [36, 40, 44, 48, 52, 56, 60, 64];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz', '160MHz'],
        );
        expect(result['160MHz'], channels);
      });

      test('160MHz with partial 36-64 group returns empty', () {
        // Missing channel 64
        final channels = [36, 40, 44, 48, 52, 56, 60];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '160MHz'],
        );
        expect(result.containsKey('160MHz'), isFalse);
      });

      test('multiple 80MHz groups coexist', () {
        final channels = [
          36, 40, 44, 48, // UNII-1
          100, 104, 108, 112, // UNII-2 extended
          149, 153, 157, 161, // UNII-3
        ];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '80MHz'],
        );
        expect(result['80MHz'], channels);
      });
    });

    // -----------------------------------------------------------------------
    // 6 GHz
    // -----------------------------------------------------------------------

    group('6 GHz', () {
      test('20MHz returns all possible channels', () {
        final channels = [1, 5, 9, 13, 17, 21, 25, 29];
        final result = computeChannelsPerBandwidth(
          band: '6GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '20MHz'],
        );
        expect(result['20MHz'], channels);
      });

      test('40MHz returns valid pairs', () {
        final channels = [1, 5, 9, 13, 17, 21, 25, 29];
        final result = computeChannelsPerBandwidth(
          band: '6GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '40MHz'],
        );
        // Pairs: [1,5], [9,13], [17,21], [25,29]
        expect(result['40MHz'], channels);
      });

      test('80MHz returns valid groups of 4', () {
        final channels = [1, 5, 9, 13, 17, 21, 25, 29];
        final result = computeChannelsPerBandwidth(
          band: '6GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '80MHz'],
        );
        // Groups: [1,5,9,13], [17,21,25,29]
        expect(result['80MHz'], channels);
      });

      test('160MHz returns valid groups of 8', () {
        final channels = [1, 5, 9, 13, 17, 21, 25, 29];
        final result = computeChannelsPerBandwidth(
          band: '6GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '160MHz'],
        );
        // Group: [1,5,9,13,17,21,25,29]
        expect(result['160MHz'], channels);
      });

      test('160MHz with partial group returns empty', () {
        // Only 6 of 8 channels
        final channels = [1, 5, 9, 13, 17, 21];
        final result = computeChannelsPerBandwidth(
          band: '6GHz',
          possibleChannels: channels,
          supportedBandwidths: ['Auto', '160MHz'],
        );
        expect(result.containsKey('160MHz'), isFalse);
      });
    });

    // -----------------------------------------------------------------------
    // Default bandwidths (when supportedBandwidths is empty)
    // -----------------------------------------------------------------------

    group('default bandwidths fallback', () {
      test('computes all known widths when supportedBandwidths is empty', () {
        final channels = [36, 40, 44, 48, 52, 56, 60, 64];
        final result = computeChannelsPerBandwidth(
          band: '5GHz',
          possibleChannels: channels,
          supportedBandwidths: [],
        );
        expect(result.containsKey('Auto'), isTrue);
        expect(result.containsKey('20MHz'), isTrue);
        expect(result.containsKey('40MHz'), isTrue);
        expect(result.containsKey('80MHz'), isTrue);
        expect(result.containsKey('160MHz'), isTrue);
      });

      test('unknown band returns 20MHz only', () {
        final channels = [1, 2, 3];
        final result = computeChannelsPerBandwidth(
          band: 'unknown',
          possibleChannels: channels,
          supportedBandwidths: [],
        );
        expect(result['Auto'], channels);
        expect(result['20MHz'], channels);
        expect(result.length, 2); // Only Auto + 20MHz
      });
    });
  });
}
