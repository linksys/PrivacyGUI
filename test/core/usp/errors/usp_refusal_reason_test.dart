import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/usp/errors/usp_refusal_reason.dart';

void main() {
  group('UspRefusalReason.fromErrorMessage', () {
    test('each name in the FWDEV#204 contract reads as its own reason', () {
      // The contract's tables (FWDEV#204 GUI API, 2026-10-09; IPv6 port
      // services, 2026-10-14), spelled out rather than read off the enum.
      const contract = {
        'ErrorRulesOverlap': UspRefusalReason.rulesOverlap,
        'ErrorTooManyRules': UspRefusalReason.tooManyRules,
        'ErrorInvalidInternalServerIPAddress':
            UspRefusalReason.invalidInternalServerIpAddress,
        'ErrorDescriptionTooLong': UspRefusalReason.descriptionTooLong,
        'ErrorInvalidDestinationIPAddress':
            UspRefusalReason.invalidDestinationIpAddress,
        'ErrorInvalidDestinationMACAddress':
            UspRefusalReason.invalidDestinationMacAddress,
        'ErrorMultipleDestinations': UspRefusalReason.multipleDestinations,
        'ErrorInvalidSourceRestriction':
            UspRefusalReason.invalidSourceRestriction,
        'ErrorNoPortRanges': UspRefusalReason.noPortRanges,
        'ErrorInvalidPortRange': UspRefusalReason.invalidPortRange,
        'ErrorInvalidPort': UspRefusalReason.invalidPort,
        'ErrorDescriptionInUse': UspRefusalReason.descriptionInUse,
      };
      contract.forEach((name, reason) {
        expect(UspRefusalReason.fromErrorMessage('$name: some detail.'), reason,
            reason: name);
      });
      expect(UspRefusalReason.values.toSet()..remove(UspRefusalReason.unknown),
          contract.values.toSet(),
          reason: 'every reason is one the contract names');
    });

    test('the measured messages (bench 2026-10-12)', () {
      expect(
          UspRefusalReason.fromErrorMessage(
              'ErrorRulesOverlap: external port 18080 is already forwarded.'),
          UspRefusalReason.rulesOverlap);
      expect(
          UspRefusalReason.fromErrorMessage(
              'ErrorDescriptionTooLong: at most 32 bytes.'),
          UspRefusalReason.descriptionTooLong);
      expect(
          UspRefusalReason.fromErrorMessage(
              "ErrorInvalidInternalServerIPAddress"
              ": '192.168.1.1' is not a LAN host address."),
          UspRefusalReason.invalidInternalServerIpAddress);
    });

    test(
        'a name is matched whole: ErrorInvalidPortRange is not ErrorInvalidPort',
        () {
      expect(
          UspRefusalReason.fromErrorMessage(
              'ErrorInvalidPortRange: 18400 is above 18390.'),
          UspRefusalReason.invalidPortRange);
      expect(UspRefusalReason.fromErrorMessage('ErrorInvalidPort'),
          UspRefusalReason.invalidPort);
      expect(UspRefusalReason.fromErrorMessage('ErrorInvalidPorts: x'),
          UspRefusalReason.unknown);
      expect(UspRefusalReason.fromErrorMessage('ErrorRulesOverlap2: x'),
          UspRefusalReason.unknown);
    });

    test('no reason when the message does not start with a name it knows', () {
      // What every other leaf of a refused Set carries (bench 2026-10-12).
      expect(
          UspRefusalReason.fromErrorMessage("SetParameterGroup: group set "
              "failed at 'Device.NAT.PortMapping.2.ExternalPort' (Invalid "
              'value)'),
          UspRefusalReason.unknown);
      // Measured too: a value outside the leaf's enumeration.
      expect(
          UspRefusalReason.fromErrorMessage(
              "List enumerations did not include 'ICMP' value"),
          UspRefusalReason.unknown);
      expect(
          UspRefusalReason.fromErrorMessage(
              'Rejected: ErrorRulesOverlap later in the text'),
          UspRefusalReason.unknown);
      // Static routes' names (FWDEV#213) are read by their own service.
      expect(
          UspRefusalReason.fromErrorMessage(
              'ErrorInvalidIPAddress: 127.20.0.0 is a reserved address.'),
          UspRefusalReason.unknown);
      expect(UspRefusalReason.fromErrorMessage(''), UspRefusalReason.unknown);
    });

    // The wrapper is measured (FW 2.0.2, 2026-10-05, a 7005 refusal); an
    // FWDEV#204 name inside it is not. It is the only shape a router message
    // takes in a thrown error, so this pins where the name is read there.
    group('inside the WASM client transport wrapper', () {
      const wrapper = 'Transport error: Protocol error: Decoding error: '
          'Received error response: ';

      test('the router message follows the wrapper', () {
        expect(
            UspRefusalReason.fromErrorMessage(
                '${wrapper}ErrorMultipleDestinations: clear DestIP first. '
                '(code: 7012)'),
            UspRefusalReason.multipleDestinations);
      });

      test('a bare name followed only by the code suffix', () {
        expect(
            UspRefusalReason.fromErrorMessage(
                '${wrapper}ErrorTooManyRules (code: 7012)'),
            UspRefusalReason.tooManyRules);
      });

      test('the measured 7005 names no reason', () {
        expect(
            UspRefusalReason.fromErrorMessage(
                '${wrapper}ProcessSet_AllowPartialFalse: Allow partial=false '
                'not supported across more than one USP Service (code: 7005)'),
            UspRefusalReason.unknown);
      });
    });
  });
}
