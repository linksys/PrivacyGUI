import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';

import '../../../common/testable_widget.dart';

class _Page extends StatefulWidget {
  const _Page(this.error);
  final Object? error;

  @override
  State<_Page> createState() => _PageState();
}

class _PageState extends State<_Page> with PageSnackbarMixin {
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: () => showErrorMessageSnackBar(widget.error),
        child: const Text('fail'),
      );
}

void main() {
  Future<void> failWith(WidgetTester tester, Object? error) async {
    await tester.pumpWidget(testableWidget(child: _Page(error)));
    await tester.tap(find.text('fail'));
    await tester.pump();
  }

  // #1637: the app root already says why for every refused write, so a page
  // reporting its own failed save must not say it a second time.
  testWidgets('a refused write adds no second snackbar', (tester) async {
    await failWith(
        tester, const ReadOnlyAccessException(JNAPAction.setWANSettings));

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('an error that is not a JNAP error still gets a message',
      (tester) async {
    await failWith(tester, StateError('boom'));

    expect(tester.takeException(), isNull);
    expect(find.text('Unknown error'), findsOneWidget);
  });

  testWidgets('a timeout keeps its general message', (tester) async {
    await failWith(tester, TimeoutException('slow'));

    expect(find.text('Oops, something wrong here! Please try again later'),
        findsOneWidget);
  });

  testWidgets('a JNAP error keeps its mapped message', (tester) async {
    await failWith(tester, const JNAPError(result: 'ErrorInvalidIPAddress'));

    expect(find.text('Invalid IP address'), findsOneWidget);
  });
}
