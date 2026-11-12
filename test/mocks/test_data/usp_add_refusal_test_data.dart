/// Responses for an Add the agent created but refused part of, as usp-client
/// 0.14.0 returns them (linksys/usp_framework#114).
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

  /// A write the router accepted (a Set or a Delete).
  static const Map<String, dynamic> accepted = {
    'success': true,
    'result': {'data': <String, dynamic>{}},
  };
}
