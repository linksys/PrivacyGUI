import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_guest_step_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_wifi_step_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_your_network_step_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/collector.dart';
import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../util/dashboard/text_readability_probe.dart';
import '../../../mocks/provider_overrides/mock_pnp.dart';
import '../../../mocks/test_data/scenes/pnp_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// The PnP wizard's step pages (#1511 P4) — deliberately **untagged**.
///
/// `run_tests.sh` runs `--exclude-tags="golden||loc||ui"`, so a `ui` tag would
/// keep these out of the PR gate, and the first group is about a production
/// crash.
///
/// ## Where these came from
///
/// `PnpSetupView` was one page for every step and every status screen, with
/// the step in a widget-state `int`. #1378 found it threw on teardown: its four
/// unified-mode controllers were `late final`, assigned only on the form's
/// branch and disposed unconditionally, so leaving the wizard before the form
/// rendered was a `LateInitializationError`. Since #1511 P4 each step is a page
/// of its own whose controllers are created in `initState`, from the step's
/// draft; the status screens are `PnpFlowFrameView`'s
/// (`pnp_flow_frame_view_test.dart`). The teardown guard is kept, per page.
void main() {
  setUpAll(() async {
    // Real fonts: widths and wraps are measured in pixels.
    await loadAppFonts();
  });

  final en = lookupAppLocalizations(const Locale('en'));

  /// The flow on its steps, with the plan of a router with a guest SSID.
  PnpState onTheSteps({
    PnpFlowPlan plan = pnpPlanWithGuest,
    List<NodeEntity>? nodes,
  }) =>
      PnpState(
        phase: const WizardConfiguring(),
        plan: plan,
        meshNodes: nodes ?? [pnpMeshNodes.first],
        serialNumber: 'SN-TEST',
      );

  void enlargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Bounded pump — the gate's host never settles on a spinner.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// [view] in the app's route scaffolding, its drafts begun at [router].
  Future<FixedPnpNotifier> pumpStep(
    WidgetTester tester,
    Widget view, {
    PnpWizardData router = pnpUnifiedRouter,
    PnpState? state,
    AppModeProfile profile = const LocalModeProfile(),
    DeviceCapabilities? capabilities,
    Locale locale = const Locale('en'),
  }) async {
    enlargeSurface(tester);
    final notifier = FixedPnpNotifier(state ?? onTheSteps());
    await runWithOverflowCollection((_) async {
      await tester.pumpWidget(pageSurfaceHost(
        view: view,
        locale: locale,
        overrides: [
          ...pnpOverrides(notifier.build(), router: router),
          pnpProvider.overrideWith(() => notifier),
          appModeProfileProvider.overrideWithValue(profile),
          deviceCapabilitiesProvider.overrideWithValue(capabilities ??
              DeviceCapabilities(const {DeviceCapability.bleOnboarding})),
        ],
        childRoutes: [
          LinksysRoute(
            path: RoutePath.pnpAddNodes,
            name: RouteNamed.pnpAddNodes,
            builder: (context, state) => Scaffold(
              body: Center(
                child: TextButton(
                  // GoRouter's pop, as PnpAddNodesView's Done is off the web.
                  onPressed: () => context.pop(),
                  child: const Text('add nodes page'),
                ),
              ),
            ),
          ),
        ],
      ));
      await settle(tester);
    });
    return notifier;
  }

  Finder buttonLabelled(String label) => find.widgetWithText(AppButton, label);

  group('every step page disposes cleanly (#1378)', () {
    final pages = <String, (Widget, PnpWizardData)>{
      'Wi-Fi, unified': (const PnpWifiStepView(), pnpUnifiedRouter),
      'Wi-Fi, split': (const PnpWifiStepView(), pnpSplitRouter),
      'guest, unified': (const PnpGuestStepView(), pnpUnifiedRouter),
      'guest, split': (const PnpGuestStepView(), pnpSplitRouter),
      'Your Network': (const PnpYourNetworkStepView(), pnpUnifiedRouter),
    };
    for (final entry in pages.entries) {
      testWidgets(entry.key, (tester) async {
        final (view, router) = entry.value;
        await pumpStep(tester, view, router: router);

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();

        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('the Wi-Fi step\'s fields begin at its draft', (tester) async {
    await pumpStep(tester, const PnpWifiStepView());

    // `find.text` reads `EditableText.controller.text`, so it sees the
    // obscured password field too.
    expect(find.text(pnpUnifiedRouter.main.ssid), findsOneWidget);
    expect(find.text(pnpUnifiedRouter.main.password), findsOneWidget);
  });

  group('a step\'s card wraps its content (bench, 2026-11-13)', () {
    // The card was the inner page's own child, so it took the scroll view's
    // minimum height and ran to the bottom of a 2400px surface. No overflow,
    // so the layout gate could not see it; the bench screenshot did.
    for (final entry in <String, Widget>{
      'Wi-Fi': const PnpWifiStepView(),
      'guest': const PnpGuestStepView(),
      'Your Network': const PnpYourNetworkStepView(),
    }.entries) {
      testWidgets(entry.key, (tester) async {
        await pumpStep(tester, entry.value);

        expect(
            tester.getSize(find.byType(AppCard).first).height, lessThan(1200),
            reason: 'the surface is 2400px tall and no step is half that');
      });
    }
  });

  testWidgets('a split network has a block per band', (tester) async {
    await pumpStep(tester, const PnpWifiStepView(), router: pnpSplitRouter);

    expect(find.byType(AppPasswordInput),
        findsNWidgets(pnpSplitRouter.main.bands.length));
  });

  group('Save is where the plan puts it', () {
    testWidgets('the Wi-Fi and guest steps end in Next', (tester) async {
      await pumpStep(tester, const PnpWifiStepView());
      expect(buttonLabelled(en.next), findsOneWidget);
      expect(buttonLabelled(en.save), findsNothing);

      await pumpStep(tester, const PnpGuestStepView());
      expect(buttonLabelled(en.next), findsOneWidget);
      expect(buttonLabelled(en.back), findsOneWidget);
      expect(buttonLabelled(en.save), findsNothing);
    });

    for (final plan in const [
      pnpPlanWithGuest,
      PnpFlowPlan(settingStepIds: ['wifi']),
    ]) {
      testWidgets('Your Network holds Save: ${plan.stepIds.join(' → ')}',
          (tester) async {
        final notifier = await pumpStep(
          tester,
          const PnpYourNetworkStepView(),
          state: onTheSteps(plan: plan),
        );
        expect(buttonLabelled(en.save), findsOneWidget);
        expect(buttonLabelled(en.next), findsNothing);

        await tester.tap(buttonLabelled(en.save));
        await settle(tester);
        expect(notifier.saves, 1);
      });
    }
  });

  testWidgets(
      'Back and Save on Your Network keep their labels whole at 320px, in every '
      'locale', (tester) async {
    // The footer is a `Wrap` because Back beside Save overflowed `el` by 17px at
    // 320px on this step's first sweep (#1511 P4). A `Wrap` constrains each
    // button to the line, so a button with too little room squeezes its label
    // instead of overflowing — invisible to the layout gate's 234 cells. Both
    // verdicts, in the gate skill's rule 4 order: neither subsumes the other.
    final offenders = <String>[];
    for (final locale in AppLocalizations.supportedLocales) {
      await setLayoutSurface(tester, const Size(320, 1600));
      await tester.pumpWidget(KeyedSubtree(
        key: ValueKey(locale.toString()),
        child: pageSurfaceHost(
          view: const PnpYourNetworkStepView(),
          locale: locale,
          overrides: pnpOverrides(onTheSteps(nodes: pnpMeshNodes)),
        ),
      ));
      await settle(tester);

      final footer = find.byType(Wrap).last;
      final buttons =
          find.descendant(of: footer, matching: find.byType(AppButton));
      expect(buttons, findsNWidgets(2), reason: '$locale: Back and Save');
      for (var i = 0; i < 2; i++) {
        final label =
            find.descendant(of: buttons.at(i), matching: find.byType(Text));
        if (label.evaluate().length != 1) continue;
        final text = tester.paragraphOf(label).text.toPlainText();
        if (tester.isTextClipped(label)) {
          offenders.add('$locale: "$text" is truncated inside its button');
        } else if (!kLocalesWithoutWordSpaces.contains(locale.toString()) &&
            tester.hasSplitToken(label)) {
          offenders.add('$locale: "$text" broke mid-word inside its button');
        }
      }
    }

    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  // ===========================================================================
  // Your Network and Add nodes (#1734)
  // ===========================================================================
  group('Your Network and Add nodes (#1734)', () {
    testWidgets('labels each node by its role, not by its place in the list',
        (tester) async {
      // The nodes keep DataElements order, which does not promise the
      // controller first (#1688 review).
      await pumpStep(
        tester,
        const PnpYourNetworkStepView(),
        state: onTheSteps(nodes: pnpMeshNodes.reversed.toList()),
      );

      String descriptionOf(String model) => tester
          .widget<AppNodeListCard>(find.ancestor(
              of: find.text(model), matching: find.byType(AppNodeListCard)))
          .description!;
      expect(descriptionOf('MR7500'), 'Master');
      expect(descriptionOf('MX2000'), 'Slave');
    });

    // Reading the nodes again on the way back is the add-nodes route's
    // `onExit`, not this step's, so it is tested against the production route
    // in `test/route/pnp_wizard_route_test.dart`; this harness's stub route has
    // none.
    testWidgets(
        'Add nodes opens the add-nodes page, and closing it comes back to the '
        'step', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpStep(tester, const PnpYourNetworkStepView());

      expect(
          find.bySemanticsIdentifier(kPnpAddNodesIdentifier), findsOneWidget);
      await runWithOverflowCollection((_) async {
        await tester.tap(buttonLabelled(en.addNodes));
        await settleIgnoringAnimations(tester);
      });
      expect(find.text('add nodes page'), findsOneWidget);

      await runWithOverflowCollection((_) async {
        await tester.tap(find.text('add nodes page'));
        await settleIgnoringAnimations(tester);
      });

      expect(buttonLabelled(en.save), findsOneWidget,
          reason: 'back on the step it was opened from');
      handle.dispose();
    });

    testWidgets('firmware without the onboarding API offers no Add nodes',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpStep(tester, const PnpYourNetworkStepView(),
          capabilities: DeviceCapabilities.empty);

      expect(buttonLabelled(en.save), findsOneWidget);
      expect(find.bySemanticsIdentifier(kPnpAddNodesIdentifier), findsNothing);
      handle.dispose();
    });

    testWidgets('remote assistance offers no Add nodes', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpStep(tester, const PnpYourNetworkStepView(),
          profile: const RemoteModeProfile());

      expect(buttonLabelled(en.save), findsOneWidget);
      expect(find.bySemanticsIdentifier(kPnpAddNodesIdentifier), findsNothing);
      handle.dispose();
    });

    testWidgets('a mesh read that found nothing shows no empty list',
        (tester) async {
      await pumpStep(tester, const PnpYourNetworkStepView(),
          state: onTheSteps(nodes: const []));

      expect(find.byType(AppNodeListCard), findsNothing);
      expect(find.byType(LayoutBlock), findsNothing,
          reason: 'an empty block would be a frame with nothing in it');
      expect(buttonLabelled(en.addNodes), findsOneWidget,
          reason: 'the way to add one does not depend on the list');
    });

    testWidgets('the node roles are the topology\'s localized words',
        (tester) async {
      // In English the old hard-coded 'Master' / 'Slave' and the localized
      // words read the same, so only another locale tells them apart.
      const zhTw = Locale.fromSubtags(languageCode: 'zh', countryCode: 'TW');
      final words = lookupAppLocalizations(zhTw);
      await pumpStep(tester, const PnpYourNetworkStepView(),
          state: onTheSteps(nodes: pnpMeshNodes), locale: zhTw);

      final descriptions = tester
          .widgetList<AppNodeListCard>(find.byType(AppNodeListCard))
          .map((card) => card.description)
          .toSet();
      expect(descriptions, {words.master, words.slave});
      expect(descriptions, isNot(contains('Master')));
    });
  });
}
