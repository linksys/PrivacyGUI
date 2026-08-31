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
// Two defects are pinned here, both of which shipped without tests:
//
//   #1418 - a single failed getDeviceMode in startPolling() skipped both the
//           command-set build and the timer install, so polling stopped for good
//           and even pull-to-refresh sent an empty transaction.
//   #7    - any failed poll was read as a rejected credential and logged the user
//           out, so a router that briefly took its HTTP service away ejected the
//           session.
//
// Both are "the loop must survive one bad request" defects, which is why they
// share a harness: what needs asserting in each case is what the loop does on
// the tick *after* the failure.

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
  void whenTransaction(Future<JNAPTransactionSuccessWrap> Function(int n) answer) {
    when(mockRepo.transaction(
      any,
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) {
      transactions.add(invocation.positionalArguments.first as JNAPTransactionBuilder);
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

      expect(transactions, hasLength(2));
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
      whenTransaction((_) async =>
          throw const JNAPError(result: errorJNAPUnauthorized));

      notifier.startPolling();
      await advanceToFirstPoll(tester);

      expect(auth.logoutCount, 1);

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
}
