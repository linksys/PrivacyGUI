import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/services/refused_add_service.dart';

/// Sends [write] and returns its envelope — or, when the router never answered
/// it, the failed envelope the client resolved with before #1666.
///
/// Since #1666 `UspClient` throws a write the router never answered (a lost
/// connection, a 5xx, a 401 it could not recover), so that a 401 reaches the
/// session check ([UspClient.throwIfUnanswered]). A save made of several
/// writes is read from their envelopes: a failed step is recorded and the
/// next one still goes out, and a save that landed in part says so — which is
/// what sends a page back to the router (`saveReadingBackAfterPartialWrite`).
/// Stopping at the throw would lose that: a page whose first step landed would
/// keep the edits as if nothing had been written, and its next save could add
/// the same row twice. So here the throw becomes the one `kind: request` 9999
/// entry it was built from, with the client's own text, and the caller parses
/// the step like any other — exactly what it did before #1666.
///
/// For the writes of [BatchTally] and the other multi-step saves that decide
/// "landed in part" from a failed envelope. Every other throw propagates.
Future<Map<String, dynamic>> writeOrUnanswered(
    Future<Map<String, dynamic>> Function() write) async {
  try {
    return await write();
  } catch (e) {
    final parsed = e is ServiceError ? null : parseUspError(e);
    if (parsed == null || parsed.category != UspErrorCategory.transport) {
      rethrow;
    }
    return {
      'success': false,
      'result': {
        'data': const <String, dynamic>{},
        'errors': [
          {
            'kind': 'request',
            'errorCode': 9999,
            'errorMessage': 'Transport error: ${parsed.message}',
          },
        ],
      },
    };
  }
}

/// The outcome of every step in one batch save.
///
/// Any step that failed, partly or fully, fails the save: the batch used to
/// throw only when *every* step failed, so a save that left a rule behind on
/// the router still reported "saved". The user is shown the reason the router
/// named on any failure, else its error for the first one.
class BatchTally {
  /// [_tag] is the grep-friendly log prefix, e.g. `[PortForwarding]`.
  BatchTally(this._tag);

  final String _tag;
  final List<UspErrorDetail> _failures = [];
  int _steps = 0;
  int _failedSteps = 0;

  void record(String step, UspOperationResult<dynamic> result) {
    _steps++;
    final List<UspErrorDetail> failures;
    switch (result) {
      case UspSuccess():
        return;
      case UspPartialSuccess(failures: final f):
        failures = f;
      case UspFailure(errors: final e):
        _failedSteps++;
        failures = e;
    }
    _failures.addAll(failures);
    logger.w('$_tag: $step failed: '
        '${failures.map((f) => f.errorMessage).join('; ')}');
  }

  /// Records an Add step from its [raw] result, after deleting any row the
  /// router refused part of ([parseAddRemovingRefusedRows]); returns the
  /// parsed result, for a caller that needs the created path.
  Future<UspAddResult> recordAdd(
      UspClient usp, String step, Map<String, dynamic> raw) async {
    final result = await parseAddRemovingRefusedRows(usp, raw, tag: _tag);
    record(step, result);
    return result;
  }

  /// A step whose result said success but left the save unable to go on.
  void recordMissing(String step, String why) {
    _steps++;
    _failedSteps++;
    _failures.add(UspErrorDetail(
      requestedPath: '',
      errorCode: 0,
      errorMessage: why,
    ));
    logger.w('$_tag: $step failed: $why');
  }

  void throwIfAnyFailed() {
    if (_failures.isEmpty) return;
    final summary = '$_tag batch: ${_failures.first.errorMessage}';
    if (_failedSteps == _steps) {
      throw UspCompleteFailureError(summary: summary, failures: _failures);
    }
    throw UspPartialFailureError(
      summary: summary,
      successPaths: const [],
      failures: _failures,
    );
  }
}
