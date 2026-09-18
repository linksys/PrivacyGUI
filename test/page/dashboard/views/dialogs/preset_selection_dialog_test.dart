import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/dashboard/models/usp_dashboard_preset.dart';
import 'package:privacy_gui/page/dashboard/views/dialogs/preset_selection_dialog.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Widget tests for the dashboard style picker, covering #1492: the `remote`
/// preset exists only for Remote Assistance, which *forces* it, and it was
/// nonetheless offered as the fifth card to local users — the one mode that can
/// select it is the one mode it is not for.
///
/// The picker's contents had no widget test at all before this file; the only
/// thing that pumped it was the `preset_dialog` golden interaction
/// (`test/golden_test/page/dashboard/localizations/usp_dashboard_view_test.dart`),
/// and a golden cannot assert *absence* — a missing card just shifts pixels that
/// the baseline is then regenerated to accept.
///
/// Deliberately untagged. `run_tests.sh:74` sets
/// `BASE_EXCLUDE_TAGS="golden||loc||ui"` and both CI test jobs go through that
/// script, so tagging this `ui` — as the neighbouring
/// `wifi_channel_dialog_test.dart` does — would make it gate nothing.
void main() {
  /// Every preset the dialog is expected to offer, in declaration order.
  const offered = <UspDashboardPreset>[
    UspDashboardPreset.essential,
    UspDashboardPreset.standard,
    UspDashboardPreset.professional,
    UspDashboardPreset.monitoring,
  ];

  UspDashboardPreset? result;
  bool completed = false;

  setUp(() {
    result = null;
    completed = false;
  });

  Widget host({UspDashboardPreset? currentPreset}) {
    final themeConfig = ThemeJsonConfig.defaultConfig();
    return MaterialApp(
      locale: const Locale('en'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: themeConfig.createLightTheme(),
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () async {
                result = await showPresetSelectionDialog(
                  context,
                  currentPreset: currentPreset,
                );
                completed = true;
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(
    WidgetTester tester, {
    UspDashboardPreset? currentPreset,
  }) async {
    // A tall view: the dialog is scrollable, and an off-screen card is still in
    // the tree, so height does not change any assertion here — it only keeps
    // the default 800px surface from clipping cards out of a hit test.
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(host(currentPreset: currentPreset));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  /// `find.bySemanticsIdentifier` needs the semantics tree, and the handle has
  /// to be disposed *inside* the test body: `_endOfTestVerifications` runs
  /// before `addTearDown` callbacks, so a leaked handle throws its own failure
  /// and masks whatever the test was actually asserting. `finally` keeps that
  /// true when an `expect` throws.
  void testDialog(
      String description, Future<void> Function(WidgetTester) body) {
    testWidgets(description, (tester) async {
      final handle = tester.ensureSemantics();
      try {
        await body(tester);
      } finally {
        handle.dispose();
      }
    });
  }

  group('showPresetSelectionDialog', () {
    // Epic #1474 acceptance 2, and the red→green half of #1492: this fails on
    // `UspDashboardPreset.values` and passes on `.selectable`.
    testDialog('does not offer the remote preset', (tester) async {
      await openDialog(tester);

      expect(find.bySemanticsIdentifier('preset-remote'), findsNothing);
      expect(find.text('Remote Support'), findsNothing);
    });

    testDialog('offers every other preset', (tester) async {
      await openDialog(tester);

      for (final preset in offered) {
        expect(
          find.bySemanticsIdentifier('preset-${preset.name}'),
          findsOneWidget,
          reason: '${preset.name} must stay offered',
        );
      }
      // The count is asserted as well as the membership, so a preset that is
      // added to the enum but not to `offered` fails here rather than silently
      // going untested.
      expect(
        find.bySemanticsIdentifier(RegExp(r'^preset-(?!cancel|apply)')),
        findsNWidgets(offered.length),
      );
    });

    testDialog('applying returns the tapped preset', (tester) async {
      await openDialog(tester);

      await tester.tap(find.bySemanticsIdentifier('preset-monitoring'));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsIdentifier('preset-apply'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(result, UspDashboardPreset.monitoring);
    });

    // The documented consequence of filtering the rendered list but not
    // `currentPreset` (#1492: "do not add fallback logic for it"). A local user
    // who persisted `remote` before the fix keeps a working 8-card layout and
    // simply sees nothing highlighted — so Apply stays enabled and still pops
    // `remote`, which is what RA's forced-preset path relies on.
    testDialog(
        'a non-offered currentPreset highlights nothing and still '
        'round-trips through Apply', (tester) async {
      await openDialog(tester, currentPreset: UspDashboardPreset.remote);

      expect(find.bySemanticsIdentifier('preset-remote'), findsNothing);
      // The highlight is the check icon `_PresetCard` renders only when
      // `isSelected`, so counting it asserts the rendered state rather than the
      // semantics flag behind it.
      expect(find.byIcon(Icons.check_circle), findsNothing);

      await tester.tap(find.bySemanticsIdentifier('preset-apply'));
      await tester.pumpAndSettle();

      expect(result, UspDashboardPreset.remote);
    });

    testDialog('cancelling returns null', (tester) async {
      await openDialog(tester, currentPreset: UspDashboardPreset.standard);

      // The positive counterpart of the highlight assertion above: an *offered*
      // currentPreset does highlight, so "nothing highlighted" there is the
      // filter's consequence and not a broken initial state.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);

      await tester.tap(find.bySemanticsIdentifier('preset-cancel'));
      await tester.pumpAndSettle();

      expect(completed, isTrue);
      expect(result, isNull);
    });
  });
}
