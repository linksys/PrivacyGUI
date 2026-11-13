import 'usp_envelope_test_data.dart';

/// Responses for an Add the agent created but refused part of, as usp-client
/// 0.14.0 returns them (linksys/usp_framework#114), and for one it refused as
/// a whole, as 0.15.0 does ([refusedAsAWhole], #1787).
class UspAddRefusalTestData {
  UspAddRefusalTestData._();

  /// `success` stays true, every created row is in `data.instances`, and each
  /// refused parameter of [refusedRow] has an `error` entry keyed
  /// `<row path><param>`.
  ///
  /// The shape and the default message are the bench's (FW 2.0.4.26103108,
  /// 2026-11-09, a 26th port trigger, its captured response decoded by
  /// 0.14.0): code 7005 on every entry, the error name on the refused leaf,
  /// and "group set failed" on each of [otherParams].
  static Map<String, dynamic> refusedAdd({
    required List<String> instances,
    required String refusedRow,
    String refusedParam = 'Port',
    String message = 'ErrorTooManyRules: at most 25 port triggering rules.',
    List<String> otherParams = const ['Enable'],
  }) =>
      {
        'success': true,
        'result': {
          'data': {'affectedCount': instances.length, 'instances': instances},
          'error': {
            for (final p in otherParams)
              '$refusedRow$p': {
                'errorCode': 7005,
                'errorMessage': "SetParameterGroup: group set failed at "
                    "'$refusedRow$refusedParam' (Resources exceeded)",
              },
            '$refusedRow$refusedParam': {
              'errorCode': 7005,
              'errorMessage': message,
            },
          },
        },
      };

  /// An Add the router refused as a whole (a USP `Error`), as usp-client
  /// 0.15.0 and later return it: `success: false`, nothing created
  /// (`affectedCount: 0`, no instances), one `kind: request` entry per
  /// parameter the `Error` names, keyed by its `param_path`, or, when it names
  /// none, one keyed by the table path that was added to.
  ///
  /// The shape is the vendored 0.16.0 client's, from Node, for an `Error`
  /// whose `param_errs` names `Device.NAT.PortTrigger.{i}.Port` (#1787): the
  /// instance number is the template's `{i}`, since no row was created.
  static Map<String, dynamic> refusedAsAWhole({
    String table = 'Device.NAT.PortTrigger.',
    int errorCode = 7005,
    String? refusedParam = 'Port',
    String message = 'ErrorTooManyRules: at most 25 port triggering rules.',
  }) =>
      UspEnvelopeTestData.envelope(
        success: false,
        data: const {'affectedCount': 0, 'instances': <String>[]},
        errors: [
          (
            kind: 'request',
            path: refusedParam == null ? table : '$table{i}.$refusedParam',
            errorCode: errorCode,
            errorMessage: message,
          ),
        ],
      );

  /// A write the router accepted (a Set or a Delete).
  static const Map<String, dynamic> accepted = {
    'success': true,
    'result': {'data': <String, dynamic>{}},
  };
}
