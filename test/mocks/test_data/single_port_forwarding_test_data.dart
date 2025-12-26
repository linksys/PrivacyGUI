import 'package:privacy_gui/core/jnap/models/single_port_forwarding_rule.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';

/// Test data builder for SinglePortForwardingService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class SinglePortForwardingTestData {
  /// Create default LAN Settings success response
  static JNAPSuccess createLANSettingsSuccess({
    String ipAddress = '192.168.1.1',
    int networkPrefixLength = 24,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'ipAddress': ipAddress,
          'networkPrefixLength': networkPrefixLength,
          'minNetworkPrefixLength': 8,
          'maxNetworkPrefixLength': 30,
          'minAllowedDHCPLeaseMinutes': 1,
          'hostName': 'linksys',
          'maxDHCPReservationDescriptionLength': 32,
          'isDHCPEnabled': true,
          'dhcpSettings': {
            'lastClientIPAddress': '192.168.1.254',
            'leaseMinutes': 1440,
            'reservations': [],
            'firstClientIPAddress': '192.168.1.100',
          },
        },
      );

  /// Create default Single Port Forwarding Rules success response
  static JNAPSuccess createRulesSuccess({
    List<Map<String, dynamic>>? rules,
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'rules': rules ?? [_createDefaultRuleMap()],
          'maxRules': maxRules,
          'maxDescriptionLength': maxDescriptionLength,
        },
      );

  /// Create a JNAP error response
  static JNAPError createJNAPError({
    String result = '_ErrorUnknown',
    String error = 'Unknown error',
  }) =>
      JNAPError(result: result, error: error);

  /// Create a single JNAP rule (Data Model)
  static SinglePortForwardingRule createJNAPRule({
    bool isEnabled = true,
    int externalPort = 8080,
    String protocol = 'TCP',
    String internalServerIPAddress = '192.168.1.100',
    int internalPort = 8080,
    String description = 'Test Rule',
  }) =>
      SinglePortForwardingRule(
        isEnabled: isEnabled,
        externalPort: externalPort,
        protocol: protocol,
        internalServerIPAddress: internalServerIPAddress,
        internalPort: internalPort,
        description: description,
      );

  /// Create a single UI Model rule
  static SinglePortForwardingRuleUIModel createUIRule({
    bool isEnabled = true,
    int externalPort = 8080,
    String protocol = 'TCP',
    String internalServerIPAddress = '192.168.1.100',
    int internalPort = 8080,
    String description = 'Test Rule',
  }) =>
      SinglePortForwardingRuleUIModel(
        isEnabled: isEnabled,
        externalPort: externalPort,
        protocol: protocol,
        internalServerIPAddress: internalServerIPAddress,
        internalPort: internalPort,
        description: description,
      );

  /// Create a list of JNAP rules
  static List<SinglePortForwardingRule> createJNAPRuleList({
    int count = 3,
  }) =>
      List.generate(
        count,
        (index) => createJNAPRule(
          externalPort: 8080 + index,
          internalPort: 8080 + index,
          description: 'Test Rule ${index + 1}',
        ),
      );

  /// Create a list of UI Model rules
  static List<SinglePortForwardingRuleUIModel> createUIRuleList({
    int count = 3,
  }) =>
      List.generate(
        count,
        (index) => createUIRule(
          externalPort: 8080 + index,
          internalPort: 8080 + index,
          description: 'Test Rule ${index + 1}',
        ),
      );

  // Private helper to create a default rule map
  static Map<String, dynamic> _createDefaultRuleMap() => {
        'isEnabled': true,
        'externalPort': 8080,
        'protocol': 'TCP',
        'internalServerIPAddress': '192.168.1.100',
        'internalPort': 8080,
        'description': 'Test Rule',
      };
}
