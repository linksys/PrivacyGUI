import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/screen.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

/// Found by the identifier the page view stamps on the button, not its label.
final _positive = find.byWidgetPredicate(
    (widget) => widget is AppFilledButton && widget.identifier == 'page-save');

AppFilledButton _positiveButton(WidgetTester tester) =>
    tester.widget<AppFilledButton>(_positive);

// The two shared commit points most settings pages save through: the page
// bottom bar and the submit dialog. #1637 guards the bar's positive action in
// read-only mode (page_bottom_bar_access_test.dart); these pin what both do
// with full access - the enable flag alone decides whether the positive action
// can fire, and the negative action follows its own flag.
void main() {
  // The desktop layout builds the top navigation menu, which reads its theme
  // from get_it.
  mockDependencyRegister();

  Future<void> pumpPage(WidgetTester tester,
      {PageBottomBar? bar, ScreenSize size = device1440w}) async {
    await tester.setScreenSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [accessPolicyProvider.overrideWithValue(AccessPolicy.full)],
      child: StyledAppPageView(
        title: 'Settings',
        bottomBar: bar,
        child: (context, constraints) => const SizedBox(height: 100),
      ),
    ));
    await tester.pumpAndSettle();
  }

  // An enabled positive action firing once per tap is pinned by
  // page_bottom_bar_access_test.dart.
  group('PageBottomBar', () {
    testWidgets('a disabled positive action cannot fire', (tester) async {
      var taps = 0;
      await pumpPage(tester,
          bar: PageBottomBar(
            isPositiveEnabled: false,
            onPositiveTap: () => taps++,
          ));

      expect(_positiveButton(tester).onTap, isNull);
      await tester.tap(_positive, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);
    });

    testWidgets('the negative action follows its own flag', (tester) async {
      var negativeTaps = 0;
      await pumpPage(tester,
          bar: PageBottomBar(
            isPositiveEnabled: false,
            isNegitiveEnabled: true,
            negitiveLable: 'Discard',
            onPositiveTap: () {},
            onNegitiveTap: () => negativeTaps++,
          ));

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(negativeTaps, 1);
    });

    testWidgets('the inverse bar fires its destructive action', (tester) async {
      var taps = 0;
      await pumpPage(tester,
          bar: InversePageBottomBar(
            isPositiveEnabled: true,
            positiveLabel: 'Delete',
            onPositiveTap: () => taps++,
          ));

      await tester.tap(_positive);
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('a page without a bar renders no positive action',
        (tester) async {
      await pumpPage(tester);

      expect(_positive, findsNothing);
    });
  });

  // E2E tests locate the bar's buttons by these (constitution 11.2).
  group('PageBottomBar identifiers', () {
    for (final size in [device480w, device1440w]) {
      testWidgets('are page-save and page-cancel by default at ${size.name}',
          (tester) async {
        final semantics = tester.ensureSemantics();
        var saves = 0;
        var cancels = 0;
        await pumpPage(tester,
            size: size,
            bar: PageBottomBar(
              isPositiveEnabled: true,
              isNegitiveEnabled: true,
              onPositiveTap: () => saves++,
              onNegitiveTap: () => cancels++,
            ));

        await tester.tap(find.bySemanticsIdentifier('page-save'));
        await tester.tap(find.bySemanticsIdentifier('page-cancel'));
        await tester.pumpAndSettle();
        // Before any expect: flutter_test checks for a live handle before
        // tear-down runs.
        semantics.dispose();

        expect(saves, 1);
        expect(cancels, 1);
      });
    }

    testWidgets('are the bar\'s own when it passes them', (tester) async {
      final semantics = tester.ensureSemantics();
      await pumpPage(tester,
          bar: PageBottomBar(
            isPositiveEnabled: true,
            isNegitiveEnabled: true,
            positiveLabel: 'Test again',
            negitiveLable: 'Close',
            positiveIdentifier: 'speed-test-again',
            negativeIdentifier: 'speed-test-close',
            onPositiveTap: () {},
            onNegitiveTap: () {},
          ));

      final found = {
        for (final id in [
          'speed-test-again',
          'speed-test-close',
          'page-save',
          'page-cancel',
        ])
          id: find.bySemanticsIdentifier(id).evaluate().length,
      };
      semantics.dispose();

      expect(found, {
        'speed-test-again': 1,
        'speed-test-close': 1,
        'page-save': 0,
        'page-cancel': 0,
      });
    });

    test('copyWith keeps them unless it is given others', () {
      final bar = PageBottomBar(
        isPositiveEnabled: true,
        positiveIdentifier: 'speed-test-again',
        negativeIdentifier: 'speed-test-close',
        onPositiveTap: () {},
      );

      final kept = bar.copyWith(isPositiveEnabled: false);
      final replaced = bar.copyWith(positiveIdentifier: 'speed-test-start');

      expect((kept.positiveIdentifier, kept.negativeIdentifier),
          ('speed-test-again', 'speed-test-close'));
      expect(replaced.positiveIdentifier, 'speed-test-start');
    });
  });

  group('showSubmitAppDialog', () {
    Future<void> open(
      WidgetTester tester, {
      required Future<String> Function() event,
      bool Function()? checkPositiveEnabled,
      void Function(Object?, StackTrace)? onError,
      void Function(String?)? onResult,
    }) async {
      await tester.setScreenSize(device1440w);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(testableSingleRoute(
        locale: const Locale('en'),
        child: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showSubmitAppDialog<String>(
                context,
                title: 'Rename',
                positiveLabel: 'Submit',
                negitiveLabel: 'Close',
                contentBuilder: (context, setState, submit) =>
                    const Text('content'),
                checkPositiveEnabled: checkPositiveEnabled,
                event: event,
                onError: onError,
              ).then((value) => onResult?.call(value)),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    AppTextButton submitButton(WidgetTester tester) =>
        tester.widget(find.widgetWithText(AppTextButton, 'Submit'));

    testWidgets('submit runs the event once and returns its value',
        (tester) async {
      var calls = 0;
      String? result;
      await open(tester,
          event: () async {
            calls++;
            return 'saved';
          },
          onResult: (value) => result = value);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(calls, 1);
      expect(result, 'saved');
      expect(find.text('content'), findsNothing);
    });

    testWidgets('submit is disabled while the check says so', (tester) async {
      var calls = 0;
      await open(tester,
          event: () async {
            calls++;
            return 'saved';
          },
          checkPositiveEnabled: () => false);

      expect(submitButton(tester).onTap, isNull);
      await tester.tap(find.text('Submit'), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(calls, 0);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('a failed event keeps the dialog open and reports the error',
        (tester) async {
      Object? reported;
      await open(tester,
          event: () async => throw StateError('router said no'),
          onError: (error, _) => reported = error);

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      expect(reported, isA<StateError>());
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('cancel closes without running the event', (tester) async {
      var calls = 0;
      await open(tester, event: () async {
        calls++;
        return 'saved';
      });

      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(calls, 0);
      expect(find.text('content'), findsNothing);
    });
  });
}
