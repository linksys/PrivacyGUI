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
/// [repo] answers `send` and `transaction` from one table of outputs, and logs
/// every command in the order the router got it. A test of a save says what the
/// router holds, runs the save, and reads [sent] for what was written.
///
/// An action the table does not name answers OK with no output when its name
/// starts with `set` or `renew`; any other fails the test, naming the action,
/// so that a provider reading something new cannot pass on an empty answer.
/// A write named otherwise, such as `updateFirmwareNow`, has to be given an
/// answer with [holds].
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
  }

  final MockRouterRepository repo;

  /// Every command the router received, from `send` and from transactions.
  final List<SentCommand> sent = [];

  /// The commands of each transaction, one list per transaction.
  final List<List<SentCommand>> transactions = [];

  final Map<JNAPAction, JNAPSuccess Function()> _answers = {};
  Object? _transactionFailure;

  /// The router answers [action] with [output].
  void holds(JNAPAction action, Map<String, dynamic> output) {
    _answers[action] = () => JNAPSuccess(result: 'OK', output: output);
  }

  /// The router refuses [action], whether it comes alone or in a transaction.
  void refuses(JNAPAction action) {
    _answers[action] = () =>
        throw const JNAPError(result: 'ErrorUnknown', error: 'ErrorUnknown');
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
    final answer = _answers[action];
    if (answer != null) {
      return answer();
    }
    if (action.name.startsWith('set') || action.name.startsWith('renew')) {
      return const JNAPSuccess(result: 'OK', output: {});
    }
    throw StateError('The router was asked for $action, which this test '
        'does not give it.');
  }
}
