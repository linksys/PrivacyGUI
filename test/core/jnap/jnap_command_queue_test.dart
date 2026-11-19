import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';
import 'package:privacy_gui/core/jnap/jnap_command_queue.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/spec/jnap_spec.dart';

class _Executor extends Fake implements JNAPCommandExecutor<JNAPResult> {}

/// A command whose [publish] logs its action and answers with [answer].
class _Command extends BaseCommand<JNAPResult, HttpJNAPSpec> {
  _Command(String action, this.log, {Future<JNAPResult> Function()? answer})
      : answer = answer ?? (() async => _ok),
        super(spec: HttpJNAPSpec(action: action), executor: _Executor());

  final List<String> log;
  final Future<JNAPResult> Function() answer;

  @override
  Future<JNAPResult> publish() {
    log.add(spec.action);
    return answer();
  }
}

const _ok = JNAPSuccess(result: 'OK');

/// One tick of the queue's timer.
const _tick = Duration(milliseconds: 50);

/// What an enqueued command came back with, once it has. The tests read it
/// after pumping, and never await the queue's future: a queue that stalls
/// then fails a test instead of hanging it on the fake clock.
class _Outcome {
  Object? value;
  Object? error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  // The queue's constructor reads the command cache, which reaches for the
  // temp directory.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.path,
  );

  late CommandQueue queue;
  late List<String> log;

  // The queue is a singleton. It is built here, on the real clock, so that
  // its cache starts its file work outside the tests' fake clock.
  setUpAll(() async {
    queue = CommandQueue();
    await pumpEventQueue();
  });

  setUp(() {
    log = [];
    // A test that fails while the queue is paused must not leave the next
    // tests paused too.
    queue.pause = false;
  });

  _Outcome enqueue(String action, {Future<JNAPResult> Function()? answer}) {
    final outcome = _Outcome();
    queue.enqueue(_Command(action, log, answer: answer)).then(
          (value) => outcome.value = value,
          onError: (Object error) => outcome.error = error,
        );
    return outcome;
  }

  /// Runs the queue dry: after sixty empty ticks it stops its timer. Each test
  /// ends with this, and testWidgets fails a test that ends with a timer still
  /// running, so every test also checks that the queue stops.
  Future<void> idle(WidgetTester tester) =>
      tester.pump(const Duration(seconds: 4));

  testWidgets('runs one command a tick, in the order they came',
      (tester) async {
    final first = enqueue('first');
    final second = enqueue('second');

    await tester.pump(_tick);
    expect(log, ['first']);
    await tester.pump(_tick);
    expect(log, ['first', 'second']);
    expect((first.value, second.value), (_ok, _ok));

    await idle(tester);
  });

  testWidgets('completes a command that fails with its error', (tester) async {
    final failed = enqueue('failing',
        answer: () async => throw const JNAPError(result: 'ErrorUnknown'));

    final next = enqueue('next');

    await tester.pump(_tick);
    expect(failed.error, isA<JNAPError>());
    // The queue goes on to the next command.
    await tester.pump(_tick);
    expect(log, ['failing', 'next']);
    expect(next.value, _ok);

    await idle(tester);
  });

  testWidgets('holds its commands while paused', (tester) async {
    queue.pause = true;
    final held = enqueue('held');

    await tester.pump(_tick * 10);
    expect(log, isEmpty);

    queue.pause = false;
    await tester.pump(_tick);
    expect(log, ['held']);
    expect(held.value, _ok);

    await idle(tester);
  });

  testWidgets('starts again for a command that comes after it stopped',
      (tester) async {
    enqueue('first');
    await tester.pump(_tick);
    await idle(tester);

    final next = enqueue('next');
    await tester.pump(_tick);

    expect(log, ['first', 'next']);
    expect(next.value, _ok);

    await idle(tester);
  });
}
