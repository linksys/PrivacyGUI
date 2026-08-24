/// The page chrome family: the dashboard's top bar and header bar (#1342).
///
/// Proof surface for [runOverflowSweep], and deliberately the first one: it is
/// the smaller of the two real inputs and needs neither the ratchet nor the
/// report, so the abstraction is settled here before the expensive family moves
/// onto it.
///
/// ## Two families, not one
///
/// `doc/testing/overflow_gate_architecture.md` §3.1 sketches a single
/// `PageChromeFamily`; the tree has two, because the chrome suite measures two
/// widgets with different axes and unrelated hosts, and #1337's committed dataset
/// already records them as two groups (`chrome.top_bar`, `chrome.header`). One
/// class would have had to carry a widget discriminator as an axis, which is the
/// `OverflowReportItem`-demands-a-`cardId` mistake in the other direction.
///
/// ## Overflow is **not** monotone in width here
///
/// The second essential difference of §2, and the reason these axes are a literal
/// list rather than a derived worst case. `menu_holder.dart:79` renders the top
/// nav as `SizedBox.shrink()` at or below `breakpointMobile` (600), so #1328's
/// failure band is **601–767px with clean water on both sides**: the row broke at
/// exactly the width the nav chips appear at. A family that pumped only the
/// narrowest width — which is sound for a card, whose narrowest realization is
/// its worst case — would have measured 320px, found it clean, and reported the
/// bug as absent.
///
/// Locale is a first-class axis for the same defect: `en` cleared at 640px but
/// `pl` needed 768px, so an `en`-only measurement would have reported a 167px-wide
/// failure band as a 39px edge case.
///
/// ## The two defects the sweep pins
///
/// - **#1314, dashboard header.** `Row(spaceBetween)` with an unbounded title on
///   the left and three or four `AppIconButton`s on the right. Neither child could
///   yield, so it overflowed at and below 480px.
/// - **#1328, top bar.** `Row(spaceBetween)` with three rigid children, over the
///   601–767px band described above.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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
import '../sweep.dart';

/// Screen widths swept per locale.
///
/// Both sides of both breakpoints that matter — `breakpointMobile` (600) and
/// `kTopNavLabelMinWidth` (768) — plus the interior of the 601–767 band #1328
/// broke in, plus 320 as the narrowest width the app claims to support.
///
/// Shared with the suite's non-sweep tests, which slice it (the label-fit
/// assertion takes `>= kTopNavLabelMinWidth`, the icon-only assertion the band
/// between the two breakpoints). One list, so a width added here is covered by
/// every question the suite asks.
const kChromeSweepWidths = <double>[
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
const kChromeSweepHeight = 800.0;

/// The three action sets [DashboardHeaderBar] can render.
///
/// Not the full 2×2 of the two flags: edit mode ignores `isRemoteMode` entirely
/// (the edit action is already gone), so `editing + remote` is the same tree as
/// `editing + local` and sweeping it would buy nothing.
///
/// Two names per mode, and the split matters (#1356). [id] is the identity: it
/// goes into the cell id and therefore into the freshness key, so it must change
/// only when the *case* changes. [label] is prose for failure messages, and is
/// free to say how many actions the mode renders — which is exactly why the count
/// cannot be in the id. It was: the ids read `mode=viewing, local (3 actions)`, so
/// adding or moving a header action renamed every cell of this sweep, and the
/// baseline diff would have reported a re-labelled coordinate as its whole
/// coverage lost and an equal number of new cells found — the one reading
/// `doc/testing/overflow_baselines.md` tells a porter to treat as the dangerous
/// case.
const kChromeHeaderModes =
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

/// Stands up what the hosts below read from outside the widget tree.
///
/// Deliberately a plain function rather than a member of
/// [OverflowSurfaceFamily]: a family answers which coordinates exist and how one
/// becomes a host widget, and adding a third question to that interface for a
/// GetIt singleton and a platform channel would let the next family put anything
/// there. The suite calls it from `setUpAll`, which is also where its fonts are
/// loaded.
///
/// Synchronous, and stays that way until something inside it has to wait: a
/// `Future` nobody awaits is a promise every caller pays for and no test can
/// check.
void prepareChromeHosts() {
  // Called for its side effect only. It registers the GetIt singletons
  // `UspTopBar` and `buildStudioThemeData` read; the override list it returns is
  // discarded because this suite needs the *widest* top bar — logged in with the
  // Apps capability on — and `commonOverrides` pins both to their logged-out
  // values. See [_widestTopBarOverrides].
  commonOverrides();
  _stubPackageInfoChannel();
}

/// The top bar's sweep: `chrome.top_bar`, one axis, 26 locales each.
///
/// The name is [OverflowCell.sweep]'s `<baseline>.<group>` and matches the
/// committed dataset, so renaming it would read as 312 coordinates lost and 312
/// found.
class ChromeTopBarFamily extends OverflowSurfaceFamily {
  const ChromeTopBarFamily();

  @override
  String get name => 'chrome.top_bar';

  @override
  List<String> get axisNames => const ['screen_px'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() {
    return [
      for (final width in kChromeSweepWidths)
        for (final locale in AppLocalizations.supportedLocales)
          OverflowSweepCell(
            axes: {
              // `screen_px`, not `px`: what this sweep varies is the screen,
              // while the card sweeps vary a card inside one. Both would read
              // `px=800` and mean different things — and these ids are what a
              // porter greps when a row changes.
              //
              // Whole pixels, the same identity `CardWidthCase.widthKey` gives a
              // width — and rounded rather than truncated for the same reason it
              // is: two widths a pixel apart must not collapse into one cell id.
              'screen_px': width.toStringAsFixed(0),
            },
            locale: locale,
            surfaceSize: Size(width, kChromeSweepHeight),
            build: () => chromeTopBarHost(locale: locale),
          ),
    ];
  }

  /// Empty, and written out rather than defaulted away.
  ///
  /// The top bar's "is it still legible" question is asked by the suite's own
  /// label-fit test, which is a different oracle at a different set of widths:
  /// `AppChipGroup` gives the label `maxLines: 1` + ellipsis, so a truncated chip
  /// *fits* and no overflow assertion can see it, and the answer is only expected
  /// to be yes at and above `kTopNavLabelMinWidth` — below that the chips are
  /// icon-only by design (#1328), so a per-cell readability verdict here would
  /// have to encode that band and would be the same test twice.
  @override
  Future<void> onCellSettled(
      WidgetTester tester, OverflowSweepCell cell) async {}
}

/// The dashboard header's sweep: `chrome.header`, two axes, 26 locales each.
class ChromeHeaderFamily extends OverflowSurfaceFamily {
  const ChromeHeaderFamily();

  @override
  String get name => 'chrome.header';

  @override
  List<String> get axisNames => const ['screen_px', 'mode'];

  @override
  Iterable<OverflowSweepCell> enumerateCells() {
    return [
      for (final width in kChromeSweepWidths)
        for (final mode in kChromeHeaderModes)
          for (final locale in AppLocalizations.supportedLocales)
            OverflowSweepCell(
              axes: {
                // The screen width, as in `chrome.top_bar` above.
                'screen_px': width.toStringAsFixed(0),
                'mode': mode.id,
              },
              locale: locale,
              surfaceSize: Size(width, kChromeSweepHeight),
              build: () => chromeHeaderHost(
                locale: locale,
                isEditMode: mode.isEditMode,
                isRemoteMode: mode.isRemoteMode,
              ),
            ),
    ];
  }

  /// Empty, and written out rather than defaulted away.
  ///
  /// The header's readability question is the suite's `keeps the page title
  /// whole` test, and it is asked at 320px only — deliberately, because that is
  /// where the actions collapse and leave the title 188px, and it is the width at
  /// which an ellipsis and a mid-word break were both found while every overflow
  /// assertion in the file stayed green. Repeating those two verdicts at the
  /// other eleven widths would measure a title that has more room, not a new
  /// question.
  @override
  Future<void> onCellSettled(
      WidgetTester tester, OverflowSweepCell cell) async {}
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
/// - **`ExcludeSemantics` around that `Navigator`.** Its `MaterialPageRoute`
///   ships a `ModalBarrier`, and a modal barrier is a `BlockSemantics` — it drops
///   the semantics of everything painted before it, which in this `Column` is the
///   entire top bar. Measured: without it the semantics tree held only the route,
///   so every `nav-*` identifier read as absent at *every* width and the suite's
///   icon-only assertion failed for a reason that had nothing to do with the nav.
///   Production does not have this problem — there the top bar and the page
///   content are plain siblings in a `Column` (`usp_dashboard_view.dart:36`), with
///   no nested route between them — so the blocker is this host's, and excluding
///   the placeholder route's semantics is the honest fix rather than a workaround
///   for app behaviour.
///
/// [cellKey] was a fourth: Flutter reports each `RenderFlex`'s overflow once per
/// render-object lifetime, so re-pumping a same-shaped tree used to need a fresh
/// root key or every cell after the first read clean. **The sweep no longer
/// passes it** — that is invariant 1, and the runner keys the subtree it wraps
/// this in, on the cell id. It survives for the suite's non-sweep tests, which
/// pump many trees in one test for oracles of their own and are not on the
/// runner; they get the same freshness by the same means, one level down.
Widget chromeTopBarHost({required Locale locale, String? cellKey}) {
  return ProviderScope(
    key: cellKey == null ? null : ValueKey('top-bar-$cellKey'),
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
/// view instead would mean standing up the whole dashboard orchestrator per cell.
///
/// [cellKey] is the sweep's old freshness key, kept for the suite's non-sweep
/// tests — see [chromeTopBarHost].
Widget chromeHeaderHost({
  required Locale locale,
  required bool isEditMode,
  required bool isRemoteMode,
  String? cellKey,
  VoidCallback? onPrint,
}) {
  return MaterialApp(
    key: cellKey == null ? null : ValueKey('header-$cellKey'),
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
