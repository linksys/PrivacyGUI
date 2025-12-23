import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for Port Range Forwarding Service tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class PortRangeForwardingTestData {
  /// Create a default single rule (Xbox Live example)
  static Map<String, dynamic> createDefaultRule({
    bool isEnabled = true,
    int firstExternalPort = 3074,
    String protocol = 'TCP',
    String internalServerIPAddress = '192.168.1.100',
    int? lastExternalPort,
    String description = 'XBox Live',
  }) {
    return {
      'isEnabled': isEnabled,
      'firstExternalPort': firstExternalPort,
      'protocol': protocol,
      'internalServerIPAddress': internalServerIPAddress,
      'lastExternalPort': lastExternalPort ?? firstExternalPort,
      'description': description,
    };
  }

  /// Create a port range rule (multiple ports)
  static Map<String, dynamic> createPortRangeRule({
    bool isEnabled = true,
    int firstExternalPort = 8000,
    int lastExternalPort = 8100,
    String protocol = 'Both',
    String internalServerIPAddress = '192.168.1.200',
    String description = 'Media Server',
  }) {
    return {
      'isEnabled': isEnabled,
      'firstExternalPort': firstExternalPort,
      'protocol': protocol,
      'internalServerIPAddress': internalServerIPAddress,
      'lastExternalPort': lastExternalPort,
      'description': description,
    };
  }

  /// Create a disabled rule
  static Map<String, dynamic> createDisabledRule() {
    return createDefaultRule(
      isEnabled: false,
      description: 'Disabled Rule',
    );
  }

  /// Create default GetPortRangeForwardingRules success response
  static JNAPSuccess createGetRulesSuccess({
    List<Map<String, dynamic>>? rules,
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'rules': rules ??
            [
              createDefaultRule(),
              createPortRangeRule(),
            ],
        'maxRules': maxRules,
        'maxDescriptionLength': maxDescriptionLength,
      },
    );
  }

  /// Create empty rules response
  static JNAPSuccess createEmptyRulesSuccess({
    int maxRules = 50,
    int maxDescriptionLength = 32,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'rules': [],
        'maxRules': maxRules,
        'maxDescriptionLength': maxDescriptionLength,
      },
    );
  }

  /// Create GetLANSettings success response
  static JNAPSuccess createGetLANSettingsSuccess({
    String ipAddress = '192.168.1.1',
    int networkPrefixLength = 24,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: <String, dynamic>{
        'ipAddress': ipAddress,
        'networkPrefixLength': networkPrefixLength,
        'isDHCPEnabled': true,
        'minNetworkPrefixLength': 8,
        'maxNetworkPrefixLength': 30,
        'minAllowedDHCPLeaseMinutes': 1,
        'maxAllowedDHCPLeaseMinutes': 10080,
        'maxDHCPReservationDescriptionLength': 32,
        'hostName': 'Linksys',
        'dhcpSettings': <String, dynamic>{
          'firstClientIPAddress': '192.168.1.100',
          'lastClientIPAddress': '192.168.1.200',
          'leaseMinutes': 1440,
          'reservations': const <Map<String, dynamic>>[],
        },
      },
    );
  }

  /// Create SetPortRangeForwardingRules success response
  static JNAPSuccess createSetRulesSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: <String, dynamic>{},
    );
  }

  /// Create JNAP error response for invalid IP address
  static JNAPError createInvalidIPAddressError() {
    return const JNAPError(
      result: 'ErrorInvalidIPAddress',
      error: 'The IP address is invalid',
    );
  }

  /// Create JNAP error response for invalid destination IP address
  static JNAPError createInvalidDestinationIPAddressError() {
    return const JNAPError(
      result: 'ErrorInvalidDestinationIPAddress',
      error: 'The destination IP address is invalid',
    );
  }

  /// Create JNAP error response for rule overlap
  static JNAPError createRuleOverlapError() {
    return const JNAPError(
      result: 'ErrorRuleOverlap',
      error: 'Port forwarding rules overlap',
    );
  }

  /// Create JNAP error response for unauthorized access
  static JNAPError createUnauthorizedError() {
    return const JNAPError(
      result: '_ErrorUnauthorized',
      error: 'Unauthorized access',
    );
  }

  /// Create JNAP error response for invalid input
  static JNAPError createInvalidInputError({String? message}) {
    return JNAPError(
      result: 'ErrorInvalidInput',
      error: message ?? 'Invalid input data',
    );
  }

  /// Create a complete successful JNAP transaction response
  ///
  /// Supports partial override design: only specify fields that need to change
  static JNAPTransactionSuccessWrap createSuccessfulTransaction({
    Map<String, dynamic>? lanSettings,
    Map<String, dynamic>? portRules,
  }) {
    final defaultLANSettings = {
      'ipAddress': '192.168.1.1',
      'networkPrefixLength': 24,
      'dhcpEnabled': true,
    };

    final defaultPortRules = {
      'rules': [
        createDefaultRule(),
      ],
      'maxRules': 50,
      'maxDescriptionLength': 32,
    };

    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.getLANSettings,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultLANSettings, ...?lanSettings},
          ),
        ),
        MapEntry(
          JNAPAction.getPortRangeForwardingRules,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultPortRules, ...?portRules},
          ),
        ),
      ],
    );
  }

  /// Create a partial error transaction (for error handling tests)
  static JNAPTransactionSuccessWrap createPartialErrorTransaction({
    required JNAPAction errorAction,
    String errorMessage = 'Operation failed',
  }) {
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.getLANSettings,
          createGetLANSettingsSuccess(),
        ),
        MapEntry(
          errorAction,
          JNAPError(
            result: 'Error',
            error: errorMessage,
          ),
        ),
      ],
    );
  }
}