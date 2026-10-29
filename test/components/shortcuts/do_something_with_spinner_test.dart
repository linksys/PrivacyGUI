import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// `doSomethingWithSpinner` closes the spinner it opened, and nothing else.
///
/// Bench, 2026-10-07 (#1499): a Wi-Fi save showed "Processing"; while it ran,
/// the reload dropped the event stream and the shell pushed its own "Connection
/// lost" dialog on top. When the save finished, the spinner's `pop()` closed
/// whatever was on top — the recovery dialog — and "Processing" stayed up with
/// no way out (`barrierDismissible: false`, no actions).
void main() {
  final theme = ThemeJsonConfig.defaultConfig().createLightTheme();

  late BuildContext pageContext;
  final processing = find.textContaining('Processing');

  /// Frames, not `pumpAndSettle`: the spinner never stops animating.
  Future<void> frames(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpHost(WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: Builder(builder: (context) {
        pageContext = context;
        return const Scaffold(body: Text('page'));
      }),
    ));
  }

  /// Another dialog pushed over the spinner while the task runs — what the
  /// shell's natural recovery listener does.
  void pushOverlayDialog() {
    showDialog<void>(
      context: pageContext,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(content: Text('Connection lost')),
    );
  }

  testWidgets('with nothing above it, the spinner closes when the task ends',
      (tester) async {
    await pumpHost(tester);
    final task = Completer<void>();

    final done = doSomethingWithSpinner(pageContext, task.future);
    await frames(tester);
    expect(processing, findsOneWidget);

    task.complete();
    await done;
    await frames(tester);

    expect(processing, findsNothing);
    expect(find.text('page'), findsOneWidget);
  });

  for (final outcome in ['succeeds', 'fails']) {
    testWidgets(
        'a dialog pushed above it survives when the task $outcome — only the '
        'spinner closes', (tester) async {
      await pumpHost(tester);
      final task = Completer<void>();

      final done = doSomethingWithSpinner(pageContext, task.future);
      await frames(tester);
      pushOverlayDialog();
      await frames(tester);
      expect(find.text('Connection lost'), findsOneWidget);

      if (outcome == 'succeeds') {
        task.complete();
        await done;
      } else {
        task.completeError(StateError('save failed'));
        await expectLater(done, throwsStateError);
      }
      await frames(tester);

      expect(processing, findsNothing,
          reason: 'the spinner the task opened is gone');
      expect(find.text('Connection lost'), findsOneWidget,
          reason: 'the dialog above it was not the spinner\'s to close');
    });
  }

  testWidgets('a task that ends before the spinner is shown leaves nothing up',
      (tester) async {
    await pumpHost(tester);

    final done = doSomethingWithSpinner(pageContext, Future<void>.value());
    await frames(tester);
    await done;
    await frames(tester);

    expect(processing, findsNothing);
    expect(find.text('page'), findsOneWidget);
  });
}
