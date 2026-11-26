import 'dart:convert';

import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';

import '../mocks/router_repository_mocks.dart';

/// A JNAP command as the router received it: the action and its payload.
typedef SentCommand = MapEntry<JNAPAction, Map<String, dynamic>>;

/// The router, as a provider under test meets it through [RouterRepository].
///
/// [repo] answers `send`, `transaction` and `scheduledCommand` from one table
/// of outputs, and logs every command in the order the router got it. A test
/// of a save says what the router holds, runs the save, and reads [sent] for
/// what was written.
///
/// An action the table does not name answers OK with no output when its name
/// starts with `set` or `renew`. Any other throws a [StateError] naming the
/// action, so that a provider reading something new cannot pass on an empty
/// answer. A write named otherwise, such as `updateFirmwareNow`, has to be
/// given an answer with [holds].
///
/// The [StateError] reaches the provider, so a provider that catches
/// everything a send throws can swallow it and the test still passes. Assert
/// on what the provider did, such as [actions] or its state, not only that it
/// did not throw.
class RouterBoundary {
  RouterBoundary() : repo = MockRouterRepository() {
    when(repo.send(
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
    )).thenAnswer((invocation) async {
      final action = invocation.positionalArguments.first as JNAPAction;
      final data =
          (invocation.namedArguments[#data] as Map<String, dynamic>?) ?? {};
      sent.add(SentCommand(action, data));
      return _answer(action);
    });
    when(repo.transaction(
      any,
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) async {
      final builder =
          invocation.positionalArguments.first as JNAPTransactionBuilder;
      final commands = [
        for (final command in builder.commands)
          SentCommand(command.key, command.value),
      ];
      sent.addAll(commands);
      transactions.add(commands);
      final failure = _transactionFailure;
      if (failure != null) {
        throw failure;
      }
      return JNAPTransactionSuccessWrap(
        result: 'OK',
        data: [
          for (final command in commands)
            MapEntry(command.key, _answer(command.key)),
        ],
      );
    });
    when(repo.scheduledCommand(
      action: anyNamed('action'),
      retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
      maxRetry: anyNamed('maxRetry'),
      firstDelayInMilliSec: anyNamed('firstDelayInMilliSec'),
      data: anyNamed('data'),
      condition: anyNamed('condition'),
      onCompleted: anyNamed('onCompleted'),
      requestTimeoutOverride: anyNamed('requestTimeoutOverride'),
      auth: anyNamed('auth'),
      logoutGeneration: anyNamed('logoutGeneration'),
    )).thenAnswer((invocation) {
      final named = invocation.namedArguments;
      return _poll(
        named[#action] as JNAPAction,
        data: (named[#data] as Map<String, dynamic>?) ?? {},
        maxRetry: named[#maxRetry] as int,
        firstDelay: named[#firstDelayInMilliSec] as int,
        retryDelay: named[#retryDelayInMilliSec] as int,
        condition: named[#condition] as bool Function(JNAPResult)?,
        onCompleted: named[#onCompleted] as Function(bool)?,
      );
    });
  }

  final MockRouterRepository repo;

  /// Every command the router received: from `send`, from transactions and
  /// from each scheduled poll.
  final List<SentCommand> sent = [];

  /// The commands of each transaction, one list per transaction.
  final List<List<SentCommand>> transactions = [];

  /// Each action's answers, used in turn; the last one stands from then on.
  final Map<JNAPAction, List<JNAPSuccess Function()>> _answers = {};
  Object? _transactionFailure;

  /// The scheduled polls a provider started, one action per poll.
  final List<JNAPAction> polls = [];

  /// Whether a scheduled poll waits out its first and retry delays, as the
  /// real one does. Off, polls run back to back. On, run the test in
  /// testWidgets so that its fake clock, moved by pump, sets the pace.
  bool honorsPollDelays = false;

  /// The router answers [action] with [output].
  void holds(JNAPAction action, Map<String, dynamic> output) {
    _answers[action] = [() => JNAPSuccess(result: 'OK', output: output)];
  }

  /// The router answers [action] with each of [answers] in turn, and with the
  /// last from then on. An answer is an output map, or a [JNAPError] the
  /// router answers with instead.
  void holdsInTurn(JNAPAction action, List<Object> answers) {
    if (answers.isEmpty) {
      throw ArgumentError.value(
          answers, 'answers', 'needs at least one answer for $action');
    }
    _answers[action] = [
      for (final answer in answers)
        switch (answer) {
          final JNAPError error => () => throw error,
          final Map<String, dynamic> output => () =>
              JNAPSuccess(result: 'OK', output: output),
          _ => throw ArgumentError.value(answer, 'answers'),
        },
    ];
  }

  /// The router refuses [action] with [result], whether it comes alone, in a
  /// transaction or in a scheduled poll.
  void refuses(JNAPAction action, {String result = 'ErrorUnknown'}) {
    _answers[action] = [() => throw JNAPError(result: result, error: result)];
  }

  /// Every transaction fails with [error], as a whole.
  void failsTransactions(Object error) {
    _transactionFailure = error;
  }

  /// The payloads the router received for [action], oldest first, as JSON on
  /// the wire: [RouterRepository] encodes each payload, so a model a provider
  /// puts in one arrives as its `toJson`.
  List<Map<String, dynamic>> payloadsOf(JNAPAction action) => [
        for (final command in sent)
          if (command.key == action)
            jsonDecode(jsonEncode(command.value)) as Map<String, dynamic>,
      ];

  /// The actions the router received, in order.
  List<JNAPAction> get actions => [for (final command in sent) command.key];

  JNAPSuccess _answer(JNAPAction action) {
    final turns = _answers[action];
    if (turns != null) {
      return (turns.length > 1 ? turns.removeAt(0) : turns.single)();
    }
    if (action.name.startsWith('set') || action.name.startsWith('renew')) {
      return const JNAPSuccess(result: 'OK', output: {});
    }
    throw StateError('The router was asked for $action, which this test '
        'does not give it.');
  }

  /// [RouterRepository.scheduledCommand], without its delays unless
  /// [honorsPollDelays] is on: each poll sends [action] to the table, yields
  /// the answer, checks [condition], and stops there or once [maxRetry] polls
  /// ran; [onCompleted] is then told whether the polls ran out.
  ///
  /// The delays fall where the real ones do: [firstDelay] before the first
  /// poll, and [retryDelay] after each poll that does not meet [condition],
  /// the last one included.
  ///
  /// A JNAP error is yielded, not thrown, as it is there. Anything else is
  /// thrown, where the real one would yield it as a JNAP error: the only
  /// such throw here is an action the table does not name, which is a gap in
  /// the test, so it fails the test rather than reaching the provider.
  Stream<JNAPResult> _poll(
    JNAPAction action, {
    required Map<String, dynamic> data,
    required int maxRetry,
    required int firstDelay,
    required int retryDelay,
    bool Function(JNAPResult)? condition,
    Function(bool exceedMaxRetry)? onCompleted,
  }) async* {
    polls.add(action);
    var retry = 0;
    var exceededMaxRetry = true;
    while (++retry <= maxRetry || maxRetry == -1) {
      if (honorsPollDelays && retry == 1) {
        await Future.delayed(Duration(milliseconds: firstDelay));
      }
      if (maxRetry == -1 && retry > _endlessPollLimit) {
        throw StateError('$action was polled $_endlessPollLimit times and '
            'never met its condition: give it an answer that does.');
      }
      sent.add(SentCommand(action, data));
      JNAPResult result;
      try {
        result = _answer(action);
      } on JNAPError catch (error) {
        result = error;
      }
      yield result;
      if (condition?.call(result) ?? false) {
        exceededMaxRetry = false;
        break;
      }
      if (honorsPollDelays) {
        await Future.delayed(Duration(milliseconds: retryDelay));
      }
    }
    onCompleted?.call(exceededMaxRetry);
  }

  /// How many times a poll with no limit (maxRetry -1) may run in a test.
  static const _endlessPollLimit = 1000;
}
