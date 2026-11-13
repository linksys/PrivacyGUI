import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';

/// Test data builder for IPv6 Port Service tests.
class Ipv6PortServiceTestData {
  /// A saved IPv6 port service rule (a `Defaults Configuration` chain rule with
  /// IPVersion 6 and Target Accept).
  static Ipv6PortServiceRuleUIModel createRule({
    String? instancePath = 'Device.Firewall.Chain.3.Rule.40.',
    bool enabled = true,
    String description = 'NAS',
    String ipv6Address = '2001:db8::10',
    String protocol = 'TCP',
    int startPort = 443,
    int endPort = 443,
  }) =>
      Ipv6PortServiceRuleUIModel(
        instancePath: instancePath,
        enabled: enabled,
        description: description,
        ipv6Address: ipv6Address,
        protocol: protocol,
        startPort: startPort,
        endPort: endPort,
      );
}
