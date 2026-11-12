import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/firewall/models/firewall_card_summary.dart';
import 'package:privacy_gui/page/firewall/models/firewall_verdict.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';

import '../../../mocks/test_data/firewall_test_data.dart';
import '../../../mocks/test_data/ipv6_port_service_test_data.dart';
import '../../../mocks/test_data/port_forwarding_test_data.dart';

/// What the dashboard's Firewall card shows, rule by rule from #1130's 11-09
/// and 11-12 comments.
void main() {
  FirewallData firewall({
    bool ipv4 = true,
    bool ipv6 = true,
    DmzUIModel? dmz,
  }) =>
      FirewallTestData.createFirewallData(
        firewallModel: FirewallTestData.createFirewallUIModel(
          isIPv4FirewallEnabled: ipv4,
          isIPv6FirewallEnabled: ipv6,
        ),
        dmzModel: dmz ?? FirewallTestData.createDmzUIModel(),
      );

  final on = PortForwardingTestData.createRule(enabled: true);
  final off = PortForwardingTestData.createRule(enabled: false);
  final triggerOn = PortForwardingTestData.createTriggerRule(enabled: true);
  final triggerOff = PortForwardingTestData.createTriggerRule(enabled: false);

  /// A new router: SPI on, DMZ off, no port rules, UPnP on.
  FirewallCardSummary summary({
    FirewallData? data,
    List<PortForwardingRuleUIModel>? forwarding = const [],
    List<PortTriggeringRuleUIModel>? triggering = const [],
    List<Ipv6PortServiceRuleUIModel>? ipv6 = const [],
    bool? upnp = true,
  }) =>
      FirewallCardSummary.of(
        firewall: data ?? firewall(),
        forwardingRules: forwarding,
        triggeringRules: triggering,
        ipv6PortServiceRules: ipv6,
        upnpEnabled: upnp,
      );

  group('badge', () {
    test('is the shared verdict: IPv4 SPI off with DMZ on is At Risk', () {
      final s = summary(
        data: firewall(
          ipv4: false,
          dmz: FirewallTestData.createEnabledDmzUIModel(),
        ),
      );

      expect(s.verdict, FirewallVerdict.atRisk);
    });
  });

  group('SPI firewall row', () {
    test('is absent while both SPI firewalls are on', () {
      expect(summary().spiOff, isNull);
    });

    test('says which one is off', () {
      expect(summary(data: firewall(ipv4: false)).spiOff, SpiOff.ipv4);
      expect(summary(data: firewall(ipv6: false)).spiOff, SpiOff.ipv6);
      expect(
        summary(data: firewall(ipv4: false, ipv6: false)).spiOff,
        SpiOff.both,
      );
    });
  });

  group('DMZ row', () {
    test('is off when the DMZ page has it off', () {
      final s = summary();

      expect(s.dmzOn, isFalse);
    });

    test('names the host by IP', () {
      final s = summary(
        data: firewall(
          dmz: FirewallTestData.createDmzUIModel(
            isEnabled: true,
            destIp: '192.168.1.50',
          ),
        ),
      );

      expect(s.dmzOn, isTrue);
      expect(s.dmzHost, '192.168.1.50');
    });

    test('names the host by MAC when the DMZ page gives it by MAC', () {
      final s = summary(
        data: firewall(
          dmz: FirewallTestData.createDmzUIModel(
            isEnabled: true,
            destinationType: DmzDestinationType.mac,
            destIp: '192.168.1.50',
            destMac: 'AA:BB:CC:DD:EE:01',
          ),
        ),
      );

      expect(s.dmzHost, 'AA:BB:CC:DD:EE:01');
    });
  });

  group('Port Forwarding row', () {
    test('counts the rules that are on, on all three tabs', () {
      final s = summary(
        forwarding: [on, on, off],
        triggering: [triggerOn, triggerOff],
      );

      expect(s.portRules, (on: 3, total: 5));
    });

    test('is unknown until both forwarding and triggering are read', () {
      expect(summary(forwarding: null).portRules, isNull);
      expect(summary(triggering: null).portRules, isNull);
    });
  });

  group('UPnP row', () {
    test('shows what the Administration page shows', () {
      expect(summary(upnp: true).upnpOn, isTrue);
      expect(summary(upnp: false).upnpOn, isFalse);
    });

    test('is unknown until it is read', () {
      expect(summary(upnp: null).upnpOn, isNull);
    });
  });

  group('"nothing opened" sentence', () {
    test('shows on a new router, with UPnP on', () {
      expect(summary(upnp: true).nothingOpen, isTrue);
    });

    test('shows when every port rule is off', () {
      final s = summary(forwarding: [off], triggering: [triggerOff]);

      expect(s.nothingOpen, isTrue);
    });

    test('is hidden by a port rule that is on, triggering included', () {
      expect(summary(forwarding: [on]).nothingOpen, isFalse);
      expect(summary(triggering: [triggerOn]).nothingOpen, isFalse);
    });

    test('is hidden by DMZ on', () {
      final s = summary(
        data: firewall(dmz: FirewallTestData.createEnabledDmzUIModel()),
      );

      expect(s.nothingOpen, isFalse);
    });

    test('is hidden by either SPI firewall off', () {
      expect(summary(data: firewall(ipv4: false)).nothingOpen, isFalse);
      expect(summary(data: firewall(ipv6: false)).nothingOpen, isFalse);
    });

    test('is not claimed while the port rules are unknown', () {
      expect(summary(forwarding: null).nothingOpen, isFalse);
    });

    // An IPv6 port service rule lets IPv6 connections from the internet reach
    // a device in the home, so it opens that device as much as port forwarding
    // does (PR #1806 review).
    test('is hidden by an IPv6 Port Service rule that is on', () {
      final s = summary(ipv6: [Ipv6PortServiceTestData.createRule()]);

      expect(s.nothingOpen, isFalse);
    });

    test('shows when every IPv6 Port Service rule is off', () {
      final s = summary(
        ipv6: [Ipv6PortServiceTestData.createRule(enabled: false)],
      );

      expect(s.nothingOpen, isTrue);
    });

    test('is not claimed while the IPv6 rules are unknown', () {
      expect(summary(ipv6: null).nothingOpen, isFalse);
    });
  });
}
