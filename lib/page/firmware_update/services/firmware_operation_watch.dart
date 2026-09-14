import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/sse_operation_awaiter.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Subscribe to `OperationComplete` for [referencePath], or carry on without it.
///
/// Both firmware OTA flows — the check and the install — need the same channel for
/// the same reason, and both have to survive not getting it. Shared so that the
/// decision to degrade lives in one place with one name, rather than as two
/// try/catch blocks that a later reader has to compare.
///
/// **Why it degrades rather than throwing.** Opening the watch is an HTTP POST to
/// the bridge's subscription endpoint, so it can fail on its own — and if that
/// threw out of the flow, the caller would be left holding a phase it set before
/// calling: a button spins, nothing resets it, and the thrown object is not a
/// [ServiceError], so the notifier's `on ServiceError` would not catch it either.
/// It is also the same trade [SseOperationAwaiter.watchOperationComplete] already
/// makes internally when SSE is disconnected: it returns a watch nobody can feed
/// rather than refusing.
///
/// **The cost is real and belongs at the call site.** `cmd_failure` travels on
/// this channel and no other, so without it a *refused* command is indistinguishable
/// from one still working — and what that costs differs per flow: a refused check
/// reads as "nothing found", a refused install reads as an install still running.
/// Each caller says which it is accepting; this function only says that the flow
/// continues.
///
/// A null [awaiter] is the ordinary case, not an error: `sseOperationAwaiterProvider`
/// is nullable, and these flows are offered on every surface.
Future<OperationCompleteWatch?> openOperationCompleteWatch(
  SseOperationAwaiter? awaiter, {
  required String referencePath,
}) async {
  if (awaiter == null) return null;
  try {
    return await awaiter.watchOperationComplete(referencePath: referencePath);
  } catch (e) {
    logger.w(
        '[FirmwareUpdate] could not watch OperationComplete on $referencePath '
        '— continuing without the refusal channel',
        error: e);
    return null;
  }
}
