// RouterRepository.scheduledCommand: the loop behind every status check that
// polls the router (#1904 P0, safety-net row 4).
//
// The real loop, over an executor that records what reaches it, so that its
// delays, stop rules and error mapping are pinned in one place. Provider tests
// that copy the loop into a mock (router_boundary.dart,
// firmware_update_provider_test.dart) lean on what is pinned here.
//
// A loop can be tied to the login its work began in (#1904 P1): a logout then
// ends it before its next request. The "tied to a login" group pins that.
//
// Cancelling the subscription during a delay ends the loop before its next
// request (#1904 P2). An async* loop notices a cancel only at a yield, so the
// loop yields nothing after each delay, ahead of the send.
//
// Time is the test binding's fake clock. Each request waits for the command
// queue's next 50 ms tick before it reaches the executor, so the checks below
// leave a margin after each delay rather than landing on its edge.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/http/linksys_http_client.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/command/http/base_http_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/di.dart';

/// What the router does with one request.
typedef _Answer = Response Function();

Response _ok([Map<String, dynamic> output = const {}]) => Response(
    jsonEncode({keyJnapResult: jnapResultOk, keyJnapOutput: output}), 200);

Response _refused(String result) =>
    Response(jsonEncode({keyJnapResult: result}), 200);

/// Records each request as it reaches the executor, and answers from [answers]
/// in order. Once they run out, every request is answered OK.
class _ScriptedExecutor with JNAPCommandExecutor<Response> {
  final List<_Answer> answers = [];
  final List<JNAPHttpCommand> requests = [];

  /// The executor's timeout and retries as each request saw them.
  final List<(int timeoutMs, int retries)> settings = [];

  /// How long the router takes to answer each request. A request counts as
  /// received when it arrives, before the wait.
  Duration answerDelay = Duration.zero;

  @override
  Future<Response> execute(BaseCommand command) async {
    requests.add(command as JNAPHttpCommand);
    settings.add((timeoutMs, retries));
    if (answerDelay > Duration.zero) await Future.delayed(answerDelay);
    return answers.isEmpty ? _ok() : answers.removeAt(0)();
  }

  @override
  void dropCommand(String id) {}
}

class _TestRouterRepository extends RouterRepository {
  _TestRouterRepository(super.ref, this.executorUnderTest);

  final _ScriptedExecutor executorUnderTest;

  @override
  JNAPCommandExecutor get executor => executorUnderTest;
}

class _LocalConnectivityNotifier extends ConnectivityNotifier {
  @override
  ConnectivityState build() => const ConnectivityState(
        hasInternet: true,
        connectivityInfo: ConnectivityInfo(
          gatewayIp: '192.168.1.1',
          routerType: RouterType.behindManaged,
        ),
      );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // A logout resets the device manager, which asks the service helper.
  mockDependencyRegister();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.createTempSync('scheduled_command').path,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
    (_) async => null,
  );
  messenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/shared_preferences'),
    (_) async => <String, Object>{},
  );

  late _ScriptedExecutor executor;
  late ProviderContainer container;
  late RouterRepository repo;

  setUp(() {
    // Every service, so that every action has a value. JNAPService.values,
    // not a list of the app's services, holds across #1923's PRs.
    buildBetterActions(JNAPService.values.map((s) => s.value).toList());
    executor = _ScriptedExecutor();
    container = ProviderContainer(overrides: [
      connectivityProvider.overrideWith(() => _LocalConnectivityNotifier()),
      routerRepositoryProvider
          .overrideWith((ref) => _TestRouterRepository(ref, executor)),
    ]);
    repo = container.read(routerRepositoryProvider);
  });

  tearDown(() => container.dispose());

  /// Advances the fake clock by [ms], letting timers and microtasks run.
  Future<void> advance(WidgetTester tester, int ms) =>
      tester.pump(Duration(milliseconds: ms));

  /// Lets the loop finish and the command queue's own timer run out, so no
  /// timer is left pending when the test ends. The queue stops after 60 empty
  /// 50 ms ticks, 3 s after its last request.
  Future<void> drainQueue(WidgetTester tester) => advance(tester, 10000);

  /// [testWidgets], with the queue drained after [body] even when it fails.
  /// The queue is a singleton: a timer left behind in a fake clock that nobody
  /// advances any more would keep it from ever sending again, and every case
  /// after the failing one would fail too.
  void queueTest(
    String description,
    Future<void> Function(WidgetTester tester) body,
  ) {
    testWidgets(description, (tester) async {
      try {
        await body(tester);
      } finally {
        await drainQueue(tester);
      }
    });
  }

  /// Starts a loop of [JNAPAction.getFirmwareUpdateStatus] and collects what it
  /// yields, the errors it ends with, and the one `onCompleted` call.
  ({
    List<JNAPResult> results,
    List<Object> errors,
    List<bool> completed,
    Completer<void> done,
  }) run({
    int firstDelay = 1000,
    int retryDelay = 2000,
    int maxRetry = 10,
    bool Function(JNAPResult)? condition,
    int? requestTimeout,
    int? logoutGeneration,
  }) {
    final results = <JNAPResult>[];
    final errors = <Object>[];
    final completed = <bool>[];
    final done = Completer<void>();
    repo
        .scheduledCommand(
          action: JNAPAction.getFirmwareUpdateStatus,
          firstDelayInMilliSec: firstDelay,
          retryDelayInMilliSec: retryDelay,
          maxRetry: maxRetry,
          condition: condition,
          onCompleted: completed.add,
          requestTimeoutOverride: requestTimeout,
          logoutGeneration: logoutGeneration,
        )
        .listen(results.add, onError: errors.add, onDone: done.complete);
    return (results: results, errors: errors, completed: completed, done: done);
  }

  queueTest('waits the first delay, then sends once per retry delay',
      (tester) async {
    final loop = run(firstDelay: 1000, retryDelay: 2000, maxRetry: 3);

    await advance(tester, 900);
    expect(executor.requests, isEmpty, reason: 'still in the first delay');
    await advance(tester, 300); // 1200
    expect(executor.requests, hasLength(1));
    await advance(tester, 1500); // 2700
    expect(executor.requests, hasLength(1), reason: 'in the retry delay');
    await advance(tester, 600); // 3300
    expect(executor.requests, hasLength(2));
    await advance(tester, 2100); // 5400
    expect(executor.requests, hasLength(3));

    await drainQueue(tester);
    expect(executor.requests, hasLength(3), reason: 'maxRetry is 3');
    expect(loop.done.isCompleted, isTrue);
  });

  queueTest('stops as soon as the condition holds, and says so',
      (tester) async {
    executor.answers.addAll([
      () => _ok({'step': 1}),
      () => _ok({'step': 2}),
    ]);
    final loop = run(
      firstDelay: 0,
      retryDelay: 100,
      condition: (result) =>
          result is JNAPSuccess && result.output['step'] == 2,
    );

    await drainQueue(tester);

    expect(executor.requests, hasLength(2),
        reason: 'nothing is sent once the condition holds');
    expect(loop.results.map((r) => (r as JNAPSuccess).output['step']), [1, 2],
        reason: 'the answer that met the condition is still yielded');
    expect(loop.completed, [false], reason: 'the retries did not run out');
    expect(loop.done.isCompleted, isTrue);
  });

  queueTest('stops after maxRetry requests, and says the retries ran out',
      (tester) async {
    final loop = run(
      firstDelay: 0,
      retryDelay: 100,
      maxRetry: 4,
      condition: (_) => false,
    );

    await drainQueue(tester);

    expect(executor.requests, hasLength(4));
    expect(loop.results, hasLength(4));
    expect(loop.completed, [true]);
    expect(loop.done.isCompleted, isTrue);
  });

  queueTest('with maxRetry -1, polls until the condition holds',
      (tester) async {
    executor.answers.addAll([
      for (var step = 1; step <= 12; step++) () => _ok({'step': step}),
    ]);
    final loop = run(
      firstDelay: 0,
      retryDelay: 100,
      maxRetry: -1,
      condition: (result) =>
          result is JNAPSuccess && result.output['step'] == 12,
    );

    await drainQueue(tester);

    expect(executor.requests, hasLength(12),
        reason: 'past the default of 10: -1 means no limit');
    expect(loop.completed, [false]);
    expect(loop.done.isCompleted, isTrue);
  });

  group('a failed request is yielded, and the loop goes on', () {
    queueTest('a JNAP error, as itself', (tester) async {
      executor.answers.add(() => _refused('ErrorUnknownAction'));
      final loop = run(firstDelay: 0, retryDelay: 100, maxRetry: 2);

      await drainQueue(tester);

      expect(loop.results.first, isA<JNAPError>());
      expect((loop.results.first as JNAPError).result, 'ErrorUnknownAction');
      expect(loop.results.last, isA<JNAPSuccess>(),
          reason: 'the next request still went out');
      expect(executor.requests, hasLength(2));
    });

    queueTest('a timeout, as a JNAPError named after it', (tester) async {
      executor.answers.add(() => throw TimeoutException('no answer'));
      final loop = run(firstDelay: 0, retryDelay: 100, maxRetry: 2);

      await drainQueue(tester);

      expect(loop.results.first, isA<JNAPError>());
      expect((loop.results.first as JNAPError).result, 'TimeoutException');
      expect(loop.results.last, isA<JNAPSuccess>());
    });

    queueTest('anything else, as UNKNOWN with the error type', (tester) async {
      executor.answers.add(() => throw StateError('socket closed'));
      final loop = run(firstDelay: 0, retryDelay: 100, maxRetry: 2);

      await drainQueue(tester);

      final error = loop.results.first as JNAPError;
      expect(error.result, 'UNKNOWN');
      expect(error.error, 'StateError');
      expect(loop.results.last, isA<JNAPSuccess>());
    });
  });

  queueTest(
      'a stop condition that throws ends the loop with its error, '
      'without onCompleted', (tester) async {
    // The condition runs outside the request's try, so what it throws ends the
    // loop. Pinned so that a change to it is made on purpose: the firmware
    // install's condition parses each status with casts, so a status it
    // cannot read ends the install's checks this way.
    final loop = run(
      firstDelay: 0,
      retryDelay: 100,
      maxRetry: 5,
      condition: (_) => throw const FormatException('not a status'),
    );

    await drainQueue(tester);

    expect(executor.requests, hasLength(1));
    expect(loop.results, hasLength(1),
        reason: 'the answer is yielded before the condition reads it');
    expect(loop.errors.single, isA<FormatException>());
    expect(loop.completed, isEmpty);
    expect(loop.done.isCompleted, isTrue);
  });

  queueTest(
      'every request skips the cache, is tried once, '
      'and uses the timeout override', (tester) async {
    run(firstDelay: 0, retryDelay: 100, maxRetry: 2, requestTimeout: 3000);

    await drainQueue(tester);

    expect(executor.requests, hasLength(2));
    for (final request in executor.requests) {
      expect(request.cacheLevel, CacheLevel.noCache);
      expect(request.fetchRemote, isTrue);
    }
    expect(executor.settings, everyElement((3000, 0)));
  });

  queueTest('without an override, a request times out after 10 s',
      (tester) async {
    run(firstDelay: 0, retryDelay: 100, maxRetry: 1);

    await drainQueue(tester);

    expect(executor.settings, [(10000, 0)]);
  });

  group('tied to a login', () {
    // A loop given the AuthNotifier.logoutGeneration its work began in (#1904
    // P1). The real AuthNotifier, so the logout is the app's own.
    AuthNotifier auth() => container.read(authProvider.notifier);

    setUp(() {
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
    });

    // AuthNotifier's constructor installs a handler on the shared client.
    tearDown(() => LinksysHttpClient.onError = null);

    queueTest('ends at a logout, before its next request', (tester) async {
      final loop = run(
        firstDelay: 0,
        retryDelay: 2000,
        logoutGeneration: auth().logoutGeneration,
      );
      await advance(tester, 500);
      expect(executor.requests, hasLength(1));

      await auth().logout();
      await drainQueue(tester);

      expect(executor.requests, hasLength(1),
          reason: 'nothing is sent once the logout has happened');
      expect(loop.errors.single, isA<LoggedOutException>());
      expect(loop.completed, isEmpty,
          reason: 'neither did the condition hold, nor did the retries run '
              'out, so the caller is told neither');
      expect(loop.done.isCompleted, isTrue);
    });

    queueTest('drops the answer to a request that was out at the logout',
        (tester) async {
      // The request went out before the logout, but its answer belongs to a
      // login that has ended. Handing it on would let the caller act on it,
      // as the firmware install's completion did (#1956 review).
      executor.answerDelay = const Duration(seconds: 1);
      final loop = run(
        firstDelay: 0,
        retryDelay: 2000,
        logoutGeneration: auth().logoutGeneration,
      );
      await advance(tester, 200);
      expect(executor.requests, hasLength(1), reason: 'the request is out');

      await auth().logout();
      await drainQueue(tester);

      expect(executor.requests, hasLength(1));
      expect(loop.results, isEmpty, reason: 'its answer is not handed on');
      expect(loop.errors.single, isA<LoggedOutException>());
      expect(loop.completed, isEmpty);
    });

    queueTest('started after the logout it belongs to, sends nothing',
        (tester) async {
      // Work that began before a logout and reaches its loop only after it,
      // such as a firmware check whose first request was still out.
      final generation = auth().logoutGeneration;
      await auth().logout();

      final loop =
          run(firstDelay: 0, retryDelay: 100, logoutGeneration: generation);
      await drainQueue(tester);

      expect(executor.requests, isEmpty);
      expect(loop.errors.single, isA<LoggedOutException>());
      expect(loop.completed, isEmpty);
    });

    queueTest('a loop not tied to the login goes on across a logout',
        (tester) async {
      // The other owners keep today's behaviour until #1904 P2 ties them.
      final loop = run(firstDelay: 0, retryDelay: 1000, maxRetry: 3);
      await advance(tester, 500);
      expect(executor.requests, hasLength(1));

      await auth().logout();
      await drainQueue(tester);

      expect(executor.requests, hasLength(3));
      expect(loop.errors, isEmpty);
      expect(loop.completed, [true]);
    });

    queueTest(
        'ends at a logout during its last retry delay, without onCompleted',
        (tester) async {
      // The retries run out at the end of the last delay, with no request
      // after it. A logout in that delay still ends the loop, as one in any
      // other delay does (#1904).
      final loop = run(
        firstDelay: 0,
        retryDelay: 2000,
        maxRetry: 1,
        logoutGeneration: auth().logoutGeneration,
      );
      await advance(tester, 500);
      expect(executor.requests, hasLength(1));

      await auth().logout();
      await drainQueue(tester);

      expect(loop.errors.single, isA<LoggedOutException>());
      expect(loop.completed, isEmpty,
          reason: 'a loop ended by a logout does not say the retries ran out');
      expect(loop.done.isCompleted, isTrue);
    });
  });

  queueTest(
      'cancelling the subscription stops the loop before its next '
      'request', (tester) async {
    final results = <JNAPResult>[];
    final subscription = repo
        .scheduledCommand(
          action: JNAPAction.getFirmwareUpdateStatus,
          firstDelayInMilliSec: 0,
          retryDelayInMilliSec: 2000,
          maxRetry: 10,
        )
        .listen(results.add);

    await advance(tester, 500);
    expect(executor.requests, hasLength(1));
    // Not awaited: an async* stream's cancel completes only once the loop
    // reaches its next yield, and the fake clock does not run while a test
    // awaits.
    var cancelled = false;
    unawaited(subscription.cancel().then((_) => cancelled = true));

    await advance(tester, 10000);
    await drainQueue(tester);

    expect(cancelled, isTrue);
    expect(executor.requests, hasLength(1),
        reason: 'no request after the cancel');
  });

  queueTest('cancelling the subscription during the first delay sends nothing',
      (tester) async {
    final subscription = repo
        .scheduledCommand(
          action: JNAPAction.getFirmwareUpdateStatus,
          firstDelayInMilliSec: 3000,
          retryDelayInMilliSec: 2000,
          maxRetry: 10,
        )
        .listen((_) {});

    await advance(tester, 1000);
    var cancelled = false;
    unawaited(subscription.cancel().then((_) => cancelled = true));
    await advance(tester, 10000);
    await drainQueue(tester);

    expect(cancelled, isTrue);
    expect(executor.requests, isEmpty, reason: 'no request after the cancel');
  });

  queueTest(
      'cancelling the subscription during the last retry delay does not '
      'say the retries ran out', (tester) async {
    final completed = <bool>[];
    final subscription = repo
        .scheduledCommand(
          action: JNAPAction.getFirmwareUpdateStatus,
          firstDelayInMilliSec: 0,
          retryDelayInMilliSec: 2000,
          maxRetry: 1,
          onCompleted: completed.add,
        )
        .listen((_) {});

    await advance(tester, 500);
    expect(executor.requests, hasLength(1));
    var cancelled = false;
    unawaited(subscription.cancel().then((_) => cancelled = true));
    await advance(tester, 10000);
    await drainQueue(tester);

    expect(cancelled, isTrue);
    expect(completed, isEmpty,
        reason: 'a cancelled loop tells its caller nothing');
  });
}
