import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/generated/transforms.g.dart';

void main() {
  // ---------------------------------------------------------------------------
  // durationSeconds
  // ---------------------------------------------------------------------------

  group('Transforms — durationSeconds', () {
    test('returns seconds between two DateTimes', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0);
      final end = DateTime(2026, 1, 1, 12, 0, 5);

      expect(Transforms.durationSeconds(start, end), 5.0);
    });

    test('returns fractional seconds for sub-second difference', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0, 0);
      final end = DateTime(2026, 1, 1, 12, 0, 0, 500);

      expect(Transforms.durationSeconds(start, end), 0.5);
    });

    test('returns negative when end is before start', () {
      final start = DateTime(2026, 1, 1, 12, 0, 5);
      final end = DateTime(2026, 1, 1, 12, 0, 0);

      expect(Transforms.durationSeconds(start, end), -5.0);
    });
  });

  // ---------------------------------------------------------------------------
  // durationMs
  // ---------------------------------------------------------------------------

  group('Transforms — durationMs', () {
    test('returns milliseconds between two DateTimes', () {
      final start = DateTime(2026, 1, 1, 12, 0, 0, 0);
      final end = DateTime(2026, 1, 1, 12, 0, 0, 750);

      expect(Transforms.durationMs(start, end), 750);
    });

    test('returns zero for same time', () {
      final t = DateTime(2026, 1, 1);
      expect(Transforms.durationMs(t, t), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // cidrToNetmask
  // ---------------------------------------------------------------------------

  group('Transforms — cidrToNetmask', () {
    test('/0 returns 0.0.0.0', () {
      expect(Transforms.cidrToNetmask(0), '0.0.0.0');
    });

    test('/8 returns 255.0.0.0', () {
      expect(Transforms.cidrToNetmask(8), '255.0.0.0');
    });

    test('/16 returns 255.255.0.0', () {
      expect(Transforms.cidrToNetmask(16), '255.255.0.0');
    });

    test('/24 returns 255.255.255.0', () {
      expect(Transforms.cidrToNetmask(24), '255.255.255.0');
    });

    test('/32 returns 255.255.255.255', () {
      expect(Transforms.cidrToNetmask(32), '255.255.255.255');
    });

    test('/25 returns 255.255.255.128', () {
      expect(Transforms.cidrToNetmask(25), '255.255.255.128');
    });

    test('negative CIDR returns 0.0.0.0', () {
      expect(Transforms.cidrToNetmask(-1), '0.0.0.0');
    });

    test('CIDR > 32 returns 0.0.0.0', () {
      expect(Transforms.cidrToNetmask(33), '0.0.0.0');
    });
  });

  // ---------------------------------------------------------------------------
  // formatBandwidth
  // ---------------------------------------------------------------------------

  group('Transforms — formatBandwidth', () {
    test('below 1000 Mbps shows Mbps', () {
      expect(Transforms.formatBandwidth(100.0), '100.00 Mbps');
    });

    test('at 1000 Mbps shows Gbps', () {
      expect(Transforms.formatBandwidth(1000.0), '1.00 Gbps');
    });

    test('above 1000 Mbps shows Gbps', () {
      expect(Transforms.formatBandwidth(2500.0), '2.50 Gbps');
    });

    test('custom precision', () {
      expect(Transforms.formatBandwidth(1234.5, precision: 1), '1.2 Gbps');
    });
  });

  // ---------------------------------------------------------------------------
  // formatDuration
  // ---------------------------------------------------------------------------

  group('Transforms — formatDuration', () {
    test('seconds only', () {
      expect(Transforms.formatDuration(45), '45s');
    });

    test('minutes and seconds', () {
      expect(Transforms.formatDuration(125), '2m 5s');
    });

    test('hours, minutes, and seconds', () {
      expect(Transforms.formatDuration(3661), '1h 1m 1s');
    });

    test('zero seconds', () {
      expect(Transforms.formatDuration(0), '0s');
    });

    test('exact hour', () {
      expect(Transforms.formatDuration(3600), '1h 0m 0s');
    });

    test('exact minute', () {
      expect(Transforms.formatDuration(60), '1m 0s');
    });
  });

  // ---------------------------------------------------------------------------
  // formatBytes
  // ---------------------------------------------------------------------------

  group('Transforms — formatBytes', () {
    test('bytes (< 1024)', () {
      expect(Transforms.formatBytes(512), '512 B');
    });

    test('kilobytes', () {
      expect(Transforms.formatBytes(1024), '1.0 KB');
    });

    test('megabytes', () {
      expect(Transforms.formatBytes(1048576), '1.0 MB');
    });

    test('gigabytes', () {
      expect(Transforms.formatBytes(1073741824), '1.0 GB');
    });

    test('terabytes', () {
      expect(Transforms.formatBytes(1099511627776), '1.0 TB');
    });

    test('value >= 10 uses 0 decimal places', () {
      // 15 KB = 15360 bytes → "15 KB" (no decimal)
      expect(Transforms.formatBytes(15360), '15 KB');
    });

    test('value < 10 uses 1 decimal place', () {
      // 5.5 KB = 5632 bytes → "5.5 KB"
      expect(Transforms.formatBytes(5632), '5.5 KB');
    });

    test('zero bytes', () {
      expect(Transforms.formatBytes(0), '0.0 B');
    });
  });

  // ---------------------------------------------------------------------------
  // formatPercent
  // ---------------------------------------------------------------------------

  group('Transforms — formatPercent', () {
    test('default precision (1 decimal)', () {
      expect(Transforms.formatPercent(85.678), '85.7%');
    });

    test('custom precision', () {
      expect(Transforms.formatPercent(85.678, precision: 2), '85.68%');
    });

    test('zero percent', () {
      expect(Transforms.formatPercent(0.0), '0.0%');
    });
  });

  // ---------------------------------------------------------------------------
  // formatNumber
  // ---------------------------------------------------------------------------

  group('Transforms — formatNumber', () {
    test('small number without commas', () {
      expect(Transforms.formatNumber(999.0), '999');
    });

    test('thousands separator', () {
      expect(Transforms.formatNumber(1234567.0), '1,234,567');
    });

    test('with precision', () {
      expect(Transforms.formatNumber(1234.567, precision: 2), '1,234.57');
    });

    test('no decimal part with default precision', () {
      expect(Transforms.formatNumber(100.0), '100');
    });
  });

  // ---------------------------------------------------------------------------
  // formatSpeed
  // ---------------------------------------------------------------------------

  group('Transforms — formatSpeed', () {
    test('below 1000 Kbps shows Kbps', () {
      expect(Transforms.formatSpeed(500.0), '500.00 Kbps');
    });

    test('1000-999999 Kbps shows Mbps', () {
      expect(Transforms.formatSpeed(1500.0), '1.50 Mbps');
    });

    test('at 1000000 Kbps shows Gbps', () {
      expect(Transforms.formatSpeed(1000000.0), '1.00 Gbps');
    });

    test('above 1000000 Kbps shows Gbps', () {
      expect(Transforms.formatSpeed(2500000.0), '2.50 Gbps');
    });

    test('custom precision', () {
      expect(Transforms.formatSpeed(1234.0, precision: 1), '1.2 Mbps');
    });
  });

  // ---------------------------------------------------------------------------
  // hexDecode
  // ---------------------------------------------------------------------------

  group('Transforms — hexDecode', () {
    test('decodes hex string to bytes', () {
      final result = Transforms.hexDecode('48656C6C6F');
      expect(result, Uint8List.fromList([0x48, 0x65, 0x6C, 0x6C, 0x6F]));
    });

    test('decodes lowercase hex', () {
      final result = Transforms.hexDecode('ff00ab');
      expect(result, Uint8List.fromList([0xFF, 0x00, 0xAB]));
    });

    test('empty string returns empty list', () {
      final result = Transforms.hexDecode('');
      expect(result, isEmpty);
    });
  });
}
