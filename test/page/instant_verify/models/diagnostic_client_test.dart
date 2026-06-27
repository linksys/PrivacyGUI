import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';

DiagnosticClient _client(String? hostname, {String mac = 'AA:BB:CC:DD:EE:FF'}) =>
    DiagnosticClient(
      macAddress: mac,
      hostname: hostname,
      band: '5 GHz',
      isWireless: true,
    );

void main() {
  group('DiagnosticClient — name cleaning (mDNS/Bonjour strip)', () {
    test('strips ._device-info._tcp.local suffix', () {
      final c = _client("Anita's MacBook Pro._device-info._tcp.local");
      expect(c.cleanHostname, "Anita's MacBook Pro");
      expect(c.displayName, "Anita's MacBook Pro");
      expect(c.displayNameWithOui, "Anita's MacBook Pro");
    });

    test('strips a _udp service segment too', () {
      final c = _client('Living Room Speaker._sonos._udp.local');
      expect(c.cleanHostname, 'Living Room Speaker');
    });

    test('strips a bare trailing .local', () {
      expect(_client('office-printer.local').cleanHostname, 'office-printer');
    });

    test('raw identifiers without a service suffix pass through unchanged', () {
      expect(_client('RINCON_38420B6505D20140').cleanHostname,
          'RINCON_38420B6505D20140');
      expect(_client('wiz_1727f5').cleanHostname, 'wiz_1727f5');
      expect(_client('bb91a21a-21f8-42c0-b0ba-d7bf002c4479').cleanHostname,
          'bb91a21a-21f8-42c0-b0ba-d7bf002c4479');
      expect(_client('Android_CZHGJ17H').cleanHostname, 'Android_CZHGJ17H');
    });

    test('null hostname → null cleanHostname, name falls back to MAC', () {
      final c = _client(null);
      expect(c.cleanHostname, isNull);
      expect(c.displayName, 'AA:BB:CC:DD:EE:FF');
      expect(c.displayNameWithOui, 'AA:BB:CC:DD:EE:FF');
    });

    test('hostname that is only a service suffix → MAC fallback', () {
      final c = _client('._device-info._tcp.local');
      expect(c.cleanHostname, isNull);
      expect(c.displayName, 'AA:BB:CC:DD:EE:FF');
    });
  });
}
