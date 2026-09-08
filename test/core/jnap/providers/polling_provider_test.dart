// Unit tests for the real [PollingNotifier] - the core poll loop behind the
// dashboard.
//
// A ProviderContainer hosts the real notifier with routerRepositoryProvider
// overridden by a MockRouterRepository, so every JNAP call the loop makes is
// observable and every failure mode is injectable. The tests run under
// testWidgets purely for its fake clock: the loop is a `Timer.periodic` plus a
// one-second first-poll delay, and `tester.pump(duration)` is what lets a test
// stand at a chosen point in poll time without waiting in real time.
//
// Three defects are pinned here, the first two of which shipped without tests:
//
//   #1418 - a single failed getDeviceMode in startPolling() skipped both the
//           command-set build and the timer install, so polling stopped for good
//           and even pull-to-refresh sent an empty transaction.
//   #7    - any failed poll was read as a rejected credential and logged the user
//           out, so a router that briefly took its HTTP service away ejected the
//           session.
//   #1419 - the flip side of #7: once a failed poll no longer logged anyone out,
//           it said nothing at all, and the dashboard kept presenting the last
//           good snapshot as if it were live.
//
// All three are "the loop must survive one bad request" defects, which is why
// they share a harness: what needs asserting in each case is what the loop does
// on the tick *after* the failure.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';

import '../../../common/di.dart';
import '../../../mocks/instant_privacy_provider_mocks.dart';
import '../../../mocks/router_repository_mocks.dart';

/// An [AuthNotifier] that reports a local login and records logouts instead of
/// performing one.
///
/// The real [AuthNotifier.logout] clears shared preferences and secure storage
/// and drops the session; none of that is what these tests are about. Whether
/// the poll loop *decided* to log out is the whole question, so it is counted
/// and nothing else happens.
class _RecordingAuthNotifier extends AuthNotifier {
  int logoutCount = 0;

  @override
  Future<AuthState> build() =>
      Future.value(const AuthState(loginType: LoginType.local));

  @override
  Future logout() async {
    logoutCount++;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // serviceHelper is a get_it singleton resolved lazily on first use;
  // _buildCoreTransaction asks it which optional commands to include. The mock
  // answers false to everything, so the command set under test is the
  // unconditional core - which is all these tests need, and keeps the expected
  // set from drifting as feature flags come and go.
  mockDependencyRegister();

  // LinksysCacheManager.init() reaches for the temp directory through
  // path_provider on its way to the on-disk cache file. It is fire-and-forget, so
  // a MissingPluginException there would surface as an unhandled async error
  // rather than a readable failure. Point it at the real temp directory.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.path,
  );

  late MockRouterRepository mockRepo;
  late _RecordingAuthNotifier auth;
  late ProviderContainer container;
  late PollingNotifier notifier;

  /// Every transaction the loop sent, in order. The commands each one carried
  /// are the observable stand-in for the private `_coreTransactions`.
  late List<JNAPTransactionBuilder> transactions;

  /// Every single-action request the loop sent, in order - in practice
  /// getDeviceMode, since that is the only `send` PollingNotifier makes.
  late List<JNAPAction> sends;

  setUp(() {
    // JNAPAction.actionValue reads a map that main() populates at start-up;
    // without this every command name in the transaction is a null assertion.
    initBetterActions();
    transactions = [];
    sends = [];
    mockRepo = MockRouterRepository();
    auth = _RecordingAuthNotifier();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(mockRepo),
      authProvider.overrideWith(() => auth),
      // _additionalPolling fans out to other notifiers once a poll succeeds.
      // Only this one runs with every service unsupported, and it would
      // otherwise send its own getMACFilterSettings through the same mock and
      // muddy the request log.
      instantPrivacyProvider.overrideWith(() => MockInstantPrivacyNotifier()),
    ]);
    notifier = container.read(pollingProvider.notifier);
  });

  tearDown(() {
    // PollingNotifier._timer is static, so a timer left running would keep
    // polling into the next test. It also has to be cancelled inside the test
    // body (see [stopAndSettle]) to satisfy the fake clock's pending-timer
    // check; this is the backstop for a test that threw before getting there.
    notifier.stopPolling();
    container.dispose();
  });

  /// Stubs `send`, recording the action and delegating to [answer].
  void whenSend(Future<JNAPSuccess> Function(JNAPAction action) answer) {
    when(mockRepo.send(
      any,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) {
      final action = invocation.positionalArguments.first as JNAPAction;
      sends.add(action);
      return answer(action);
    });
  }

  /// Stubs `transaction`, recording the builder and delegating to [answer],
  /// which is passed the 1-based number of the poll so a test can fail an
  /// individual tick.
  void whenTransaction(
      Future<JNAPTransactionSuccessWrap> Function(int n) answer) {
    when(mockRepo.transaction(
      any,
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) {
      transactions
          .add(invocation.positionalArguments.first as JNAPTransactionBuilder);
      return answer(transactions.length);
    });
  }

  JNAPSuccess deviceMode(String mode) =>
      JNAPSuccess(result: 'OK', output: {'mode': mode});

  /// A transaction answer echoing back the commands that were asked for, so the
  /// resulting CoreTransactionData is non-empty exactly when the request was.
  Future<JNAPTransactionSuccessWrap> transactionSuccess() async =>
      JNAPTransactionSuccessWrap(
        result: 'OK',
        data: transactions.last.commands
            .map((command) => MapEntry(
                command.key, JNAPSuccess(result: 'OK', output: const {})))
            .toList(),
      );

  /// Advances the fake clock by [d] and drains everything it set off.
  ///
  /// A poll is several awaits deep (transaction, then the fan-out), so the
  /// trailing pump is what lets those microtasks run before a test looks.
  Future<void> advance(WidgetTester tester, Duration d) async {
    await tester.pump(d);
    await tester.pump();
  }

  /// Time to the first poll: the deliberate [pollFirstDelayInSec] head start,
  /// plus a moment for the awaits around it.
  Future<void> advanceToFirstPoll(WidgetTester tester) =>
      advance(tester, const Duration(seconds: pollFirstDelayInSec + 1));

  /// Time to the next periodic tick.
  Future<void> advanceOneTick(WidgetTester tester) =>
      advance(tester, const Duration(seconds: BuildConfig.refreshTimeInterval));

  /// Time from the first poll to the far side of the silence window.
  ///
  /// The window is armed when a poll goes out, which is a moment *before*
  /// [advanceToFirstPoll] returns, so standing a whole
  /// [pollUnreachableAfterInSec] on from there lands just past it.
  Future<void> advanceToUnreachable(WidgetTester tester) =>
      advance(tester, const Duration(seconds: pollUnreachableAfterInSec));

  /// Cancels the periodic timer and lets any poll it started finish.
  ///
  /// The fake clock fails a test that ends with a timer still pending, and this
  /// loop's timer is periodic by design, so every test has to put it down.
  Future<void> stopAndSettle(WidgetTester tester) async {
    notifier.stopPolling();
    await tester.pump();
  }

  group('startPolling', () {
    testWidgets('polls once after the first-poll delay, then on every tick',
        (tester) async {
      // The baseline the #1418 tests are read against: with every request
      // answering, a poll lands shortly after the call and once per interval
      // after that.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      expect(transactions, isEmpty, reason: 'the first poll is delayed');

      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1));

      await advanceOneTick(tester);
      expect(transactions, hasLength(2));

      await stopAndSettle(tester);
    });

    testWidgets('a failed getDeviceMode still installs the poll timer',
        (tester) async {
      // #1418. checkSmartMode sends getDeviceMode with `fetchRemote: true`, so
      // it never answers from cache, and a connection-level failure gets no
      // retry from LinksysHttpClient. It used to be the head of an unguarded
      // `.then` chain: when it rejected, _setTimePeriod never ran, and the
      // caller (PrepareDashboardView) had already cancelled the previous timer -
      // so polling was dead, not delayed, and the dashboard sat on cached values
      // until the user logged in again.
      whenSend((_) async => throw Exception('connection refused'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1),
          reason: 'the first poll must happen even with no mode');

      await advanceOneTick(tester);
      expect(transactions, hasLength(2),
          reason: 'the periodic timer must have been installed');

      await stopAndSettle(tester);
    });

    testWidgets('a failed getDeviceMode does not leave the transaction empty',
        (tester) async {
      // The second half of #1418, and the reason manual refresh could not save
      // the user: _coreTransactions is only populated on the far side of
      // checkSmartMode, so a rejection left it at its initial `[]`. Every later
      // forcePolling - pull-to-refresh, the refresh after saving a setting -
      // then sent a transaction that asked the router for nothing, and no amount
      // of refreshing could repopulate the dashboard.
      whenSend((_) async => throw Exception('connection refused'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await advanceToFirstPoll(tester);

      expect(transactions.single.commands, isNotEmpty);
      expect(
        transactions.single.commands.map((command) => command.key),
        containsAll([
          JNAPAction.getDevices,
          JNAPAction.getWANStatus,
          JNAPAction.getDeviceInfo,
        ]),
      );

      await stopAndSettle(tester);
    });

    testWidgets('a failed getDeviceMode still leaves forcePolling able to poll',
        (tester) async {
      whenSend((_) async => throw Exception('connection refused'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      transactions.clear();

      await notifier.forcePolling();
      await tester.pump();

      expect(transactions, isNotEmpty);
      expect(transactions.last.commands, isNotEmpty,
          reason: 'a forced poll must ask the router for something');

      await stopAndSettle(tester);
    });

    testWidgets('a known mode decides the command set', (tester) async {
      // getBackhaulInfo is the one command the mode gates, which is what makes
      // an unreadable mode worth recovering from rather than shrugging at.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await advanceToFirstPoll(tester);

      expect(transactions.single.commands.map((command) => command.key),
          contains(JNAPAction.getBackhaulInfo));

      await stopAndSettle(tester);
    });

    testWidgets('an unknown mode is re-read on a later tick', (tester) async {
      // Falling back to 'Unconfigured' keeps the loop alive but builds the
      // command set without getBackhaulInfo. Left alone, a Master that was
      // unreachable for one moment would poll without it until the next login,
      // so the mode is re-read while it is still unknown - and only while it is
      // still unknown.
      var modeFails = true;
      whenSend((_) async {
        if (modeFails) throw Exception('connection refused');
        return deviceMode('Master');
      });
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions.last.commands.map((command) => command.key),
          isNot(contains(JNAPAction.getBackhaulInfo)));

      modeFails = false;
      await advanceOneTick(tester);
      expect(transactions.last.commands.map((command) => command.key),
          contains(JNAPAction.getBackhaulInfo),
          reason: 'the recovered mode must reach the command set');

      final sendsSoFar = sends.length;
      await advanceOneTick(tester);
      expect(sends, hasLength(sendsSoFar),
          reason: 'a known mode must not be re-read every tick');

      await stopAndSettle(tester);
    });

    testWidgets('a logout forgets the mode of the router that was left',
        (tester) async {
      // init() is the logout reset, and the next login can be to a different
      // router. Carrying the old mode over as the fallback would tell a fresh
      // Slave it was a Master (and vice versa) whenever its own mode read failed.
      var modeFails = false;
      whenSend((_) async {
        if (modeFails) throw Exception('connection refused');
        return deviceMode('Master');
      });
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions.last.commands.map((command) => command.key),
          contains(JNAPAction.getBackhaulInfo));

      await stopAndSettle(tester);
      notifier.init();

      modeFails = true;
      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions.last.commands.map((command) => command.key),
          isNot(contains(JNAPAction.getBackhaulInfo)));

      await stopAndSettle(tester);
    });

    testWidgets('a failed first poll still installs the timer', (tester) async {
      // The timer install used to hang off the first poll's future too, so a
      // start-up that reached the poll and lost it there was just as fatal.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((n) async {
        if (n == 1) throw TimeoutException('first poll lost');
        return transactionSuccess();
      });

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceOneTick(tester);

      // Three polls, not two: the lost one, the re-try it earns
      // [pollRetryDelayInSec] later (see 'reporting an unreachable router'), and
      // then the periodic tick - which is the one this test is about.
      expect(transactions, hasLength(3));
      expect(container.read(pollingProvider).hasValue, isTrue,
          reason: 'the second tick must have recovered the data');

      await stopAndSettle(tester);
    });

    testWidgets('a paused notifier neither polls nor installs a timer',
        (tester) async {
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) => transactionSuccess());

      notifier.paused = true;
      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceOneTick(tester);

      expect(transactions, isEmpty);
      verifyNever(mockRepo.send(any,
          data: anyNamed('data'),
          extraHeaders: anyNamed('extraHeaders'),
          auth: anyNamed('auth'),
          type: anyNamed('type'),
          fetchRemote: anyNamed('fetchRemote'),
          cacheLevel: anyNamed('cacheLevel'),
          timeoutMs: anyNamed('timeoutMs'),
          retries: anyNamed('retries'),
          sideEffectOverrides: anyNamed('sideEffectOverrides')));

      await stopAndSettle(tester);
    });

    testWidgets('the mode read is not retried for ever', (tester) async {
      // The repair is for a transient failure. A router that keeps refusing
      // getDeviceMode would otherwise put the request's full timeout in front of
      // every tick and every pull-to-refresh for the rest of the session, to fix
      // nothing.
      whenSend((_) async => throw Exception('connection refused'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      for (var tick = 0; tick < 8; tick++) {
        await advanceOneTick(tester);
      }

      expect(sends.length, lessThan(6),
          reason: 'the mode read must stop being retried, not run every tick');
      expect(transactions, hasLength(9),
          reason: 'giving up on the mode must not stop the polling');

      await stopAndSettle(tester);
    });
  });

  group('cancelling a start-up already in flight', () {
    // The timer install is now guaranteed, which means the sequence must not
    // outlive the reason it was started. Everything that stops polling does so
    // while the sequence is between its own awaits, so each of these lands in
    // that window and asserts the stop stuck.

    testWidgets('a stopPolling during the first-poll delay stops everything',
        (tester) async {
      // The window this covers: logout calls stopPolling, and a start-up that
      // carried on to install a timer would poll on with no credential - whose
      // first _ErrorUnauthorized then forces another logout.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await tester.pump();
      notifier.stopPolling();

      await advanceToFirstPoll(tester);
      await advanceOneTick(tester);

      expect(transactions, isEmpty,
          reason: 'neither the first poll nor any tick should have happened');
    });

    testWidgets('a stopPolling during the first poll installs no timer',
        (tester) async {
      // Same window, one step later. The sequence now awaits the first poll, so
      // a stop that lands while that poll is in flight has to be noticed when it
      // comes back - the poll finishing is not permission to carry on.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((n) async {
        if (n == 1) notifier.stopPolling();
        return transactionSuccess();
      });

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1), reason: 'the first poll did happen');

      await advanceOneTick(tester);
      await advanceOneTick(tester);

      expect(transactions, hasLength(1),
          reason: 'the stop must have prevented the timer install');
    });

    testWidgets('a stopPolling during a forced poll installs no timer',
        (tester) async {
      // forcePolling installs the timer too - a pull-to-refresh is allowed to
      // revive a loop an earlier start-up lost - and its install sits on the far
      // side of an await just the same. A reboot is the likely collision: the
      // operator pulls to refresh, then restarts the router, and a timer put back
      // here would have its next ticks report the router unreachable over the
      // restart's own progress dialog.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((n) async {
        if (n == 2) notifier.stopPolling();
        return transactionSuccess();
      });

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1));

      await notifier.forcePolling();
      await tester.pump();
      expect(transactions, hasLength(2), reason: 'the forced poll did happen');

      await advanceOneTick(tester);
      await advanceOneTick(tester);

      expect(transactions, hasLength(2),
          reason: 'the stop must have prevented the timer install');
    });

    testWidgets('a pause during the first-poll delay stops everything',
        (tester) async {
      // `paused` cancels the timer directly rather than through stopPolling, and
      // brings polling back itself on the way out, so the sequence has to stand
      // down on its own.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await tester.pump();
      notifier.paused = true;

      await advanceToFirstPoll(tester);
      await advanceOneTick(tester);

      expect(transactions, isEmpty);

      notifier.paused = false;
      await advanceToFirstPoll(tester);
      expect(transactions, isNotEmpty,
          reason: 'unpausing must start polling again');

      await stopAndSettle(tester);
    });

    testWidgets('a restart supersedes nothing it should not', (tester) async {
      // The ordinary restart path - stopPolling() then startPolling(), as
      // PrepareDashboardView does - must still end up polling. This is the test
      // that would catch a generation check that called off the wrong sequence.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) => transactionSuccess());

      notifier.stopPolling();
      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1));

      await advanceOneTick(tester);
      expect(transactions, hasLength(2));

      await stopAndSettle(tester);
    });
  });

  group('poll failure classification', () {
    testWidgets('a timeout does not log out, and the next tick recovers',
        (tester) async {
      // #7. Every failed poll used to force a logout, so anything that briefly
      // took the router's HTTP service away - a service restart, the make-Master
      // credential rotation - kicked the user back to the login page with a
      // password that was still perfectly good. A timeout is the router not
      // answering, which says nothing about the credential.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((n) async {
        if (n == 1) throw TimeoutException('no answer');
        return transactionSuccess();
      });

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(auth.logoutCount, 0);
      expect(container.read(pollingProvider).hasError, isTrue);

      await advanceOneTick(tester);
      expect(auth.logoutCount, 0);
      final data = container.read(pollingProvider).value;
      expect(data?.data, isNotEmpty, reason: 'the next tick must recover');

      await stopAndSettle(tester);
    });

    testWidgets('an unauthorized JNAPError logs out', (tester) async {
      // The one failure that does mean the session is gone: the router answered,
      // and what it said was that the credential was rejected.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction(
          (_) async => throw const JNAPError(result: errorJNAPUnauthorized));

      notifier.startPolling();
      await advanceToFirstPoll(tester);

      expect(auth.logoutCount, 1);

      await stopAndSettle(tester);
    });

    testWidgets('an unauthorized poll is not asked again', (tester) async {
      // What logging out on the first one is protecting. The router locks the
      // admin account after a handful of refused credentials, and
      // LinksysHttpClient retries a 401 once, so this single poll has already
      // spent two of the operator's attempts. The short re-poll that a router
      // *not answering* earns would spend two more every
      // [pollRetryDelayInSec] - and carry the same rejected password every time,
      // which is how a stale credential turns into a locked account.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction(
          (_) async => throw const JNAPError(result: errorJNAPUnauthorized));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1));

      await advance(tester, const Duration(seconds: 3 * pollRetryDelayInSec));

      expect(transactions, hasLength(1),
          reason: 'no attempt may be spent re-offering a refused credential');

      await stopAndSettle(tester);
    });

    testWidgets('a locked admin account logs out', (tester) async {
      // Unauthorized one step further along: the attempts have run out, so the
      // credential will not be looked at again until the lockout expires.
      // Polling on with it kept feeding the counter that has to run down, and
      // left the operator watching a dashboard that had quietly stopped updating
      // with nothing to say why. The login page this drops them on reports the
      // lockout itself, through its own getAdminPasswordAuthStatus probe.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction(
          (_) async => throw const JNAPError(result: errorAdminAccountLocked));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(auth.logoutCount, 1);

      await advance(tester, const Duration(seconds: 3 * pollRetryDelayInSec));
      expect(transactions, hasLength(1),
          reason: 'and nothing may go on feeding the lockout');

      await stopAndSettle(tester);
    });

    testWidgets('any other JNAPError does not log out', (tester) async {
      // A JNAP-level complaint that is not about the credential is not evidence
      // about the credential.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction(
          (_) async => throw const JNAPError(result: '_ErrorUnknownAction'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);

      expect(auth.logoutCount, 0);

      await stopAndSettle(tester);
    });
  });

  group('reporting an unreachable router', () {
    // #1419. A tolerated failure is still a failure the operator needs to hear
    // about: the provider keeps the previous snapshot as its value, so every
    // consumer goes on drawing it and nothing on screen says the router stopped
    // answering. [routerUnreachableProvider] is the signal the UI reads, and
    // what these tests hold to is when it does and does not claim a problem.
    //
    // The claim is made on a clock, not on a tally of failed polls - see
    // [pollUnreachableAfterInSec] - so what most of these tests turn on is where
    // the fake clock stands relative to that window, and how many requests the
    // router got its chance to answer along the way.

    testWidgets('a router that is answering makes no claim', (tester) async {
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) => transactionSuccess());

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);

      expect(container.read(routerUnreachableProvider), 0);

      await stopAndSettle(tester);
    });

    testWidgets('a blip that ends inside the window is never reported',
        (tester) async {
      // The whole point of the window: a router restarting its HTTP service is
      // back within seconds, and a blocking dialog for a blip is worse than the
      // blip. The clock ends up the far side of where the deadline was, which is
      // what says the deadline was called off rather than merely reset.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((n) async {
        if (n == 1) throw TimeoutException('no answer');
        return transactionSuccess();
      });

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);

      expect(container.read(routerUnreachableProvider), 0);

      await stopAndSettle(tester);
    });

    testWidgets('a failed poll is re-tried without waiting out the interval',
        (tester) async {
      // What keeps the report honest. Left to the periodic timer alone, a router
      // that came back five seconds in would still be reported unreachable at
      // twenty, because nothing had asked it since.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((n) async {
        if (n == 1) throw TimeoutException('no answer');
        return transactionSuccess();
      });

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1));

      await advance(tester, const Duration(seconds: pollRetryDelayInSec));
      expect(transactions, hasLength(2), reason: 'the re-poll must have run');
      expect(container.read(routerUnreachableProvider), 0,
          reason:
              'a re-poll that answers withdraws nothing, and claims nothing');

      await stopAndSettle(tester);
    });

    testWidgets('a refused connection is not reported before the window is up',
        (tester) async {
      // A refused connection fails the instant it is made, so the re-polls come
      // thick and fast. Several failures in is exactly where a rule that counted
      // them would have fired - four seconds into an HTTP-service restart, the
      // very blip this must sit through.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async => throw const SocketException('refused'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advance(tester, const Duration(seconds: 3 * pollRetryDelayInSec));

      expect(transactions.length, greaterThan(3),
          reason: 'the router had several chances to answer');
      expect(container.read(routerUnreachableProvider), 0,
          reason: 'and the window it has to answer in is not up yet');

      await advanceToUnreachable(tester);
      expect(container.read(routerUnreachableProvider), greaterThan(0));

      await stopAndSettle(tester);
    });

    testWidgets('a router that answers with an error is not called unreachable',
        (tester) async {
      // The window is about silence, and a JNAPError is not silence: the router
      // is there and talking, and 'Router Not Found' would be a plain untruth in
      // front of an operator whose router is on the shelf next to them. What is
      // wrong is the request or the session, and each of those reports itself.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction(
          (_) async => throw const JNAPError(result: '_ErrorUnknownAction'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);

      expect(container.read(routerUnreachableProvider), 0);

      await stopAndSettle(tester);
    });

    testWidgets('a router that never answers is reported once the window is up',
        (tester) async {
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async => throw TimeoutException('no answer'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(container.read(routerUnreachableProvider), 0);

      await advanceToUnreachable(tester);
      expect(container.read(routerUnreachableProvider), greaterThan(0));

      await stopAndSettle(tester);
    });

    testWidgets(
        'a failure that takes its time is reported on the same schedule',
        (tester) async {
      // The reason the window is a clock and not a tally. A refused connection
      // fails at once; a timeout takes the request's full 10s and gets one retry
      // from the HTTP client on top. Counting failures would put an unplugged
      // router's alert twice as far out as a merely deaf one's, and the operator
      // in front of it is waiting on the same stale dashboard either way.
      //
      // One request is all this router gets before the window is up, and one is
      // all it takes: the deadline runs out while that poll is still on the wire,
      // and the poll coming back empty is what settles it.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async {
        await Future.delayed(
            const Duration(seconds: pollUnreachableAfterInSec - 2));
        throw TimeoutException('no answer');
      });

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);

      expect(transactions, hasLength(1));
      expect(container.read(routerUnreachableProvider), greaterThan(0));

      await stopAndSettle(tester);
    });

    testWidgets('the re-polls stop once the router has been reported',
        (tester) async {
      // They exist to give a router that is coming back the chance to say so
      // before anybody is told it is gone. Once the operator has been told,
      // re-polling every few seconds behind a dialog that is already up would
      // just pile up requests.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async => throw TimeoutException('no answer'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);
      final pollsWhileWaiting = transactions.length;

      expect(
          pollsWhileWaiting,
          lessThanOrEqualTo(
              pollUnreachableAfterInSec ~/ pollRetryDelayInSec + 1),
          reason: 'the window bounds how many re-polls fit inside it');

      await advance(tester, const Duration(seconds: pollRetryDelayInSec));
      await advance(tester, const Duration(seconds: pollRetryDelayInSec));

      expect(transactions, hasLength(pollsWhileWaiting),
          reason: 'only the periodic tick asks from here on');

      await stopAndSettle(tester);
    });

    testWidgets('a router that comes back on its own withdraws the claim',
        (tester) async {
      var failing = true;
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async {
        if (failing) throw TimeoutException('no answer');
        return transactionSuccess();
      });

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);
      expect(container.read(routerUnreachableProvider), greaterThan(0));

      failing = false;
      await advanceOneTick(tester);

      expect(container.read(routerUnreachableProvider), 0);

      await stopAndSettle(tester);
    });

    testWidgets('a stop calls off the deadline the silence runs against',
        (tester) async {
      // The re-poll is not the only thing a failed poll leaves behind: the
      // deadline outlives it, and a deadline allowed to run out after the stop
      // would report a router that the flow which stopped polling took away on
      // purpose - over that flow's own progress dialog.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async => throw TimeoutException('no answer'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      notifier.stopPolling();

      await advanceToUnreachable(tester);
      await advanceToUnreachable(tester);

      expect(container.read(routerUnreachableProvider), 0);
      expect(transactions, hasLength(1));
    });

    testWidgets('a stop gives whatever polls next its own window',
        (tester) async {
      // A stop has to call off the reckoning as well as the timers. A node reboot
      // stops polling and then forces a single poll of its own, with no
      // startPolling in between to clear things up
      // (InstantTopologyView._doReboot): a window left standing as already used up
      // would have that poll reported the instant it failed, with no grace at all
      // - over the reboot's own progress dialog, which is the one place the
      // operator already knows the router is away.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async => throw TimeoutException('no answer'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);
      final reportedBefore = container.read(routerUnreachableProvider);
      expect(reportedBefore, greaterThan(0),
          reason: 'this router has used its window up');

      notifier.stopPolling();
      await tester.pump();
      final askedBefore = transactions.length;

      await notifier.forcePolling();
      await tester.pump();

      expect(transactions.length, greaterThan(askedBefore),
          reason: 'the forced poll did go out');
      expect(container.read(routerUnreachableProvider), reportedBefore,
          reason: 'and it has the whole window to answer in');

      await stopAndSettle(tester);
    });

    testWidgets('a stop calls off the pending re-try', (tester) async {
      // Everything that takes the router away deliberately - a save with a
      // DeviceRestart side effect, a firmware update, a logout - stops polling
      // first. A re-try that outlived that stop would poll a router nobody is
      // waiting on, and count a failure nobody should be told about.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async => throw TimeoutException('no answer'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1));

      notifier.stopPolling();
      await advance(tester, const Duration(seconds: pollRetryDelayInSec + 1));

      expect(transactions, hasLength(1));
    });

    testWidgets(
        'a poll still on the wire when polling stops counts for nothing',
        (tester) async {
      // The same stop, one moment earlier - and the case the timer check alone
      // does not cover. Everything that takes the router away deliberately calls
      // stopPolling() while a poll may still be waiting for an answer it is now
      // never going to get. That poll lands *after* the stop, and counting it
      // would raise the background alert over the very flow that took the router
      // away - which raises its own alert, on top of this one.
      final onTheWire = Completer<JNAPTransactionSuccessWrap>();
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) => onTheWire.future);

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      expect(transactions, hasLength(1), reason: 'the poll is on the wire');

      notifier.stopPolling();
      onTheWire.completeError(TimeoutException('no answer'));
      await tester.pump();

      expect(container.read(routerUnreachableProvider), 0,
          reason: 'the stop said nobody is watching this router any more');

      await advance(tester, const Duration(seconds: pollRetryDelayInSec + 1));
      expect(transactions, hasLength(1), reason: 'and no re-try was armed');
    });

    testWidgets('a fresh start makes no claim about the new router',
        (tester) async {
      // startPolling is the recovery path the alert's own Try again button runs,
      // so a report surviving it would put the dialog straight back up.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async => throw TimeoutException('no answer'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);
      expect(container.read(routerUnreachableProvider), greaterThan(0));

      notifier.stopPolling();
      notifier.startPolling();

      expect(container.read(routerUnreachableProvider), 0);

      await stopAndSettle(tester);
    });

    testWidgets('a logout clears the report', (tester) async {
      // init() is the logout reset. The login page has no dashboard to correct,
      // and the next login may well be to a router that is perfectly fine.
      whenSend((_) async => deviceMode('Master'));
      whenTransaction((_) async => throw TimeoutException('no answer'));

      notifier.startPolling();
      await advanceToFirstPoll(tester);
      await advanceToUnreachable(tester);
      expect(container.read(routerUnreachableProvider), greaterThan(0));

      await stopAndSettle(tester);
      notifier.init();

      expect(container.read(routerUnreachableProvider), 0);
    });
  });
}
