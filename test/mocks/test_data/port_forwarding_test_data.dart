import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';

/// Test data builder for Port Forwarding tests.
class PortForwardingTestData {
  // ---------------------------------------------------------------------------
  // UI models
  // ---------------------------------------------------------------------------

  /// A saved single-port rule. [instancePath] is dot-terminated, matching what
  /// every generated layer emits, so `ruleIdentifierKey` fallbacks behave the
  /// same as in production.
  static PortForwardingRuleUIModel createRule({
    String? instancePath = 'Device.NAT.PortMapping.1.',
    String description = 'Web Server',
    int externalPort = 80,
    int externalPortEndRange = 0,
    int internalPort = 8080,
    String internalClient = '192.168.1.101',
    String protocol = 'TCP',
    bool enabled = true,
  }) =>
      PortForwardingRuleUIModel(
        instancePath: instancePath,
        description: description,
        externalPort: externalPort,
        externalPortEndRange: externalPortEndRange,
        internalPort: internalPort,
        internalClient: internalClient,
        protocol: protocol,
        enabled: enabled,
      );

  /// A saved port-range rule ([externalPortEndRange] > [externalPort]).
  static PortForwardingRuleUIModel createRangeRule({
    String? instancePath = 'Device.NAT.PortMapping.2.',
    String description = 'Game Ports',
    int externalPort = 27015,
    int externalPortEndRange = 27020,
    int internalPort = 27015,
    String internalClient = '192.168.1.102',
    String protocol = 'UDP',
    bool enabled = false,
  }) =>
      createRule(
        instancePath: instancePath,
        description: description,
        externalPort: externalPort,
        externalPortEndRange: externalPortEndRange,
        internalPort: internalPort,
        internalClient: internalClient,
        protocol: protocol,
        enabled: enabled,
      );

  /// One single-port rule and one range rule — both branches of the
  /// single-vs-range display split.
  static List<PortForwardingRuleUIModel> createRules() => [
        createRule(),
        createRangeRule(),
      ];

  // ---------------------------------------------------------------------------
  // PortForwardingData (L1)
  // ---------------------------------------------------------------------------

  static PortForwardingData createPortForwardingData({
    List<PortForwardingRuleUIModel>? ruleModels,
  }) =>
      PortForwardingData(ruleModels: ruleModels ?? createRules());
}
