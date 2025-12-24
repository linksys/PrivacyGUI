import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for AdministrationSettingsService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// This centralizes test data and makes tests more readable.
class AdministrationSettingsTestData {
  /// Create default ManagementSettings response
  static JNAPSuccess createManagementSettingsSuccess({
    bool canManageUsingHTTP = false,
    bool canManageUsingHTTPS = false,
    bool isManageWirelesslySupported = false,
    bool canManageRemotely = false,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'canManageUsingHTTP': canManageUsingHTTP,
          'canManageUsingHTTPS': canManageUsingHTTPS,
          'isManageWirelesslySupported': isManageWirelesslySupported,
          'canManageRemotely': canManageRemotely,
        },
      );

  /// Create default UPnPSettings response
  static JNAPSuccess createUPnPSettingsSuccess({
    bool isUPnPEnabled = false,
    bool canUsersConfigure = false,
    bool canUsersDisableWANAccess = false,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'isUPnPEnabled': isUPnPEnabled,
          'canUsersConfigure': canUsersConfigure,
          'canUsersDisableWANAccess': canUsersDisableWANAccess,
        },
      );

  /// Create default ALGSettings response
  static JNAPSuccess createALGSettingsSuccess({
    bool isSIPEnabled = false,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'isSIPEnabled': isSIPEnabled,
        },
      );

  /// Create default ExpressForwardingSettings response
  static JNAPSuccess createExpressForwardingSettingsSuccess({
    bool isExpressForwardingSupported = false,
    bool isExpressForwardingEnabled = false,
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'isExpressForwardingSupported': isExpressForwardingSupported,
          'isExpressForwardingEnabled': isExpressForwardingEnabled,
        },
      );

  /// Create a complete successful JNAP transaction response
  ///
  /// Usage:
  /// ```dart
  /// final response = AdministrationSettingsTestData.createSuccessfulTransaction(
  ///   managementSettings: {'canManageUsingHTTP': true},
  ///   upnpSettings: {'isUPnPEnabled': true},
  /// );
  /// ```
  static JNAPTransactionSuccessWrap createSuccessfulTransaction({
    Map<String, dynamic>? managementSettings,
    Map<String, dynamic>? upnpSettings,
    Map<String, dynamic>? algSettings,
    Map<String, dynamic>? expressForwardingSettings,
  }) {
    // Default values
    final defaultManagement = {
      'canManageUsingHTTP': false,
      'canManageUsingHTTPS': false,
      'isManageWirelesslySupported': false,
      'canManageRemotely': false,
    };
    final defaultUPnP = {
      'isUPnPEnabled': false,
      'canUsersConfigure': false,
      'canUsersDisableWANAccess': false,
    };
    final defaultALG = {
      'isSIPEnabled': false,
    };
    final defaultExpressForwarding = {
      'isExpressForwardingSupported': false,
      'isExpressForwardingEnabled': false,
    };

    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.getManagementSettings,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultManagement, ...?managementSettings},
          ),
        ),
        MapEntry(
          JNAPAction.getUPnPSettings,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultUPnP, ...?upnpSettings},
          ),
        ),
        MapEntry(
          JNAPAction.getALGSettings,
          JNAPSuccess(
            result: 'ok',
            output: {...defaultALG, ...?algSettings},
          ),
        ),
        MapEntry(
          JNAPAction.getExpressForwardingSettings,
          JNAPSuccess(
            result: 'ok',
            output: {
              ...defaultExpressForwarding,
              ...?expressForwardingSettings
            },
          ),
        ),
      ],
    );
  }

  /// Create a partial error response (for error handling tests)
  static JNAPTransactionSuccessWrap createPartialErrorTransaction({
    required JNAPAction errorAction,
    String errorMessage = 'Operation failed',
  }) {
    final allActions = [
      (JNAPAction.getManagementSettings, _createDefaultManagement()),
      (JNAPAction.getUPnPSettings, _createDefaultUPnP()),
      (JNAPAction.getALGSettings, _createDefaultALG()),
      (
        JNAPAction.getExpressForwardingSettings,
        _createDefaultExpressForwarding()
      ),
    ];

    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        for (final (action, result) in allActions)
          if (action == errorAction)
            MapEntry(
              action,
              JNAPError(
                result: 'error',
                error: errorMessage,
              ),
            )
          else
            MapEntry(action, result),
      ],
    );
  }

  // Private helpers for default values
  static JNAPSuccess _createDefaultManagement() => JNAPSuccess(
        result: 'ok',
        output: const <String, dynamic>{
          'canManageUsingHTTP': false,
          'canManageUsingHTTPS': false,
          'isManageWirelesslySupported': false,
          'canManageRemotely': false,
        },
      );

  static JNAPSuccess _createDefaultUPnP() => JNAPSuccess(
        result: 'ok',
        output: const <String, dynamic>{
          'isUPnPEnabled': false,
          'canUsersConfigure': false,
          'canUsersDisableWANAccess': false,
        },
      );

  static JNAPSuccess _createDefaultALG() => JNAPSuccess(
        result: 'ok',
        output: const <String, dynamic>{
          'isSIPEnabled': false,
        },
      );

  static JNAPSuccess _createDefaultExpressForwarding() => JNAPSuccess(
        result: 'ok',
        output: const <String, dynamic>{
          'isExpressForwardingSupported': false,
          'isExpressForwardingEnabled': false,
        },
      );
}
