/// One entry of a unified envelope's `errors` list. A null [errorCode] leaves
/// the member out, for a test of what the app does without one.
typedef UspEnvelopeError = ({
  String kind,
  String? path,
  Object? errorCode,
  String errorMessage,
});

/// Failed usp-client envelopes, as the WASM client resolves them (0.16.0).
///
/// Each builds the `errors` list only: the member `UspClient` decides a Get or
/// an Operate by, and `UspResultParser` reads a write's failures from. The
/// client also returns the deprecated `error` map, with the same entries keyed
/// by path; it is left out so a test proves the app reads the list, and so
/// nothing here changes when the next minor client drops the map. Only an
/// entry's `kind` tells a call that failed as a whole from errors on single
/// paths: both carry a code on every requested path (#1787). The shapes are
/// the vendored client's, measured from Node (`test/web/usp_operate_test.mjs`)
/// and read from its source (`usp-client/src/wasm/mod.rs`, 0.16.0).
class UspEnvelopeTestData {
  /// A call that failed as a whole: one `kind: request` entry per requested
  /// path, `success: false`, empty `data`.
  ///
  /// [errorCode] 9999 is a transport or session failure
  /// (`Transport error: HTTP error: HTTP 401`), 9998 an answer the client could
  /// not decode (`Protocol error: …`), 9997 input it refused
  /// (`Validation error: …`); any other code is the router refusing the
  /// request, with its own message. No [paths] gives one entry with no path.
  static Map<String, dynamic> failedAsAWhole(
    List<String> paths, {
    required Object errorCode,
    required String errorMessage,
  }) =>
      envelope(
        success: false,
        data: const {},
        errors: [
          for (final String? path in paths.isEmpty ? [null] : paths)
            (
              kind: 'request',
              path: path,
              errorCode: errorCode,
              errorMessage: errorMessage,
            ),
        ],
      );

  /// Errors on single paths (`kind: path`): a Get's 7026 for a path the
  /// router does not have, a command the router refused, or an object a Set,
  /// Add or Delete could not write (`OperationFailure`, keyed by the requested
  /// object path). A Get reports `success: true` when other paths were read
  /// and `false` when the missing one was the only one.
  static Map<String, dynamic> pathErrors(
    Map<String, ({Object? code, String message})> errors, {
    required bool success,
    Map<String, dynamic>? data = const {},
  }) =>
      _keyedBy('path', errors, success: success, data: data);

  /// Parameters the router refused on an object a Set wrote or an Add
  /// created (`kind: parameter`), keyed `<object path><parameter>`.
  ///
  /// A Set is `success: false` when the object it wrote took no parameter at
  /// all, `true` when it took some; an Add that created its row is
  /// `success: true` with the row in `data.instances`.
  static Map<String, dynamic> parameterErrors(
    Map<String, ({Object? code, String message})> errors, {
    required bool success,
    Map<String, dynamic>? data = const {},
  }) =>
      _keyedBy('parameter', errors, success: success, data: data);

  static Map<String, dynamic> _keyedBy(
    String kind,
    Map<String, ({Object? code, String message})> errors, {
    required bool success,
    Map<String, dynamic>? data,
  }) =>
      envelope(
        success: success,
        data: data,
        errors: [
          for (final MapEntry(:key, :value) in errors.entries)
            (
              kind: kind,
              path: key,
              errorCode: value.code,
              errorMessage: value.message,
            ),
        ],
      );

  /// The envelope for [errors]; a null [data] leaves the member out.
  static Map<String, dynamic> envelope({
    required bool success,
    required List<UspEnvelopeError> errors,
    Map<String, dynamic>? data = const {},
  }) =>
      {
        'success': success,
        'result': {
          if (data != null) 'data': data,
          'errors': [
            for (final e in errors)
              {
                'kind': e.kind,
                if (e.path != null) 'path': e.path,
                if (e.errorCode != null) 'errorCode': e.errorCode,
                'errorMessage': e.errorMessage,
              },
          ],
        },
      };
}
