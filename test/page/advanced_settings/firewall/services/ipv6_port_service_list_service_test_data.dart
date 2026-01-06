import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/ipv6_port_service_rule_state.dart';

/// Test data builder for IPv6PortServiceListService tests
///
/// Provides factory methods to create JNAP mock responses and UI models with sensible defaults.
/// This centralizes test data and makes tests more readable.
/// Follows constitution v2.2 Section 6: Test Data Builder Pattern
class IPv6PortServiceTestData {
  /// Create successful JNAP response with empty rules list
  ///
  /// Default represents typical initial state: no rules configured
  /// Returns JNAPSuccess matching the JNAP protocol structure
  ///
  /// Usage:
  /// ```dart
  /// final response = IPv6PortServiceTestData.createEmptyResponse();
  /// ```
  static JNAPSuccess createEmptyResponse({
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'rules': const [],
          'maxRules': maxRules,
          'maxDescriptionLength': maxDescriptionLength,
        },
      );

  /// Create successful JNAP response with single rule
  ///
  /// Default represents typical configuration: one port forwarding rule
  /// Returns JNAPSuccess matching the JNAP protocol structure
  ///
  /// Usage:
  /// ```dart
  /// final response = IPv6PortServiceTestData.createSingleRuleResponse();
  /// ```
  static JNAPSuccess createSingleRuleResponse({
    String description = 'Web Server',
    String ipv6Address = '2001:db8::1',
    bool isEnabled = true,
    String protocol = 'TCP',
    int firstPort = 80,
    int lastPort = 80,
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'rules': [
            {
              'description': description,
              'ipv6Address': ipv6Address,
              'isEnabled': isEnabled,
              'portRanges': [
                {
                  'protocol': protocol,
                  'firstPort': firstPort,
                  'lastPort': lastPort,
                },
              ],
            },
          ],
          'maxRules': maxRules,
          'maxDescriptionLength': maxDescriptionLength,
        },
      );

  /// Create successful JNAP response with multiple rules
  ///
  /// Represents typical production scenario: several port forwarding rules
  /// Returns JNAPSuccess matching the JNAP protocol structure
  ///
  /// Usage:
  /// ```dart
  /// final response = IPv6PortServiceTestData.createMultipleRulesResponse();
  /// ```
  static JNAPSuccess createMultipleRulesResponse({
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'rules': const [
            {
              'description': 'Web Server',
              'ipv6Address': '2001:db8::1',
              'isEnabled': true,
              'portRanges': [
                {
                  'protocol': 'TCP',
                  'firstPort': 80,
                  'lastPort': 80,
                },
              ],
            },
            {
              'description': 'HTTPS Server',
              'ipv6Address': '2001:db8::1',
              'isEnabled': true,
              'portRanges': [
                {
                  'protocol': 'TCP',
                  'firstPort': 443,
                  'lastPort': 443,
                },
              ],
            },
            {
              'description': 'Game Server',
              'ipv6Address': '2001:db8::2',
              'isEnabled': false,
              'portRanges': [
                {
                  'protocol': 'UDP',
                  'firstPort': 7777,
                  'lastPort': 7777,
                },
              ],
            },
          ],
          'maxRules': maxRules,
          'maxDescriptionLength': maxDescriptionLength,
        },
      );

  /// Create successful JNAP response with port range rule
  ///
  /// Represents rule with port range (not single port)
  /// Returns JNAPSuccess matching the JNAP protocol structure
  ///
  /// Usage:
  /// ```dart
  /// final response = IPv6PortServiceTestData.createPortRangeResponse();
  /// ```
  static JNAPSuccess createPortRangeResponse({
    String description = 'Gaming Ports',
    String ipv6Address = '2001:db8::3',
    bool isEnabled = true,
    String protocol = 'Both',
    int firstPort = 27000,
    int lastPort = 27100,
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'rules': [
            {
              'description': description,
              'ipv6Address': ipv6Address,
              'isEnabled': isEnabled,
              'portRanges': [
                {
                  'protocol': protocol,
                  'firstPort': firstPort,
                  'lastPort': lastPort,
                },
              ],
            },
          ],
          'maxRules': maxRules,
          'maxDescriptionLength': maxDescriptionLength,
        },
      );

  /// Create JNAP error response for error handling tests
  ///
  /// Returns JNAPError to simulate various failure scenarios
  ///
  /// Usage:
  /// ```dart
  /// final response = IPv6PortServiceTestData.createErrorResponse(
  ///   errorMessage: 'Network timeout',
  /// );
  /// ```
  static JNAPError createErrorResponse({
    String errorMessage = 'Operation failed',
  }) =>
      JNAPError(
        result: 'ERROR',
        error: errorMessage,
      );

  /// Create UI model for testing
  ///
  /// Returns IPv6PortServiceRuleUI with sensible defaults
  ///
  /// Usage:
  /// ```dart
  /// final rule = IPv6PortServiceTestData.createUIRule();
  /// ```
  static IPv6PortServiceRuleUI createUIRule({
    String description = 'Web Server',
    String ipv6Address = '2001:db8::1',
    bool enabled = true,
    List<PortRangeUI>? portRanges,
  }) =>
      IPv6PortServiceRuleUI(
        description: description,
        ipv6Address: ipv6Address,
        enabled: enabled,
        portRanges: portRanges ??
            [
              const PortRangeUI(
                protocol: 'TCP',
                firstPort: 80,
                lastPort: 80,
              ),
            ],
      );

  /// Create list of UI rules for testing
  ///
  /// Returns IPv6PortServiceRuleUIList with typical configuration
  ///
  /// Usage:
  /// ```dart
  /// final rules = IPv6PortServiceTestData.createUIRuleList();
  /// ```
  static IPv6PortServiceRuleUIList createUIRuleList() =>
      IPv6PortServiceRuleUIList(rules: [
        createUIRule(
          description: 'Web Server',
          ipv6Address: '2001:db8::1',
          enabled: true,
          portRanges: [
            const PortRangeUI(
              protocol: 'TCP',
              firstPort: 80,
              lastPort: 80,
            ),
          ],
        ),
        createUIRule(
          description: 'HTTPS Server',
          ipv6Address: '2001:db8::1',
          enabled: true,
          portRanges: [
            const PortRangeUI(
              protocol: 'TCP',
              firstPort: 443,
              lastPort: 443,
            ),
          ],
        ),
        createUIRule(
          description: 'Game Server',
          ipv6Address: '2001:db8::2',
          enabled: false,
          portRanges: [
            const PortRangeUI(
              protocol: 'UDP',
              firstPort: 7777,
              lastPort: 7777,
            ),
          ],
        ),
      ]);

  /// Create response with incomplete data (missing fields)
  ///
  /// Used to test parsing error handling when JNAP returns incomplete data
  static Map<String, dynamic> createIncompleteOutput() => {
        'rules': [
          {
            'description': 'Incomplete',
            'ipv6Address': '2001:db8::1',
            // Missing isEnabled and portRanges
          },
        ],
        'maxRules': 50,
      };

  /// Create response at max rules capacity
  ///
  /// Used to test max rules validation
  static JNAPSuccess createMaxRulesResponse({
    int maxRules = 50,
  }) {
    final rules = List.generate(
      maxRules,
      (index) => {
        'description': 'Rule $index',
        'ipv6Address': '2001:db8::$index',
        'isEnabled': true,
        'portRanges': [
          {
            'protocol': 'TCP',
            'firstPort': 1000 + index,
            'lastPort': 1000 + index,
          },
        ],
      },
    );

    return JNAPSuccess(
      result: 'OK',
      output: {
        'rules': rules,
        'maxRules': maxRules,
        'maxDescriptionLength': 32,
      },
    );
  }

  /// Create response with custom settings using partial override pattern
  ///
  /// Allows overriding specific fields while maintaining sensible defaults.
  /// Useful for testing specific configurations without repeating all fields.
  ///
  /// Usage:
  /// ```dart
  /// final response = IPv6PortServiceTestData.createCustomResponse(
  ///   maxRules: 100,
  ///   maxDescriptionLength: 64,
  /// );
  /// ```
  static JNAPSuccess createCustomResponse({
    List<Map<String, dynamic>>? rules,
    int? maxRules,
    int? maxDescriptionLength,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'rules': rules ?? [],
          'maxRules': maxRules ?? 50,
          'maxDescriptionLength': maxDescriptionLength ?? 32,
        },
      );
}
