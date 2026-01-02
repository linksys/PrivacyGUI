import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_rule_provider.dart';

void main() {
  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('SinglePortForwardingRuleNotifier', () {
    group('initial state', () {
      test('has correct default initial state', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);
        final state = notifier.state;

        expect(state.rules, isEmpty);
        expect(state.rule, isNull);
        expect(state.editIndex, isNull);
        expect(state.routerIp, '192.168.1.1');
        expect(state.subnetMask, '255.255.255.0');
      });
    });

    group('init', () {
      test('initializes with all parameters for add mode', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);
        const existingRules = [
          SinglePortForwardingRuleUIModel(
            isEnabled: true,
            externalPort: 8080,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            internalPort: 8080,
            description: 'Existing',
          ),
        ];
        const newRule = SinglePortForwardingRuleUIModel(
          isEnabled: true,
          externalPort: 9000,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.101',
          internalPort: 9000,
          description: 'New',
        );

        notifier.init(
          existingRules,
          newRule,
          null,
          '10.0.0.1',
          '255.255.0.0',
        );

        expect(notifier.state.rules, existingRules);
        expect(notifier.state.rule, newRule);
        expect(notifier.state.editIndex, isNull);
        expect(notifier.state.routerIp, '10.0.0.1');
        expect(notifier.state.subnetMask, '255.255.0.0');
      });

      test('initializes for edit mode with index', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);
        const existingRule = SinglePortForwardingRuleUIModel(
          isEnabled: true,
          externalPort: 8080,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.100',
          internalPort: 8080,
          description: 'Existing',
        );
        const existingRules = [existingRule];

        notifier.init(
          existingRules,
          existingRule,
          0,
          '192.168.1.1',
          '255.255.255.0',
        );

        expect(notifier.state.rules, existingRules);
        expect(notifier.state.rule, existingRule);
        expect(notifier.state.editIndex, 0);
      });
    });

    group('updateRule', () {
      test('updates rule in state', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);
        const newRule = SinglePortForwardingRuleUIModel(
          isEnabled: true,
          externalPort: 5000,
          protocol: 'UDP',
          internalServerIPAddress: '192.168.1.150',
          internalPort: 5000,
          description: 'Updated',
        );

        notifier.updateRule(newRule);

        expect(notifier.state.rule, newRule);
      });

      test('updates rule to null', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);
        const initialRule = SinglePortForwardingRuleUIModel(
          isEnabled: true,
          externalPort: 8080,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.100',
          internalPort: 8080,
          description: 'Initial',
        );

        notifier.init([], initialRule, null, '192.168.1.1', '255.255.255.0');
        notifier.updateRule(null);

        expect(notifier.state.rule, isNull);
      });
    });

    group('isNameValid', () {
      test('returns false for empty name', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);

        expect(notifier.isNameValid(''), false);
      });

      test('returns true for non-empty name', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);

        expect(notifier.isNameValid('Test Rule'), true);
      });
    });

    group('isDeviceIpValidate', () {
      test('returns true for IP in same subnet', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);
        notifier.init([], null, null, '192.168.1.1', '255.255.255.0');

        expect(notifier.isDeviceIpValidate('192.168.1.100'), true);
      });

      test('returns false for IP in different subnet', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);
        notifier.init([], null, null, '192.168.1.1', '255.255.255.0');

        expect(notifier.isDeviceIpValidate('192.168.2.100'), false);
      });

      test('returns false for invalid IP format', () {
        final notifier =
            container.read(singlePortForwardingRuleProvider.notifier);
        notifier.init([], null, null, '192.168.1.1', '255.255.255.0');

        expect(notifier.isDeviceIpValidate('invalid'), false);
      });
    });

    // Note: isRuleValid and isPortConflict tests are skipped because they
    // require complex cross-provider mocking that is difficult to set up
    // correctly with Riverpod. These methods should be tested through
    // integration tests instead.
  });
}
