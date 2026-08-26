@Tags(['layout-gate', 'overflow'])
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/admin/views/components/usp_timezone_card.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_card.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_ipv6_section.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_single_port_tab.dart';
import 'package:privacy_gui/page/unified_diagnostics/views/widgets/diagnostic_start_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../layout_gate/collector.dart';
import '../../layout_gate/families/page_surface_cases.dart';
import '../../layout_gate/families/page_surface_family.dart';
import '../../layout_gate/locale_tag.dart';
import '../../layout_gate/surface.dart';
import '../../layout_gate/sweep.dart';
import '../../mocks/provider_overrides/mock_admin.dart';
import '../../mocks/test_data/scenes/apps_scene_data.dart';
import '../../mocks/test_data/scenes/instant_privacy_scene_data.dart';
import '../../mocks/test_data/scenes/system_log_scene_data.dart';
import '../../util/app_test_fonts.dart';
import '../../util/dashboard/text_readability_probe.dart';

/// The overflow gate's page sweep — the #1349 pilot, #1377's wave 1, #1378's wave 2,
/// #1379's wave 3 and #1380's wave 4.
///
/// **Forty-three whole pages** × 9 screen widths × 26 locales = **10,062 cells**,
/// declared through the shared runner. Everything about *which* cells exist and *how*
/// one is hosted lives in `test/layout_gate/families/page_surface_family.dart`; which
/// forty-three pages, and why those, lives in `page_surface_cases.dart`. This file is
/// the declaration, the forty-three pins, and the readability guards that sit beside
/// the fixes this family has prompted — **16 fixed sites in `lib/`, 14 of them from
/// wave 4 alone**, guarded by **13 groups**. The two counts differ because rule 4's
/// unit is the site and a group's unit is the page. `admin` holds the wave's sixth and
/// seventh (a responsive band in the page, a header in one card and a skeleton row in
/// another — two sites, three parts) and `apps` its eighth, ninth and tenth; in both
/// cases a single group asserts all of them, because the later ones are only reachable
/// through the shape the responsive fix changed, so guarding them separately would mean
/// pumping the same page twice to read two halves of one layout. The groups' own docs
/// carry those ordinals, which is how the 14 can be counted back out of this file.
/// `kReadabilityGuardPages` in
/// `test/layout_gate/page_sweep_suites.dart` is what pins that mapping, one entry per
/// group title.
///
/// **Nothing remains.** #1380 was the epic's last wave, and 43 swept + 2 excluded is
/// all 45 page views under `lib/page/`. `test/fixtures/page_roster.tsv` is the register
/// that does that arithmetic, holds the two exclusions' reasons and the per-page cost,
/// and is still the file to read before assuming a page absent from this list is a page
/// with nothing wrong with it — because the two absent ones are absent on a *verdict*,
/// not on a queue.
///
/// ## Why the pins are literals
///
/// `9 × 26 = 234` is the enumeration restating itself. The literal is what stands
/// between "the pilot deliberately swept 9 widths" and "someone dropped four
/// widths and the suite stayed green in half the time" — the same argument
/// `sweep.dart`'s header makes for every other pin in this family, and the reason
/// `expectedCellCount` is required rather than defaulted.
///
/// It was `8 × 26 = 208` until 2026-08-26, when #1372 closed the width list by
/// adding 1080 — golden CI's third coordinate, and the only width in the list that
/// renders a content box wider than 977px. Fifteen literals moved in one edit,
/// which is the shape the ticket wanted: a coverage change nobody can make while
/// looking away. `pnp_setup` brought the sixteenth later the same day, wave 3's six
/// brought the count to twenty-two, and wave 4's twenty-one closed it at forty-three —
/// so the literal is now written out forty-three times, and #1372's argument for the
/// repetition is the argument that survived the list doubling.
///
/// ## Where this file sits in the gate
///
/// `layout-gate` makes it PR-blocking (`run_tests.sh` excludes `golden||loc||ui`
/// and neither of those is here). `overflow` puts it in the pre-commit selector,
/// which it earns by pumping cells and asserting zero overflow — and which is the
/// tag whose cost this pilot measured. See §11 of
/// `doc/testing/overflow_gate_architecture.md` for the measurement and the
/// recommendation it supports.
///
/// ## Why `test/page/_shared/`, which §11.1 excludes as a *surface*
///
/// Two different `_shared`s, and the collision is worth stating because it reads
/// as a contradiction. §11.1 excludes **`lib/page/_shared/`** — production
/// components carrying golden-CI debt, which §8's graduation rule keeps out of a
/// local probe until they are fixed. This is **`test/page/_shared/`**, the repo's
/// existing location for a suite no single page owns (`test/page/_shared/utils/`
/// is the same convention), and it is where §3.1's "suites stay next to the code
/// under test" lands when the code under test is *two* pages and will be more.
/// Nothing in `lib/page/_shared/` is swept here.
///
/// It is deliberately the all-pages bucket: pages graduate one at a time (§11.3),
/// and a per-page suite file would put the shared `loadAppFonts` setup and the
/// readability guard below into as many copies as there are pages. The registry
/// consequence is recorded in `tool/overflow_baseline.sh` — one baseline id
/// (`page`) holds every family in this file, the way `card` holds three.
void main() {
  final localizationsByTag = <String, AppLocalizations>{};

  setUpAll(() async {
    // Real fonts. Under Ahem every glyph is an identical box, so every width this
    // sweep measures would be fiction (rule 7 of the skill's new-probe section).
    await loadAppFonts();

    for (final locale in AppLocalizations.supportedLocales) {
      localizationsByTag[localeTag(locale)] =
          await AppLocalizations.delegate.load(locale);
    }
  });

  // 9 widths × 26 locales. Every page sweeps the same axis, so every pin is the
  // same number — which is a fact about the axis, not a copy: a page that ever
  // needs its own width list changes only its own pin.
  //
  // One `runOverflowSweep` call per page and not a loop over `kPageSurfaceCases`,
  // which is the same argument the literal pin rests on one level down. A loop
  // would make the *inventory* of swept pages derived too, so deleting a case
  // would delete its sweep and this file would stay green in less time. Written
  // out, a page leaving the gate is a deletion someone has to perform here, in a
  // diff that names it.
  runOverflowSweep(
    family: PageSurfaceFamily(kDhcpPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kWifiSettingsPageCase),
    expectedCellCount: 234,
  );

  // Wave 1 (#1377): five pages whose fixture was already written. See
  // `page_surface_cases.dart` for why these five, and `test/fixtures/page_roster.tsv`
  // for what is still queued.
  runOverflowSweep(
    family: PageSurfaceFamily(kDeviceListPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kDeviceDetailPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kTopologyPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kNodeDetailPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kPortForwardingPageCase),
    expectedCellCount: 234,
  );

  // Wave 2 (#1378): the instant_setup flow, in flow order — eight here and the
  // ninth (`pnp_setup`) at the end of the file, where its own comment says why it
  // is out of order. `pnp_complete_view` is the tenth view and stays excluded as
  // unreachable. The register is the roster.
  runOverflowSweep(
    family: PageSurfaceFamily(kPnpEntryPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kPnpNoInternetPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kPnpIspSettingsPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kPnpPppoePageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kPnpStaticIpPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kPnpUnplugModemPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kPnpModemLightsOffPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kPnpWaitingModemPageCase),
    expectedCellCount: 234,
  );

  // Wave 2's ninth, and the only page in this file that arrived after its wave. It
  // was `queued` for a day on `linksys/privacyGUI-UI-kit#70` — `AppStepper`'s bar
  // variant was over by `stepCount × 4` at every width in every locale, so all 208
  // of its cells failed — and v2.40.2 fixed it. The tripwire that pinned the
  // arithmetic (`test/page/instant_setup/views/pnp_setup_view_test.dart`) went red
  // with an empty incident list on the bump and was deleted, which is the order §8's
  // graduation rule asks for: fix to zero, then declare, then capture.
  runOverflowSweep(
    family: PageSurfaceFamily(kPnpSetupPageCase),
    expectedCellCount: 234,
  );

  // Wave 3 (#1379): the six entry surfaces — what a user sees before there is a
  // session. All six arrived at zero, so no widget fix landed with this wave; the
  // prediction it was filed on ("expect finds in narrow-column login forms") is
  // falsified in `page_surface_cases.dart`'s wave 3 header. Five needed only a
  // declaration; `auto_parent_first_login` needed the wave's one new fixture, and it
  // is the family's only loader-is-content page.
  runOverflowSweep(
    family: PageSurfaceFamily(kHomePageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kLoginLocalPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kLocalRouterRecoveryPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kLocalResetRouterPasswordPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kMenuPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kAutoParentFirstLoginPageCase),
    expectedCellCount: 234,
  );

  // Wave 4 (#1380): the last twenty-one, in two slices — the eight pages a fixture
  // already reached, then the thirteen #1370 found unreachable behind their loaders.
  runOverflowSweep(
    family: PageSurfaceFamily(kAdvancedSettingsPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kRemoteAssistancePageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kSupportPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kUnifiedDiagnosticsPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kFirmwareUpdatePageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kRouterAssistantPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kTestConsolePageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kSliverDashboardPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kUspDashboardPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kAdminPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kAppsPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kDmzPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kFirewallPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kInstantPrivacyPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kInstantSafetyPageCase),
    expectedCellCount: 234,
  );

  runOverflowSweep(
    family: PageSurfaceFamily(kInternetSettingsPageCase),
    expectedCellCount: 234,
  );

  // `ipv6_port_service` — a CRUD list of pinholes; see `kIpv6PortServicePageCase` for
  // why `LayoutBlock` and not `AppSwitch` is what proves the list rendered, and its
  // scene for why the fixture holds a full-form address and an unnamed rule.
  runOverflowSweep(
    family: PageSurfaceFamily(kIpv6PortServicePageCase),
    expectedCellCount: 234,
  );

  // `local_network` — nine form fields plus the family's one unconditional bottom bar;
  // `kLocalNetworkPageCase` says why both field types are premises.
  runOverflowSweep(
    family: PageSurfaceFamily(kLocalNetworkPageCase),
    expectedCellCount: 234,
  );

  // `static_routing` — `ipv6_port_service`'s card shape again; the two pages are one
  // menu entry apart and are declared the same way.
  runOverflowSweep(
    family: PageSurfaceFamily(kStaticRoutingPageCase),
    expectedCellCount: 234,
  );

  // `statistics` — tab 0, and of tab 0 only what the viewport lays out;
  // `kStatisticsPageCase` states both limits and names the suites that cover the rest.
  runOverflowSweep(
    family: PageSurfaceFamily(kStatisticsPageCase),
    expectedCellCount: 234,
  );

  // `system_log` — the 45th page, and the last one this epic had to account for.
  runOverflowSweep(
    family: PageSurfaceFamily(kSystemLogPageCase),
    expectedCellCount: 234,
  );

  // The readability assertion rule 4 of the skill requires beside an overflow
  // assertion, aimed at the one site this pilot changed. Neither this group nor
  // wave 1's below names a cell, so the committed `page` baseline counts the page
  // sweeps and nothing else, and `overflow_baselines.md` §5's "every collector call
  // names a cell" stays true: these two tests do not install the collector at all,
  // because their oracle is not "did a RenderFlex overflow".
  group('readability at the site the pilot fixed', () {
    /// How many lines the reservations title may wrap onto before the wrap stops
    /// being the better trade.
    ///
    /// One line of headroom over the deepest coordinate measured (`ar`, two lines at
    /// both widths — 197.0px at 320px and 169.5px at 601px; `ru` also takes two at
    /// 601px and those three are the only coordinates that wrap), which is the whole
    /// design: tight enough that a real regression trips it, loose enough that a
    /// one-line drift from an ARB edit does not send someone to a fixture they did
    /// not break. It is not a design token — nothing in the app enforces it — so
    /// raising it is a deliberate act with the new number recorded here.
    ///
    /// It read 5 against a deepest-of-4 until #1380 fixed the over-count in
    /// [TextReadabilityProbe.textLineCount] — `tight` glyph boxes made one line of a
    /// font-fallback string look like two, so every depth in this file was inflated.
    /// The ceilings came down with the measurements; nothing about the sites changed.
    const kTitleLineCeiling = 3;

    testWidgets('the reservations title stays whole where the Flexible wraps',
        (tester) async {
      final failures = <String>[];
      final wrapped = <String>[];

      // The two widths the defect appeared at, and the reason the pair is needed:
      // 601px is where the page's two-column band hands this card a *narrower*
      // box than 320px's one-column band does (+141px against +113px), so the
      // narrower screen is not the worse case for this site.
      for (final width in const [320.0, 601.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          // Its own key per pump, invariant 1's other half: a tree pumped outside
          // `runOverflowSweep` needs a fresh subtree or its own test.
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('dhcp-title-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kDhcpPageCase.view(),
              locale: locale,
              overrides: kDhcpPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final label = localizationsByTag[tag]!.dhcpReservations;
          // Scoped to the card, not `find.text` alone: the same string is the
          // page's own section heading in some locales, and a bare literal finder
          // would measure whichever came first in tree order.
          final title = find.descendant(
            of: find.byType(UspDhcpReservationsDetailCard),
            matching: find.text(label),
          );
          if (title.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the title resolved to '
                '${title.evaluate().length} widgets, so nothing was measured');
            continue;
          }

          // Both verdicts, for the reason the chrome sweep records: a mid-word
          // break drops nothing, so `didExceedMaxLines` is blind to it, and an
          // ellipsis leaves every surviving token fitting, so `hasSplitToken` is
          // blind to that.
          final paragraph = tester.paragraphOf(title);
          final lines = tester.textLineCount(title);
          if (lines > 1) wrapped.add('$tag@${width.toInt()}px:${lines}L');
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on '
              '$lines line(s), widest token '
              '${tester.widestTokenWidth(title).toStringAsFixed(1)}px, whole '
              'string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px'
              ' — "$label"';
          // The third verdict, and the one that bounds the dimension the fix
          // actually moved. `lines` was measured into `wrapped` and then only
          // checked for being non-empty, so a wrap of any depth passed: `ar`
          // takes four lines today, and an ARB edit, a font-fallback change or a
          // fixture change that pushed it to twelve — pushing the rest of the card
          // off the visible surface — would leave `failures` empty and this suite
          // green. A wrap is the better trade than an overflow only up to a point,
          // and this is the point.
          if (lines > kTitleLineCeiling) {
            failures.add('$tag @${width.toInt()}px: wrapped onto $lines lines, '
                'past the $kTitleLineCeiling-line ceiling — $numbers');
          }
          if (tester.isTextClipped(title)) {
            failures.add('$tag @${width.toInt()}px: ellipsized — $numbers');
          } else if (tester.hasSplitToken(title)) {
            failures
                .add('$tag @${width.toInt()}px: broken mid-word — $numbers');
          }
        }
      }

      // The premise, as a value rather than a hope — #1364/#1366 one layer down.
      // If no locale wraps at either width, every assertion above passed against a
      // title that fitted on one line, which is a test that cannot fail: the trade
      // the `Flexible` made would be unmeasured and this suite would report it as
      // covered. Kept as a *list* so a failure names what the coverage was.
      //
      // 3 of the 52 coordinates wrap today, all onto two lines: `ar` at both widths
      // and `ru` at 601px — the narrower-content-at-a-wider-screen step showing up
      // in the readability data as well as in the overflow data, since `ru` wraps
      // at the *wider* of the two widths and not at 320px.
      //
      // It read 16, with `ar` at four lines, until #1380 fixed the over-count in
      // [TextReadabilityProbe.textLineCount]: `tight` glyph boxes split one line of
      // a font-fallback string into two, so thirteen of those sixteen were not wraps
      // at all. Nothing about this site changed.
      //
      // The floor only. [kTitleLineCeiling] is the other end, checked per
      // coordinate above: this list being non-empty says the wrap was measured, and
      // says nothing about how deep it went.
      expect(
        wrapped,
        isNotEmpty,
        reason:
            'no locale wrapped this title at 320px or 601px, so nothing here '
            'measured the wrap the #1349 fix introduced — the fixture, the widths '
            'or the string lengths have drifted',
      );

      expect(
        failures,
        isEmpty,
        reason:
            'the #1349 fix traded an overflow for a wrap, and a wrap is only '
            'the better trade while the title stays readable:\n'
            '${failures.join('\n')}',
      );
    });
  });

  // The same guard for the site wave 1 fixed, and it is here for the same reason
  // rather than by symmetry: `usp_single_port_tab.dart:30` traded an overflow for
  // a wrap too, so the nine cells it stopped failing are now nine cells whose
  // *content* nothing checks. Rule 4 of the skill — an overflow assertion needs a
  // readability assertion beside it — is what makes those nine a fix rather than a
  // relocation of the defect into a dimension the sweep cannot see.
  group('readability at the site wave 1 fixed', () {
    /// As [kTitleLineCeiling] above, and deliberately a separate constant: this
    /// title is a different string in a different box, and one number covering both
    /// would move for reasons belonging to the other site.
    ///
    /// Same rule for the number — one line over the deepest coordinate measured,
    /// which here is two lines in the 240.0px box at 320px, in nine locales (`da`,
    /// `de`, `fi`, `fr`, `nb`, `pl`, `pt`, `pt_PT`, `ru`) and at no other width. Not
    /// a design token; raising it is a deliberate act with the new number recorded
    /// here. As [kTitleLineCeiling], it came down from 5 with #1380's `textLineCount`
    /// fix rather than because anything about the site moved.
    const kTabTitleLineCeiling = 3;

    testWidgets(
        'the single-port tab title stays whole where the Expanded wraps',
        (tester) async {
      final failures = <String>[];
      final wrapped = <String>[];

      // 320px is where all nine of #1370's overflowing cells were, and 601px is
      // the same narrower-content-at-a-wider-screen check the group above makes —
      // the page's margin steps up at 600px, so the tab's box does not simply grow
      // with the screen.
      for (final width in const [320.0, 601.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('pf-title-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kPortForwardingPageCase.view(),
              locale: locale,
              overrides: kPortForwardingPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final label = localizationsByTag[tag]!.singlePortForwarding;
          // `textContaining` scoped to the tab, not an exact string: the widget
          // renders the label with a live rule count appended, and pinning the
          // count here would make this guard fail on a fixture edit that changed
          // nothing about readability. The scope is what keeps it unambiguous —
          // the same label is also the tab bar's own text, one level up in
          // `UspPortForwardingDetailView`.
          final title = find.descendant(
            of: find.byType(UspSinglePortTab),
            matching: find.textContaining(label),
          );
          if (title.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the title resolved to '
                '${title.evaluate().length} widgets, so nothing was measured');
            continue;
          }

          final paragraph = tester.paragraphOf(title);
          final lines = tester.textLineCount(title);
          if (lines > 1) wrapped.add('$tag@${width.toInt()}px:${lines}L');
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on '
              '$lines line(s), widest token '
              '${tester.widestTokenWidth(title).toStringAsFixed(1)}px, whole '
              'string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px'
              ' — "$label"';
          if (lines > kTabTitleLineCeiling) {
            failures.add('$tag @${width.toInt()}px: wrapped onto $lines lines, '
                'past the $kTabTitleLineCeiling-line ceiling — $numbers');
          }
          if (tester.isTextClipped(title)) {
            failures.add('$tag @${width.toInt()}px: ellipsized — $numbers');
          } else if (tester.hasSplitToken(title)) {
            failures
                .add('$tag @${width.toInt()}px: broken mid-word — $numbers');
          }
        }
      }

      // The premise, as a value rather than a hope — the same argument the group
      // above makes. Every assertion in the loop passes trivially against a title
      // that fitted on one line, so without this the guard would report the trade
      // as covered while measuring nothing about it.
      //
      // 9 of the 52 coordinates wrap today, every one of them at 320px and every one
      // onto two lines: `da` `de` `fi` `fr` `nb` `pl` `pt` `pt_PT` `ru` — the Latin
      // locales, which is the opposite grouping from the one this comment used to
      // report. Nothing wraps at 601px: the tab's box grows to 489.0px there and no
      // locale's title needs a second line of it. `ru` is among the nine and is the
      // same locale that was +58px over before the fix.
      //
      // It read 26, with `ru` at four lines and nine coordinates still wrapping at
      // 601px, until #1380 fixed the over-count in
      // [TextReadabilityProbe.textLineCount] — see [kTitleLineCeiling].
      //
      // The floor only. [kTabTitleLineCeiling] is the other end, checked per
      // coordinate above.
      expect(
        wrapped,
        isNotEmpty,
        reason:
            'no locale wrapped this title at 320px or 601px, so nothing here '
            'measured the wrap the #1377 fix introduced — and if it does not '
            'wrap, the nine cells #1370 recorded as overflowing cannot be '
            'reproduced either, so check the fixture and the widths before '
            'deleting this guard:\n${wrapped.join(', ')}',
      );

      expect(
        failures,
        isEmpty,
        reason: 'the #1377 fix traded an overflow for a wrap on the nine cells '
            '#1370 found, and a wrap is only the better trade while the title '
            'stays readable:\n${failures.join('\n')}',
      );
    });
  });

  // The third instance of the same rule, for wave 4's first fix. Same trade as the
  // two above — `usp_advanced_settings_view.dart:110` was over by 15px in `fr_CA`
  // and the `Expanded` that fixed it turned that into a wrap — and the same reason
  // it needs its own group rather than a case in one of theirs: the ceiling below is
  // a number about *these* six strings in *this* box, and one constant covering
  // three sites would move for reasons belonging to the other two.
  //
  // What differs is the count. The other two guards measure one string; this page
  // renders six rows of the same widget, so all six labels are measured at both
  // widths. That is not thoroughness for its own sake: the row that overflowed is
  // not the row with the longest English label, and a guard pinned to one of the six
  // would be a guard on whichever row was longest the day it was written.
  // Wave 4 ended up fixing **fourteen sites on eleven pages**, and it declares
  // **eleven** guard groups — one per page, not one per site.
  // `kReadabilityGuardPages` pairs a group title with the *one* page it pumps, so a
  // group spanning two pages could not be registered at all; and
  // `pageSweepSuiteWeightMs` bills one fixture per group title, so N groups on one
  // page would bill that page's fixture N times. That is why `admin`'s two sites and
  // `apps`' three each live in a single group: the register keys on the page, and a
  // page is what a guard has to travel with on the day the sweep is split.
  group('readability at the site wave 4 fixed in advanced_settings', () {
    /// As [kTitleLineCeiling] and [kTabTitleLineCeiling], and a third constant for
    /// the reason stated there: six navigation labels in a 288px box are not the
    /// same measurement as a card title.
    ///
    /// Same rule for the number — one line over the deepest coordinate measured.
    /// Four coordinates wrap and all four take two lines: `fr_CA`'s `internet` at
    /// 320px (236.0px granted) and at 601px (208.5px), `pt_PT`'s `port_forwarding`
    /// and `ru`'s `static_routing` at 601px.
    const kSectionRowLineCeiling = 3;

    testWidgets('every advanced-settings row title stays whole where it wraps',
        (tester) async {
      final failures = <String>[];
      final wrapped = <String>[];

      // The two widths the overflow appeared at, which here is the whole of it:
      // `fr_CA` was +15px at 320px and 601px and clean at the other seven. 601px
      // grants 537px of content but the desktop grid puts two cards in it, so each
      // row's box is ~253px — *narrower* than 320px's 288px, which is why the pair
      // is the pair and not just the floor.
      for (final width in const [320.0, 601.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('advset-rows-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kAdvancedSettingsPageCase.view(),
              locale: locale,
              overrides: kAdvancedSettingsPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // The six in `_buildItems` order. Read off the ARB rather than off the
          // widget tree so that a row losing its label is a failure here rather
          // than a shorter loop.
          final labels = <String, String>{
            'internet': loc.internetSettings,
            'local_network': loc.localNetwork,
            'firewall': loc.firewall,
            'dmz': loc.dmz,
            'port_forwarding': loc.portForwarding,
            'static_routing': loc.staticRouting,
          };

          for (final entry in labels.entries) {
            // Scoped to the block, like both guards above: `UiKitPageView`'s own
            // title is `advancedSettings` so there is no collision with the page
            // chrome, but two of these six strings are one word apart in some
            // locales and an unscoped `find.text` would not say which row it read.
            final title = find.descendant(
              of: find.byType(LayoutBlock),
              matching: find.text(entry.value),
            );
            if (title.evaluate().length != 1) {
              failures.add('$tag @${width.toInt()}px: ${entry.key} resolved to '
                  '${title.evaluate().length} widgets, so nothing was measured');
              continue;
            }

            final paragraph = tester.paragraphOf(title);
            final lines = tester.textLineCount(title);
            if (lines > 1) {
              wrapped.add('$tag@${width.toInt()}px/${entry.key}:${lines}L');
            }
            final numbers = 'granted '
                '${paragraph.size.width.toStringAsFixed(1)}px on '
                '$lines line(s), widest token '
                '${tester.widestTokenWidth(title).toStringAsFixed(1)}px, whole '
                'string '
                '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px'
                ' — "${entry.value}"';
            if (lines > kSectionRowLineCeiling) {
              failures.add(
                  '$tag @${width.toInt()}px: ${entry.key} wrapped onto '
                  '$lines lines, past the $kSectionRowLineCeiling-line ceiling '
                  '— $numbers');
            }
            // Both verdicts for the reason the two groups above give: an ellipsis
            // and a mid-word break are blind to each other.
            if (tester.isTextClipped(title)) {
              failures
                  .add('$tag @${width.toInt()}px: ${entry.key} ellipsized — '
                      '$numbers');
            } else if (tester.hasSplitToken(title)) {
              failures.add('$tag @${width.toInt()}px: ${entry.key} broken '
                  'mid-word — $numbers');
            }
          }
        }
      }

      // The floor premise, third instance. Without it every assertion in the loop
      // passes against six titles that all fitted on one line, and the wrap the
      // #1380 fix introduced would be reported as covered while being unmeasured.
      //
      // 4 of the 312 coordinates wrap today (26 locales × 2 widths × 6 rows), all
      // onto two lines: `fr_CA`'s `internet` at both widths, and `pt_PT`'s
      // `port_forwarding` and `ru`'s `static_routing` at 601px only — the
      // narrower-content-at-a-wider-screen step again, since two of the four appear
      // at the wider width and not at 320px. Three of the six rows — `local_network`,
      // `firewall` and `dmz` — never wrap in any locale at either width, which is why
      // the loop reads all six rather than sampling one: sampling `dmz` would have
      // measured nothing at all.
      //
      // It read 53 until #1380 fixed the over-count in
      // [TextReadabilityProbe.textLineCount] — see [kTitleLineCeiling].
      expect(
        wrapped,
        isNotEmpty,
        reason:
            'no locale wrapped any of the six row titles at 320px or 601px, '
            'so nothing here measured the wrap the #1380 fix introduced — and if '
            'nothing wraps, the fr_CA overflow #1370 recorded cannot be '
            'reproduced either, so check the ARB strings and the widths before '
            'deleting this guard:\n${wrapped.join(', ')}',
      );

      expect(
        failures,
        isEmpty,
        reason: 'the #1380 fix traded an overflow for a wrap on the two widths '
            'fr_CA failed at, and a wrap is only the better trade while the row '
            'label stays readable:\n${failures.join('\n')}',
      );
    });
  });

  group('readability at the site wave 4 fixed in unified_diagnostics', () {
    // The wave's second fix, and the one guard in this file whose oracle is not a
    // text metric. `diagnostic_start_view.dart:125` overflowed in 9 locales at
    // 320px because an `Expanded` text column had already given up all its width
    // and the icon and the button still did not fit. The fix moves the button under
    // the text below 360px of card content rather than letting it shrink — see
    // `_PrimaryAction._reflowBelow` for why shrinking was the wrong trade: ui_kit
    // already ellipsizes the button's label inside a `Flexible`, so the sweep would
    // have gone green on "Commencer maintenant" rendered as "Comm…".
    //
    // That makes rule 4's usual pair the wrong instrument here — nothing wraps and
    // nothing is meant to ellipsize. What needs pinning is the *shape*, in both
    // directions:
    //
    // 1. At 320px the button is below the title, in all 26 locales, with its label
    //    whole. Without this the fix could regress to a shrunk button and only the
    //    (still green) overflow sweep would notice, which is to say nothing would.
    // 2. At the other eight widths it is still beside the title. Without this the
    //    threshold could drift up to the 600px mobile breakpoint — or to
    //    `double.infinity` — and every sweep would stay green while the page
    //    silently lost its desktop layout at 480px and 601px, which were clean.
    testWidgets(
        'the diagnostics primary action reflows at 320px and only there',
        (tester) async {
      final failures = <String>[];
      // Layout mode is a function of width alone, so the eight row-mode widths are
      // read in one locale — `fr`, which is the worst of the nine that overflowed
      // (+74px) and therefore the likeliest to reflow early if the threshold drifts.
      final fr = AppLocalizations.supportedLocales
          .firstWhere((locale) => localeTag(locale) == 'fr');

      for (final width in kPageSweepWidths) {
        final reflowExpected = width == 320.0;
        final locales =
            reflowExpected ? AppLocalizations.supportedLocales : <Locale>[fr];

        for (final locale in locales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('diag-primary-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kUnifiedDiagnosticsPageCase.view(),
              locale: locale,
              overrides: kUnifiedDiagnosticsPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // The primary card is the only thing on this page with an `AppButton` in
          // it — the two secondary cards are a whole-card tap with a chevron — so
          // scoping to the start view is enough, and the count assertion is what
          // says so out loud rather than assuming it.
          final button = find.descendant(
            of: find.byType(DiagnosticStartView),
            matching: find.byType(AppButton),
          );
          final title = find.descendant(
            of: find.byType(DiagnosticStartView),
            matching: find.text(loc.runFullDiagnostic),
          );
          if (button.evaluate().length != 1 || title.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: found '
                '${button.evaluate().length} button(s) and '
                '${title.evaluate().length} title(s) in the start view, so '
                'nothing was measured');
            continue;
          }

          final buttonRect = tester.getRect(button);
          final titleRect = tester.getRect(title);
          final reflowed = buttonRect.top >= titleRect.bottom;
          if (reflowed != reflowExpected) {
            failures.add('$tag @${width.toInt()}px: expected the button '
                '${reflowExpected ? 'below' : 'beside'} the title but it was '
                '${reflowed ? 'below' : 'beside'} it — title '
                '${titleRect.left.toStringAsFixed(1)}..'
                '${titleRect.right.toStringAsFixed(1)} × '
                '${titleRect.top.toStringAsFixed(1)}..'
                '${titleRect.bottom.toStringAsFixed(1)}, button '
                '${buttonRect.left.toStringAsFixed(1)}..'
                '${buttonRect.right.toStringAsFixed(1)} × '
                '${buttonRect.top.toStringAsFixed(1)}..'
                '${buttonRect.bottom.toStringAsFixed(1)}');
          }

          // The half of the trade the shape assertion cannot see. The reflow is
          // only better than a shrink while the label it protects is whole, and
          // ui_kit's ellipsis is silent — no overflow, no exception, just a
          // truncated call to action.
          final label = find.descendant(
            of: button,
            matching: find.text(loc.startNow),
          );
          if (label.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the button label '
                '"${loc.startNow}" resolved to ${label.evaluate().length} '
                'widgets');
          } else if (tester.isTextClipped(label)) {
            final paragraph = tester.paragraphOf(label);
            failures.add('$tag @${width.toInt()}px: the button label '
                'ellipsized — granted '
                '${paragraph.size.width.toStringAsFixed(1)}px for a '
                '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px '
                'string "${loc.startNow}"');
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'the #1380 fix at diagnostic_start_view.dart:125 reflows the '
            'primary action below 360px of card content; both what it does at '
            '320px and what it leaves alone at the other eight widths are part '
            'of the fix:\n${failures.join('\n')}',
      );
    });
  });

  group('readability at the site wave 4 fixed in firmware_update', () {
    // The wave's third fix and its widest site: `firmware_update_view.dart:546`
    // overflowed 50 of 234 cells — all 26 locales at 320px, 19 at 480px, 5 at 601px,
    // worst `ru` at +357px and `en` itself at +160px. The `Row` held a button and an
    // up-to-date line, and neither could give: the button's width is its label, and
    // the line was `MainAxisSize.min` around a whole sentence.
    //
    // The fix stacks them below 600px of card content and lets the sentence wrap.
    // That leaves two things the overflow sweep cannot see, and this guard is both:
    //
    // 1. **A stretched button whose label ellipsizes.** `stretch` was chosen over an
    //    intrinsic-width button precisely so the label gets the whole 256px line
    //    rather than ui_kit's `Flexible` silently cutting it — but "gets the line" is
    //    not the same as "fits it", and only a text metric can tell them apart.
    // 2. **A sentence that wraps too far or breaks mid-word.** It is now `Expanded`,
    //    so it can never overflow again; what it can do instead is become four lines
    //    of two syllables, which is the trade rule 4 exists to keep honest.
    testWidgets('the OTA check card stacks below 600px with both strings whole',
        (tester) async {
      // Three, because two is what the deepest locales measure at 320px: nine of
      // them — `de`, `el`, `fi`, `id`, `pl`, `ru`, `sv`, `th`, `vi` — take two lines
      // in the 204px the stacked card grants, every other locale takes one, and no
      // coordinate above 320px wraps at all. A sentence on two lines is still a
      // sentence; the ceiling is here to catch the sixth line, not the second.
      const kOtaStatusLineCeiling = 3;
      final failures = <String>[];
      final wrapped = <String>[];
      // Stacking is a function of width alone, so the shape claim is read in one
      // locale across all nine widths, and the text claims in all 26 at the
      // narrowest — where a 256px line is the tightest the button label ever gets.
      final ru = AppLocalizations.supportedLocales
          .firstWhere((locale) => localeTag(locale) == 'ru');

      for (final width in kPageSweepWidths) {
        // The card grants ~473px at a 601px screen and ~809px at 905px, so the
        // stacked widths are the three that overflowed and no others. Written as the
        // widths rather than as `width < 600` so that a threshold change has to
        // restate its effect here.
        final stackExpected = width <= 601.0;
        final locales =
            width == 320.0 ? AppLocalizations.supportedLocales : <Locale>[ru];

        for (final locale in locales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('ota-card-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kFirmwareUpdatePageCase.view(),
              locale: locale,
              overrides: kFirmwareUpdatePageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // `checkForUpdates` is on exactly one button on this page — the idle card's
          // is `chooseFirmwareFile` — so the label doubles as the scope.
          final button = find.widgetWithText(AppButton, loc.checkForUpdates);
          final buttonLabel = find.descendant(
            of: button,
            matching: find.text(loc.checkForUpdates),
          );
          final status = find.text(loc.firmwareUpToDate);
          if (button.evaluate().length != 1 || status.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: found '
                '${button.evaluate().length} check button(s) and '
                '${status.evaluate().length} up-to-date line(s) — the fixture '
                'pins otaUpToDate: true, so both must be present or nothing '
                'here was measured');
            continue;
          }

          final buttonRect = tester.getRect(button);
          final statusRect = tester.getRect(status);
          final stacked = statusRect.top >= buttonRect.bottom;
          if (stacked != stackExpected) {
            failures.add('$tag @${width.toInt()}px: expected the up-to-date '
                'line ${stackExpected ? 'below' : 'beside'} the button but it '
                'was ${stacked ? 'below' : 'beside'} it');
          }

          // The half of the fix that `stretch` is for: a full-width button whose
          // label still had to be cut is a worse outcome than the overflow.
          if (tester.isTextClipped(buttonLabel)) {
            final paragraph = tester.paragraphOf(buttonLabel);
            failures.add('$tag @${width.toInt()}px: the check button label '
                'ellipsized — granted '
                '${paragraph.size.width.toStringAsFixed(1)}px of a '
                '${buttonRect.width.toStringAsFixed(1)}px button for a '
                '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px '
                'string "${loc.checkForUpdates}"');
          }

          final statusLines = tester.textLineCount(status);
          if (statusLines > 1) {
            wrapped.add('$tag@${width.toInt()}px:${statusLines}L');
          }
          final numbers = 'granted '
              '${tester.paragraphOf(status).size.width.toStringAsFixed(1)}px on '
              '$statusLines line(s), widest token '
              '${tester.widestTokenWidth(status).toStringAsFixed(1)}px — '
              '"${loc.firmwareUpToDate}"';
          if (statusLines > kOtaStatusLineCeiling) {
            failures.add(
                '$tag @${width.toInt()}px: the up-to-date line wrapped '
                'onto $statusLines lines, past the $kOtaStatusLineCeiling-line '
                'ceiling — $numbers');
          }
          if (tester.isTextClipped(status)) {
            failures.add('$tag @${width.toInt()}px: the up-to-date line '
                'ellipsized — $numbers');
          } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
              tester.hasSplitToken(status)) {
            // The four space-less scripts are excluded from this one assertion and
            // from nothing else — see `kLocalesWithoutWordSpaces` for why a whole
            // Thai sentence is one token and therefore trips the check by
            // construction. `th` is the locale that made it matter here: 211px of
            // unbroken run in a 204px line.
            failures.add('$tag @${width.toInt()}px: the up-to-date line broke '
                'mid-word — $numbers');
          }
        }
      }

      // The floor premise, fourth instance. `Expanded` made the sentence
      // unoverflowable; if it also never wraps, this guard is asserting nothing about
      // the trade the fix made and the 26 red cells at 320px cannot be reproduced.
      expect(
        wrapped,
        isNotEmpty,
        reason:
            'no locale wrapped the up-to-date line at any width, so nothing '
            'here measured the wrap the #1380 fix introduced:\n'
            '${wrapped.join(', ')}',
      );

      expect(
        failures,
        isEmpty,
        reason: 'the #1380 fix at firmware_update_view.dart:546 stacks the OTA '
            'row below 600px of card content and lets its sentence wrap; a '
            'stretched button with a cut label, or a sentence wrapped to '
            'shreds, is the same defect in a shape the sweep reports as '
            'clean:\n${failures.join('\n')}',
      );
    });
  });

  group('readability at the site wave 4 fixed in router_assistant', () {
    // The wave's fourth fix, and the only one in a page's *chrome*:
    // `router_assistant_view.dart:409` overflowed 7 of 234 cells, all at 320px —
    // `tr` +89px, `ru` +87, `ar` +74, `pt` +67, `pt_PT` +48, `es` and `es_AR` +22.
    // A Material `AppBar` grants its title `width - 32`, the icon and its gap spend
    // 32 more, and `tr`'s title asks 345px at `titleLarge` — so it needs a 409px
    // screen to sit on one line and there is no font size that puts it on one line
    // at 320px while leaving it a title.
    //
    // The fix gives the title a second line below 420px and the toolbar the height
    // for it. Two things follow that the sweep cannot see, and this guard is both:
    //
    // 1. **The threshold, in both directions.** The taller bar is only correct
    //    where the title needs it; drifting up to the 600px breakpoint would leave
    //    a 480px screen with an 84px bar around one line of text, and every sweep
    //    would stay green. Read off the *rendered* bar rather than the widget's
    //    `toolbarHeight`, so what is asserted is the geometry and not the argument.
    // 2. **The title is whole.** `maxLines: 2` carries an ellipsis behind it, which
    //    is exactly the silent truncation the wave has refused three times already
    //    — and an ellipsis here would eat the screen's name.
    testWidgets('the assistant app bar gains a line below 420px, title whole',
        (tester) async {
      final failures = <String>[];
      final wrapped = <String>[];
      // Bar height is a function of width alone, so the shape claim is read in one
      // locale at the eight wide widths, and everything is read in all 26 at 320px
      // — where the 256px title line is the tightest it ever gets.
      final tr = AppLocalizations.supportedLocales
          .firstWhere((locale) => localeTag(locale) == 'tr');

      for (final width in kPageSweepWidths) {
        // 84.0 and 56.0 rather than a reference to the view's constants, which are
        // private, and rather than `width < 420 ? ... : ...` for the reason the OTA
        // guard states: a threshold change should have to restate its effect here.
        // 84 is `kToolbarHeight + 28`, one more `titleLarge` line.
        final expectedBarHeight = width == 320.0 ? 84.0 : 56.0;
        final locales =
            width == 320.0 ? AppLocalizations.supportedLocales : <Locale>[tr];

        for (final locale in locales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('assistant-title-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kRouterAssistantPageCase.view(),
              locale: locale,
              overrides: kRouterAssistantPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          final bar = find.byType(AppBar);
          // Scoped to the bar because the chat screen paints this same string as a
          // welcome headline; the config screen does not, and the count assertion
          // is what would notice if the fixture ever landed on the other screen.
          final title = find.descendant(
            of: bar,
            matching: find.text(loc.aiRouterAssistant),
          );
          if (bar.evaluate().length != 1 || title.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: found '
                '${bar.evaluate().length} app bar(s) and '
                '${title.evaluate().length} title(s), so nothing was measured');
            continue;
          }

          final barHeight = tester.getSize(bar).height;
          if ((barHeight - expectedBarHeight).abs() > 0.5) {
            failures.add('$tag @${width.toInt()}px: the app bar was '
                '${barHeight.toStringAsFixed(1)}px tall, expected '
                '${expectedBarHeight.toStringAsFixed(1)}px');
          }

          final paragraph = tester.paragraphOf(title);
          final lines = tester.textLineCount(title);
          if (lines > 1) {
            wrapped.add('$tag@${width.toInt()}px:${lines}L');
          }
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on $lines line(s), '
              'widest token '
              '${tester.widestTokenWidth(title).toStringAsFixed(1)}px, whole '
              'string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px'
              ' — "${loc.aiRouterAssistant}"';
          if (tester.isTextClipped(title)) {
            failures.add('$tag @${width.toInt()}px: the title ellipsized — '
                '$numbers');
          } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
              tester.hasSplitToken(title)) {
            failures.add('$tag @${width.toInt()}px: the title broke mid-word — '
                '$numbers');
          }
        }
      }

      // The floor premise, fifth instance. The second line is the whole fix; if no
      // locale takes it, the taller bar is decorative and the seven red cells
      // #1370 recorded cannot be reproduced.
      expect(
        wrapped,
        isNotEmpty,
        reason:
            'no locale used the second title line at 320px, so nothing here '
            'measured the reflow the #1380 fix introduced:\n'
            '${wrapped.join(', ')}',
      );

      expect(
        failures,
        isEmpty,
        reason:
            'the #1380 fix at router_assistant_view.dart:409 gives the title '
            'a second line below 420px; both the height it takes there and the '
            'height it leaves alone above are part of the fix, and a title that '
            'reaches the ellipsis behind maxLines: 2 has lost what the fix was '
            'protecting:\n${failures.join('\n')}',
      );
    });
  });

  group('readability at the site wave 4 fixed in test_console', () {
    // The wave's fifth fix and the epic's only locale-independent one:
    // `usp_test_console_view.dart:1147` overflowed 52 of 234 cells — every locale at
    // 320px by +109px and every locale at 480px by +29px, the *same* number each
    // time, because the five `Notification Type` items are hard-coded English and
    // `DropdownButtonFormField` sizes itself to the widest of them. The console had
    // no narrow layout at all: two `Expanded(flex: 1)` panes either side of a
    // divider, so a 320px screen gave each one 159px.
    //
    // The fix stacks the panes below 600px, so this is a reflow and rule 4's usual
    // text pair is again the wrong instrument. Two claims need pinning, and the
    // second is the one that makes the first worth making:
    //
    // 1. **The axis, in both directions.** Stacked below 600px, side by side at and
    //    above it. Without the second half the threshold could drift to
    //    `double.infinity` and every sweep would stay green while the desktop
    //    console — the only place this page is ever used — lost its log panel to the
    //    bottom of a scroll.
    // 2. **The width the reflow was for.** The dropdown asks 236px; it was granted
    //    127px at 320px and 207px at 480px. Asserting the grant at all nine widths
    //    says what the sweep's green cannot: not merely that nothing overflowed, but
    //    that the widest item still has room, which is the difference between this
    //    fix and an `isExpanded: true` that would have ellipsized the label and gone
    //    green just the same.
    testWidgets('the console stacks its panes below 600px, dropdown kept whole',
        (tester) async {
      final failures = <String>[];
      // Layout mode is a function of width alone *and* nothing on this page is
      // localized, so the eight non-320 widths are read in one locale — `ar`, which
      // is the one that matters here: in RTL the `Row` puts the controls on the
      // right, so it is the side-by-side branch's mirror image and the only cell
      // that would catch a shape assertion written as "log is to the right of".
      final ar = AppLocalizations.supportedLocales
          .firstWhere((locale) => localeTag(locale) == 'ar');

      /// What the widest item, `4 - OperationComplete`, asks of the field.
      ///
      /// Derived from the pre-fix run rather than from a text metric: the field was
      /// granted 127px at 320px and reported +109px, and 207px at 480px and reported
      /// +29px. Both say 236. A literal for the reason the other wave-4 guards give
      /// for theirs — a threshold or a font change should have to restate its effect
      /// here rather than recompute agreement with itself.
      const dropdownAsks = 236.0;

      for (final width in kPageSweepWidths) {
        final stackExpected = width < 600.0;
        final locales =
            width == 320.0 ? AppLocalizations.supportedLocales : <Locale>[ar];

        for (final locale in locales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('console-panes-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kTestConsolePageCase.view(),
              locale: locale,
              overrides: kTestConsolePageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          // The control pane's root and the log pane's list. Both are this page's
          // only instance of their type — the count assertion below is what says so
          // out loud, and it is also what notices a pane being dropped, which is why
          // `kTestConsolePageCase` requires `SelectionArea` as well.
          final controls = find.byType(SingleChildScrollView);
          final log = find.byType(SelectionArea);
          final dropdown = find.byType(DropdownButtonFormField<int>);
          if (controls.evaluate().length != 1 ||
              log.evaluate().length != 1 ||
              dropdown.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: found '
                '${controls.evaluate().length} control pane(s), '
                '${log.evaluate().length} log pane(s) and '
                '${dropdown.evaluate().length} dropdown(s), so nothing was '
                'measured');
            continue;
          }

          final controlRect = tester.getRect(controls);
          final logRect = tester.getRect(log);
          // Read as disjointness on one axis and overlap on the other, rather than
          // as "same top" or "log is to the right of": these two rects are a pane
          // root and a sub-part of the other pane (the list sits under the log's
          // header, 65px lower), and `ar` puts the controls on the right. Disjoint
          // horizontally + overlapping vertically is true of both, and of neither
          // stacking.
          //
          // Both computed, both asserted: a layout that is neither — overlapping
          // panes, or one collapsed to nothing — fails whichever direction it was
          // pumped in, where a single `stacked != expected` would let it pass half
          // the time.
          final stacked = logRect.top >= controlRect.bottom - 0.5 &&
              (logRect.width - controlRect.width).abs() < 0.5;
          final sideBySide = (logRect.left >= controlRect.right - 0.5 ||
                  controlRect.left >= logRect.right - 0.5) &&
              logRect.top < controlRect.bottom &&
              controlRect.top < logRect.bottom;
          final geometry = 'controls '
              '${controlRect.left.toStringAsFixed(1)}..'
              '${controlRect.right.toStringAsFixed(1)} × '
              '${controlRect.top.toStringAsFixed(1)}..'
              '${controlRect.bottom.toStringAsFixed(1)}, log '
              '${logRect.left.toStringAsFixed(1)}..'
              '${logRect.right.toStringAsFixed(1)} × '
              '${logRect.top.toStringAsFixed(1)}..'
              '${logRect.bottom.toStringAsFixed(1)}';
          if (stacked != stackExpected || sideBySide == stackExpected) {
            failures.add('$tag @${width.toInt()}px: expected the panes '
                '${stackExpected ? 'stacked' : 'side by side'} but read '
                'stacked=$stacked sideBySide=$sideBySide — $geometry');
          }

          final dropdownWidth = tester.getSize(dropdown).width;
          if (dropdownWidth < dropdownAsks - 0.5) {
            failures.add('$tag @${width.toInt()}px: the Notification Type '
                'dropdown was granted '
                '${dropdownWidth.toStringAsFixed(1)}px for a '
                '${dropdownAsks.toStringAsFixed(1)}px widest item — $geometry');
          }

          // The half a width assertion cannot see. `1 - ValueChange` is the
          // selected item and so the one actually painted; if the field is ever
          // made to fit by ellipsis rather than by width, this is where it shows.
          final selected = find.descendant(
            of: dropdown,
            matching: find.text('1 - ValueChange'),
          );
          if (selected.evaluate().isEmpty) {
            failures.add('$tag @${width.toInt()}px: the dropdown painted no '
                '"1 - ValueChange", so its selection was not measured');
          } else if (tester.isTextClipped(selected.first)) {
            failures.add('$tag @${width.toInt()}px: the dropdown label '
                'ellipsized despite being granted '
                '${dropdownWidth.toStringAsFixed(1)}px');
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'the #1380 fix at usp_test_console_view.dart:1147 stacks the '
            "console's two panes below 600px; the axis in both directions and "
            'the 236px the reflow was for are both part of the fix, and a '
            'dropdown that fits by ellipsis has lost what it '
            'bought:\n${failures.join('\n')}',
      );
    });
  });

  group('readability at the site wave 4 fixed in admin', () {
    // The wave's sixth and seventh fixes, and the pair that shows why a page-level
    // sweep is not a card-level sweep with more cells. `usp_timezone_card.dart:71`
    // overflowed 30 of 234 cells and `firmware_update_card.dart:77` all 234 — but
    // the shape of *where* is the finding: 4 locales at 320px and 15 at 601px for
    // the header, and a 601px screen that was worse than a 320px one at both sites.
    //
    // Because `AppResponsiveLayout` defaults its tablet band to `desktop`, and two
    // `colWidth(6)` columns of a 601px screen are ~253px each against the 288px a
    // 320px phone gives the same card. At 601px `en`'s one-word `Timezone` heading
    // was granted 75.4px for a 77.5px word. So the fix is in three parts, and this
    // group guards all three:
    //
    // 1. **`usp_admin_view` keeps one column through the tablet band.** A box that
    //    cannot hold one word of a heading is a container being wrong, and no
    //    amount of flex inside the card fixes it. Two columns start at the desktop
    //    breakpoint, where each is ~400px and up. This is a reflow, so rule 4's
    //    companion is a shape guard asserted in *both* directions — one column at
    //    601px, two at 905px — which is the first test below.
    // 2. **The header title is expanded** (`usp_timezone_card.dart:71`), which is
    //    still needed at 320px, where 4 locales were over by up to +19px and the
    //    tablet band is not involved. That turns an overflow into a wrap, so its
    //    companion is rule 4's usual text pair.
    // 3. **The skeleton's caption is expanded and the `Update` button leaves the
    //    row while the version is unknown** (`firmware_update_card.dart:77`).
    //
    // Part 3 is the one the sweep found by luck: an `AsyncNotifier`'s `build` is a
    // `Future` even when the fixture already holds the value, so every cell renders
    // one loading frame before its data frame and the collector is installed for
    // both. The state is real in the app — a router that answers slowly holds it
    // for seconds — and nothing else in the gate pumps it deliberately.
    testWidgets('the admin page keeps one column through the tablet band',
        (tester) async {
      final failures = <String>[];

      // Read off the *rendered* card boxes rather than off the builder that was
      // called, for the reason the assistant guard gives: what is asserted should
      // be the geometry and not the argument. One column means the timezone card
      // and the password card have the same left edge; two means they do not.
      //
      // Both directions, and in `en` alone because a column count is not a function
      // of locale. The band is `AppLayoutConfig`'s, not this page's: tablet is
      // `600 < w <= 905` and `context.responsive` tests desktop first, so 601px and
      // 905px are its ends and 1080px is the first width that must still split.
      // 905px is in the loop because it is *inside* the band while looking like a
      // desktop width — it is where 13 locales were red before the fix, and the
      // coordinate a reader would assume was already two columns.
      final en = AppLocalizations.supportedLocales
          .firstWhere((locale) => localeTag(locale) == 'en');
      for (final width in const [601.0, 905.0, 1080.0]) {
        final expectStacked = width != 1080.0;
        await setLayoutSurface(tester, Size(width, kPageSweepHeight));
        await tester.pumpWidget(KeyedSubtree(
          key: ValueKey('admin-columns-${width.toInt()}'),
          child: pageSurfaceHost(
            view: kAdminPageCase.view(),
            locale: en,
            overrides: kAdminPageCase.overrides(),
          ),
        ));
        await settleIgnoringAnimations(tester);

        final timezone = find.byType(UspTimezoneCard);
        final firmware = find.byType(FirmwareUpdateCard);
        if (timezone.evaluate().length != 1 ||
            firmware.evaluate().length != 1) {
          failures.add('@${width.toInt()}px: found '
              '${timezone.evaluate().length} timezone card(s) and '
              '${firmware.evaluate().length} firmware card(s), so no column '
              'count was measured');
          continue;
        }

        // The firmware card is in the *right* column of the desktop layout and
        // below the timezone card in the mobile one, so its left edge is the
        // discriminator and its width is the number that mattered.
        final tzLeft = tester.getTopLeft(timezone).dx;
        final fwLeft = tester.getTopLeft(firmware).dx;
        final stacked = (tzLeft - fwLeft).abs() < 0.5;
        if (stacked != expectStacked) {
          failures.add('@${width.toInt()}px: the cards were '
              '${stacked ? 'stacked' : 'side by side'}, expected '
              '${expectStacked ? 'stacked' : 'side by side'} — timezone card at '
              'x=${tzLeft.toStringAsFixed(1)} '
              '(${tester.getSize(timezone).width.toStringAsFixed(1)}px wide), '
              'firmware card at x=${fwLeft.toStringAsFixed(1)} '
              '(${tester.getSize(firmware).width.toStringAsFixed(1)}px wide)');
        }

        // The half a column count cannot see. One column is only worth having
        // because it is wider than two, and the whole reason the tablet band moved
        // is that 253px was not enough for a heading; a one-column layout that
        // somehow granted less would satisfy the assertion above and lose the fix.
        final tzWidth = tester.getSize(timezone).width;
        if (expectStacked && tzWidth < 400) {
          failures.add('@${width.toInt()}px: one column granted the timezone '
              'card only ${tzWidth.toStringAsFixed(1)}px, which is not more than '
              'the ~253px two columns granted it');
        }
      }

      expect(
        failures,
        isEmpty,
        reason: "the #1380 fix gives usp_admin_view's tablet band a single "
            'column; the band that stacks and the breakpoint that stops stacking '
            'are both part of the fix, and a tablet band that quietly widened to '
            'the desktop breakpoint would leave every sweep green while `en`\'s '
            'one-word heading went back to 75px:\n${failures.join('\n')}',
      );
    });

    testWidgets('the timezone card header title stays whole where it wraps',
        (tester) async {
      /// As the three ceilings above, and a fourth for the same reason: a card
      /// heading in a 288px box is not the same measurement as a nav row's title.
      ///
      /// One line over the deepest coordinate measured — `fr`, `fr_CA`, `pl` and
      /// `ru` all take two lines of the 102.9px this header grants at 320px, and
      /// they are the only 4 of the 52 coordinates that wrap at all.
      const kCardHeadingLineCeiling = 3;

      final failures = <String>[];
      final wrapped = <String>[];

      // The two widths the mobile layout is swept at, which after part 1 of the fix
      // is where the expanded title is the whole of the remedy. 601px is guarded by
      // the shape test above instead: the card is 537px wide there now, and a
      // heading that fits on one line measures nothing about a wrap.
      for (final width in const [320.0, 480.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('admin-tz-title-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kAdminPageCase.view(),
              locale: locale,
              overrides: kAdminPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // The card paints `timezone` twice — once as this heading and once as the
          // label of its first `DetailInfoTile` — so the count is pinned at two and
          // the heading is taken in tree order, which puts it first because the
          // `Column` holds the header above the tiles. Pinning the count is what
          // makes the ordering safe to rely on: a card that grows a third mention,
          // or loses the tile, fails here rather than measuring the wrong string.
          final mentions = find.descendant(
            of: find.byType(UspTimezoneCard),
            matching: find.text(loc.timezone),
          );
          if (mentions.evaluate().length != 2) {
            failures.add('$tag @${width.toInt()}px: the timezone card painted '
                '"${loc.timezone}" ${mentions.evaluate().length} time(s), '
                'expected 2 (heading + tile label), so nothing was measured');
            continue;
          }
          final title = mentions.first;

          final paragraph = tester.paragraphOf(title);
          final lines = tester.textLineCount(title);
          if (lines > 1) {
            wrapped.add('$tag@${width.toInt()}px:${lines}L');
          }
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on $lines line(s), '
              'widest token '
              '${tester.widestTokenWidth(title).toStringAsFixed(1)}px, whole '
              'string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px'
              ' — "${loc.timezone}"';
          if (lines > kCardHeadingLineCeiling) {
            failures.add('$tag @${width.toInt()}px: the heading wrapped onto '
                '$lines lines, past the $kCardHeadingLineCeiling-line ceiling — '
                '$numbers');
          }
          if (tester.isTextClipped(title)) {
            failures.add('$tag @${width.toInt()}px: the heading ellipsized — '
                '$numbers');
          } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
              tester.hasSplitToken(title)) {
            failures.add('$tag @${width.toInt()}px: the heading broke mid-word '
                '— $numbers');
          }
        }
      }

      // The floor premise, sixth instance. Without it every assertion above passes
      // against 52 headings that all fitted on one line, and the wrap the fix
      // introduced would be reported as covered while being unmeasured.
      expect(
        wrapped,
        isNotEmpty,
        reason: 'no locale used a second heading line at either width, so '
            'nothing here measured the wrap the #1380 fix at '
            'usp_timezone_card.dart:71 introduced:\n${wrapped.join(', ')}',
      );

      expect(
        failures,
        isEmpty,
        reason: 'the #1380 fix at usp_timezone_card.dart:71 expands the header '
            'title so the status capsule and the edit button stop taking the '
            "row's whole width; a heading that fits by ellipsis, or breaks "
            'mid-word, has lost what the wrap was for:\n${failures.join('\n')}',
      );
    });

    // Part 3, and the reason it needs a guard of its own rather than a line in the
    // one above: `firmware_update_card.dart:77` overflowed at all nine widths — 26
    // locales at 320px (`de` +234px worst, `en` +70), 12 at 480px, 26 at 601px, 13
    // at 905px and 6 at each of the five wide widths (`fr_CA` +118px at 1681px). So
    // the tablet-band fix cannot be what closes it and the sweep going green does
    // not tell you which of the three parts did.
    //
    // `adminPageLoadingFirmwareOverrides` is what holds the state still: a fixture
    // that resolves is `AsyncLoading` for exactly one frame, which is enough for the
    // collector and not enough for a guard to read.
    //
    // The remaining wide widths are why the caption also needed the `Update` button
    // out of the row. This row sits inside the card's `Expanded` column beside a
    // fixed icon *and* that button, so its box is a fraction of a `colWidth(6)`
    // column and grows far more slowly than the screen does — 1681px is in the loop
    // below for that reason alone, and it is the width that would go red first if
    // the button came back.
    testWidgets('the firmware skeleton caption stays whole while it loads',
        (tester) async {
      /// The caption is a full sentence rather than a heading, so it sits one line
      /// above [kCardHeadingLineCeiling] — and, by the same rule, one over its own
      /// deepest coordinate: `fr`, `fr_CA` and `pl` take three lines of the 178.0px
      /// this row grants at 320px. Nineteen of the 78 coordinates wrap, every one of
      /// them at 320px, which is the width the `Update` button was hidden for.
      const kSkeletonCaptionLineCeiling = 4;

      final failures = <String>[];
      final wrapped = <String>[];

      // Three widths rather than the guard-usual two, because unlike every other
      // site this wave fixed, this one was red at *every* width: 320px is the
      // narrowest box the card ever gets, 601px is the tablet band part 1 moved,
      // and 1681px is the widest the family sweeps — where six locales still
      // overflowed. A guard that stopped at 601px would leave the claim "the wide
      // widths are safe" resting on the arithmetic above rather than on a
      // measurement.
      for (final width in const [320.0, 601.0, 1681.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('admin-fw-skeleton-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kAdminPageCase.view(),
              locale: locale,
              overrides: adminPageLoadingFirmwareOverrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // Scoped to the card, and counted, because the premise this guard rests
          // on is that the page is still loading. If the override ever resolves,
          // the caption is gone and every assertion below would pass over nothing
          // — which is #1366's F11 finding, and the reason the count is checked
          // rather than the finder being used as found.
          final caption = find.descendant(
            of: find.byType(FirmwareUpdateCard),
            matching: find.text(loc.loadingFirmwareInfo),
          );
          if (caption.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the card painted '
                '${caption.evaluate().length} loading caption(s), expected 1 — '
                'the card is not in its loading state, so nothing was measured');
            continue;
          }

          final paragraph = tester.paragraphOf(caption);
          final lines = tester.textLineCount(caption);
          if (lines > 1) {
            wrapped.add('$tag@${width.toInt()}px:${lines}L');
          }
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on $lines line(s), '
              'widest token '
              '${tester.widestTokenWidth(caption).toStringAsFixed(1)}px, whole '
              'string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px'
              ' — "${loc.loadingFirmwareInfo}"';
          if (lines > kSkeletonCaptionLineCeiling) {
            failures.add('$tag @${width.toInt()}px: the caption wrapped onto '
                '$lines lines, past the $kSkeletonCaptionLineCeiling-line '
                'ceiling — $numbers');
          }
          if (tester.isTextClipped(caption)) {
            failures.add('$tag @${width.toInt()}px: the caption ellipsized — '
                '$numbers');
          } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
              tester.hasSplitToken(caption)) {
            failures.add('$tag @${width.toInt()}px: the caption broke mid-word '
                '— $numbers');
          }
        }
      }

      // The floor premise, seventh instance.
      expect(
        wrapped,
        isNotEmpty,
        reason: 'no locale used a second caption line at any of the three '
            'widths, so nothing here measured the wrap the #1380 fix at '
            'firmware_update_card.dart:77 introduced:\n${wrapped.join(', ')}',
      );

      expect(
        failures,
        isEmpty,
        reason: 'the #1380 fix at firmware_update_card.dart:77 expands the '
            "skeleton's caption so a spinner's own label stops pushing the row "
            'past its box; a caption that fits by ellipsis has lost what the '
            'wrap was for, and a caption that is absent means this guard stopped '
            'measuring a loading state at all:\n${failures.join('\n')}',
      );
    });
  });

  // Wave 4's eighth, ninth and tenth fixes, all on `usp_apps_view`, and the reason
  // they are one group is the reason admin's two are: `kReadabilityGuardPages` bills
  // one fixture per group, and this is one page.
  //
  // The three sites, and what each cost before the fix:
  //
  // 1. **`usp_apps_view.dart:90`**, the page's own heading beside the `Store`
  //    button, `spaceBetween` with an inflexible icon-bearing button — 16 locales
  //    over at 320px, worst +49px. Expanded, so a wrap, so rule 4's text pair.
  // 2. **`usp_apps_view.dart:155`**, the grid card's content column against a
  //    hard-coded `mainAxisExtent` — every locale, every card, +6.0px at 320px and
  //    480px. Not a locale defect at all: 112px was 6px short of the card's own
  //    content, and the sum is written out at the fix. A raised box is a shape
  //    change, so the companion is a shape guard, and it is asserted in both
  //    directions — the box must hold the column, and it must not be a line taller
  //    than the column needs, because "make the box huge" is the other way to turn
  //    this site green.
  // 3. **`usp_apps_view.dart:159`**, the card's header row of 36px tile + badge —
  //    11 locales over at 601px alone, worst +29px. This is the tablet band again,
  //    exactly as on `admin`: three columns of a 601px screen are 152.3px each
  //    against the 240px one column of a 320px phone gives. Two columns at 601px
  //    are 236.5px and the row is clean. A reflow, so both directions again.
  group('readability at the sites wave 4 fixed in apps', () {
    testWidgets('the apps heading and its `Store` button reflow, never shrink',
        (tester) async {
      // The companion to a *reflow* fix, so it is a shape guard asserted in both
      // directions rather than a line ceiling: what the `Wrap` promises is that
      // the two children keep their intrinsic widths and the button changes rows,
      // and both halves of that are falsifiable.
      //
      // The readability half is `lines == 1`, not a ceiling. The heading is one
      // word in every locale — the widest whole string is `es`'s 149.9px, inside
      // the ~240px the mobile content row grants — so once it no longer shares a
      // row with an inflexible button there is nothing left to wrap. A second
      // line here would mean the heading is being squeezed again, which is the
      // defect this fix removed: under the `Expanded` it had, 7 locales broke
      // mid-word inside an 85–113px box.
      final failures = <String>[];
      final stacked = <String>[];

      // 320 and 480 are the mobile band, where the two children stop fitting;
      // 1441 is the wide side, where the reflow must not have cost the
      // `spaceBetween` geometry the `Row` gave for free.
      const kWideWidth = 1441.0;
      for (final width in const [320.0, 480.0, kWideWidth]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('apps-heading-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kAppsPageCase.view(),
              locale: locale,
              overrides: kAppsPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // `loc.apps` is painted twice — once by `UiKitPageView`'s own `title:`
          // and once by this heading — so the finder is scoped to the content
          // column rather than counted. The column is the grid's closest `Column`
          // ancestor, which is the one at `usp_apps_view.dart:87`; the page title
          // lives in the chrome above it and is measured by the #1314 sweep.
          final content = find
              .ancestor(
                of: find.byType(GridView),
                matching: find.byType(Column),
              )
              .first;
          final row = find.descendant(
            of: content,
            matching: find.byType(Wrap),
          );
          final heading = find.descendant(
            of: content,
            matching: find.text(loc.apps),
          );
          final button = find.descendant(
            of: content,
            matching: find.byType(AppButton),
          );
          if (heading.evaluate().length != 1 ||
              button.evaluate().length != 1 ||
              row.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the content column painted '
                '${heading.evaluate().length} heading(s), '
                '${button.evaluate().length} button(s) and '
                '${row.evaluate().length} `Wrap`(s), expected 1 of each, so '
                'nothing was measured');
            continue;
          }

          final paragraph = tester.paragraphOf(heading);
          final lines = tester.textLineCount(heading);
          final rowRect = tester.getRect(row);
          final headingRect = tester.getRect(heading);
          final buttonRect = tester.getRect(button);
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on $lines line(s) of '
              'the ${rowRect.width.toStringAsFixed(1)}px row, whole string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px, '
              'button ${buttonRect.width.toStringAsFixed(1)}px — "${loc.apps}"';

          // Direction one: nothing shrank. One line, no ellipsis, no mid-word
          // break — the heading got the width it asked for.
          if (lines != 1) {
            failures.add('$tag @${width.toInt()}px: the heading took $lines '
                'lines; a one-word heading that wraps is one being squeezed — '
                '$numbers');
          }
          if (tester.isTextClipped(heading)) {
            failures.add(
                '$tag @${width.toInt()}px: the heading ellipsized — $numbers');
          } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
              tester.hasSplitToken(heading)) {
            failures.add('$tag @${width.toInt()}px: the heading broke mid-word '
                '— $numbers');
          }

          // Direction two: the button moved instead. `isStacked` is read off the
          // geometry — a second run starts below the first — and not off the
          // width arithmetic, which would only re-implement `Wrap`.
          final isStacked = buttonRect.top >= headingRect.bottom;
          if (isStacked) {
            stacked.add('$tag@${width.toInt()}px');
            if (width == kWideWidth) {
              failures.add('$tag @${width.toInt()}px: the button dropped to a '
                  'second row on the wide side, where both children fit — '
                  '$numbers');
            }
          } else if (width == kWideWidth) {
            // Sharing a row on the wide side is not enough: `spaceBetween` is
            // what put the button at the far edge, and a `Wrap` that sized to its
            // widest run instead of its constraint would leave it beside the
            // heading. Asserted as "one child touches each end of the row" so it
            // reads the same in `ar` as in `en`.
            final leading =
                headingRect.left < buttonRect.left ? headingRect : buttonRect;
            final trailing =
                headingRect.left < buttonRect.left ? buttonRect : headingRect;
            if ((leading.left - rowRect.left).abs() > 1.0 ||
                (rowRect.right - trailing.right).abs() > 1.0) {
              failures.add('$tag @${width.toInt()}px: the row is '
                  '${rowRect.width.toStringAsFixed(1)}px wide but its children '
                  'span ${leading.left.toStringAsFixed(1)}px..'
                  '${trailing.right.toStringAsFixed(1)}px — `spaceBetween` no '
                  'longer reaches both ends, so the `Wrap` sized to its run '
                  'rather than to the page — $numbers');
            }
          }
        }
      }

      // The floor premise, eighth instance: if the two children fit side by side
      // in all 26 locales at 320px, the `Wrap` is inert and this guard is a
      // tautology over a `Row`.
      expect(
        stacked,
        isNotEmpty,
        reason: 'no locale needed a second row at any width, so nothing here '
            'measured the reflow the #1380 fix at usp_apps_view.dart:90 '
            'introduced',
      );

      expect(
        failures,
        isEmpty,
        reason:
            'the #1380 fix at usp_apps_view.dart:90 drops the `Store` button '
            'below the heading when the two do not fit, instead of squeezing the '
            'heading into what the button leaves; a heading that wraps or '
            'ellipsizes means something shrank after all, and a button that '
            'stopped reaching the far edge on a wide page means the reflow was '
            'paid for by every other width:\n${failures.join('\n')}',
      );
    });

    testWidgets('the apps grid takes one, two and three columns by band',
        (tester) async {
      final failures = <String>[];

      // Read off the rendered card boxes rather than off `crossAxisCount`, for the
      // reason admin's shape guard gives: what is asserted should be the geometry
      // and not the argument.
      //
      // Both directions, and in `en` alone because a column count is not a function
      // of locale. Four widths for three bands: 480px is inside mobile, 601px and
      // 905px are the ends of `AppLayoutConfig`'s tablet band — 905px is the one
      // that looks like a desktop width and is not — and 1080px is the first width
      // that must take three.
      const expectedColumns = <(double, int)>[
        (480.0, 1),
        (601.0, 2),
        (905.0, 2),
        (1080.0, 3),
      ];

      for (final (width, expected) in expectedColumns) {
        await setLayoutSurface(tester, Size(width, kPageSweepHeight));
        await tester.pumpWidget(KeyedSubtree(
          key: ValueKey('apps-columns-${width.toInt()}'),
          child: pageSurfaceHost(
            view: kAppsPageCase.view(),
            locale: const Locale('en'),
            overrides: kAppsPageCase.overrides(),
          ),
        ));
        await settleIgnoringAnimations(tester);

        final cards = find.byType(AppCard);
        if (cards.evaluate().length != gateApps.length) {
          failures.add('@${width.toInt()}px: found ${cards.evaluate().length} '
              'cards, expected ${gateApps.length} — the fixture is not the grid '
              'this guard measures');
          continue;
        }

        // Cards sharing the first card's top edge are its row, which is the column
        // count. `mainAxisExtent` is fixed per band, so every row shares an edge.
        final tops = cards.evaluate().map((e) {
          final f = find.byWidget(e.widget);
          return tester.getTopLeft(f).dy;
        }).toList();
        final columns =
            tops.where((dy) => (dy - tops.first).abs() < 0.5).length;
        if (columns != expected) {
          failures.add('@${width.toInt()}px: the grid laid out $columns '
              'column(s), expected $expected');
        }
      }

      expect(
        failures,
        isEmpty,
        reason:
            'the #1380 fix at usp_apps_view.dart:82 gives the tablet band two '
            'columns of its own; the band that takes two and the breakpoints on '
            'either side of it are all part of the fix, and a tablet band that '
            'went back to three would leave every sweep green while a 601px '
            'screen handed a card less width than a 320px phone does:\n'
            '${failures.join('\n')}',
      );
    });

    testWidgets('the mobile card box holds the column it was raised for',
        (tester) async {
      /// The slack the box is allowed over its content, and one `bodySmall` line
      /// (16px) because that is the unit a "just make the box taller" fix would
      /// spend. The measured slack is 2px: 19px of `AppCard` padding + 36px tile +
      /// 4px + 20px title + 4px + 16px description = 118 against the 120 the fix
      /// sets.
      const kBoxSlackCeiling = 16.0;

      final failures = <String>[];

      // The mobile band, which is the band the extent was short in, and both of its
      // widths because the description's line count is capped at one here — so the
      // sum being guarded is the same at both and a difference between them would
      // mean the cap stopped holding.
      for (final width in const [320.0, 480.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('apps-box-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kAppsPageCase.view(),
              locale: locale,
              overrides: kAppsPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          // The first app's card, found through its name because app names come
          // off the router and are not localized — so the same finder works in all
          // 26 locales, and a fixture that renamed its first app fails here.
          final first = gateApps.first;
          final card = find
              .ancestor(
                of: find.text(first.name),
                matching: find.byType(AppCard),
              )
              .first;
          final description = find.descendant(
            of: card,
            matching: find.text(first.description),
          );
          if (description.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the first card painted '
                '${description.evaluate().length} description(s), expected 1');
            continue;
          }

          // The description is the column's last child, so its bottom edge is the
          // content's. `AppCard`'s padding is a theme token
          // (`AppSpacing.lg × spacingFactor`), so it is read off the geometry
          // rather than assumed: the card's own left inset is the same token.
          final cardRect = tester.getRect(card);
          final padding = tester.getRect(description).left - cardRect.left;
          final slack =
              (cardRect.bottom - padding) - tester.getRect(description).bottom;
          final numbers = 'card ${cardRect.height.toStringAsFixed(1)}px tall, '
              '${padding.toStringAsFixed(1)}px padding, description bottom '
              '${(tester.getRect(description).bottom - cardRect.top).toStringAsFixed(1)}px '
              'from the top, slack ${slack.toStringAsFixed(1)}px';
          if (slack < 0) {
            failures.add('$tag @${width.toInt()}px: the content column runs '
                '${(-slack).toStringAsFixed(1)}px past the card box — $numbers');
          } else if (slack > kBoxSlackCeiling) {
            failures.add('$tag @${width.toInt()}px: the card box is '
                '${slack.toStringAsFixed(1)}px taller than its content, past the '
                '${kBoxSlackCeiling.toStringAsFixed(0)}px ceiling — $numbers');
          }
        }
      }

      expect(
        failures,
        isEmpty,
        reason: 'the #1380 fix at usp_apps_view.dart:83 raises the mobile '
            "`mainAxisExtent` to the card's own content height; a box that still "
            'clips the description, or one padded out until nothing could '
            'overflow it, both leave the sweep green over a card nobody can '
            'read:\n${failures.join('\n')}',
      );
    });

    testWidgets('the narrowest non-mobile card still holds its badge row',
        (tester) async {
      final failures = <String>[];
      final budgets = <String, double>{};

      // 601px alone: it is the narrowest card any band produces above mobile
      // (236.5px, against 388.5px at 905px and 317.3px at 1080px — the tablet band
      // is *wider* than the first desktop width because two columns of 601px beat
      // three of 1080px), and it is where all 11 red locales were.
      const width = 601.0;
      for (final locale in AppLocalizations.supportedLocales) {
        final tag = localeTag(locale);
        await setLayoutSurface(tester, Size(width, kPageSweepHeight));
        await tester.pumpWidget(KeyedSubtree(
          key: ValueKey('apps-badge-$tag'),
          child: pageSurfaceHost(
            view: kAppsPageCase.view(),
            locale: locale,
            overrides: kAppsPageCase.overrides(),
          ),
        ));
        await settleIgnoringAnimations(tester);

        // Every badge in the grid, not the first card's. The fixture paints two
        // labels — `New` on the recent app and `User` on the two user-category
        // ones — and in `ar` the `New` badge is 21.5px while `User` is the wider
        // of the pair, so measuring only the first card would report the narrower
        // label as this page's worst case and pass a budget nothing runs against.
        final badges = find.byType(AppBadge);
        if (badges.evaluate().length != gateAppsBadgeCount) {
          failures.add('$tag: the grid painted ${badges.evaluate().length} '
              'badge(s), expected $gateAppsBadgeCount — apps_scene_data.dart is '
              'not the fixture this guard measures');
          continue;
        }

        for (var i = 0; i < badges.evaluate().length; i++) {
          final badge = badges.at(i);
          final card =
              find.ancestor(of: badge, matching: find.byType(AppCard)).first;

          // What the header row has to fit: the 36px icon tile and the badge, with
          // the card's padding taken off both sides. Asserted as the *budget*
          // rather than as an overflow, because the sweep already owns the
          // overflow — this is the headroom that made the two-column band the fix.
          final cardRect = tester.getRect(card);
          final badgeRect = tester.getRect(badge);
          // The badge is the header row's trailing child under `spaceBetween`, and
          // "trailing" is the left edge in `ar` — so the padding is whichever of
          // the two gaps is the inset rather than the row's free space. Reading
          // only `cardRect.right - badgeRect.right` reported a *negative* content
          // width in RTL.
          final padding = math.min(
            badgeRect.left - cardRect.left,
            cardRect.right - badgeRect.right,
          );
          final content = cardRect.width - padding * 2;
          final needed = 36.0 + badgeRect.width;
          if (badgeRect.width > (budgets[tag] ?? 0)) {
            budgets[tag] = badgeRect.width;
          }
          if (needed > content) {
            failures.add('$tag: the header row of the card at '
                '${cardRect.left.toStringAsFixed(1)}px needs '
                '${needed.toStringAsFixed(1)}px (36px tile + '
                '${badgeRect.width.toStringAsFixed(1)}px badge) of the '
                '${content.toStringAsFixed(1)}px this card grants it');
          }
        }
      }

      // The floor premise, ninth instance, and the one that keeps this guard from
      // being a tautology: three columns gave a 152.3px card, and after 19px of
      // padding on each side and the 36px tile that left 78.3px for the badge. If
      // no locale's widest badge came near that, the 11 red locales were not red
      // for the reason this fix assumes and the two-column band is not what
      // closed them.
      const kThreeColumnBadgeBudget = 78.3;
      final widest = budgets.values.fold(0.0, (a, b) => b > a ? b : a);
      expect(
        widest,
        greaterThan(kThreeColumnBadgeBudget),
        reason:
            'no locale needed more badge width than three columns of a 601px '
            'screen could give it, so nothing here measured the site the #1380 '
            'fix at usp_apps_view.dart:82 closed — widest badge '
            '${widest.toStringAsFixed(1)}px against the '
            '${kThreeColumnBadgeBudget.toStringAsFixed(1)}px budget',
      );

      expect(
        failures,
        isEmpty,
        reason:
            "the #1380 fix at usp_apps_view.dart:82 widens the tablet band's "
            'cards so the badge stops pushing the header row past its box:\n'
            '${failures.join('\n')}',
      );
    });
  });

  // Wave 4's eleventh fix, and the first in this file whose site is a *list header*
  // rather than a page heading or a card. `instant_privacy_view.dart:172` put the
  // `allowedDevicesCount` label beside an `AppButton.text` under `spaceBetween` with
  // neither child flexible: 14 of the 26 locales were over at 320px, worst `fr` at
  // +110px, and `ja` at +7.7px shows how little slack the row had even where the
  // string is short.
  //
  // The first fix here was an `Expanded` on the label, and **this guard is why it is
  // not the fix that shipped**. The overflow went green and the readability half came
  // back red: the button is ~194px of a 288px content row, so 17 locales wrapped, `fr`
  // took 4 lines inside 76.7px and `ru` broke a 95.8px word inside 94.1px. That is the
  // `apps` heading finding one page over — a box that cannot hold one word is the row
  // being wrong for the screen — so the shipped fix is `apps`' reflow, and the guard
  // is a *both-directions* shape guard rather than a line ceiling.
  group('readability at the site wave 4 fixed in instant_privacy', () {
    testWidgets(
        'the allowed-devices count and its `addDevice` button reflow, '
        'never shrink', (tester) async {
      final failures = <String>[];
      final stacked = <String>[];

      // 320 and 480 are the mobile band, where the two children stop fitting; 1441
      // is the wide side, where the reflow must not have cost the `spaceBetween`
      // geometry the `Row` gave for free. This page is a single full-width column
      // with no grid, so content width rises monotonically with the screen and there
      // is no narrower-content-at-a-wider-screen step to pair 320px with — unlike
      // `advanced_settings` and `apps`, which both needed a tablet width.
      const kWideWidth = 1441.0;
      for (final width in const [320.0, 480.0, kWideWidth]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('instant-privacy-count-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kInstantPrivacyPageCase.view(),
              locale: locale,
              overrides: kInstantPrivacyPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // Read off the ARB with the fixture's own count, so a fixture that stops
          // rendering three devices fails here rather than measuring a different
          // string. `allowedDevicesCount` appears once on the page — the toggle
          // card's label is `instantPrivacy` — so the finder is unscoped and the
          // count asserted.
          final countText = loc.allowedDevicesCount(
              gateInstantPrivacyState.allowedDevices.length);
          final label = find.text(countText);
          final button = find.widgetWithText(AppButton, loc.addDevice);
          if (label.evaluate().length != 1 || button.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the page painted '
                '${label.evaluate().length} count label(s) and '
                '${button.evaluate().length} `addDevice` button(s), expected 1 of '
                'each, so nothing was measured');
            continue;
          }
          // The header's own `Wrap`, reached through the label rather than by type,
          // so nothing in the page chrome can be measured by mistake.
          final row =
              find.ancestor(of: label, matching: find.byType(Wrap)).first;
          if (row.evaluate().length != 1) {
            failures.add(
                '$tag @${width.toInt()}px: the count label has no `Wrap` '
                'ancestor, so the reflow this guard measures is not in the tree');
            continue;
          }

          final paragraph = tester.paragraphOf(label);
          final lines = tester.textLineCount(label);
          final rowRect = tester.getRect(row);
          final labelRect = tester.getRect(label);
          final buttonRect = tester.getRect(button);
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on $lines line(s) of '
              'the ${rowRect.width.toStringAsFixed(1)}px row, whole string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px, '
              'widest token ${tester.widestTokenWidth(label).toStringAsFixed(1)}px, '
              'button ${buttonRect.width.toStringAsFixed(1)}px — "$countText"';

          // Direction one: nothing shrank. One line, no ellipsis, no mid-word
          // break — the label got the width it asked for. `lines == 1` and not a
          // ceiling, for `apps`' reason: the whole string is 197.9px at its widest
          // (`ru`) inside the ~288px a 320px page grants, so once the label no
          // longer shares a row with an inflexible button there is nothing left to
          // wrap, and a second line means it is being squeezed again.
          if (lines != 1) {
            failures.add(
                '$tag @${width.toInt()}px: the count label took $lines '
                'lines; a label that fits whole and wraps anyway is one being '
                'squeezed — $numbers');
          }
          if (tester.isTextClipped(label)) {
            failures
                .add('$tag @${width.toInt()}px: the count label ellipsized — '
                    '$numbers');
          } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
              tester.hasSplitToken(label)) {
            failures.add('$tag @${width.toInt()}px: the count label broke '
                'mid-word — $numbers');
          }

          // Direction two: the button moved instead. Read off the geometry — a
          // second run starts below the first — and not off width arithmetic,
          // which would only re-implement `Wrap`.
          final isStacked = buttonRect.top >= labelRect.bottom;
          if (isStacked) {
            stacked.add('$tag@${width.toInt()}px');
            if (width == kWideWidth) {
              failures.add('$tag @${width.toInt()}px: the button dropped to a '
                  'second row on the wide side, where both children fit — '
                  '$numbers');
            }
          } else if (width == kWideWidth) {
            // Sharing a row on the wide side is not enough: `spaceBetween` is what
            // put the button at the far edge, and a `Wrap` that sized to its widest
            // run instead of its constraint would leave it beside the label.
            // Asserted as "one child touches each end of the row" so it reads the
            // same in `ar` as in `en`.
            final leading =
                labelRect.left < buttonRect.left ? labelRect : buttonRect;
            final trailing =
                labelRect.left < buttonRect.left ? buttonRect : labelRect;
            if ((leading.left - rowRect.left).abs() > 1.0 ||
                (rowRect.right - trailing.right).abs() > 1.0) {
              failures.add('$tag @${width.toInt()}px: the row is '
                  '${rowRect.width.toStringAsFixed(1)}px wide but its children '
                  'span ${leading.left.toStringAsFixed(1)}px..'
                  '${trailing.right.toStringAsFixed(1)}px — `spaceBetween` no '
                  'longer reaches both ends, so the `Wrap` sized to its run '
                  'rather than to the page — $numbers');
            }
          }
        }
      }

      // The floor premise, tenth instance: if the count and the button fit side by
      // side in all 26 locales at 320px, the `Wrap` is inert and this guard is a
      // tautology over a `Row`.
      expect(
        stacked,
        isNotEmpty,
        reason: 'no locale needed a second row at any width, so nothing here '
            'measured the reflow the #1380 fix at instant_privacy_view.dart:172 '
            'introduced',
      );

      expect(
        failures,
        isEmpty,
        reason: 'the #1380 fix at instant_privacy_view.dart:172 drops the '
            '`addDevice` button below the count label when the two do not fit, '
            'instead of squeezing the label into what the button leaves; a label '
            'that wraps or ellipsizes means something shrank after all — which is '
            'what the `Expanded` this fix replaced did — and a button that stopped '
            'reaching the far edge on a wide page means the reflow was paid for by '
            'every other width:\n${failures.join('\n')}',
      );
    });
  });

  // Wave 4's twelfth fix, and the one whose site is not a locale defect at all:
  // `usp_ipv6_section.dart:170` put a fixed `SizedBox(width: 160)` label box, a
  // `Spacer` and an `AppSwitch` in one `Row`, and at 601px the desktop layout's two
  // columns give that row ~253px — 5.5px less than the fixed parts need, in all 26
  // locales and at that width alone. The `Expanded` that replaced the box turns the
  // floor into a share, so rule 4 applies and this is the companion.
  //
  // Both directions, like `apps`' heading: the label must not be squeezed, and the
  // switch must still sit at the far edge — because "let the label have everything"
  // is the other way to make this site green.
  group('readability at the site wave 4 fixed in internet_settings', () {
    testWidgets('every IPv6 switch label keeps its row and its far-edge switch',
        (tester) async {
      final failures = <String>[];
      final measured = <String>[];

      // 601px is the whole of the defect and the narrowest box the page ever
      // produces: `AppResponsiveLayout` switches to two columns there, so each is
      // ~253px against the ~288px a 320px phone gives the single column. 320px is
      // kept as the mobile control — the same row at a wider box, where it was always
      // clean — so a fix that traded one band for the other cannot pass here.
      for (final width in const [320.0, 601.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('internet-switch-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kInternetSettingsPageCase.view(),
              locale: locale,
              overrides: kInternetSettingsPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // The three in `build` order. Read off the ARB rather than off the tree, so
          // a section that stopped rendering a row fails here instead of shortening
          // the loop.
          final labels = <String, String>{
            'ipv6': loc.ipv6,
            'dhcpv6': loc.dhcpv6,
            'sixrd': loc.sixrdTunnel,
          };

          for (final entry in labels.entries) {
            // Scoped to the section: `loc.ipv6` is also the IPv6 renew card's
            // protocol label and part of `protocolDhcp`, so an unscoped finder would
            // measure whichever the tree walked into first.
            final label = find.descendant(
              of: find.byType(UspIpv6Section),
              matching: find.text(entry.value),
            );
            if (label.evaluate().length != 1) {
              failures.add('$tag @${width.toInt()}px: ${entry.key} resolved to '
                  '${label.evaluate().length} widgets inside the IPv6 section, so '
                  'nothing was measured');
              continue;
            }
            final row =
                find.ancestor(of: label, matching: find.byType(Row)).first;
            final switchFinder = find.descendant(
              of: row,
              matching: find.byType(AppSwitch),
            );
            if (switchFinder.evaluate().length != 1) {
              failures.add(
                  '$tag @${width.toInt()}px: ${entry.key}\'s row holds '
                  '${switchFinder.evaluate().length} switches, expected 1 — this is '
                  'not the row the fix changed');
              continue;
            }

            final paragraph = tester.paragraphOf(label);
            final lines = tester.textLineCount(label);
            final rowRect = tester.getRect(row);
            final labelRect = tester.getRect(label);
            final switchRect = tester.getRect(switchFinder);
            final numbers = 'granted '
                '${paragraph.size.width.toStringAsFixed(1)}px on $lines line(s) of '
                'the ${rowRect.width.toStringAsFixed(1)}px row, whole string '
                '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px, '
                'switch ${switchRect.width.toStringAsFixed(1)}px — "${entry.value}"';
            measured.add('$tag@${width.toInt()}px/${entry.key}:'
                '${rowRect.width.toStringAsFixed(0)}px');

            // Direction one: the label may use the second line the fix cost it, and
            // no more. Two, not one, and the difference is a measured 0.2px: `sv`
            // renders `sixrdTunnel` as "6rd Tunnel (6rd-tunnel)" at 159.8px, which
            // cleared the old fixed 160px box and does not clear the 142.5px share,
            // so it is the one of these 78 label×locale pairs that the fix moved onto
            // two lines. The other 77 are 58.6px (`zh_TW`'s DHCPv6) or less against
            // the same box, so two lines is a ceiling with the whole distribution
            // under it: a third line means the box fell below ~80px, which is the
            // `Expanded` having stopped being a share of this row.
            const kSwitchLabelLineCeiling = 2;
            if (lines > kSwitchLabelLineCeiling) {
              failures.add('$tag @${width.toInt()}px: ${entry.key} took $lines '
                  'lines, ceiling is $kSwitchLabelLineCeiling — $numbers');
            }
            if (tester.isTextClipped(label)) {
              failures
                  .add('$tag @${width.toInt()}px: ${entry.key} ellipsized — '
                      '$numbers');
            } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
                tester.hasSplitToken(label)) {
              failures
                  .add('$tag @${width.toInt()}px: ${entry.key} broke mid-word '
                      '— $numbers');
            }

            // Direction two: the switch is still at the far edge. This is what the
            // `Spacer` used to do, and it is the half a "give the label everything"
            // fix would break. Read as "the trailing child touches the trailing end",
            // so `ar` reads the same as `en`.
            final trailingGap = labelRect.left < switchRect.left
                ? rowRect.right - switchRect.right
                : switchRect.left - rowRect.left;
            if (trailingGap.abs() > 1.0) {
              failures.add(
                  '$tag @${width.toInt()}px: ${entry.key}\'s switch sits '
                  '${trailingGap.toStringAsFixed(1)}px from the row\'s trailing '
                  'edge — the `Expanded` stopped pushing it out, which is what the '
                  '`Spacer` was for — $numbers');
            }
          }
        }
      }

      // The floor premise, eleventh instance, and here it is about the *box* rather
      // than about a wrap: the fix is only the fix if some measured row is narrower
      // than the 160px + switch the old code demanded. 601px must produce a row under
      // ~215px; if every row measured wider than that, the two-column layout is not
      // being rendered and this guard is measuring the mobile page twice.
      const kFixedFloorRowWidth = 215.0;
      final narrow = measured
          .where((m) =>
              double.parse(m.split(':').last.replaceAll('px', '')) <
              kFixedFloorRowWidth)
          .toList();
      expect(
        narrow,
        isNotEmpty,
        reason: 'no measured switch row was narrower than '
            '${kFixedFloorRowWidth.toStringAsFixed(0)}px, so none of them could '
            'have failed against the fixed 160px box the #1380 fix at '
            'usp_ipv6_section.dart:170 removed — check that 601px still renders the '
            'two-column desktop layout before deleting this guard:\n'
            '${measured.join(', ')}',
      );

      expect(
        failures,
        isEmpty,
        reason:
            'the #1380 fix at usp_ipv6_section.dart:170 gives each switch label '
            'a share of its row instead of a fixed 160px; a label that wraps or '
            'ellipsizes means the share is too small, and a switch that left the far '
            'edge means the row stopped looking like the other switch rows on the '
            'page:\n${failures.join('\n')}',
      );
    });
  });

  group('readability at the site wave 4 fixed in local_network', () {
    /// As [kSectionRowLineCeiling], and by the same rule: one line over the deepest
    /// coordinate measured. Two of the 52 wrap and both take two lines — `ru` at
    /// 320px, which is the overflow the fix removed (230.0px of label wanted in a
    /// 218px gap, reported as +12.0px), and `de` at 320px, which did *not* overflow:
    /// at 210.2px it cleared the old inflexible row by 7.8px and now takes the second
    /// line the wider box offers it. That second locale is the fix's whole cost, and
    /// it is a wrap where `ru` was a clip.
    const kLinkRowLineCeiling = 3;

    testWidgets('the DHCP reservations link stays whole beside its chevron',
        (tester) async {
      final failures = <String>[];
      final wrapped = <String>[];

      // 320px is where the overflow was and 1681px is the control. Unlike
      // `advanced_settings` and `internet_settings` there is no narrower-box-at-a-
      // wider-screen step to look for on this page: `_buildContent` is a plain
      // `Column` of two full-width cards at every width, so the row's box grows
      // monotonically — 238.0px at 320px against 927.0px at 1681px. The wide end is
      // therefore not a second suspect but the proof that the `Expanded` did not
      // swallow the chevron's position at a width where nothing is tight.
      for (final width in const [320.0, 1681.0]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('localnet-link-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kLocalNetworkPageCase.view(),
              locale: locale,
              overrides: kLocalNetworkPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // Unscoped, unlike the other guards in this file: `viewDhcpReservations`
          // appears once on the page and shares no wording with the page title
          // (`localNetwork`) or either card heading. The single-match check below is
          // what makes that claim fail loudly if a second use ever appears.
          final label = find.text(loc.viewDhcpReservations);
          if (label.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: viewDhcpReservations '
                'resolved to ${label.evaluate().length} widgets, so nothing was '
                'measured');
            continue;
          }
          final row =
              find.ancestor(of: label, matching: find.byType(Row)).first;
          final chevron = find.descendant(
            of: row,
            matching: find.byIcon(Icons.chevron_right),
          );

          final paragraph = tester.paragraphOf(label);
          final lines = tester.textLineCount(label);
          final rowRect = tester.getRect(row);
          final labelRect = tester.getRect(label);
          final numbers = 'granted '
              '${paragraph.size.width.toStringAsFixed(1)}px on $lines line(s) of '
              'the ${rowRect.width.toStringAsFixed(1)}px row, whole string '
              '${paragraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px'
              ' — "${loc.viewDhcpReservations}"';
          if (lines > 1) {
            wrapped.add('$tag@${width.toInt()}px:${lines}L');
          }
          if (lines > kLinkRowLineCeiling) {
            failures.add('$tag @${width.toInt()}px: wrapped onto $lines lines, '
                'past the $kLinkRowLineCeiling-line ceiling — $numbers');
          }
          if (tester.isTextClipped(label)) {
            failures.add('$tag @${width.toInt()}px: ellipsized — $numbers');
          } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
              tester.hasSplitToken(label)) {
            failures
                .add('$tag @${width.toInt()}px: broken mid-word — $numbers');
          }
          if (chevron.evaluate().length != 1) {
            failures.add('$tag @${width.toInt()}px: the row holds '
                '${chevron.evaluate().length} chevrons, expected 1');
          } else {
            final chevronRect = tester.getRect(chevron);
            final trailingGap = labelRect.left < chevronRect.left
                ? rowRect.right - chevronRect.right
                : chevronRect.left - rowRect.left;
            if (trailingGap.abs() > 1.0) {
              failures.add('$tag @${width.toInt()}px: the chevron sits '
                  '${trailingGap.toStringAsFixed(1)}px from the row\'s trailing '
                  'edge — $numbers');
            }
          }
        }
      }

      // The floor premise, twelfth instance. Without it the loop passes against 52
      // one-line labels and the wrap the fix introduced would be reported as covered
      // while never being measured. Two of the 52 wrap today, both at 320px: `ru`
      // (230.0px of string) and `de` (210.2px) in a 206.0px box. Nothing wraps at
      // 1681px, where the box is 895.0px.
      expect(
        wrapped,
        isNotEmpty,
        reason:
            'no locale wrapped the DHCP reservations link at 320px or 1681px, '
            'so nothing here measured the wrap the #1380 fix at '
            'usp_local_network_view.dart:399 introduced — and if nothing wraps, the '
            'ru overflow that fix removed cannot be reproduced either, so check the '
            'ARB strings and the widths before deleting this guard:'
            '\n${wrapped.join(', ')}',
      );

      expect(
        failures,
        isEmpty,
        reason:
            'the #1380 fix gave this label the whole row instead of whatever the '
            'chevron left, which is only the better trade while the label stays '
            'readable and the chevron stays where every other trailing affordance on '
            'the page is:\n${failures.join('\n')}',
      );
    });
  });

  // Wave 4's fourteenth fix, at the last of the 45 pages and the widest-spread defect
  // the wave found: `usp_system_log_view.dart:100` put the size text, the
  // persistent badge, a `Spacer` and the export button in one `Row`, and that row
  // overflowed a 320px phone in **all 26 locales on both log cards** — +20.0px in `fi`
  // to +85.0px in `ja`. The `Wrap` that replaced it drops the button onto its own run,
  // so rule 4 applies and this is the companion.
  //
  // Both directions, like `instant_privacy`'s: nothing may shrink to make the row fit,
  // and the wide side must keep the far-edge geometry the `Spacer` gave for free.
  //
  // Two strings are watched rather than one, because only one of them is localized.
  // `Max Size: …` and `Persistent`/`Volatile` are hard-coded English in `lib` and are
  // the same width in every cell; `loc.export` is the string that makes `ja` the worst
  // case. So the guard reads the size text for the *group's* integrity and the export
  // label for the *locale's*.
  group('readability at the site wave 4 fixed in system_log', () {
    testWidgets(
        'both log cards keep their metadata whole and their export '
        'button at the far edge', (tester) async {
      final failures = <String>[];
      final stacked = <String>[];

      // 320 is where the row stopped fitting, 480 the first width that fits, and 1441
      // the wide side where the reflow must not have cost anything. Like
      // `instant_privacy`, this page is one full-width column with no grid, so content
      // width rises monotonically with the screen and there is no
      // narrower-content-at-a-wider-screen step to pair 320px with.
      const kWideWidth = 1441.0;
      for (final width in const [320.0, 480.0, kWideWidth]) {
        for (final locale in AppLocalizations.supportedLocales) {
          final tag = localeTag(locale);
          await setLayoutSurface(tester, Size(width, kPageSweepHeight));
          await tester.pumpWidget(KeyedSubtree(
            key: ValueKey('system-log-export-$tag-${width.toInt()}'),
            child: pageSurfaceHost(
              view: kSystemLogPageCase.view(),
              locale: locale,
              overrides: kSystemLogPageCase.overrides(),
            ),
          ));
          await settleIgnoringAnimations(tester);

          final loc = localizationsByTag[tag]!;
          // Both cards, and each reached through its own size string — `512 KB` and
          // `Unknown` differ, which is what makes the two rows separable without
          // indexing into a list of matches. That the two strings come from the
          // fixture is also the check that the scene still renders both shapes.
          for (final logFile in gateSystemLogState) {
            final where = '$tag @${width.toInt()}px ${logFile.name}';
            final sizeText = 'Max Size: ${logFile.formattedSize}';
            final sizeLabel = find.text(sizeText);
            if (sizeLabel.evaluate().length != 1) {
              failures.add('$where: the page painted '
                  '${sizeLabel.evaluate().length} "$sizeText" label(s), expected '
                  '1, so nothing was measured for this card');
              continue;
            }
            // This card's own `Wrap`, reached through its size label, so the other
            // card's row cannot be measured by mistake.
            final row =
                find.ancestor(of: sizeLabel, matching: find.byType(Wrap)).first;
            if (row.evaluate().length != 1) {
              failures
                  .add('$where: the size label has no `Wrap` ancestor, so the '
                      'reflow this guard measures is not in the tree');
              continue;
            }
            final buttonLabel =
                find.descendant(of: row, matching: find.text(loc.export));
            final button =
                find.descendant(of: row, matching: find.byType(AppButton));
            if (buttonLabel.evaluate().length != 1 ||
                button.evaluate().length != 1) {
              failures.add('$where: this card\'s row holds '
                  '${buttonLabel.evaluate().length} "${loc.export}" label(s) and '
                  '${button.evaluate().length} `AppButton`(s), expected 1 of '
                  'each');
              continue;
            }

            final rowRect = tester.getRect(row);
            final sizeRect = tester.getRect(sizeLabel);
            final buttonRect = tester.getRect(button);
            final sizeLines = tester.textLineCount(sizeLabel);
            final exportLines = tester.textLineCount(buttonLabel);
            final exportParagraph = tester.paragraphOf(buttonLabel);
            final numbers = 'row ${rowRect.width.toStringAsFixed(1)}px, size '
                '"$sizeText" on $sizeLines line(s), export "${loc.export}" on '
                '$exportLines line(s) granted '
                '${exportParagraph.size.width.toStringAsFixed(1)}px of a whole '
                '${exportParagraph.getMaxIntrinsicWidth(double.infinity).toStringAsFixed(1)}px, '
                'button ${buttonRect.width.toStringAsFixed(1)}px';

            // Direction one: nothing shrank. Both strings on one line, neither
            // ellipsized, neither broken mid-word. `== 1` and not a ceiling, for
            // `instant_privacy`'s reason: once the button no longer shares a run
            // with the metadata each of them has the whole row, and the widest of
            // the two is far inside it, so a second line means it is being squeezed
            // again rather than being long.
            if (sizeLines != 1) {
              failures.add('$where: the size label took $sizeLines lines; a '
                  'hard-coded English string that fits whole and wraps anyway is '
                  'one being squeezed — $numbers');
            }
            if (exportLines != 1) {
              failures.add('$where: the export label took $exportLines lines — '
                  '$numbers');
            }
            for (final (name, finder) in [
              ('size', sizeLabel),
              ('export', buttonLabel),
            ]) {
              if (tester.isTextClipped(finder)) {
                failures.add('$where: the $name label ellipsized — $numbers');
              } else if (!kLocalesWithoutWordSpaces.contains(tag) &&
                  tester.hasSplitToken(finder)) {
                failures
                    .add('$where: the $name label broke mid-word — $numbers');
              }
            }

            // Direction two: the button moved instead. Read off the geometry — a
            // second run starts below the first — rather than off width arithmetic,
            // which would only re-implement `Wrap`.
            final isStacked = buttonRect.top >= sizeRect.bottom;
            if (isStacked) {
              stacked.add('$tag@${width.toInt()}px/${logFile.name}');
              if (width == kWideWidth) {
                failures
                    .add('$where: the export button dropped to a second run '
                        'on the wide side, where both groups fit — $numbers');
              }
            } else if (width == kWideWidth) {
              // Sharing a run on the wide side is not enough: the `Spacer` is what
              // put the button at the far edge, and a `Wrap` that sized to its
              // widest run instead of to its constraint would leave it beside the
              // badge. Asserted as "one child touches each end of the row" so it
              // reads the same in `ar` as in `en`.
              final leading =
                  sizeRect.left < buttonRect.left ? sizeRect : buttonRect;
              final trailing =
                  sizeRect.left < buttonRect.left ? buttonRect : sizeRect;
              if ((leading.left - rowRect.left).abs() > 1.0 ||
                  (rowRect.right - trailing.right).abs() > 1.0) {
                failures.add('$where: the row is '
                    '${rowRect.width.toStringAsFixed(1)}px wide but its groups '
                    'span ${leading.left.toStringAsFixed(1)}px..'
                    '${trailing.right.toStringAsFixed(1)}px — `spaceBetween` no '
                    'longer reaches both ends, so the `Wrap` sized to its run '
                    'rather than to the card — $numbers');
              }
            }
          }
        }
      }

      // The floor premise, thirteenth instance: if the metadata and the button fit
      // side by side everywhere, the `Wrap` is inert and this guard is a tautology
      // over the `Row` it replaced.
      expect(
        stacked,
        isNotEmpty,
        reason: 'no locale needed a second run at any width, so nothing here '
            'measured the reflow the #1380 fix at usp_system_log_view.dart:100 '
            'introduced',
      );

      expect(
        failures,
        isEmpty,
        reason:
            'the #1380 fix at usp_system_log_view.dart:100 drops the export '
            'button below the size-and-badge group when the two do not fit, '
            'instead of letting the row run off the edge as it did in all 26 '
            'locales at 320px; a label that wraps or ellipsizes means the fix '
            'bought its width from the text after all, and a button that stopped '
            'reaching the far edge on a wide page means the reflow was paid for by '
            'every other width:\n${failures.join('\n')}',
      );
    });
  });
}
