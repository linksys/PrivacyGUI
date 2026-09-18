import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/dhcp/views/components/usp_dhcp_reservations_detail_card.dart';
import 'package:privacy_gui/page/dmz/views/usp_dmz_view.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_status.dart';
import 'package:privacy_gui/page/instant_safety/views/instant_safety_view.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart';
import 'package:privacy_gui/page/local_network/views/usp_local_network_view.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_port_range_tab.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_port_triggering_tab.dart';
import 'package:privacy_gui/page/port_forwarding/views/components/usp_single_port_tab.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_status.dart';
import 'package:privacy_gui/page/static_routing/views/usp_static_routing_view.dart';
import 'package:privacy_gui/page/wifi_settings/models/wifi_advanced_status.dart';
import 'package:privacy_gui/page/wifi_settings/providers/usp_wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/views/tabs/wifi_advanced_tab.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_dmz.dart';
import '../../../mocks/provider_overrides/mock_instant_safety.dart';
import '../../../mocks/provider_overrides/mock_ipv6_port_service.dart';
import '../../../mocks/provider_overrides/mock_local_network.dart';
import '../../../mocks/provider_overrides/mock_static_routing.dart';
import '../../../mocks/provider_overrides/mock_wifi_settings.dart';
import '../../../mocks/test_data/scenes/dhcp_scene_data.dart' as dhcp_scene;
import '../../../mocks/test_data/scenes/dmz_scene_data.dart' as dmz_scene;
import '../../../mocks/test_data/scenes/instant_safety_scene_data.dart'
    as safety_scene;
import '../../../mocks/test_data/scenes/ipv6_port_service_scene_data.dart'
    as ipv6_scene;
import '../../../mocks/test_data/scenes/port_forwarding_scene_data.dart'
    as pf_scene;
import '../../../mocks/test_data/scenes/local_network_scene_data.dart'
    as ln_scene;
import '../../../mocks/test_data/scenes/static_routing_scene_data.dart'
    as sr_scene;
import '../../../mocks/test_data/scenes/wifi_settings_scene_data.dart'
    as wifi_scene;
import '../../../util/app_test_fonts.dart';

/// #1542 Part B: the `AppSwitch`es whose only busy signal was dimming.
///
/// Each passed `onChanged: isSaving ? null : …` and nothing else, so for as long
/// as a USP write took, the control read as **unavailable** rather than
/// **saving** — the dimmed track `AppSwitch` gives a null callback, which is the
/// same picture it gives a switch you may simply never use, and to a screen
/// reader no hint at all. Part A took that conflation out of
/// `ToggleRow`/`NetworkRow`; these are the rest of it. Unlike Part A this is new
/// behaviour rather than de-duplication: there was no busy treatment here to
/// replace, so "the tests still pass" could not have told us it arrived.
///
/// **Ten sites, not the six the ticket lists.** Re-measured across every
/// `AppSwitch` in `lib/`: the four in the last group have the same shape behind a
/// `disabled` alias, and they were already present at `b2d16ed9` — the commit the
/// ticket measured at — so the census undercounted rather than the tree having
/// drifted. All ten are here, and the ticket body is corrected to match.
///
/// Two properties per site:
///
/// * **`isLoading` while saving, and only then** — what draws the kit's busy
///   figure over the track the switch already occupies, without resizing it (the
///   footprint is pinned once, on the first site, since one `AppSwitch` behaves
///   like the next).
/// * **The hint is the app's localised string.** With `busySemanticLabel` unset
///   the kit falls back to its own hardcoded English `Busy` in all 26 locales.
///
/// The four list tabs/cards take `isSaving` as a constructor argument and read no
/// provider on their build path, so they are pumped directly. The six whole
/// views/tabs derive it from `state.status.isSaving`, so those get a saving scene
/// through the existing override factories.
void main() {
  setUpAll(() async {
    // For the one rect equality below: Ahem gives every glyph the same box, and
    // the row's label column is what leaves the switch its width.
    await loadAppFonts();
  });

  /// Bounded, not `pumpAndSettle`: the busy figure animates forever, so settling
  /// would time out on exactly the state this file is about.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Host for anything that needs no router chrome. `flat` is the app's default
  /// design style and the branch the busy figure is drawn on; `Column(stretch)`
  /// for the reason `row_busy_test.dart` records — a row handed a tight height
  /// stretches, and a rect equality on a stretched box cannot see the vertical
  /// half of what it claims to check.
  Widget tabHost(Widget child) => MaterialApp(
        theme: AppTheme.create(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          designThemeBuilder: (c) =>
              CustomDesignTheme.fromJson({'style': 'flat'}),
        ),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      );

  /// The four widgets that take `isSaving` as a constructor argument, which read
  /// no provider on their build path.
  Future<void> pumpTab(WidgetTester tester, Widget tab) async {
    await tester.pumpWidget(ProviderScope(child: tabHost(tab)));
    await settle(tester);
  }

  /// Whole-page host, through the layout gate's [pageSurfaceHost] for the reason
  /// `pnp_setup_view_test.dart` records: `UspTopBar` inside `UiKitPageView`
  /// reaches `GoRouter.of(context)` unguarded, so a plain `MaterialApp` throws
  /// before the page is reached. It supplies `commonOverrides()` itself, so only
  /// the feature override is passed — adding a second copy of the same override
  /// to one scope is an error.
  Future<void> pumpView(
    WidgetTester tester,
    Widget view,
    List<Override> overrides,
  ) async {
    // A page with several rule rows is taller than the default 800×600, and a
    // `RenderFlex` overflow is a `FlutterError` — which would fail this test for
    // a reason that belongs to the layout gate, not here.
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(pageSurfaceHost(
      view: view,
      locale: const Locale('en'),
      overrides: overrides,
    ));
    await settle(tester);
  }

  List<AppSwitch> switches(WidgetTester tester) =>
      tester.widgetList<AppSwitch>(find.byType(AppSwitch)).toList();

  /// Every row switch on the surface must agree about being busy — and there
  /// must be one, or a fixture that rendered an empty list would pass this
  /// without measuring anything.
  void expectAllBusy(WidgetTester tester, {required bool busy}) {
    final found = switches(tester);
    expect(found, isNotEmpty,
        reason: 'the fixture must render at least one row, or this assertion '
            'passes vacuously');
    for (final s in found) {
      expect(s.isLoading, busy,
          reason: busy
              ? 'a row switch must show the write it is waiting on'
              : 'an idle row must not look busy');
      expect(
        s.busySemanticLabel,
        busy ? 'Processing...' : isNull,
        reason: busy
            ? 'the kit falls back to its own untranslated `Busy` when this is '
                'null, so the localised string has to be passed'
            : 'nothing is in flight, so there is nothing to announce',
      );
    }
  }

  group('port forwarding tabs', () {
    final forwardingRules =
        pf_scene.dataState().settings.current.forwardingRules;
    final triggeringRules =
        pf_scene.dataState().settings.current.triggeringRules;

    testWidgets('single port: idle rows are not busy', (tester) async {
      await pumpTab(tester, UspSinglePortTab(rules: forwardingRules));
      expectAllBusy(tester, busy: false);
    });

    testWidgets('single port: a saving page marks every row busy',
        (tester) async {
      await pumpTab(
          tester, UspSinglePortTab(rules: forwardingRules, isSaving: true));
      expectAllBusy(tester, busy: true);
    });

    testWidgets(
        'single port: going busy does not resize or displace the switch',
        (tester) async {
      // Pinned once for all six: they render the same `AppSwitch` at the head of
      // the same `Row`, so what could displace it is the treatment, not the call
      // site. Same guarantee `instant_privacy_toggle_busy_test.dart` pins for the
      // page-level toggle, where a `Stack`-plus-`AppLoader` swap was what moved
      // it.
      //
      // Measured **relative to the row that contains it**, not in surface
      // coordinates. The absolute rect moves 4px between these two states for a
      // reason that is not this change: the header's add button is disabled while
      // saving and the kit renders a disabled `AppIconButton` 44px tall instead
      // of 48, which lifts the whole card. That is pre-existing (verified by
      // measuring both states with these six edits reverted — byte-identical
      // numbers), it belongs to the button rather than the switch, and an
      // absolute-rect assertion here would have reported it as this change's
      // regression.
      Rect offsetInRow(WidgetTester tester) {
        final row = tester.getRect(find
            .ancestor(
              of: find.byType(AppSwitch).first,
              matching: find.byType(LayoutBlock),
            )
            .first);
        final sw = tester.getRect(find.byType(AppSwitch).first);
        return sw.translate(-row.left, -row.top);
      }

      await pumpTab(tester, UspSinglePortTab(rules: forwardingRules));
      final idle = offsetInRow(tester);

      // A rebuild with a changed constructor argument, so the element — and its
      // slot — is the one just measured.
      await pumpTab(
          tester, UspSinglePortTab(rules: forwardingRules, isSaving: true));

      expect(switches(tester).first.isLoading, isTrue);
      expect(offsetInRow(tester), idle,
          reason:
              'the busy figure draws over the track; it must not resize the '
              'switch or shift it within its row, or every row below moves for '
              'the length of a write');
    });

    testWidgets('port range: a saving page marks every row busy',
        (tester) async {
      await pumpTab(
          tester, UspPortRangeTab(rules: forwardingRules, isSaving: true));
      expectAllBusy(tester, busy: true);
    });

    testWidgets('port triggering: a saving page marks every row busy',
        (tester) async {
      await pumpTab(
          tester, UspPortTriggeringTab(rules: triggeringRules, isSaving: true));
      expectAllBusy(tester, busy: true);
    });
  });

  group('dhcp reservations', () {
    final reservations = dhcp_scene.dataState().settings.current.reservations;

    testWidgets('idle rows are not busy', (tester) async {
      await pumpTab(
          tester, UspDhcpReservationsDetailCard(reservations: reservations));
      expectAllBusy(tester, busy: false);
    });

    testWidgets('a saving card marks every row busy', (tester) async {
      await pumpTab(
        tester,
        UspDhcpReservationsDetailCard(
            reservations: reservations, isSaving: true),
      );
      expectAllBusy(tester, busy: true);
    });
  });

  group('static routing', () {
    testWidgets('a saving page marks every route row busy', (tester) async {
      await pumpView(
        tester,
        const UspStaticRoutingView(),
        staticRoutingOverrides(sr_scene.gateStaticRoutingState.copyWith(
          status: const StaticRoutingStatus(isSaving: true),
        )),
      );
      expectAllBusy(tester, busy: true);
    });

    testWidgets('an idle page marks none of them busy', (tester) async {
      await pumpView(
          tester, const UspStaticRoutingView(), staticRoutingOverrides());
      expectAllBusy(tester, busy: false);
    });
  });

  group('ipv6 port service', () {
    testWidgets('a saving page marks every rule row busy', (tester) async {
      await pumpView(
        tester,
        const UspIpv6PortServiceView(),
        ipv6PortServiceOverrides(ipv6_scene.gateIpv6PortServiceState.copyWith(
          status: const Ipv6PortServiceStatus(isSaving: true),
        )),
      );
      expectAllBusy(tester, busy: true);
    });

    testWidgets('an idle page marks none of them busy', (tester) async {
      await pumpView(
          tester, const UspIpv6PortServiceView(), ipv6PortServiceOverrides());
      expectAllBusy(tester, busy: false);
    });
  });

  /// The four the ticket's census missed.
  ///
  /// Same defect, same two lines, same `state.status.isSaving` behind the null —
  /// verified present at `b2d16ed9`, the commit the ticket measured at, so this is
  /// an undercount in the census rather than drift since. One real difference,
  /// which does not change the fix: these four pages buffer their edits behind a
  /// dirty guard and a Save button, where the six above write on the tap. Either
  /// way `isSaving` means *the page is writing*, and either way the switch was the
  /// only thing saying so — by dimming, which is also how the kit draws a control
  /// you may never use.
  ///
  /// Each is pumped through the whole page rather than a component, because
  /// unlike the tabs above none of them takes the flag as an argument.
  group('the four sites the census missed', () {
    testWidgets('local network: a saving page marks the DHCP switch busy',
        (tester) async {
      await pumpView(tester, const UspLocalNetworkView(),
          localNetworkOverrides(ln_scene.dirtyState(isSaving: true)));
      expectAllBusy(tester, busy: true);
    });

    testWidgets('local network: an idle page marks it not busy',
        (tester) async {
      await pumpView(
          tester, const UspLocalNetworkView(), localNetworkOverrides());
      expectAllBusy(tester, busy: false);
    });

    testWidgets('dmz: a saving page marks the enable switch busy',
        (tester) async {
      await pumpView(tester, const UspDmzView(),
          dmzOverrides(dmz_scene.dirtyState(isSaving: true)));
      expectAllBusy(tester, busy: true);
    });

    testWidgets('dmz: an idle page marks it not busy', (tester) async {
      await pumpView(tester, const UspDmzView(), dmzOverrides());
      expectAllBusy(tester, busy: false);
    });

    testWidgets('instant safety: a saving page marks the enable switch busy',
        (tester) async {
      await pumpView(
        tester,
        const UspInstantSafetyView(),
        instantSafetyOverrides(safety_scene.enabledState().copyWith(
              status: const InstantSafetyStatus(isSaving: true),
            )),
      );
      expectAllBusy(tester, busy: true);
    });

    testWidgets('instant safety: an idle page marks it not busy',
        (tester) async {
      await pumpView(
          tester, const UspInstantSafetyView(), instantSafetyOverrides());
      expectAllBusy(tester, busy: false);
    });

    // A tab rather than a page, and it reads exactly one provider, so it needs no
    // router chrome — the simple host is enough.
    testWidgets('wifi advanced: a saving tab marks every DFS switch busy',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          uspWifiAdvancedProvider.overrideWith(() => FixedWifiAdvancedNotifier(
                wifi_scene.advancedDfsOnState.copyWith(
                  status: const WifiAdvancedStatus(isSaving: true),
                ),
              )),
        ],
        child: tabHost(const UspWifiAdvancedTab()),
      ));
      await settle(tester);
      expectAllBusy(tester, busy: true);
    });

    testWidgets('wifi advanced: an idle tab marks none of them busy',
        (tester) async {
      await tester.pumpWidget(ProviderScope(
        overrides: [
          uspWifiAdvancedProvider.overrideWith(
            () => FixedWifiAdvancedNotifier(wifi_scene.advancedDfsOnState),
          ),
        ],
        child: tabHost(const UspWifiAdvancedTab()),
      ));
      await settle(tester);
      expectAllBusy(tester, busy: false);
    });
  });

  group('and the busy row says so out loud', () {
    testWidgets('the hint reaches the semantics tree', (tester) async {
      // `busySemanticLabel` is asserted as a property everywhere above because
      // that is all six sites have in common; here it is checked on the rendered
      // node, which is what a screen reader would read. Part A could not make
      // this assertion at all — `ToggleRow`/`NetworkRow` sit inside
      // `AppListTile`, which wraps its content in `ExcludeSemantics`. These six
      // are bare `Row`s, so nothing swallows it.
      final handle = tester.ensureSemantics();
      try {
        final rules = pf_scene.dataState().settings.current.forwardingRules;
        await pumpTab(tester, UspSinglePortTab(rules: rules, isSaving: true));

        expect(
          tester.getSemantics(find.byType(AppSwitch).first).hint,
          'Processing...',
          reason: 'work in progress, announced — and in the app string rather '
              "than the kit's English-only fallback",
        );
      } finally {
        // `try`/`finally` rather than `addTearDown`: tear-downs run *after* the
        // framework's live-handle check, so a leaked handle would pile a second
        // failure on top of whichever assertion actually regressed.
        handle.dispose();
      }
    });

    testWidgets('a busy row switch swallows taps', (tester) async {
      // Passes either way today, because every call site still nulls `onChanged`
      // while saving. It is here because `isLoading` is what keeps holding the
      // guarantee if a later change stops doing that: the kit refuses input for
      // the duration on its own.
      final rules = pf_scene.dataState().settings.current.forwardingRules;
      await pumpTab(tester, UspSinglePortTab(rules: rules, isSaving: true));

      // No notifier override in this host, so a tap that got through to
      // `toggleForwardingRule` would throw rather than fail quietly.
      await tester.tap(find.byType(AppSwitch).first, warnIfMissed: false);
      await tester.pump();

      expect(switches(tester).first.value, isTrue,
          reason: 'the row still shows the rule state it was given');
    });
  });
}
