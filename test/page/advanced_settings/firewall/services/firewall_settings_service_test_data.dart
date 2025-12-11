import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for FirewallSettingsService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
/// Follows constitution v2.2 Section 6: Test Data Builder Pattern
class FirewallSettingsTestData {
  /// Create successful JNAP response with default firewall settings
  ///
  /// Default represents typical configuration: all firewall options disabled
  /// Returns JNAPSuccess matching the JNAP protocol structure
  ///
  /// Usage:
  /// ```dart
  /// final response = FirewallSettingsTestData.createSuccessfulResponse();
  /// ```
  static JNAPSuccess createSuccessfulResponse({
    bool blockAnonymousRequests = false,
    bool blockIDENT = false,
    bool blockIPSec = false,
    bool blockL2TP = false,
    bool blockMulticast = false,
    bool blockNATRedirection = false,
    bool blockPPTP = false,
    bool isIPv4FirewallEnabled = false,
    bool isIPv6FirewallEnabled = false,
  }) =>
      JNAPSuccess(
        result: 'OK',
        output: {
          'blockAnonymousRequests': blockAnonymousRequests,
          'blockIDENT': blockIDENT,
          'blockIPSec': blockIPSec,
          'blockL2TP': blockL2TP,
          'blockMulticast': blockMulticast,
          'blockNATRedirection': blockNATRedirection,
          'blockPPTP': blockPPTP,
          'isIPv4FirewallEnabled': isIPv4FirewallEnabled,
          'isIPv6FirewallEnabled': isIPv6FirewallEnabled,
        },
      );

  /// Create response with custom settings using partial override pattern
  ///
  /// Allows overriding specific fields while maintaining sensible defaults.
  /// Useful for testing specific configurations without repeating all fields.
  ///
  /// Usage:
  /// ```dart
  /// final response = FirewallSettingsTestData.createResponseWithCustomSettings(
  ///   isIPv4FirewallEnabled: true,
  ///   blockAnonymousRequests: true,
  /// );
  /// ```
  static JNAPSuccess createResponseWithCustomSettings({
    bool? blockAnonymousRequests,
    bool? blockIDENT,
    bool? blockIPSec,
    bool? blockL2TP,
    bool? blockMulticast,
    bool? blockNATRedirection,
    bool? blockPPTP,
    bool? isIPv4FirewallEnabled,
    bool? isIPv6FirewallEnabled,
  }) =>
      createSuccessfulResponse(
        blockAnonymousRequests: blockAnonymousRequests ?? false,
        blockIDENT: blockIDENT ?? false,
        blockIPSec: blockIPSec ?? false,
        blockL2TP: blockL2TP ?? false,
        blockMulticast: blockMulticast ?? false,
        blockNATRedirection: blockNATRedirection ?? false,
        blockPPTP: blockPPTP ?? false,
        isIPv4FirewallEnabled: isIPv4FirewallEnabled ?? false,
        isIPv6FirewallEnabled: isIPv6FirewallEnabled ?? false,
      );

  /// Create JNAP error response for error handling tests
  ///
  /// Returns JNAPError to simulate various failure scenarios
  ///
  /// Usage:
  /// ```dart
  /// final response = FirewallSettingsTestData.createErrorResponse(
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

  /// Create response with all firewall protections enabled
  ///
  /// Represents maximum security configuration
  static JNAPSuccess createFullyEnabledResponse() => createSuccessfulResponse(
        blockAnonymousRequests: true,
        blockIDENT: true,
        blockIPSec: true,
        blockL2TP: true,
        blockMulticast: true,
        blockNATRedirection: true,
        blockPPTP: true,
        isIPv4FirewallEnabled: true,
        isIPv6FirewallEnabled: true,
      );

  /// Create response with IPv4 firewall enabled only
  ///
  /// Represents common configuration: IPv4 firewall with basic blocking
  static JNAPSuccess createIPv4EnabledResponse() => createSuccessfulResponse(
        isIPv4FirewallEnabled: true,
        blockAnonymousRequests: true,
      );

  /// Create response with IPv6 firewall enabled only
  ///
  /// Represents IPv6-focused configuration
  static JNAPSuccess createIPv6EnabledResponse() => createSuccessfulResponse(
        isIPv6FirewallEnabled: true,
        blockMulticast: true,
      );

  /// Create response with protocol blocking enabled
  ///
  /// Represents configuration blocking specific protocols (VPN, tunneling)
  static JNAPSuccess createProtocolBlockingResponse() =>
      createSuccessfulResponse(
        blockIPSec: true,
        blockL2TP: true,
        blockPPTP: true,
      );

  /// Create response with incomplete data (missing fields)
  ///
  /// Used to test parsing error handling when JNAP returns incomplete data
  static Map<String, dynamic> createIncompleteOutput() => {
        'blockAnonymousRequests': false,
        'blockIDENT': false,
        // Missing other required fields
      };
}
