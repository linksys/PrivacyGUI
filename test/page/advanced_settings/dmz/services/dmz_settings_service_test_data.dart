import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for DMZSettingsService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
/// Follows constitution v2.2 Section 6: Test Data Builder Pattern
class DMZSettingsTestData {
  /// Create default LANSettings response
  ///
  /// Default represents typical configuration: 192.168.1.0/24 network
  static JNAPSuccess createLANSettingsSuccess({
    String ipAddress = '192.168.1.1',
    int networkPrefixLength = 24,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'ipAddress': ipAddress,
          'networkPrefixLength': networkPrefixLength,
        },
      );

  /// Create default DMZSettings response
  ///
  /// Default represents typical disabled DMZ configuration
  static JNAPSuccess createDMZSettingsSuccess({
    bool isDMZEnabled = false,
    String? destinationIPAddress,
    String? destinationMACAddress,
    Map<String, dynamic>? sourceRestriction,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'isDMZEnabled': isDMZEnabled,
          if (destinationIPAddress != null)
            'destinationIPAddress': destinationIPAddress,
          if (destinationMACAddress != null)
            'destinationMACAddress': destinationMACAddress,
          if (sourceRestriction != null) 'sourceRestriction': sourceRestriction,
        },
      );

  /// Create a complete successful JNAP transaction response
  ///
  /// Combines getLANSettings and getDMZSettings responses with partial override pattern.
  /// Sensible defaults represent "typical device" state (DMZ disabled, standard network).
  ///
  /// Usage:
  /// ```dart
  /// final response = DMZSettingsTestData.createSuccessfulTransaction(
  ///   isDMZEnabled: true,
  ///   destinationIPAddress: '192.168.1.100',
  /// );
  /// ```
  static JNAPTransactionSuccessWrap createSuccessfulTransaction({
    String lanIPAddress = '192.168.1.1',
    int lanNetworkPrefixLength = 24,
    bool isDMZEnabled = false,
    String? destinationIPAddress,
    String? destinationMACAddress,
    Map<String, dynamic>? sourceRestriction,
  }) {
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.getLANSettings,
          createLANSettingsSuccess(
            ipAddress: lanIPAddress,
            networkPrefixLength: lanNetworkPrefixLength,
          ),
        ),
        MapEntry(
          JNAPAction.getDMZSettings,
          createDMZSettingsSuccess(
            isDMZEnabled: isDMZEnabled,
            destinationIPAddress: destinationIPAddress,
            destinationMACAddress: destinationMACAddress,
            sourceRestriction: sourceRestriction,
          ),
        ),
      ],
    );
  }

  /// Create a partial error response for error handling tests
  ///
  /// Returns a transaction with getLANSettings success but getDMZSettings failure
  /// Usage:
  /// ```dart
  /// final response = DMZSettingsTestData.createPartialErrorTransaction(
  ///   errorAction: JNAPAction.getDMZSettings,
  /// );
  /// ```
  static JNAPTransactionSuccessWrap createPartialErrorTransaction({
    required JNAPAction errorAction,
    String errorMessage = 'Operation failed',
  }) {
    final data = <MapEntry<JNAPAction, JNAPResult>>[];

    // Always include successful LAN settings
    data.add(
      MapEntry(
        JNAPAction.getLANSettings,
        createLANSettingsSuccess(),
      ),
    );

    // Add error for requested action
    if (errorAction == JNAPAction.getDMZSettings) {
      data.add(
        MapEntry(
          JNAPAction.getDMZSettings,
          JNAPError(
            result: 'error',
            error: errorMessage,
          ),
        ),
      );
    }

    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: data,
    );
  }

  /// Create a response with enabled DMZ and IP destination
  ///
  /// Represents common use case: DMZ enabled targeting specific IP address
  static JNAPTransactionSuccessWrap createEnabledDMZWithIP({
    String destinationIP = '192.168.1.100',
  }) =>
      createSuccessfulTransaction(
        isDMZEnabled: true,
        destinationIPAddress: destinationIP,
      );

  /// Create a response with enabled DMZ and MAC destination
  ///
  /// Represents use case: DMZ enabled targeting specific MAC address
  static JNAPTransactionSuccessWrap createEnabledDMZWithMAC({
    String destinationMac = '00:11:22:33:44:55',
  }) =>
      createSuccessfulTransaction(
        isDMZEnabled: true,
        destinationMACAddress: destinationMac,
      );

  /// Create a response with source IP range restriction
  ///
  /// Represents use case: DMZ with source IP restriction
  static JNAPTransactionSuccessWrap createDMZWithSourceRestriction({
    String firstIPAddress = '192.168.1.50',
    String lastIPAddress = '192.168.1.99',
    String destinationIP = '192.168.1.100',
  }) =>
      createSuccessfulTransaction(
        isDMZEnabled: true,
        destinationIPAddress: destinationIP,
        sourceRestriction: {
          'firstIPAddress': firstIPAddress,
          'lastIPAddress': lastIPAddress,
        },
      );
}
