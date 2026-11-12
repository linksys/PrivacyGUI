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
/// Each builds both members the client returns from the same entries:
/// `errors`, the list `UspClient` decides a Get or an Operate by, and the
/// deprecated `error` map, keyed by `path` (`""` when there is none). Only an
/// entry's `kind` tells a call that failed as a whole from errors on single
/// paths: both carry a code on every requested path (#1787). The shapes are
/// the vendored client's, measured from Node (`test/web/usp_operate_test.mjs`).
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
  /// router does not have, or a command the router refused. A Get reports
  /// `success: true` when other paths were read and `false` when the missing
  /// one was the only one.
  static Map<String, dynamic> pathErrors(
    Map<String, ({Object? code, String message})> errors, {
    required bool success,
    Map<String, dynamic>? data = const {},
  }) =>
      envelope(
        success: success,
        data: data,
        errors: [
          for (final MapEntry(:key, :value) in errors.entries)
            (
              kind: 'path',
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
          'error': {
            for (final e in errors)
              e.path ?? '': {
                if (e.errorCode != null) 'errorCode': e.errorCode,
                'errorMessage': e.errorMessage,
              },
          },
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
