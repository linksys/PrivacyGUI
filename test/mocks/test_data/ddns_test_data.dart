import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for DDNSService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
/// Supports partial override pattern via named parameters.
class DDNSTestData {
  /// Default provider names
  static const String dynDNSProvider = 'DynDNS';
  static const String noIPProvider = 'No-IP';
  static const String tzoProvider = 'TZO';
  static const String noDDNSProvider = '';

  /// Supported providers list
  static const List<String> supportedProviders = [
    '',
    'DynDNS',
    'No-IP',
    'TZO',
  ];

  /// Create successful getDDNSSettings response
  static JNAPSuccess createGetDDNSSettingsSuccess({
    String ddnsProvider = '',
    Map<String, dynamic>? dynDNSSettings,
    Map<String, dynamic>? noIPSettings,
    Map<String, dynamic>? tzoSettings,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'ddnsProvider': ddnsProvider,
        if (dynDNSSettings != null) 'dynDNSSettings': dynDNSSettings,
        if (noIPSettings != null)
          'noipSettings': noIPSettings, // Note: lowercase 'ip' per JNAP model
        if (tzoSettings != null) 'tzoSettings': tzoSettings,
      },
    );
  }

  /// Create successful getDDNSStatus response
  static JNAPSuccess createGetDDNSStatusSuccess({
    String status = 'Unknown',
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'status': status,
      },
    );
  }

  /// Create successful getSupportedDDNSProviders response
  static JNAPSuccess createGetSupportedProvidersSuccess({
    List<String>? providers,
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'supportedDDNSProviders': providers ?? supportedProviders,
      },
    );
  }

  /// Create successful getWANStatus response for IP address
  static JNAPSuccess createGetWANStatusSuccess({
    String wanIP = '192.168.1.1',
    String wanStatus = 'Connected',
  }) {
    return JNAPSuccess(
      result: 'ok',
      output: {
        'macAddress': '00:11:22:33:44:55',
        'detectedWANType': 'DHCP',
        'wanStatus': wanStatus,
        'wanIPv6Status': 'Disconnected',
        'supportedWANTypes': const ['DHCP', 'Static', 'PPPoE'],
        'supportedIPv6WANTypes': const [],
        'supportedWANCombinations': const [],
        'wanConnection': {
          'wanType': 'DHCP',
          'ipAddress': wanIP,
          'networkPrefixLength': 24,
          'gateway': '192.168.1.1',
          'mtu': 1500,
          'dnsServer1': '8.8.8.8',
        },
      },
    );
  }

  /// Create successful transaction response for fetching all DDNS data
  static JNAPTransactionSuccessWrap createFetchDDNSDataSuccess({
    String ddnsProvider = '',
    Map<String, dynamic>? dynDNSSettings,
    Map<String, dynamic>? noIPSettings,
    Map<String, dynamic>? tzoSettings,
    String status = 'Unknown',
    List<String>? supportedProviders,
    String wanIP = '192.168.1.1',
  }) {
    return JNAPTransactionSuccessWrap(
      result: 'ok',
      data: [
        MapEntry(
          JNAPAction.getDDNSSettings,
          createGetDDNSSettingsSuccess(
            ddnsProvider: ddnsProvider,
            dynDNSSettings: dynDNSSettings,
            noIPSettings: noIPSettings,
            tzoSettings: tzoSettings,
          ),
        ),
        MapEntry(
          JNAPAction.getDDNSStatus,
          createGetDDNSStatusSuccess(status: status),
        ),
        MapEntry(
          JNAPAction.getSupportedDDNSProviders,
          createGetSupportedProvidersSuccess(providers: supportedProviders),
        ),
        MapEntry(
          JNAPAction.getWANStatus,
          createGetWANStatusSuccess(wanIP: wanIP),
        ),
      ],
    );
  }

  /// Create successful setDDNSSettings response
  static JNAPSuccess createSetDDNSSettingsSuccess() {
    return const JNAPSuccess(
      result: 'ok',
      output: {},
    );
  }

  /// Create DynDNS settings with filled data
  static Map<String, dynamic> createDynDNSSettingsData({
    String username = 'testuser',
    String password = 'testpass',
    String hostName = 'test.dyndns.org',
    bool isWildcardEnabled = false,
    String mode = 'Dynamic',
    bool isMailExchangeEnabled = false,
    String? mailExchangeHostName,
    bool isBackup = false,
  }) {
    return {
      'username': username,
      'password': password,
      'hostName': hostName,
      'isWildcardEnabled': isWildcardEnabled,
      'mode': mode,
      'isMailExchangeEnabled': isMailExchangeEnabled,
      if (isMailExchangeEnabled)
        'mailExchangeSettings': {
          'hostName': mailExchangeHostName ?? '',
          'isBackup': isBackup,
        },
    };
  }

  /// Create NoIP settings with filled data
  static Map<String, dynamic> createNoIPSettingsData({
    String username = 'testuser',
    String password = 'testpass',
    String hostName = 'test.no-ip.org',
  }) {
    return {
      'username': username,
      'password': password,
      'hostName': hostName,
    };
  }

  /// Create TZO settings with filled data
  static Map<String, dynamic> createTZOSettingsData({
    String username = 'testuser',
    String password = 'testpass',
    String hostName = 'test.tzo.com',
  }) {
    return {
      'username': username,
      'password': password,
      'hostName': hostName,
    };
  }

  /// Create generic JNAP error
  static JNAPError createGenericError({
    String errorCode = 'ErrorUnknown',
    String? errorMessage,
  }) {
    return JNAPError(
      result: errorCode,
      error: errorMessage,
    );
  }

  /// Create unsupported provider error
  static JNAPError createUnsupportedProviderError() {
    return const JNAPError(
      result: 'ErrorUnsupportedDDNSProvider',
      error: null,
    );
  }
}
