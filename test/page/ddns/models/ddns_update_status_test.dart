import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';

void main() {
  // The rows of the implementation doc's §7.3 on linksys/FWDEV#191: each 1.0
  // status is a distinct combination of standard TR-181 values.
  group('DdnsUpdateStatus.fromWire', () {
    for (final (client, lastError, hostname, expected) in [
      ('Disabled', 'NO_ERROR', 'Disabled', DdnsUpdateStatus.disabled),
      ('Connecting', 'NO_ERROR', 'Updating', DdnsUpdateStatus.connecting),
      ('Updated', 'NO_ERROR', 'Registered', DdnsUpdateStatus.success),
      (
        'Error',
        'AUTHENTICATION_ERROR',
        'Error',
        DdnsUpdateStatus.authenticationFailed
      ),
      (
        'Error_Misconfigured',
        'MISCONFIGURATION_ERROR',
        'Error',
        DdnsUpdateStatus.invalidHostname
      ),
      (
        'Error_Misconfigured',
        'MISCONFIGURATION_ERROR',
        'UpdateNeeded',
        DdnsUpdateStatus.settingsIncomplete
      ),
      (
        'Error',
        'CONNECTION_ERROR',
        'UpdateNeeded',
        DdnsUpdateStatus.connectionFailed
      ),
      ('Error', 'PROTOCOL_ERROR', 'Error', DdnsUpdateStatus.failed),
    ]) {
      test('$client + $lastError + host name $hostname → ${expected.name}', () {
        expect(
          DdnsUpdateStatus.fromWire(
            clientStatus: client,
            lastError: lastError,
            hostnameStatus: hostname,
          ),
          expected,
        );
      });
    }

    test(
        'Error_Misconfigured with no enabled host name is settings '
        'incomplete, not an invalid host name', () {
      expect(
        DdnsUpdateStatus.fromWire(
          clientStatus: 'Error_Misconfigured',
          lastError: 'MISCONFIGURATION_ERROR',
          hostnameStatus: 'Disabled',
        ),
        DdnsUpdateStatus.settingsIncomplete,
      );
    });

    test(
        'Error_Misconfigured on a client with no host name row is settings '
        'incomplete', () {
      expect(
        DdnsUpdateStatus.fromWire(
          clientStatus: 'Error_Misconfigured',
          lastError: 'MISCONFIGURATION_ERROR',
          hostnameStatus: null,
        ),
        DdnsUpdateStatus.settingsIncomplete,
      );
    });

    test("TR-181's Authenticating reads as connecting", () {
      expect(
        DdnsUpdateStatus.fromWire(
          clientStatus: 'Authenticating',
          lastError: 'NO_ERROR',
          hostnameStatus: 'Updating',
        ),
        DdnsUpdateStatus.connecting,
      );
    });

    test('a status outside the contract is unknown, not guessed', () {
      expect(
        DdnsUpdateStatus.fromWire(
          clientStatus: 'Something',
          lastError: 'NO_ERROR',
          hostnameStatus: 'Disabled',
        ),
        DdnsUpdateStatus.unknown,
      );
    });
  });
}
