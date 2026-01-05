import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('Ipv6PortServiceListStatus', () {
    test('creates instance with default values', () {
      const status = Ipv6PortServiceListStatus();
      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
    });

    test('creates instance with custom values', () {
      const status =
          Ipv6PortServiceListStatus(maxRules: 100, maxDescriptionLength: 64);
      expect(status.maxRules, 100);
      expect(status.maxDescriptionLength, 64);
    });

    test('copyWith updates specified fields', () {
      const status = Ipv6PortServiceListStatus();
      final updated = status.copyWith(maxRules: 75);
      expect(updated.maxRules, 75);
      expect(updated.maxDescriptionLength, 32);
    });

    test('toMap/fromMap serialization works', () {
      const original =
          Ipv6PortServiceListStatus(maxRules: 100, maxDescriptionLength: 64);
      final map = original.toMap();
      final restored = Ipv6PortServiceListStatus.fromMap(map);
      expect(restored, original);
    });

    test('toJson/fromJson serialization works', () {
      const original = Ipv6PortServiceListStatus(maxRules: 100);
      final json = original.toJson();
      final restored = Ipv6PortServiceListStatus.fromJson(json);
      expect(restored, original);
    });

    test('equality comparison works', () {
      const status1 = Ipv6PortServiceListStatus(maxRules: 100);
      const status2 = Ipv6PortServiceListStatus(maxRules: 100);
      const status3 = Ipv6PortServiceListStatus(maxRules: 75);
      expect(status1, status2);
      expect(status1, isNot(status3));
    });
  });

  group('Ipv6PortServiceListState', () {
    test('creates instance with preservable settings', () {
      const rule = IPv6PortServiceRuleUI(
        enabled: true,
        description: 'Test',
        ipv6Address: '2001:db8::1',
        portRanges: [PortRangeUI(protocol: 'TCP', firstPort: 80, lastPort: 80)],
      );
      const settings = IPv6PortServiceRuleUIList(rules: [rule]);
      const status = Ipv6PortServiceListStatus();
      const state = Ipv6PortServiceListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      expect(state.settings.original, settings);
      expect(state.status, status);
    });

    test('copyWith updates specified fields', () {
      const settings = IPv6PortServiceRuleUIList(rules: []);
      const status1 = Ipv6PortServiceListStatus(maxRules: 50);
      const status2 = Ipv6PortServiceListStatus(maxRules: 100);
      const state = Ipv6PortServiceListState(
        settings: Preservable(original: settings, current: settings),
        status: status1,
      );
      final updated = state.copyWith(status: status2);
      expect(updated.status, status2);
    });

    test('toMap/fromMap serialization works', () {
      const settings = IPv6PortServiceRuleUIList(rules: []);
      const status = Ipv6PortServiceListStatus();
      const original = Ipv6PortServiceListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      final map = original.toMap();
      final restored = Ipv6PortServiceListState.fromMap(map);
      expect(restored.status.maxRules, 50);
    });

    test('toJson/fromJson serialization works', () {
      const settings = IPv6PortServiceRuleUIList(rules: []);
      const status = Ipv6PortServiceListStatus();
      const original = Ipv6PortServiceListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      final json = original.toJson();
      final restored = Ipv6PortServiceListState.fromJson(json);
      expect(restored.status.maxRules, 50);
    });

    test('equality comparison works', () {
      const settings = IPv6PortServiceRuleUIList(rules: []);
      const status = Ipv6PortServiceListStatus();
      const state1 = Ipv6PortServiceListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      const state2 = Ipv6PortServiceListState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );
      expect(state1, state2);
    });
  });
}
