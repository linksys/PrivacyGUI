import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_feature_state.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_rule_list.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

const testRules = [
  Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.26.',
    enabled: true,
    description: 'Web Server',
    ipv6Address: '2001:db8::1',
    protocol: 'TCP',
    startPort: 80,
    endPort: 80,
  ),
  Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.27.',
    enabled: true,
    description: 'Game Console',
    ipv6Address: '2001:db8::2',
    protocol: 'Both',
    startPort: 3000,
    endPort: 3100,
  ),
  Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.28.',
    enabled: false,
    description: 'SSH Access',
    ipv6Address: '2001:db8::3',
    protocol: 'TCP',
    startPort: 22,
    endPort: 22,
  ),
];

Ipv6PortServiceFeatureState dataState({
  List<Ipv6PortServiceRuleUIModel> rules = testRules,
}) {
  final settings = Ipv6PortServiceRuleList(rules: rules);
  return Ipv6PortServiceFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const Ipv6PortServiceStatus(),
  );
}

Ipv6PortServiceFeatureState dirtyState() {
  const original = Ipv6PortServiceRuleList(rules: testRules);
  final current = Ipv6PortServiceRuleList(
    rules: const [
      ...testRules,
      Ipv6PortServiceRuleUIModel(
        enabled: true,
        description: 'New Rule',
        ipv6Address: '2001:db8::ff',
        protocol: 'UDP',
        startPort: 8080,
        endPort: 8080,
      ),
    ],
  );
  return Ipv6PortServiceFeatureState(
    settings: Preservable(original: original, current: current),
    status: const Ipv6PortServiceStatus(),
  );
}

Ipv6PortServiceFeatureState emptyState() {
  const settings = Ipv6PortServiceRuleList();
  return const Ipv6PortServiceFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: Ipv6PortServiceStatus(),
  );
}
