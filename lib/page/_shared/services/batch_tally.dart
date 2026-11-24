import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/_shared/services/refused_add_service.dart';

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
