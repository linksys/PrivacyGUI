import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';

import '../layout_gate/families/page_surface_family.dart';
import 'overflow_probe.dart';

/// Shared overflow harness for the whole-page detail views (#1302).
///
/// ## Why this file exists
///
/// The Statistics and dashboard probes pump a *section* or a *card* — a widget
/// that stands alone under a `SizedBox` of a computed width. The rows #1302 fixed
/// cannot be reached that way: they sit inside `Expanded` children of rows built
/// by private methods of `UspDeviceDetailView` / `UspNodeDetailView`, so the
/// width that makes them overflow is produced by the page itself. Pumping a
/// hand-built copy of the row would measure a width this app never renders, and
/// the numbers in #1302's report (11dp, 20dp, 3.6dp) would be unreproducible.
///
/// So this probe pumps the **real view** and lets the page decide every width.
/// The split against `overflow_probe.dart` is the same as the other probes': that
/// file owns the *mechanism* (installing the collector, parsing Flutter's report,
/// settling); this one owns the *scaffolding a full view needs before it will
/// build at all* — GetIt's theme singletons, a `GoRouter` (`UspTopBar` calls
/// `GoRouter.of`, and `AppSurface` does too), and `lib/app.dart`'s theme+locale
/// wiring.
///
/// It is shared rather than inlined in its two callers because that scaffolding
/// is not a fact about either page: it is the answer to "how do I pump a real
/// view", and two copies of it would drift — the failure the Statistics probe
/// documents from its own three-copy history (#1270).
///
/// ## The scaffolding moved, and this file kept the one-pump rule (#1349)
///
/// The argument above is why the tree itself is no longer here: the #1349 page
/// family needed the same answer to the same question, and a second copy of it
/// would have been the drift this header warns about, two paragraphs after warning
/// about it. So the host is [pageSurfaceHost] (`test/layout_gate/families/
/// page_surface_family.dart`), where §3.1 puts host construction, and this file is
/// now what is *left over* once the tree is shared: the one-pump guard and the
/// tolerance filter, neither of which the declarative runner needs — it wraps every
/// cell in a `KeyedSubtree` (invariant 1), which is a better answer to the same
/// hazard than failing on the second call, and it carries the tolerance on the
/// verdict.
///
/// Which is the honest reading of what this probe is: the hand-written form of a
/// sweep, kept because its two suites carry #1302's mutation ledgers and are not
/// worth re-shaping until a page family graduates (§11).

/// Testers that have already pumped in the current test — see the one-pump rule
/// in [probeViewOverflow]. Entries are removed by the tester's own tearDown, so
/// this never grows beyond the tests running concurrently (one).
final _pumped = <WidgetTester>{};

/// Pumps [view] **once** at [screenWidth] as the app's only route, and returns
/// the RenderFlex overflows beyond [tolerancePx].
///
/// [overrides] are the view's data providers (the golden suite's
/// `deviceDetailOverrides` / `nodeDetailOverrides` fixtures); [commonOverrides]
/// is always applied underneath, since it also registers the GetIt singletons
/// `UspTopBar` reads.
///
/// [screenHeight] defaults to 1200 — the height the device-detail goldens use.
/// These pages are a single `Column` in a scroll view, so every row builds and
/// reports regardless of the height, but a taller surface keeps more of the page
/// on screen when a failure is inspected.
///
/// ## One pump per call, and why this fails loudly instead of documenting it
///
/// Flutter reports a given `RenderFlex`'s overflow only once per render-object
/// lifetime. A second pump in the same test reuses the element tree, so a
/// genuinely overflowing width reads back **clean**. Calling this twice in one
/// test is therefore an error rather than a caveat in a comment: measure a second
/// width in a second `testWidgets`. (Same rule, same reason, as
/// `probeSectionOverflow`.)
Future<List<OverflowIncident>> probeViewOverflow(
  WidgetTester tester, {
  required Widget view,
  required double screenWidth,
  required Locale locale,
  List<Override> overrides = const [],
  double screenHeight = 1200.0,
  double tolerancePx = kOverflowTolerancePx,
}) async {
  if (!_pumped.add(tester)) {
    fail('probeViewOverflow was called twice in the same test. Flutter reports '
        'a RenderFlex overflow once per render-object lifetime, so the second '
        'call would read clean no matter how badly the view overflows. Split '
        'the second measurement into its own testWidgets.');
  }
  addTearDown(() => _pumped.remove(tester));

  final surface = Size(screenWidth, screenHeight);

  return runWithOverflowCollection((sink) async {
    // [setLayoutSurface], not the three lines by hand: it is the gate's
    // Invariant 2 — the surface is set and reset in **one** place (architecture
    // doc §3.4) — and #1340 exists because those three lines were hand-copied ten
    // times, of which only the chrome half ever undid them. This file was written
    // on `dev-2.7.0`, where #1340 had not landed, so the merge made it the
    // eleventh copy and the second unreset one. Nothing measured here changes:
    // the restore runs at teardown, and both callers set their own width in every
    // test. What changes is what the *next* test in the file measures in.
    await setLayoutSurface(tester, surface);

    // The `GoRouter`/`LinksysRoute`/theme/`MediaQuery` scaffolding, and why each
    // piece is load-bearing, is documented at [pageSurfaceHost]. It is the same
    // tree this function built by hand until #1349, not a re-derivation of it —
    // which is what makes the two #1302 suites and the page sweep measurements of
    // the same thing.
    await tester.pumpWidget(
      pageSurfaceHost(view: view, locale: locale, overrides: overrides),
    );
    await settleIgnoringAnimations(tester);
    return sink.where((i) => i.pixels > tolerancePx).toList();
  });
}

/// The locale in [AppLocalizations.supportedLocales] whose tag is [tag], where a
/// tag is `languageCode` or `languageCode_countryCode` (`fr`, `fr_CA`).
///
/// Resolved from the supported list rather than built with `Locale(tag)` so a
/// locale that is dropped from the app fails the test that names it, instead of
/// silently falling back to English and reporting a row as clean because it was
/// measured in the one language it always fitted in.
Locale localeForTag(String tag) =>
    AppLocalizations.supportedLocales.firstWhere((l) {
      final t = l.countryCode == null || l.countryCode!.isEmpty
          ? l.languageCode
          : '${l.languageCode}_${l.countryCode}';
      return t == tag;
    });
