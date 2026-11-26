import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';

void main() {
  const window = Duration(milliseconds: 20);
  late UspMutationLock lock;

  setUp(() => lock = UspMutationLock());

  group('UspMutationLock.withLock', () {
    test('returns what an action that answers in time returns', () async {
      expect(await lock.withLock(() async => 42, timeout: window), 42);
      expect(lock.isLocked, isFalse);
    });

    // #1831: what leaves this method is what the callers can catch. A provider
    // may only have `on ServiceError` arms (constitution Article XIII §13.4), and
    // a bare `TimeoutException` passed every one of them: the firmware install
    // and upload were left mid-update with no failure card, and the pages that
    // re-read the router after a failed save skipped the re-read.
    test(
        'an action that outlasts its window is a TimeoutError, and the lock is '
        'free again', () async {
      await expectLater(
        lock.withLock(() => Completer<void>().future, timeout: window),
        throwsA(isA<TimeoutError>()),
      );
      expect(lock.isLocked, isFalse);
    });

    test('a TimeoutException the action throws leaves as a TimeoutError',
        () async {
      // Either side of the lock, it is the same fact — something did not answer
      // in time — so a caller does not have to know which one raised it.
      await expectLater(
        lock.withLock<void>(
          () async => throw TimeoutException('the inner read', window),
          timeout: const Duration(seconds: 5),
        ),
        throwsA(isA<TimeoutError>()
            .having((e) => e.detail, 'detail', contains('the inner read'))),
      );
      expect(lock.isLocked, isFalse);
    });

    test('every other error the action throws passes through unchanged',
        () async {
      const refused = InvalidInputError(detail: 'refused');
      await expectLater(
        lock.withLock<void>(() async => throw refused),
        throwsA(same(refused)),
      );

      final bug = StateError('a bug, not a timeout');
      await expectLater(
        lock.withLock<void>(() async => throw bug),
        throwsA(same(bug)),
      );
      expect(lock.isLocked, isFalse);
    });

    test(
        'a wait for a holder that outlasts the window takes the lock rather '
        'than throwing', () async {
      // `AddNodesNotifier` relies on this: when its Start() times out, the
      // command itself went unanswered — never the wait in front of it.
      final holder = lock.withLock(
        () => Completer<void>().future,
        timeout: const Duration(milliseconds: 200),
      );

      expect(await lock.withLock(() async => 'next', timeout: window), 'next');

      await expectLater(holder, throwsA(isA<TimeoutError>()));
    });
  });
}
