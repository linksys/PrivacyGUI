// Baseline for the two shared commit points most settings pages save through:
// the page bottom bar and the submit dialog.
//
// A read-only build is going to disable the positive action at both. These
// tests pin what the default build does today - the enable flag alone decides
// whether the positive action can fire, it fires exactly once per tap, and the
// negative action is left alone - so that change cannot quietly alter the local
// build. Both layouts are covered because the bar builds its buttons separately
// for each.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/read_only/read_only_mode_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

/// Found by the identifier the page view stamps on the button, not its label.
final _positive = find.byWidgetPredicate((widget) =>
    widget is AppFilledButton &&
    widget.identifier == 'now-page-bottom-button-positive');

AppFilledButton _positiveButton(WidgetTester tester) =>
    tester.widget<AppFilledButton>(_positive);

void main() {
  // The desktop layout builds the top navigation menu, which reads its theme
  // from get_it.
  mockDependencyRegister();

  Widget page(PageBottomBar bar, {bool readOnly = false}) =>
      testableSingleRoute(
        overrides: [readOnlyModeProvider.overrideWithValue(readOnly)],
        child: StyledAppPageView(
          title: 'Settings',
          bottomBar: bar,
          child: (context, constraints) => const SizedBox(height: 100),
        ),
      );

  group('PageBottomBar', () {
    testResponsiveWidgets('an enabled positive action fires once per tap',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(page(PageBottomBar(
        isPositiveEnabled: true,
        onPositiveTap: () => taps++,
      )));
      await tester.pumpAndSettle();

      expect(_positiveButton(tester).onTap, isNotNull);
      await tester.tap(_positive);
      await tester.pumpAndSettle();
      expect(taps, 1);
    }, variants: responsiveAllVariants);

    testResponsiveWidgets('a disabled positive action cannot fire',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(page(PageBottomBar(
        isPositiveEnabled: false,
        onPositiveTap: () => taps++,
      )));
      await tester.pumpAndSettle();

      expect(_positiveButton(tester).onTap, isNull);
      await tester.tap(_positive, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(taps, 0);
    }, variants: responsiveAllVariants);

    testResponsiveWidgets('the negative action follows its own flag',
        (tester) async {
      var negativeTaps = 0;
      await tester.pumpWidget(page(PageBottomBar(
        isPositiveEnabled: false,
        isNegitiveEnabled: true,
        negitiveLable: 'Discard',
        onPositiveTap: () {},
        onNegitiveTap: () => negativeTaps++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      await tester.pumpAndSettle();
      expect(negativeTaps, 1);
    }, variants: responsiveAllVariants);

    testResponsiveWidgets('the inverse bar fires its destructive action',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(page(InversePageBottomBar(
        isPositiveEnabled: true,
        positiveLabel: 'Delete',
        onPositiveTap: () => taps++,
      )));
      await tester.pumpAndSettle();

      await tester.tap(_positive);
      await tester.pumpAndSettle();
      expect(taps, 1);
    }, variants: responsiveAllVariants);

    testResponsiveWidgets('a page without a bar renders no positive action',
        (tester) async {
      await tester.pumpWidget(testableSingleRoute(
        child: StyledAppPageView(
          title: 'Status',
          child: (context, constraints) => const SizedBox(height: 100),
        ),
      ));
      await tester.pumpAndSettle();

      expect(_positive, findsNothing);
    }, variants: responsiveAllVariants);
  });

  group('showSubmitAppDialog', () {
    Future<void> open(
      WidgetTester tester, {
      required Future<String> Function() event,
      bool Function()? checkPositiveEnabled,
      void Function(Object?, StackTrace)? onError,
      void Function(String?)? onResult,
      bool readOnly = false,
      bool allowInReadOnly = false,
    }) async {
      await tester.pumpWidget(testableSingleRoute(
        overrides: [readOnlyModeProvider.overrideWithValue(readOnly)],
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
                allowInReadOnly: allowInReadOnly,
              ).then((value) => onResult?.call(value)),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
    }

    AppTextButton submitButton(WidgetTester tester) => tester.widget(
        find.widgetWithText(AppTextButton, 'Submit'));

    testWidgets('submit runs the event once and returns its value',
        (tester) async {
      var calls = 0;
      String? result;
      await open(tester, event: () async {
        calls++;
        return 'saved';
      }, onResult: (value) => result = value);

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

  group('read-only build', () {
    testResponsiveWidgets('the positive action cannot fire', (tester) async {
      var taps = 0;
      await tester.pumpWidget(page(
          PageBottomBar(isPositiveEnabled: true, onPositiveTap: () => taps++),
          readOnly: true));
      await tester.pumpAndSettle();

      expect(_positiveButton(tester).onTap, isNull);
      await tester.tap(_positive, warnIfMissed: false);
      expect(taps, 0);
    }, variants: responsiveAllVariants);

    testResponsiveWidgets('the negative action still works', (tester) async {
      var negativeTaps = 0;
      await tester.pumpWidget(page(
          PageBottomBar(
            isPositiveEnabled: true,
            isNegitiveEnabled: true,
            negitiveLable: 'Discard',
            onPositiveTap: () {},
            onNegitiveTap: () => negativeTaps++,
          ),
          readOnly: true));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Discard'));
      expect(negativeTaps, 1);
    }, variants: responsiveAllVariants);

    testResponsiveWidgets('a bar that writes nothing can opt out',
        (tester) async {
      var taps = 0;
      await tester.pumpWidget(page(
          PageBottomBar(
            isPositiveEnabled: true,
            allowInReadOnly: true,
            onPositiveTap: () => taps++,
          ),
          readOnly: true));
      await tester.pumpAndSettle();

      await tester.tap(_positive);
      expect(taps, 1);
    }, variants: responsiveAllVariants);

    testResponsiveWidgets('the inverse bar keeps the opt-out',
        (tester) async {
      await tester.pumpWidget(page(
          InversePageBottomBar(
            isPositiveEnabled: true,
            allowInReadOnly: true,
            onPositiveTap: () {},
          ),
          readOnly: true));
      await tester.pumpAndSettle();

      expect(_positiveButton(tester).onTap, isNotNull);
    }, variants: responsiveAllVariants);

    testWidgets('copyWith keeps the opt-out', (tester) async {
      final bar = PageBottomBar(
              isPositiveEnabled: true, allowInReadOnly: true, onPositiveTap: () {})
          .copyWith(isPositiveEnabled: false);
      expect(bar.allowInReadOnly, isTrue);
    });

    testWidgets('submit dialog cannot submit', (tester) async {
      var calls = 0;
      await tester.pumpWidget(testableSingleRoute(
        overrides: [readOnlyModeProvider.overrideWithValue(true)],
        child: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showSubmitAppDialog<String>(
                context,
                positiveLabel: 'Submit',
                contentBuilder: (context, setState, submit) =>
                    const Text('content'),
                event: () async {
                  calls++;
                  return 'saved';
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(
          tester
              .widget<AppTextButton>(
                  find.widgetWithText(AppTextButton, 'Submit'))
              .onTap,
          isNull);
      expect(calls, 0);
    });

    testWidgets('submit dialog can opt out', (tester) async {
      var calls = 0;
      await tester.pumpWidget(testableSingleRoute(
        overrides: [readOnlyModeProvider.overrideWithValue(true)],
        child: Builder(
          builder: (context) => Center(
            child: TextButton(
              onPressed: () => showSubmitAppDialog<String>(
                context,
                positiveLabel: 'Submit',
                allowInReadOnly: true,
                contentBuilder: (context, setState, submit) =>
                    const Text('content'),
                event: () async {
                  calls++;
                  return 'saved';
                },
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ));
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();
      expect(calls, 1);
    });
  });
}
