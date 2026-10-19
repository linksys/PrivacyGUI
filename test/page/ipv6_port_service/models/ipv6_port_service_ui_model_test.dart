import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

typedef _Keys = Ipv6PortServiceErrorKeys;

/// A stored rule; only the host, ports, protocol and description matter to
/// the checks under test.
Ipv6PortServiceRuleUIModel _rule({
  String description = 'Existing',
  String ipv6Address = '2001:db8::1',
  String protocol = 'TCP',
  int startPort = 80,
  int? endPort,
  bool enabled = true,
}) =>
    Ipv6PortServiceRuleUIModel(
      instancePath: 'Device.Firewall.Chain.1.Rule.26.',
      enabled: enabled,
      description: description,
      ipv6Address: ipv6Address,
      protocol: protocol,
      startPort: startPort,
      endPort: endPort ?? startPort,
    );

Map<String, String> _validate({
  String description = 'WebServer',
  String ipv6Address = '2001:db8::1',
  String startPort = '80',
  String endPort = '80',
  String protocol = 'TCP',
  List<Ipv6PortServiceRuleUIModel> otherRules = const [],
  Set<String> hiddenRuleDescriptions = const {},
}) =>
    Ipv6PortServiceRuleUIModel.validateRule(
      description: description,
      ipv6Address: ipv6Address,
      startPort: startPort,
      endPort: endPort,
      protocol: protocol,
      otherRules: otherRules,
      hiddenRuleDescriptions: hiddenRuleDescriptions,
    );

void main() {
  group('Ipv6PortServiceRuleUIModel — validateRule', () {
    test('valid rule returns empty errors', () {
      expect(_validate(startPort: '80', endPort: '443'), isEmpty);
    });

    test('a single port (end = start) is valid', () {
      expect(_validate(startPort: '443', endPort: '443'), isEmpty);
    });

    test('empty description returns error', () {
      expect(
          _validate(description: '')['description'], _Keys.descriptionRequired);
    });

    test('description with leading space returns error', () {
      expect(_validate(description: ' WebServer')['description'],
          _Keys.descriptionSurroundingSpaces);
    });

    test('empty IPv6 address returns error', () {
      expect(
          _validate(ipv6Address: '')['ipv6Address'], _Keys.ipv6AddressRequired);
    });

    test('invalid IPv6 format returns error', () {
      expect(_validate(ipv6Address: 'not-an-ipv6')['ipv6Address'],
          _Keys.invalidIpv6Address);
    });

    test('reserved IPv6 address returns error', () {
      expect(_validate(ipv6Address: '::1')['ipv6Address'],
          _Keys.reservedIpv6Address);
    });

    test('empty start port returns error', () {
      expect(_validate(startPort: '')['startPort'], _Keys.invalidPort);
    });

    test('port out of range returns error', () {
      final errors = _validate(startPort: '0', endPort: '65536');
      expect(errors['startPort'], _Keys.invalidPort);
      expect(errors['endPort'], _Keys.invalidPort);
    });

    test('end port less than start port returns error', () {
      expect(_validate(startPort: '443', endPort: '80')['endPort'],
          _Keys.portRangeReversed);
    });

    test('multiple errors returned simultaneously', () {
      final errors = _validate(
        description: '',
        ipv6Address: '',
        startPort: '',
        endPort: '',
      );
      expect(errors.length, greaterThanOrEqualTo(4));
    });
  });

  // FW refuses a description over 64 bytes with ErrorDescriptionTooLong
  // (FWDEV#204, feed_usp#50). It counts bytes, so a CJK character is three.
  group('validateRule — description length', () {
    test('64 bytes of Latin text is accepted', () {
      expect(_validate(description: 'A' * 64), isEmpty);
    });

    test('65 bytes of Latin text is refused', () {
      expect(_validate(description: 'A' * 65)['description'],
          _Keys.descriptionTooLong);
    });

    test('21 CJK characters (63 bytes) is accepted', () {
      expect(_validate(description: '規' * 21), isEmpty);
    });

    // 22 characters, 66 bytes: under any character limit up to 64, but FW
    // refuses it.
    test('22 CJK characters (66 bytes) is refused', () {
      expect(_validate(description: '規' * 22)['description'],
          _Keys.descriptionTooLong);
    });
  });

  // FLWRT finds a rule by its description, so FW refuses a second rule with
  // the same one (ErrorDescriptionInUse), against every rule in
  // Device.Firewall.Chain.1.Rule, the ones this page hides included. It
  // compares with strcmp, so case counts.
  group('validateRule — description in use', () {
    test('the description of another rule on the page is refused', () {
      expect(
        _validate(
          description: 'Game',
          otherRules: [_rule(description: 'Game')],
        )['description'],
        _Keys.descriptionInUse,
      );
    });

    test('the description of a rule the page hides is refused', () {
      expect(
        _validate(
          description: 'RULE_IDENT',
          hiddenRuleDescriptions: {'RULE_IDENT', 'Allow-DHCPv6'},
        )['description'],
        _Keys.descriptionInUse,
      );
    });

    test('a description differing only in case is accepted', () {
      expect(
        _validate(
          description: 'game',
          otherRules: [_rule(description: 'Game', ipv6Address: '2001:db8::9')],
          hiddenRuleDescriptions: {'Rule_Ident'},
        ),
        isEmpty,
      );
    });
  });

  // FW refuses an overlap with ErrorRulesOverlap (feed_usp#50,
  // ls_ipv6_service_check): the same LAN host (compared as an address, so
  // the compressed and full forms are one host), overlapping closed port
  // ranges, and a shared protocol, with Both counting as TCP and as UDP.
  // Disabled rules count.
  group('validateRule — overlap', () {
    Map<String, String> overlapWith(
      Ipv6PortServiceRuleUIModel existing, {
      String ipv6Address = '2001:db8::1',
      String startPort = '80',
      String endPort = '80',
      String protocol = 'TCP',
    }) =>
        _validate(
          ipv6Address: ipv6Address,
          startPort: startPort,
          endPort: endPort,
          protocol: protocol,
          otherRules: [existing],
        );

    test('the same port to the same host on the same protocol is refused', () {
      expect(overlapWith(_rule())['endPort'], _Keys.rulesOverlap);
    });

    test('a range covering another rule\'s port is refused', () {
      expect(
        overlapWith(_rule(startPort: 8080),
            startPort: '8000', endPort: '8100')['endPort'],
        _Keys.rulesOverlap,
      );
    });

    test('ranges that share only their end port are refused', () {
      expect(
        overlapWith(_rule(startPort: 3000, endPort: 3074),
            startPort: '3074', endPort: '3080')['endPort'],
        _Keys.rulesOverlap,
      );
    });

    test('adjacent ranges are accepted', () {
      expect(
        overlapWith(_rule(startPort: 3000, endPort: 3074),
            startPort: '3075', endPort: '3080'),
        isEmpty,
      );
    });

    test('the same port to a different host is accepted', () {
      expect(overlapWith(_rule(), ipv6Address: '2001:db8::2'), isEmpty);
    });

    test('the full form of the same address is the same host', () {
      expect(
        overlapWith(_rule(ipv6Address: '2001:db8::1'),
            ipv6Address: '2001:0DB8:0000:0000:0000:0000:0000:0001')['endPort'],
        _Keys.rulesOverlap,
      );
    });

    test('TCP and UDP on the same port are accepted', () {
      expect(overlapWith(_rule(protocol: 'UDP'), protocol: 'TCP'), isEmpty);
    });

    test('Both collides with TCP and with UDP, either way round', () {
      for (final (mine, theirs) in [
        ('Both', 'TCP'),
        ('Both', 'UDP'),
        ('TCP', 'Both'),
        ('UDP', 'Both'),
      ]) {
        expect(
          overlapWith(_rule(protocol: theirs), protocol: mine)['endPort'],
          _Keys.rulesOverlap,
          reason: '$mine against $theirs',
        );
      }
    });

    test('a disabled rule still counts', () {
      expect(overlapWith(_rule(enabled: false))['endPort'], _Keys.rulesOverlap);
    });

    test('no overlap is reported while the ports are invalid', () {
      expect(
        overlapWith(_rule(), startPort: '80', endPort: '70')['endPort'],
        _Keys.portRangeReversed,
      );
    });
  });
}
