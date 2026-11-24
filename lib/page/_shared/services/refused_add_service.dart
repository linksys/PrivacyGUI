import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// An Add's [raw] result, parsed, with the rows a refused Add left on the
/// router deleted.
///
/// usp-client sends every Add parameter with `required: false`, so an agent
/// that refuses one creates the row anyway, with that parameter at its
/// default, and reports the refusal in `OperationSuccess.param_errs`. Since
/// usp-client 0.14.0 (linksys/usp_framework#114) the refusal reaches the
/// caller as a [UspPartialSuccess]: the row in `data.instances`, and one
/// failure per refused parameter keyed `<row path><param>`. 0.13.0 dropped the
/// refusal, so the row was a silent leftover. Measured on FL-WRT
/// 2.0.4.26103108 (2026-11-09): a 26th port trigger is stored with `Port=0`,
/// and a 16th IPv6 port service with `Target=Drop`, which the page never
/// lists.
///
/// A row is refused when a failure's path starts with the row's path. The
/// row path keeps its trailing dot, so `….1.` never matches a failure on
/// `….10.…`. Each refused row is deleted, one at a time and the highest
/// instance number first, as the app's batch deletes go, since the router
/// renumbers rows after a delete. Rows that were not refused stay.
///
/// The deletes are writes, so call this inside the mutation lock
/// (`uspMutationLockProvider.withLock`), as every caller does through its
/// notifier. A delete can renumber the rows above it, so the paths the
/// returned result lists for rows of the same Add may no longer be theirs.
/// No caller uses them: on a partial result the page reads the router back.
///
/// Only an instance path, `….<number>.`, is ever deleted. When the agent
/// names no instance, 0.14.0 falls back to the table path (`Device.X.Y.`).
/// Such a row, or any other shape, is left alone and keeps the result
/// partial, so the page reads the router. The refused instance rows of the
/// same Add are still deleted; the partial result still lists them among its
/// successes, which the read-back makes moot.
///
/// Returns a [UspFailure] carrying the refusals when every created row was
/// refused and deleted: the Add wrote nothing, so the caller can keep the
/// user's edit for a retry. Otherwise the parsed result as it was: either the
/// Add was clean, or a row was written (one not refused, one the delete could
/// not remove, or one with no instance path), and the caller has to read the
/// router again. A `BatchTally` step takes `BatchTally.recordAdd`, which
/// calls this.
///
/// Use it for every Add that sends parameters. The two that send none, the
/// PPP interface (`UspInternetSettingsService`) and the notification
/// subscription (`UspClient`), keep `UspResultParser.parseAddResult`: with no
/// parameter there is nothing for the agent to refuse and leave behind.
Future<UspAddResult> parseAddRemovingRefusedRows(
  UspClient usp,
  Map<String, dynamic> raw, {
  required String tag,
}) async {
  final result = UspResultParser.parseAddResult(raw);
  if (result is! UspPartialSuccess<List<String>>) return result;
  final created =
      result.allCreatedInstances.map((c) => c.affectedPath).toList();
  final refused = created
      .where(_instancePath.hasMatch)
      .where(
          (row) => result.failures.any((f) => f.requestedPath.startsWith(row)))
      .toList()
    ..sort((a, b) => _instanceNumber(b).compareTo(_instanceNumber(a)));
  if (refused.isEmpty) return result;

  var removed = 0;
  for (final row in refused) {
    try {
      final deleted =
          UspResultParser.parseDeleteResult(await usp.delete([row]));
      if (deleted is UspSuccess) {
        removed++;
        logger.w('$tag: refused Add row $row deleted');
      } else {
        logger.w('$tag: refused Add row $row not deleted: $deleted');
      }
    } catch (e) {
      logger.w('$tag: refused Add row $row not deleted: $e');
    }
  }

  final everyRowGone =
      removed == refused.length && refused.length == created.length;
  return everyRowGone ? UspFailure<List<String>>(result.failures) : result;
}

final _instancePath = RegExp(r'\.(\d+)\.$');

int _instanceNumber(String row) =>
    int.parse(_instancePath.firstMatch(row)!.group(1)!);
