import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/cs_diagnostic/models/diagnostic_client.dart';

void main() {
  group('DiagnosticClient — signalStrength', () {
    test('returns excellent for signal >= -65 dBm', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        signalDecibels: -38,
        isWireless: true,
      );
      expect(client.signalStrength, SignalStrength.excellent);
    });

    test('returns excellent at exactly -65 dBm boundary', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        signalDecibels: -65,
        isWireless: true,
      );
      expect(client.signalStrength, SignalStrength.excellent);
    });

    test('returns fair for signal between -66 and -75 dBm', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        signalDecibels: -70,
        isWireless: true,
      );
      expect(client.signalStrength, SignalStrength.fair);
    });

    test('returns fair at exactly -75 dBm boundary', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        signalDecibels: -75,
        isWireless: true,
      );
      expect(client.signalStrength, SignalStrength.fair);
    });

    test('returns weak for signal between -76 and -85 dBm', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '2.4GHz',
        signalDecibels: -80,
        isWireless: true,
      );
      expect(client.signalStrength, SignalStrength.weak);
    });

    test('returns veryWeak for signal below -85 dBm', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '2.4GHz',
        signalDecibels: -90,
        isWireless: true,
      );
      expect(client.signalStrength, SignalStrength.veryWeak);
    });

    test('returns unknown for wired client', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: 'Wired',
        isWireless: false,
      );
      expect(client.signalStrength, SignalStrength.unknown);
    });

    test('returns unknown when signal is null on wireless client', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.signalStrength, SignalStrength.unknown);
    });
  });

  group('DiagnosticClient — isFlagged', () {
    test('flags client with weak signal below -75 dBm', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '2.4GHz',
        signalDecibels: -80,
        txRateMbps: 100,
        rxRateMbps: 100,
        isWireless: true,
      );
      expect(client.isFlagged, true);
    });

    test('does not flag client at exactly -75 dBm', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        signalDecibels: -75,
        txRateMbps: 100,
        rxRateMbps: 100,
        isWireless: true,
      );
      expect(client.isFlagged, false);
    });

    test('flags client with low txRate below 10 Mbps', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '2.4GHz',
        signalDecibels: -50,
        txRateMbps: 6,
        rxRateMbps: 100,
        isWireless: true,
      );
      expect(client.isFlagged, true);
    });

    test('flags client with low rxRate below 10 Mbps', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '2.4GHz',
        signalDecibels: -50,
        txRateMbps: 100,
        rxRateMbps: 5,
        isWireless: true,
      );
      expect(client.isFlagged, true);
    });

    test('does not flag healthy wireless client', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        signalDecibels: -45,
        txRateMbps: 866,
        rxRateMbps: 780,
        isWireless: true,
      );
      expect(client.isFlagged, false);
    });

    test('never flags wired client regardless of rates', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: 'Wired',
        txRateMbps: 1,
        rxRateMbps: 1,
        isWireless: false,
      );
      expect(client.isFlagged, false);
    });

    test('does not flag wireless client with null signal and good rates', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        txRateMbps: 100,
        rxRateMbps: 100,
        isWireless: true,
      );
      expect(client.isFlagged, false);
    });
  });

  group('DiagnosticClient — manufacturer / OUI lookup', () {
    test('returns Apple for known Apple OUI prefix', () {
      const client = DiagnosticClient(
        macAddress: 'AC:DE:48:11:22:33',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.manufacturer, 'Apple');
    });

    test('returns Samsung for known Samsung OUI prefix', () {
      const client = DiagnosticClient(
        macAddress: 'B4:79:A7:11:22:33',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.manufacturer, 'Samsung');
    });

    test('returns Linksys for known Linksys OUI prefix', () {
      const client = DiagnosticClient(
        macAddress: '00:1A:70:DE:AD:01',
        band: 'Wired',
        isWireless: false,
      );
      expect(client.manufacturer, 'Linksys');
    });

    test('returns null for unknown OUI prefix', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:33',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.manufacturer, null);
    });

    test('returns null for short MAC address', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.manufacturer, null);
    });

    test('handles lowercase MAC addresses via toUpperCase', () {
      const client = DiagnosticClient(
        macAddress: 'ac:de:48:11:22:33',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.manufacturer, 'Apple');
    });
  });

  group('DiagnosticClient — displayName / displayNameWithOui', () {
    test('displayName returns hostname when present', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:33',
        hostname: 'iPhone 15 Pro',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.displayName, 'iPhone 15 Pro');
    });

    test('displayName falls back to macAddress when no hostname', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:33',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.displayName, 'AA:BB:CC:11:22:33');
    });

    test('displayNameWithOui returns hostname when present', () {
      const client = DiagnosticClient(
        macAddress: 'AC:DE:48:11:22:33',
        hostname: 'iPhone 15 Pro',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.displayNameWithOui, 'iPhone 15 Pro');
    });

    test('displayNameWithOui returns manufacturer + MAC when no hostname and OUI found', () {
      const client = DiagnosticClient(
        macAddress: 'AC:DE:48:11:22:33',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.displayNameWithOui, 'Apple (AC:DE:48:11:22:33)');
    });

    test('displayNameWithOui returns bare MAC when no hostname and no OUI', () {
      const client = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:33',
        band: '5GHz',
        isWireless: true,
      );
      expect(client.displayNameWithOui, 'AA:BB:CC:11:22:33');
    });
  });

  group('DiagnosticClient — Equatable', () {
    test('two clients with same props are equal', () {
      const a = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        hostname: 'Test',
        ipAddress: '192.168.1.1',
        band: '5GHz',
        signalDecibels: -50,
        txRateMbps: 100,
        rxRateMbps: 80,
        isWireless: true,
      );
      const b = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        hostname: 'Test',
        ipAddress: '192.168.1.1',
        band: '5GHz',
        signalDecibels: -50,
        txRateMbps: 100,
        rxRateMbps: 80,
        isWireless: true,
      );
      expect(a, equals(b));
    });

    test('clients with different signal are not equal', () {
      const a = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        signalDecibels: -50,
        isWireless: true,
      );
      const b = DiagnosticClient(
        macAddress: 'AA:BB:CC:11:22:01',
        band: '5GHz',
        signalDecibels: -70,
        isWireless: true,
      );
      expect(a, isNot(equals(b)));
    });
  });
}
