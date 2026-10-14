import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

void main() {
  group('Ipv6PortServiceRuleUIModel — validateRule', () {
    test('valid rule returns empty errors', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: 'WebServer',
        ipv6Address: '2001:db8::1',
        startPort: '80',
        endPort: '443',
      );
      expect(errors, isEmpty);
    });

    test('empty description returns error', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: '',
        ipv6Address: '2001:db8::1',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['description'], 'Name is required');
    });

    test('description with leading space returns error', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: ' WebServer',
        ipv6Address: '2001:db8::1',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['description'],
          'Name must not have leading or trailing spaces');
    });

    test('description over 32 chars returns error', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: 'A' * 33,
        ipv6Address: '2001:db8::1',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['description'], 'Name must be 32 characters or less');
    });

    test('empty IPv6 address returns error', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: 'Rule1',
        ipv6Address: '',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['ipv6Address'], 'IPv6 address is required');
    });

    test('invalid IPv6 format returns error', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: 'Rule1',
        ipv6Address: 'not-an-ipv6',
        startPort: '80',
        endPort: '80',
      );
      expect(errors['ipv6Address'], 'Invalid IPv6 address format');
    });

    test('empty start port returns error', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: 'Rule1',
        ipv6Address: '2001:db8::1',
        startPort: '',
        endPort: '80',
      );
      expect(errors['startPort'], 'Start port is required');
    });

    test('port out of range returns error', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: 'Rule1',
        ipv6Address: '2001:db8::1',
        startPort: '0',
        endPort: '65536',
      );
      expect(errors['startPort'], 'Port must be 1-65535');
      expect(errors['endPort'], 'Port must be 1-65535');
    });

    test('end port less than start port returns error', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: 'Rule1',
        ipv6Address: '2001:db8::1',
        startPort: '443',
        endPort: '80',
      );
      expect(errors['endPort'], 'End port must be >= start port');
    });

    test('multiple errors returned simultaneously', () {
      final errors = Ipv6PortServiceRuleUIModel.validateRule(
        description: '',
        ipv6Address: '',
        startPort: '',
        endPort: '',
      );
      expect(errors.length, greaterThanOrEqualTo(4));
    });
  });
}
