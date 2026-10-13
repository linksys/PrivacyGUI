// #1683: the spinner a long task puts up has to take away its own dialog when
// the task ends, and only that one - not the background router-not-found alert
// (#1419) that can arrive on top of it while the task runs.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/route/router_provider.dart';

import '../../../common/di.dart';
import '../../../common/testable_router.dart';

void main() {
  mockDependencyRegister();

  /// The spinner, found by the message it shows by default.
  final spinner = find.text('Processing...');

  /// The dialog that lands on top of the spinner while its task is running.
  final alert = find.text('on top');

  late Completer<void> task;

  /// Puts up a spinner over a task the test finishes when it chooses.
  Future<void> startTask(WidgetTester tester) async {
    task = Completer<void>();
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      child: Builder(
        builder: (context) => TextButton(
          // A real handler rather than ignore(): an async function that returns
          // a chained future hands its error on to that future, which ignore()
          // never marked, and the failure would surface as an uncaught error.
          onPressed: () => doSomethingWithSpinner(context, task.future)
              .catchError((_) => null),
          child: const Text('start'),
        ),
      ),
    ));
    await tester.tap(find.text('start'));
    // The spinner goes up on the next event-loop turn, and the task is only
    // waited on 100ms after that.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(spinner, findsOneWidget,
        reason: 'the spinner is what is under test');
  }

  /// Lets a dialog finish coming or going.
  ///
  /// Not pumpAndSettle: the spinner animates for as long as it is on screen,
  /// so nothing settles while it is up - which is the failure under test.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
  }

  /// Pushes a dialog over the spinner, the way the background alert arrives.
  ///
  /// Onto the shell navigator, which is where the alert is pushed. The spinner
  /// sits on the root one, and in this harness the two are the same navigator -
  /// as they are for any dialog in the app, since both are shown on the root.
  void pushDialogOnTop() {
    showDialog<void>(
      context: shellNavigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(content: Text('on top')),
    );
  }

  testWidgets('a task that ends takes its spinner away', (tester) async {
    await startTask(tester);

    task.complete();
    await tester.pumpAndSettle();

    expect(spinner, findsNothing);
  });

  testWidgets('a task that fails takes its spinner away too', (tester) async {
    await startTask(tester);

    task.completeError(Exception('no answer'));
    await tester.pumpAndSettle();

    expect(spinner, findsNothing);
  });

  testWidgets('a dialog that arrived on top of the spinner is left alone',
      (tester) async {
    await startTask(tester);
    pushDialogOnTop();
    await settle(tester);
    expect(alert, findsOneWidget);

    task.completeError(Exception('no answer'));
    await settle(tester);

    expect(alert, findsOneWidget,
        reason: 'it was not the spinner that put it up');
    expect(spinner, findsNothing,
        reason: 'and the spinner must not outlive its task behind it');

    shellNavigatorKey.currentState!.pop();
    await settle(tester);
  });
}
