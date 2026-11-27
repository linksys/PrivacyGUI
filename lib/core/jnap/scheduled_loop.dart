import 'dart:async';

import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// The loop behind `RouterRepository.scheduledCommand`, with its request, its
/// guard and its wait passed in.
///
/// `RouterRepository` passes its own request and the check that ends a loop
/// whose login has ended. The router a provider test stands in passes its
/// answers, so the loop a provider test runs is this one, not a copy (#1904).
///
/// Each turn:
/// 1. waits: [firstDelayInMilliSec] before the first request, and
///    [retryDelayInMilliSec] after each answer that does not meet [condition];
/// 2. runs [guard], then [request], then [guard] again, and once the turns
///    are over, [guard] once more, before [onCompleted];
/// 3. yields the answer, with a failed request turned into a [JNAPError];
/// 4. stops when [condition] holds.
///
/// Once [condition] holds or [maxRetry] turns have run (-1 for no limit),
/// [onCompleted] is told whether the retries ran out. Anything [guard] throws
/// ends the loop as it is, and so does a cancel: [onCompleted] is not called.
Stream<JNAPResult> scheduledLoop({
  required JNAPAction action,
  required Future<JNAPResult> Function() request,
  required void Function() guard,
  required int retryDelayInMilliSec,
  required int maxRetry,
  required int firstDelayInMilliSec,
  bool Function(JNAPResult)? condition,
  Function(bool exceedMaxRetry)? onCompleted,
  Future<void> Function(Duration delay) wait = _wait,
}) async* {
  int retry = 0;
  bool exceedMaxRetry = true;
  while (++retry <= maxRetry || maxRetry == -1) {
    logger.d('SCHEDULED COMMAND: publish command {$action}: $retry times');
    if (retry <= 1) {
      await wait(Duration(milliseconds: firstDelayInMilliSec));
    }
    // An async* loop learns of a cancel only at a yield, and the next yield
    // comes after the request. Yielding nothing here, after the delay, lets
    // a cancel during the delay end the loop before it sends (#1904).
    yield* const Stream<JNAPResult>.empty();
    // After the delay and before the request, so that a logout during the
    // delay stops the request it was waiting to send.
    guard();
    late JNAPResult result;
    try {
      result = await request();
    } on JNAPError catch (e) {
      // JNAP error
      logger.d('SCHEDULED COMMAND: error catched $e, from command {$action}');
      result = e;
    } on TimeoutException catch (e) {
      // Timeout exception
      result = JNAPError(result: e.runtimeType.toString());
    } catch (e) {
      // Unknown Exception
      result = JNAPError(
        result: 'UNKNOWN',
        error: e.runtimeType.toString(),
      );
    }
    // And once the answer is in: a request that was out at the logout
    // answers for a login that has ended, and a caller handed its answer
    // would act on it, as the firmware install's completion did.
    guard();
    yield result;

    if (condition?.call(result) ?? false) {
      logger.d(
          'SCHEDULED COMMAND: command {$action}: $retry times: satisfy condition, STOP!');
      exceedMaxRetry = false;
      break;
    }
    await wait(Duration(milliseconds: retryDelayInMilliSec));
  }
  // The last retry delay ends the loop with no request after it, so a cancel
  // or a logout during that delay is noticed here, before the caller is told
  // that the retries ran out (#1904).
  yield* const Stream<JNAPResult>.empty();
  guard();
  onCompleted?.call(exceedMaxRetry);
}

Future<void> _wait(Duration delay) => Future.delayed(delay);
