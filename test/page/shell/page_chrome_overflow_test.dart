@Tags(['layout-gate', 'overflow'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/styled/menus/menu_consts.dart';
import 'package:privacy_gui/components/styled/menus/widgets/top_navigation_menu.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/apps/providers/apps_capability_provider.dart';
import 'package:privacy_gui/page/dashboard/views/components/dashboard_header_bar.dart';
import 'package:privacy_gui/page/shell/usp_dashboard_shell.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
// `uspShellNavigatorKey` lives in `route_usp_dashboard.dart`, which is a part of
// this library.
import 'package:privacy_gui/route/router_provider.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../golden_test/golden_framework/mocks/mock_common.dart';
import '../../layout_gate/locale_tag.dart';
import '../../util/app_test_fonts.dart';
import '../../util/dashboard/text_readability_probe.dart';
import '../../util/overflow_baseline.dart';
import '../../util/overflow_probe.dart';

/// Overflow coverage for the dashboard's **page chrome** — the top bar and the
/// dashboard header — across screen width and locale.
///
/// ## Why this exists next to the #1183 gate rather than inside it
///
/// The gate (`test/page/dashboard/cards/dashboard_card_overflow_test.dart`) is
/// card-width-keyed: `dashboard_card_probe.dart`'s `narrowestRealizationOf(span)`
/// computes each span's narrowest *card box* and pumps one card at that width. It
/// never renders a page at a screen width, so a `Row` belonging to the page
/// rather than to a card is invisible to it **by construction** — no amount of
/// tuning the gate would have caught either bug below. Hence a separate suite
/// with its own axes, sharing only the measurement spine — `test/layout_gate/`
/// since #1338/#1340, still reached through `test/util/overflow_probe.dart`,
/// which is now a re-export of it. This suite's surface handling is part of that
/// sharing as of #1340: the three-line dance it hand-copied seven times, and the
/// private teardown that undid it, are now `setLayoutSurface` in
/// `test/layout_gate/surface.dart`, which the card path calls too and which
/// registers the restore itself.
///
/// ## The two defects it pins
///
/// - **#1314, dashboard header.** `Row(spaceBetween)` with an unbounded title on
///   the left and three or four `AppIconButton`s on the right. Neither child
///   could yield, so it overflowed at and below 480px.
/// - **#1328, top bar.** `Row(spaceBetween)` with three rigid children. The
///   failure band was **601–767px**, not the narrow widths intuition suggests:
///   `menu_holder.dart` collapses the top nav to `SizedBox.shrink()` below 601px,
///   so the row broke at exactly the width the nav chips appear at. `en` cleared
///   at 640px but `pl` needed 768px — **locale is a first-class axis here**, and
///   an `en`-only measurement would have reported a 167px-wide failure band as a
///   39px edge case.
///
/// ## Tag choice
///
/// `layout-gate` and `overflow` (#1336). `run_tests.sh` only does
/// `--exclude-tags="golden||loc||ui"` and no CI config names either tag — so
/// "in the PR gate" means "not excluded", and `layout-gate` is that meaning
/// written as a name: a PR-blocking defensive layout gate. `overflow` is the
/// narrower second selector, carried only by a suite that pumps cells and
/// asserts zero overflow, so `flutter test --tags overflow` runs this suite and
/// the three card sweeps and nothing else — the pre-commit run.
/// Tagging this `ui` or `loc` would have removed it from the gate silently.
void main() {
  /// Widths swept per locale.
  ///
  /// Both sides of both breakpoints that matter — `breakpointMobile` (600) and
  /// [kTopNavLabelMinWidth] (768) — plus the interior of the 601–767 band #1328
  /// broke in, plus 320 as the narrowest width the app claims to support.
  const sweepWidths = <double>[
    320,
    375,
    480,
    600,
    601,
    640,
    700,
    768,
    800,
    905,
    1024,
    1280,
  ];

  /// Tall enough that nothing is vertically pressured: every assertion here is
  /// about horizontal fit, and a short surface would add unrelated incidents.
  const sweepHeight = 800.0;

  /// The three action sets [DashboardHeaderBar] can render.
  ///
  /// Not the full 2×2 of the two flags: edit mode ignores `isRemoteMode`
  /// entirely (the edit action is already gone), so `editing + remote` is the
  /// same tree as `editing + local` and sweeping it would buy nothing.
  ///
  /// Two names per mode, and the split matters (#1356). [id] is the identity: it
  /// goes into the baseline cell id and the host's widget key, so it must change
  /// only when the *case* changes. [label] is prose for failure messages, and is
  /// free to say how many actions the mode renders — which is exactly why the
  /// count cannot be in the id. It was: the ids read
  /// `mode=viewing, local (3 actions)`, so adding or moving a header action
  /// renamed every cell of this sweep, and the baseline diff would have reported
  /// a re-labelled coordinate as its whole coverage lost and an equal number of
  /// new cells found — the one reading `overflow_baselines.md` tells a porter to
  /// treat as the dangerous case.
  const headerModes =
      <({String id, String label, bool isEditMode, bool isRemoteMode})>[
    (
      id: 'viewing_local',
      label: 'viewing, local (3 actions)',
      isEditMode: false,
      isRemoteMode: false
    ),
    (
      id: 'viewing_remote',
      label: 'viewing, remote (2 actions)',
      isEditMode: false,
      isRemoteMode: true
    ),
    (
      id: 'editing',
      label: 'editing (4 actions)',
      isEditMode: true,
      isRemoteMode: false
    ),
  ];

  final localizationsByTag = <String, AppLocalizations>{};

  setUpAll(() async {
    // Without the real fonts every glyph is an Ahem block and every width
    // measured below is fiction.
    await loadAppFonts();

    // Called for its side effect only. It registers the GetIt singletons
    // `UspTopBar` and `buildStudioThemeData` read; the override list it returns
    // is discarded because this suite needs the *widest* top bar — logged in
    // with the Apps capability on — and `commonOverrides` pins both to their
    // logged-out values. See [_widestTopBarOverrides].
    commonOverrides();

    _stubPackageInfoChannel();

    for (final locale in AppLocalizations.supportedLocales) {
      localizationsByTag[localeTag(locale)] =
          await AppLocalizations.delegate.load(locale);
    }
  });

  group('top bar', () {
    for (final width in sweepWidths) {
      testWidgets('lays out cleanly at ${width.toInt()}px in every locale',
          (tester) async {
        final failures = <String>[];

        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          final incidents = await collectOverflow(
            tester,
            _topBarHost(locale: locale, cellKey: '$width-$tag'),
            surfaceSize: Size(width, sweepHeight),
            cell: OverflowCell('chrome.top_bar', {
              // `screen_px`, not `px`: what this sweep varies is the screen, while
              // the card sweeps vary a card inside one. Both would read `px=800`
              // and mean different things — and these ids are what a porter greps
              // when a row changes.
              //
              // Whole pixels, the same identity `CardWidthCase.widthKey` gives a
              // width — and rounded rather than truncated for the same reason it
              // is: two widths a pixel apart must not collapse into one cell id.
              'screen_px': width.toStringAsFixed(0),
              'locale': tag,
            }),
          );
          final real =
              incidents.where((i) => i.pixels > kOverflowTolerancePx).toList();
          if (real.isNotEmpty) {
            failures.add('$tag: ${real.join(', ')}');
          }
        }

        expect(
          failures,
          isEmpty,
          reason: 'top bar overflowed at ${width.toInt()}px in '
              '${failures.length} locale(s):\n${failures.join('\n')}',
        );
      });
    }

    testWidgets(
        'keeps the nav labels whole in every locale at and above '
        '${kTopNavLabelMinWidth.toInt()}px', (tester) async {
      final labelledWidths =
          sweepWidths.where((w) => w >= kTopNavLabelMinWidth).toList();
      final failures = <String>[];

      for (final width in labelledWidths) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, sweepHeight));
          await tester.pumpWidget(
            _topBarHost(locale: locale, cellKey: 'labels-$width-$tag'),
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
      final iconOnlyWidths = sweepWidths
          .where((w) => w > AppLayoutConfig.breakpointMobile)
          .where((w) => w < kTopNavLabelMinWidth)
          .toList();
      expect(iconOnlyWidths, isNotEmpty,
          reason: 'the sweep must cover the icon-only band');

      for (final width in iconOnlyWidths) {
        await setLayoutSurface(tester, Size(width, sweepHeight));
        await tester.pumpWidget(
          _topBarHost(locale: const Locale('en'), cellKey: 'icons-$width'),
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
    for (final width in sweepWidths) {
      testWidgets('lays out cleanly at ${width.toInt()}px in every locale',
          (tester) async {
        final failures = <String>[];

        for (final mode in headerModes) {
          for (final locale in AppLocalizations.supportedLocales) {
            final tag = localeTag(locale);
            final incidents = await collectOverflow(
              tester,
              _headerHost(
                locale: locale,
                cellKey: '$width-$tag-${mode.id}',
                isEditMode: mode.isEditMode,
                isRemoteMode: mode.isRemoteMode,
              ),
              surfaceSize: Size(width, sweepHeight),
              cell: OverflowCell('chrome.header', {
                // The screen width, as in `chrome.top_bar` above.
                'screen_px': width.toStringAsFixed(0),
                'mode': mode.id,
                'locale': tag,
              }),
            );
            final real = incidents
                .where((i) => i.pixels > kOverflowTolerancePx)
                .toList();
            if (real.isNotEmpty) {
              failures.add('$tag [${mode.label}]: ${real.join(', ')}');
            }
          }
        }

        expect(
          failures,
          isEmpty,
          reason: 'dashboard header overflowed at ${width.toInt()}px in '
              '${failures.length} case(s):\n${failures.join('\n')}',
        );
      });
    }

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
      for (final mode in headerModes) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, const Size(width, sweepHeight));
          await tester.pumpWidget(_headerHost(
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

      for (final mode in headerModes) {
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

        await setLayoutSurface(tester, const Size(320, sweepHeight));
        await tester.pumpWidget(_headerHost(
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

      await setLayoutSurface(tester, const Size(320, sweepHeight));
      await tester.pumpWidget(_headerHost(
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
        await setLayoutSurface(tester, Size(width, sweepHeight));
        await tester.pumpWidget(_headerHost(
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
      for (final mode in headerModes) {
        final expected = switch (mode.isEditMode) {
          true => 4,
          false when mode.isRemoteMode => 2,
          false => 3,
        };
        await setLayoutSurface(tester, const Size(1280, sweepHeight));
        await tester.pumpWidget(_headerHost(
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

/// The widest top bar the app can render: logged in, Apps capability on.
///
/// Both are overridden rather than left to `commonOverrides`, which returns the
/// logged-out pair. The logged-out row is a strict subset of this one — it drops
/// the Apps button and keeps everything else — so sweeping the widest
/// configuration covers both, and sweeping the narrow one would have hidden the
/// case #1328 was reported from.
///
/// The list length is fixed on purpose: `ProviderScope` asserts
/// `_debugOverridesLength == overrides.length` across rebuilds, so a
/// conditionally-included override reads as a framework assertion rather than as
/// the layout question this suite is asking.
List<Override> _widestTopBarOverrides() => [
      authProvider.overrideWith(() => _LoggedInAuthNotifier()),
      appsCapabilityProvider.overrideWith((ref) => true),
    ];

class _LoggedInAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() =>
      Future.value(const AuthState(loginType: LoginType.local));
}

/// Hosts [UspTopBar] the way the shell does.
///
/// Three parts of this are load-bearing:
/// - **A `GoRouter` ancestor.** `MenuHolderState.didChangeDependencies` calls
///   `GoRouter.of(context)` unguarded, so a bare `MaterialApp` throws.
/// - **A mounted `Navigator` under [uspShellNavigatorKey].** `MenuHolder.build`
///   returns `MenuDisplay.none` while `navigatorKey.currentContext` is null, so
///   without it the nav never appears and the sweep measures a row that is
///   missing the child that overflowed.
/// - **A unique [cellKey] per pump.** Flutter reports each `RenderFlex`'s
///   overflow once per render-object lifetime. Re-pumping a same-shaped tree
///   updates the elements in place and reuses those render objects, so every
///   cell after the first would report clean. Re-keying the root forces a fresh
///   subtree.
/// - **`ExcludeSemantics` around that `Navigator`.** Its `MaterialPageRoute`
///   ships a `ModalBarrier`, and a modal barrier is a `BlockSemantics` — it
///   drops the semantics of everything painted before it, which in this `Column`
///   is the entire top bar. Measured: without it the semantics tree held only
///   the route, so every `nav-*` identifier read as absent at *every* width and
///   the icon-only assertion below failed for a reason that had nothing to do
///   with the nav. Production does not have this problem — there the top bar and
///   the page content are plain siblings in a `Column`
///   (`usp_dashboard_view.dart:36`), with no nested route between them — so the
///   blocker is this host's, and excluding the placeholder route's semantics is
///   the honest fix rather than a workaround for app behaviour.
Widget _topBarHost({required Locale locale, required String cellKey}) {
  return ProviderScope(
    key: ValueKey('top-bar-$cellKey'),
    overrides: _widestTopBarOverrides(),
    child: MaterialApp.router(
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: Column(
                children: [
                  UspTopBar(controllerProvider: uspMenuController),
                  Expanded(
                    child: ExcludeSemantics(
                      child: Navigator(
                        key: uspShellNavigatorKey,
                        onGenerateRoute: (settings) => MaterialPageRoute(
                          builder: (_) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// Hosts [DashboardHeaderBar] with the padding `UspSliverDashboardView` wraps it
/// in, so the width it is measured at is the width production grants it.
///
/// No `ProviderScope`: the widget takes values and callbacks only, which is what
/// makes a 12-width × 26-locale × 3-mode sweep affordable at all. Pumping the
/// view instead would mean standing up the whole dashboard orchestrator per
/// cell.
Widget _headerHost({
  required Locale locale,
  required String cellKey,
  required bool isEditMode,
  required bool isRemoteMode,
  VoidCallback? onPrint,
}) {
  return MaterialApp(
    key: ValueKey('header-$cellKey'),
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    theme: ThemeJsonConfig.defaultConfig().createLightTheme(),
    home: Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(
            builder: (context) => Padding(
              padding: EdgeInsets.symmetric(
                horizontal: context.pageMargin,
                vertical: AppSpacing.md,
              ),
              child: DashboardHeaderBar(
                isEditMode: isEditMode,
                isRemoteMode: isRemoteMode,
                onPrint: onPrint ?? () {},
                onRefresh: () {},
                onEdit: () {},
                onOptimizeLayout: () {},
                onLayoutSettings: () {},
                onCancelEdit: () {},
                onCommitEdit: () {},
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

/// `GeneralSettingsWidget` inside the top bar reads `package_info` during build,
/// which has no platform implementation under `flutter test`.
void _stubPackageInfoChannel() {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/package_info'),
    (MethodCall methodCall) async {
      if (methodCall.method == 'getAll') {
        return <String, dynamic>{
          'appName': 'PrivacyGUI',
          'packageName': 'com.linksys.privacygui',
          'version': '0.0.0',
          'buildNumber': '0',
        };
      }
      return null;
    },
  );
}
