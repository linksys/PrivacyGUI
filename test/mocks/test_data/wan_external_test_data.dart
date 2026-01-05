import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

/// Test data builder for WanExternalService tests
///
/// Provides factory methods to create JNAP mock responses with sensible defaults.
class WanExternalTestData {
  /// Create a successful JNAP response for getWANExternal action
  static JNAPSuccess createWanExternalResponse({
    String? publicWanIPv4 = '203.0.113.1',
    String? publicWanIPv6 = '2001:db8::1',
    String? privateWanIPv4 = '192.168.1.1',
    String? privateWanIPv6 = 'fe80::1',
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          if (publicWanIPv4 != null) 'PublicWanIPv4': publicWanIPv4,
          if (publicWanIPv6 != null) 'PublicWanIPv6': publicWanIPv6,
          if (privateWanIPv4 != null) 'PrivateWanIPv4': privateWanIPv4,
          if (privateWanIPv6 != null) 'PrivateWanIPv6': privateWanIPv6,
        },
      );

  /// Create a successful response with only IPv4 addresses
  static JNAPSuccess createIpv4OnlyResponse({
    String publicWanIPv4 = '203.0.113.1',
    String privateWanIPv4 = '192.168.1.1',
  }) =>
      JNAPSuccess(
        result: 'ok',
        output: {
          'PublicWanIPv4': publicWanIPv4,
          'PrivateWanIPv4': privateWanIPv4,
        },
      );

  /// Create a successful response with empty data
  static JNAPSuccess createEmptyResponse() => const JNAPSuccess(
        result: 'ok',
        output: {},
      );

  /// Create an unauthorized error response
  static JNAPError createUnauthorizedError() => const JNAPError(
        result: '_ErrorUnauthorized',
        error: null,
      );

  /// Create an unexpected error response
  static JNAPError createUnexpectedError([String? message]) => JNAPError(
        result: message ?? 'ErrorUnknown',
        error: null,
      );
}
