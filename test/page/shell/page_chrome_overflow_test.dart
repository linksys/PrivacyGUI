@Tags(['layout-gate', 'overflow'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../layout_gate/collector.dart';
import '../../layout_gate/families/page_chrome_family.dart';
import '../../layout_gate/locale_tag.dart';
import '../../layout_gate/surface.dart';
import '../../layout_gate/sweep.dart';
import '../../util/app_test_fonts.dart';
import '../../util/dashboard/text_readability_probe.dart';

/// Overflow coverage for the dashboard's **page chrome** — the top bar and the
/// dashboard header — across screen width and locale.
///
/// ## What is where, since #1342
///
/// The two width × locale sweeps are **declared**, not written: `runOverflowSweep`
/// (`test/layout_gate/sweep.dart`) owns the surface, the fresh subtree, the
/// settle, the tolerance filter, the per-cell exception isolation and the
/// aggregated failure, and the two families in
/// `test/layout_gate/families/page_chrome_family.dart` own the axes and the hosts.
/// Nothing about the coordinates measured changed in that port — proved cell by
/// cell against the committed baseline
/// (`./tool/overflow_baseline.sh check chrome`, 1,248 cells identical).
///
/// What stays in this file is everything the runner is not for: the assertions
/// whose oracle is not "did a `RenderFlex` overflow". They are the reason this
/// suite found defects an overflow sweep cannot see — an ellipsized nav chip
/// *fits*, and so does a page title broken mid-word.
///
/// ## Why this exists next to the #1183 gate rather than inside it
///
/// The gate (`test/page/dashboard/cards/dashboard_card_overflow_test.dart`) is
/// card-width-keyed: `dashboard_card_probe.dart`'s `narrowestRealizationOf(span)`
/// computes each span's narrowest *card box* and pumps one card at that width. It
/// never renders a page at a screen width, so a `Row` belonging to the page rather
/// than to a card is invisible to it **by construction** — no amount of tuning the
/// gate would have caught either #1314 or #1328. Hence a separate suite with its
/// own axes, now sharing the whole measurement spine rather than one file.
///
/// ## Tag choice
///
/// `layout-gate` and `overflow` (#1336). `run_tests.sh` only does
/// `--exclude-tags="golden||loc||ui"` and no CI config names either tag — so "in
/// the PR gate" means "not excluded", and `layout-gate` is that meaning written as
/// a name: a PR-blocking defensive layout gate. `overflow` is the narrower second
/// selector, carried only by a suite that pumps cells and asserts zero overflow,
/// so `flutter test --tags overflow` runs this suite and the three card sweeps and
/// nothing else — the pre-commit run. Tagging this `ui` or `loc` would have
/// removed it from the gate silently.
///
/// The readability assertions below share the file and therefore both tags. They
/// are **not** what `overflow` selects for and do not belong to the sweeps: their
/// oracle is "is it still legible", and merging the two questions would blur both.
void main() {
  final localizationsByTag = <String, AppLocalizations>{};

  setUpAll(() async {
    // Without the real fonts every glyph is an Ahem block and every width
    // measured below is fiction.
    await loadAppFonts();

    // The GetIt singletons and the platform channel the hosts read from outside
    // the widget tree.
    prepareChromeHosts();

    for (final locale in AppLocalizations.supportedLocales) {
      localizationsByTag[localeTag(locale)] =
          await AppLocalizations.delegate.load(locale);
    }
  });

  // 12 widths × 26 locales. A literal, not `widths.length * locales.length`,
  // which would be the enumeration restating itself: after the framework's
  // regrouping this sweep reports 12 tests where it used to report 12 cells
  // apiece, so "deliberately regrouped" and "stopped enumerating" look identical
  // in the report and only a hand-written number tells them apart.
  runOverflowSweep(family: const ChromeTopBarFamily(), expectedCellCount: 312);

  // 12 widths × 3 modes × 26 locales. 312 + 936 = the 1,248 cells
  // `test/fixtures/overflow_baselines/chrome.tsv` records.
  runOverflowSweep(family: const ChromeHeaderFamily(), expectedCellCount: 936);

  group('top bar', () {
    testWidgets(
        'keeps the nav labels whole in every locale at and above '
        '${kTopNavLabelMinWidth.toInt()}px', (tester) async {
      final labelledWidths =
          kChromeSweepWidths.where((w) => w >= kTopNavLabelMinWidth).toList();
      final failures = <String>[];

      for (final width in labelledWidths) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kChromeSweepHeight));
          await tester.pumpWidget(
            chromeTopBarHost(locale: locale, cellKey: 'labels-$width-$tag'),
          );
          await settleIgnoringAnimations(tester);

          final l10n = localizationsByTag[tag]!;
          for (final label in [l10n.home, l10n.menu, l10n.support]) {
            final finder = find.descendant(
              of: find.byType(TopNavigationMenu),
              matching: find.text(label),
            );
            if (finder.evaluate().isEmpty) {
              failures.add('${width.toInt()}px $tag: "$label" not rendered');
              continue;
            }
            // `AppChipGroup` gives its label `maxLines: 1` + ellipsis, so this
            // is the layout's own verdict on whether characters were dropped.
            // Overflow alone would not have caught it: an ellipsized label
            // fits, and a chip truncated to "S…" reads as nothing at all.
            if (tester.isTextClipped(finder.first)) {
              failures.add('${width.toInt()}px $tag: "$label" ellipsized');
            }
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'nav labels were dropped or truncated where they are supposed '
            'to fit:\n${failures.join('\n')}',
      );
    });

    testWidgets(
        'goes icon-only below ${kTopNavLabelMinWidth.toInt()}px '
        'without dropping a destination', (tester) async {
      // Disposed inline rather than via `addTearDown`: the binding verifies
      // every handle is released at the end of the test *body*, before tearDowns
      // run, so a deferred dispose fails the test it was meant to clean up.
      final handle = tester.ensureSemantics();

      // Identifiers and chip counts do not vary by locale, so one locale is the
      // whole story here — unlike the label-fit assertion above.
      final iconOnlyWidths = kChromeSweepWidths
          .where((w) => w > AppLayoutConfig.breakpointMobile)
          .where((w) => w < kTopNavLabelMinWidth)
          .toList();
      expect(iconOnlyWidths, isNotEmpty,
          reason: 'the sweep must cover the icon-only band');

      for (final width in iconOnlyWidths) {
        await setLayoutSurface(tester, Size(width, kChromeSweepHeight));
        await tester.pumpWidget(
          chromeTopBarHost(locale: const Locale('en'), cellKey: 'icons-$width'),
        );
        await settleIgnoringAnimations(tester);

        expect(find.byType(TopNavigationMenu), findsOneWidget,
            reason: 'the top nav must still be shown at ${width.toInt()}px');
        for (final type in NaviType.values) {
          expect(
            find.bySemanticsIdentifier('nav-${type.name}'),
            findsOneWidget,
            reason: 'icon-only hides the labels, not the destinations — '
                'nav-${type.name} missing at ${width.toInt()}px',
          );
        }
        // The label text is what goes away, and it is the reason the row fits.
        expect(
          find.descendant(
            of: find.byType(TopNavigationMenu),
            matching: find.text(localizationsByTag['en']!.home),
          ),
          findsNothing,
          reason: 'chips must be icon-only at ${width.toInt()}px',
        );
      }

      handle.dispose();
    });
  });

  group('dashboard header', () {
    testWidgets('keeps the page title whole at the narrowest supported width',
        (tester) async {
      const width = 320.0;
      final failures = <String>[];

      // This is the assertion that stops "green but unreadable" from passing for
      // this widget, and it found two defects, not one. Collapsing the actions
      // leaves the title 188px at 320px; every overflow assertion in this file
      // stayed green while the title was first *ellipsized* and later *broken
      // mid-word*, because both of those fit.
      //
      // Hence two verdicts per cell, and the second one is not redundant:
      // `didExceedMaxLines` is blind to a mid-word break (nothing was dropped,
      // so nothing "exceeded"), and `hasSplitToken` is blind to an ellipsis (the
      // surviving tokens all fit). "Instrumentpane / l" is the case that proved
      // it — 3.6px over the box, reported clean by the first check alone.
      for (final mode in kChromeHeaderModes) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, const Size(width, kChromeSweepHeight));
          await tester.pumpWidget(chromeHeaderHost(
            locale: locale,
            cellKey: 'title-$tag-${mode.id}',
            isEditMode: mode.isEditMode,
            isRemoteMode: mode.isRemoteMode,
          ));
          await settleIgnoringAnimations(tester);

          final title = find.text(localizationsByTag[tag]!.uspDashboard);
          if (title.evaluate().isEmpty) {
            failures.add('$tag [${mode.label}]: title not rendered');
            continue;
          }
          // Report the numbers, not just the verdict: "granted 188.0, wants
          // 191.6" is what turns this failure into a decision about type size
          // versus wording, which is exactly the decision it forced both times.
          final paragraph = tester.paragraphOf(title);
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px, widest token '
              '${tester.widestTokenWidth(title).toStringAsFixed(1)}px, whole '
              'string ${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px '
              '— "${localizationsByTag[tag]!.uspDashboard}"';
          if (tester.isTextClipped(title)) {
            failures.add('$tag [${mode.label}]: title ellipsized — $numbers');
          } else if (tester.hasSplitToken(title)) {
            failures.add('$tag [${mode.label}]: title broken mid-word — '
                '$numbers');
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'the page title must stay readable at ${width.toInt()}px:\n'
            '${failures.join('\n')}',
      );
    });

    testWidgets('reaches every collapsed action through the overflow menu',
        (tester) async {
      // Disposed inline rather than via `addTearDown`: the binding verifies
      // every handle is released at the end of the test *body*, before tearDowns
      // run, so a deferred dispose fails the test it was meant to clean up.
      final handle = tester.ensureSemantics();

      for (final mode in kChromeHeaderModes) {
        // The action that keeps its own button, and the ones that move into the
        // menu. Identifier values are unchanged from the pre-#1314 header — the
        // only change is that below 600px the menu has to be open first.
        final (primary, collapsed) = switch (mode.isEditMode) {
          true => (
              'dashboard-edit-commit',
              [
                'dashboard-optimize-layout',
                'dashboard-layout-settings',
                'dashboard-edit-cancel'
              ],
            ),
          false when mode.isRemoteMode => (
              'dashboard-refresh',
              ['dashboard-print'],
            ),
          false => (
              'dashboard-refresh',
              ['dashboard-print', 'dashboard-edit'],
            ),
        };

        await setLayoutSurface(tester, const Size(320, kChromeSweepHeight));
        await tester.pumpWidget(chromeHeaderHost(
          locale: const Locale('en'),
          cellKey: 'menu-${mode.id}',
          isEditMode: mode.isEditMode,
          isRemoteMode: mode.isRemoteMode,
        ));
        await settleIgnoringAnimations(tester);

        expect(find.bySemanticsIdentifier(primary), findsOneWidget,
            reason: '$primary keeps its own button in [${mode.label}]');
        expect(
            find.bySemanticsIdentifier('dashboard-header-more'), findsOneWidget,
            reason:
                'the overflow trigger must be anchorable in [${mode.label}]');
        for (final id in collapsed) {
          expect(find.bySemanticsIdentifier(id), findsNothing,
              reason: '$id is behind the menu while it is closed');
        }

        await tester.tap(find.byIcon(Icons.more_vert));
        await settleIgnoringAnimations(tester);

        for (final id in collapsed) {
          expect(find.bySemanticsIdentifier(id), findsOneWidget,
              reason: '$id must be reachable once the menu is open '
                  'in [${mode.label}]');
        }
      }

      handle.dispose();
    });

    testWidgets('menu selection invokes the action the item was built from',
        (tester) async {
      // Disposed inline rather than via `addTearDown`: the binding verifies
      // every handle is released at the end of the test *body*, before tearDowns
      // run, so a deferred dispose fails the test it was meant to clean up.
      final handle = tester.ensureSemantics();
      var printed = 0;

      await setLayoutSurface(tester, const Size(320, kChromeSweepHeight));
      await tester.pumpWidget(chromeHeaderHost(
        locale: const Locale('en'),
        cellKey: 'invoke-print',
        isEditMode: false,
        isRemoteMode: false,
        onPrint: () => printed++,
      ));
      await settleIgnoringAnimations(tester);

      await tester.tap(find.byIcon(Icons.more_vert));
      await settleIgnoringAnimations(tester);
      await tester.tap(find.bySemanticsIdentifier('dashboard-print'));
      await settleIgnoringAnimations(tester);

      expect(printed, 1,
          reason: 'the collapsed form must run the same callback the wide '
              'button does');

      handle.dispose();
    });
  });

  group('header headroom', () {
    testWidgets(
        'collapsed, the action cluster does not grow with the action '
        'count', (tester) async {
      // #1314's second acceptance criterion, as a measurement rather than a
      // promise. Below 600px the row is [primary, gap, ⋮] whatever the mode
      // holds, so a fifth action would land in the menu and cost the header
      // nothing. Comparing the primary button's left edge is what proves it:
      // the cluster is right-aligned against a fixed edge, so equal left edges
      // mean equal cluster widths — for three actions and for four.
      Future<double> primaryLeftEdge({
        required bool isEditMode,
        required IconData primaryIcon,
        required double width,
      }) async {
        await setLayoutSurface(tester, Size(width, kChromeSweepHeight));
        await tester.pumpWidget(chromeHeaderHost(
          locale: const Locale('en'),
          cellKey: 'headroom-$width-$isEditMode',
          isEditMode: isEditMode,
          isRemoteMode: false,
        ));
        await settleIgnoringAnimations(tester);
        return tester.getTopLeft(find.byIcon(primaryIcon)).dx;
      }

      final viewing = await primaryLeftEdge(
        isEditMode: false,
        primaryIcon: Icons.refresh,
        width: 320,
      );
      expect(find.byType(AppIconButton), findsOneWidget,
          reason: 'viewing mode collapses three actions to one button');

      final editing = await primaryLeftEdge(
        isEditMode: true,
        primaryIcon: Icons.check,
        width: 320,
      );
      expect(find.byType(AppIconButton), findsOneWidget,
          reason: 'editing mode collapses four actions to one button');

      expect(
        editing,
        closeTo(viewing, 0.5),
        reason: 'one more action must not move the cluster: viewing started at '
            '${viewing.toStringAsFixed(1)}px, editing at '
            '${editing.toStringAsFixed(1)}px',
      );
    });

    testWidgets('wide, the header still shows every action as its own button',
        (tester) async {
      // The contrast that makes the assertion above meaningful, and the
      // regression guard for "the wide header renders exactly as it did before
      // #1314".
      for (final mode in kChromeHeaderModes) {
        final expected = switch (mode.isEditMode) {
          true => 4,
          false when mode.isRemoteMode => 2,
          false => 3,
        };
        await setLayoutSurface(tester, const Size(1280, kChromeSweepHeight));
        await tester.pumpWidget(chromeHeaderHost(
          locale: const Locale('en'),
          cellKey: 'wide-${mode.id}',
          isEditMode: mode.isEditMode,
          isRemoteMode: mode.isRemoteMode,
        ));
        await settleIgnoringAnimations(tester);

        expect(find.byType(AppIconButton), findsNWidgets(expected),
            reason: '[${mode.label}] must show $expected buttons at 1280px');
        expect(find.byType(AppPopupMenu<VoidCallback>), findsNothing,
            reason: 'no overflow menu in the wide form [${mode.label}]');
      }
    });
  });
}
