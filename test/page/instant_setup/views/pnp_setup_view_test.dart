import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/core/mode/remote_mode_profile.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_setup_view.dart';
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

/// Lifecycle tests for [PnpSetupView] — deliberately **untagged**.
///
/// `run_tests.sh` runs `--exclude-tags="golden||loc||ui"`, so the sibling
/// `pnp_no_internet_view_test.dart`'s `@Tags(['ui'])` keeps it out of the PR
/// gate. The defect below is a production crash, so its regression test has to
/// be in the set a PR cannot merge past.
///
/// ## The defect (#1378)
///
/// The four unified-mode controllers were `late final` fields assigned only
/// inside `_initControllers(WizardConfiguring)`, while `dispose()` disposed all
/// four unconditionally. Every phase other than `WizardConfiguring` renders
/// through `_ => const Center(child: AppLoader())` and never calls
/// `_initControllers`, so any user who left the wizard before it finished
/// initialising — back button, a `WizardError`, a `WizardSaving` that navigated
/// away — tore the widget down into a `LateInitializationError`.
///
/// It surfaced as a *gate* finding rather than a *field* report because #1378
/// tried to sweep this page across 208 cells and every cell died at teardown.
/// The fix is in the widget: the controllers are created with the field, and
/// `_initControllers` assigns `.text`.
///
/// ## The second finding, and where it went
///
/// Sweeping this page also found a layout overflow that was **not ours to fix**:
/// `AppStepper`'s bar variant divided `constraints.maxWidth` among its bars while
/// each bar carried a permanent 4px of horizontal focus-ring offset, so it
/// overflowed by `stepCount × 4` at every width in every locale — 208 of 208 cells
/// at +12.0px. A tripwire test lived at the bottom of this file pinning that
/// arithmetic, because it was the thing standing between this page and the gate.
///
/// It was filed as `linksys/privacyGUI-UI-kit#70`, fixed there by `936c1da6` and
/// released as v2.40.2; the tripwire went red with an empty incident list on the
/// bump, which is the signal it was written to give, and was deleted in the same
/// commit that declared `kPnpSetupPageCase`. So the width-and-locale coverage of
/// this page is the layout gate's now
/// (`test/page/_shared/page_surface_overflow_test.dart`, 234 cells), and what is
/// left here is the lifecycle.
void main() {
  setUpAll(() async {
    // Real fonts, because the last test measures an overflow in pixels and Ahem
    // makes every glyph the same box.
    await loadAppFonts();
  });

  /// Hosted through the layout gate's [pageSurfaceHost] rather than a local
  /// `MaterialApp`, because this page needs the app's real route scaffolding: the
  /// `UspTopBar` inside `UiKitPageView` reaches `GoRouter.of(context)` unguarded
  /// from `MenuHolderState.didChangeDependencies`, so a plain `MaterialApp` throws
  /// `No GoRouter found in context` before the phase under test is ever reached.
  /// That host's own header records it as the single place a real page is pumped
  /// and `test/util/detail_view_probe.dart` already delegates to it, so this is
  /// reuse rather than a third copy.
  ///
  /// `pnpOverrides` pins the phase, so each test below states which branch of the
  /// view's `switch` it is tearing down rather than inheriting whatever
  /// `PnpNotifier.build()` happens to return.
  Widget host(PnpPhase phase) => pageSurfaceHost(
        view: const PnpSetupView(),
        locale: const Locale('en'),
        overrides: pnpOverrides(
          PnpState(phase: phase, serialNumber: 'SN-TEST'),
        ),
      );

  /// The wizard form is taller and wider than the default 800×600 test surface,
  /// and a `RenderFlex` overflow is a `FlutterError` — so a cramped surface would
  /// fail these tests for a reason that has nothing to do with the lifecycle they
  /// are about. Width and locale coverage is the layout gate's job
  /// (`test/page/_shared/page_surface_overflow_test.dart`), not this file's.
  void enlargeSurface(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  /// Bounded pump — same reason as the sibling view test's.
  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  /// Pumps [phase], then replaces the tree so `dispose()` runs, and returns
  /// whatever the framework captured.
  ///
  /// Replacing the tree rather than ending the test is what makes the teardown
  /// observable: an error thrown while finalizing the tree at the *end* of a
  /// `testWidgets` body is reported against the test either way, but only a
  /// mid-test disposal lets the assertion name the phase that caused it.
  ///
  /// Wrapped in [runWithOverflowCollection] so a `RenderFlex` overflow lands in
  /// `sink` instead of in `takeException()`. It was load-bearing while
  /// `AppStepper` was over by `stepCount × 4`: without it the `WizardConfiguring`
  /// cases below reported that overflow as though the page had failed to tear
  /// down — a layout defect masquerading as a lifecycle one. v2.40.2 fixed the
  /// stepper, and the wrap stays because the separation of concerns is the point
  /// rather than the one bug: an overflow on this page is now the layout gate's
  /// verdict to give (234 cells, every width and locale), and these four tests
  /// have nothing to say about it. Genuine errors are still forwarded, which is
  /// what keeps the `LateInitializationError` these tests exist for visible.
  /// `cell: null` (the default) keeps these pumps out of the coverage dataset:
  /// they are not sweep coordinates.
  Future<Object?> exceptionOnDispose(
    WidgetTester tester,
    PnpPhase phase,
  ) {
    return runWithOverflowCollection((_) async {
      enlargeSurface(tester);
      await tester.pumpWidget(host(phase));
      await settle(tester);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      return tester.takeException();
    });
  }

  // The phases the switch in `build` routes to the loader — i.e. every phase a
  // user can be in *before* the wizard has anything to edit. `WizardError` is
  // in the list on purpose: it renders its own tree, so it is the one case
  // where the page was visibly useful and still could not be torn down.
  final phasesThatNeverInitControllers = <String, PnpPhase>{
    'AdminCheckingInternet': const AdminCheckingInternet(),
    'WizardInitializing': const WizardInitializing(),
    'WizardSaving': const WizardSaving(),
    'WizardError': const WizardError(message: 'boom'),
  };

  for (final entry in phasesThatNeverInitControllers.entries) {
    testWidgets('disposes cleanly from ${entry.key}', (tester) async {
      final error = await exceptionOnDispose(tester, entry.value);

      expect(
        error,
        isNull,
        reason: 'leaving PnpSetupView at ${entry.key} threw on dispose. The '
            'four unified-mode controllers are only assigned inside '
            '_initControllers(WizardConfiguring), and dispose() disposes them '
            'unconditionally — so every phase that renders the loader crashes '
            'on teardown. Initialize them with the field, not in the phase '
            'handler.',
      );
    });
  }

  testWidgets('disposes cleanly from WizardConfiguring too', (tester) async {
    // The path that always worked, kept so the fix cannot be "make dispose
    // conditional and never dispose anything".
    final error = await exceptionOnDispose(
      tester,
      WizardConfiguring(wifiConfig: pnpUnifiedWifiConfig),
    );

    expect(error, isNull);
  });

  testWidgets('prefills the unified-mode fields from the phase\'s config',
      (tester) async {
    // The behaviour eager initialization must not lose: the controllers exist
    // before the config arrives, so their text has to be assigned when it does.
    await runWithOverflowCollection((_) async {
      enlargeSurface(tester);
      await tester.pumpWidget(host(
        WizardConfiguring(wifiConfig: pnpUnifiedWifiConfig),
      ));
      await settle(tester);
    });

    // `find.text` reads `EditableText.controller.text`, so it sees the obscured
    // password field too.
    expect(find.text(pnpUnifiedWifiConfig.ssid), findsOneWidget);
    expect(find.text(pnpUnifiedWifiConfig.password), findsOneWidget);
  });
  // The "Your Network" step labels each node by its own role. It used to call
  // the first node in the list the master, but the nodes keep DataElements
  // order, which does not promise the controller first (#1688 review).
  testWidgets('labels each node by its role, not by its place in the list',
      (tester) async {
    final next = lookupAppLocalizations(const Locale('en')).next;
    await runWithOverflowCollection((_) async {
      enlargeSurface(tester);
      await tester.pumpWidget(host(WizardConfiguring(
        wifiConfig: pnpUnifiedWifiConfig,
        // The slave first: a list the old positional rule mislabels.
        meshNodes: pnpMeshNodes.reversed.toList(),
      )));
      await settle(tester);
      // Main Wi-Fi, then guest Wi-Fi, then "Your Network".
      for (var step = 0; step < 2; step++) {
        await tester.tap(find.widgetWithText(AppButton, next));
        await settle(tester);
      }
    });

    String descriptionOf(String model) => tester
        .widget<AppNodeListCard>(find.ancestor(
            of: find.text(model), matching: find.byType(AppNodeListCard)))
        .description!;
    expect(descriptionOf('MR7500'), 'Master',
        reason: 'pnpMeshNodes[0], the MasterNode, now listed second');
    expect(descriptionOf('MX2000'), 'Slave',
        reason: 'pnpMeshNodes[1], the SlaveNode, now listed first');
  });

  group('a save that returns to the form says why (#1000)', () {
    // The defect: `saveChanges()` put its error in a state field no view read,
    // so a failed save looked like the guest page "being shown twice".
    //
    // Driven through `setDemoPhase` on the pinned notifier, because what is under
    // test is the view's reaction to a *transition* into the form — the save
    // logic itself is the notifier test's.
    Future<FixedPnpNotifier> pumpSaving(WidgetTester tester) async {
      enlargeSurface(tester);
      final notifier = FixedPnpNotifier(
        const PnpState(phase: WizardSaving(), serialNumber: 'SN-TEST'),
      );
      await runWithOverflowCollection((_) async {
        await tester.pumpWidget(pageSurfaceHost(
          view: const PnpSetupView(),
          locale: const Locale('en'),
          overrides: [pnpProvider.overrideWith(() => notifier)],
        ));
        await settle(tester);
      });
      return notifier;
    }

    testWidgets('shows the localized error when the save fails',
        (tester) async {
      final notifier = await pumpSaving(tester);

      await runWithOverflowCollection((_) async {
        notifier.setDemoPhase(const WizardConfiguring(
          wifiConfig: pnpUnifiedWifiConfig,
          saveError: TimeoutError(detail: 'diagnostic only'),
        ));
        await settle(tester);
      });

      expect(find.text('The operation timed out. Please try again.'),
          findsOneWidget);
      expect(find.textContaining('diagnostic only'), findsNothing,
          reason: 'detail is diagnostic, never shown (constitution §13.6)');
    });

    testWidgets('says nothing when the form is reached without an error',
        (tester) async {
      final notifier = await pumpSaving(tester);

      await runWithOverflowCollection((_) async {
        notifier.setDemoPhase(
            const WizardConfiguring(wifiConfig: pnpUnifiedWifiConfig));
        await settle(tester);
      });

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  testWidgets(
      'the reconnect screen says the router is restarting, and lays out at '
      '320px in every locale', (tester) async {
    // The copy is new (the old line said "connect your devices to your new WiFi"
    // while that network was not on the air yet), and the reconnect screen is in
    // no layout-gate case — so this is the only thing that renders it per locale.
    // 320px is the product floor and overflow is monotonic in width.
    final overflows = <String>[];
    for (final locale in AppLocalizations.supportedLocales) {
      await setLayoutSurface(tester, const Size(320, 1600));
      final errors = await runWithOverflowCollection((sink) async {
        await tester.pumpWidget(KeyedSubtree(
          key: ValueKey(locale.toString()),
          child: pageSurfaceHost(
            view: const PnpSetupView(),
            locale: locale,
            overrides: pnpOverrides(pnpWizardNeedsReconnectState),
          ),
        ));
        await settle(tester);
        return sink;
      });
      if (errors.isNotEmpty) overflows.add('$locale: $errors');

      final copy = lookupAppLocalizations(locale).pnpReconnectWiFiRestarting;
      expect(find.text(copy), findsOneWidget, reason: '$locale');
    }

    expect(overflows, isEmpty, reason: overflows.join('\n'));
  });

  testWidgets(
      'neither completion-screen action button clips its label at 320px, in any '
      'locale', (tester) async {
    // **The assertion the layout gate structurally cannot make here, and the
    // second thing #1602's fix needs pinned.** That fix turned the `Print` /
    // `Done` `Row` into a `Wrap`, which removes the `RenderFlex` overflow the gate
    // was reading. It does not remove the failure mode: `RenderWrap` hands each
    // child the line's width as a *constraint*, so a button that wants more room
    // than the line has does not overflow — it **shrinks, and squeezes its
    // label**. Green gate, unreadable button.
    //
    // A first draft of this test asserted `buttonWidth <= wrap.constraints
    // .maxWidth` and was **inert**: mutation-checked by wrapping the `Wrap` in a
    // `SizedBox(width: 100)`, it stayed green, because that inequality is what
    // `RenderWrap` already guarantees. The oracle has to be the label, not the box.
    //
    // Measured 2026-09-21 at 320px, all 26 locales: the line is **174.0px**, the
    // widest button is `nl` at **146.0px** (`el` 143.1, `fr`/`fr_CA` 136.7), and
    // every locale's `Wrap` lays out **two runs** (104.0px tall) — so the
    // degradation really happens rather than the pair merely fitting, and no
    // label is squeezed: tightest headroom **28.0px**, ~19% of the button.
    //
    // 320px is the product floor (`kMinSupportedScreenWidth`) and overflow is
    // monotonic in width, so one width is the whole claim.
    final offenders = <String>[];
    for (final locale in AppLocalizations.supportedLocales) {
      await setLayoutSurface(tester, const Size(320, 1600));
      await tester.pumpWidget(KeyedSubtree(
        // A fresh subtree per locale, the same reason the gate's runner keys its
        // cell hosts: reused render objects would measure the first locale's
        // layout 26 times.
        key: ValueKey(locale.toString()),
        child: pageSurfaceHost(
          view: const PnpSetupView(),
          locale: locale,
          overrides: pnpOverrides(pnpWizardWifiReadyUnifiedState),
        ),
      ));
      await settle(tester);

      // The unified completion screen builds exactly one `Wrap`. If a second ever
      // appears this throws rather than silently measuring the wrong one.
      final buttons = find.descendant(
          of: find.byType(Wrap), matching: find.byType(AppButton));
      expect(buttons, findsNWidgets(2),
          reason: 'the action Wrap should hold Print and Done');

      for (var i = 0; i < 2; i++) {
        final label =
            find.descendant(of: buttons.at(i), matching: find.byType(Text));
        if (label.evaluate().length != 1) continue;
        final paragraph = tester.paragraphOf(label);
        final text = paragraph.text.toPlainText();
        // Both verdicts, in the order rule 4 of the gate skill puts them: neither
        // subsumes the other. An ellipsis leaves every surviving token fitting, and
        // a mid-word break drops nothing, so `didExceedMaxLines` stays false.
        if (tester.isTextClipped(label)) {
          offenders.add('$locale: "$text" is truncated inside its button — '
              'granted ${paragraph.size.width.toStringAsFixed(1)}px');
        } else if (!kLocalesWithoutWordSpaces.contains(locale.toString()) &&
            tester.hasSplitToken(label)) {
          offenders.add('$locale: "$text" broke mid-word inside its button — '
              'granted ${paragraph.size.width.toStringAsFixed(1)}px, widest token '
              '${tester.widestTokenWidth(label).toStringAsFixed(1)}px');
        }
      }
    }

    expect(
      offenders,
      isEmpty,
      reason:
          'a `Wrap` constrains its children to the line, so a button with too '
          'little room squeezes its label instead of overflowing — invisible to '
          'every one of the 234 cells in page.pnp_setup_complete_unified:\n'
          '${offenders.join('\n')}',
    );
  });

  // ===========================================================================
  // Your Network and Add nodes (#1734)
  // ===========================================================================
  //
  // Your Network is shown with one node as with several, so Save is always on
  // it; and under its list the step offers Add nodes on exactly the topology's
  // two conditions — the onboarding capability, and a surface that has the way
  // in. The add-nodes page is a stand-in here: what is under test is that the
  // step opens it and reads the nodes again when it pops.
  group('Your Network and Add nodes (#1734)', () {
    final en = lookupAppLocalizations(const Locale('en'));

    /// The wizard with [config] and [nodes], on a stand-in add-nodes route that
    /// is a *child* of the wizard's, as `pnpAddNodes` is of `pnpConfig`, so a
    /// pop lands back on the step.
    Future<FixedPnpNotifier> pumpWizard(
      WidgetTester tester, {
      PnpWifiConfig config = pnpUnifiedWifiConfig,
      List<NodeEntity>? nodes,
      AppModeProfile profile = const LocalModeProfile(),
      DeviceCapabilities? capabilities,
      Locale locale = const Locale('en'),
    }) async {
      enlargeSurface(tester);
      final notifier = FixedPnpNotifier(PnpState(
        phase: WizardConfiguring(
          wifiConfig: config,
          meshNodes: nodes ?? [pnpMeshNodes.first],
        ),
        serialNumber: 'SN-TEST',
      ));
      await runWithOverflowCollection((_) async {
        await tester.pumpWidget(pageSurfaceHost(
          view: const PnpSetupView(),
          locale: locale,
          overrides: [
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
                    // GoRouter's pop, as PnpAddNodesView's Done is.
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

    /// Presses Next until the stepper is on its last step.
    Future<void> toYourNetwork(WidgetTester tester) async {
      await runWithOverflowCollection((_) async {
        while (find.widgetWithText(AppButton, en.next).evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(AppButton, en.next));
          await settle(tester);
        }
      });
    }

    Finder buttonLabelled(String label) =>
        find.widgetWithText(AppButton, label);

    for (final entry in {
      'one node and no guest SSID': pnpNoGuestWifiConfig,
      'one node and a guest SSID': pnpUnifiedWifiConfig,
    }.entries) {
      testWidgets(
          '${entry.key}: every step before Your Network ends in Next, '
          'and Your Network holds Save', (tester) async {
        await pumpWizard(tester, config: entry.value);

        expect(buttonLabelled(en.save), findsNothing,
            reason: 'main Wi-Fi saves only when it is the last step, and Your '
                'Network now always follows');
        await toYourNetwork(tester);

        expect(find.text(en.pnpYourNetworkTitle), findsWidgets);
        expect(buttonLabelled(en.save), findsOneWidget);
        expect(find.byType(AppStepper), findsOneWidget,
            reason: 'two steps at least, so the stepper always renders');
      });
    }

    testWidgets(
        'Add nodes opens the add-nodes page, and the nodes are read '
        'again once it pops', (tester) async {
      final handle = tester.ensureSemantics();
      final notifier = await pumpWizard(tester);
      await toYourNetwork(tester);

      expect(
          find.bySemanticsIdentifier(kPnpAddNodesIdentifier), findsOneWidget);
      expect(notifier.meshRefreshes, 0);
      // A route transition, so the shared settle: the local five-frame one
      // would pop the page while it is still animating in.
      await runWithOverflowCollection((_) async {
        await tester.tap(buttonLabelled(en.addNodes));
        await settleIgnoringAnimations(tester);
      });
      expect(find.text('add nodes page'), findsOneWidget);
      expect(notifier.meshRefreshes, 0,
          reason: 'not before the page has closed');

      await runWithOverflowCollection((_) async {
        await tester.tap(find.text('add nodes page'));
        await settleIgnoringAnimations(tester);
      });

      expect(find.text(en.pnpYourNetworkTitle), findsWidgets,
          reason: 'back on the step it was opened from, not step 0');
      expect(buttonLabelled(en.save), findsOneWidget);
      expect(notifier.meshRefreshes, 1);
      handle.dispose();
    });

    testWidgets('firmware without the onboarding API offers no Add nodes',
        (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWizard(tester, capabilities: DeviceCapabilities.empty);
      await toYourNetwork(tester);

      expect(buttonLabelled(en.save), findsOneWidget,
          reason: 'on the step, so the absence below is the button and not '
              'the step');
      expect(find.bySemanticsIdentifier(kPnpAddNodesIdentifier), findsNothing);
      handle.dispose();
    });

    testWidgets('remote assistance offers no Add nodes', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpWizard(tester, profile: const RemoteModeProfile());
      await toYourNetwork(tester);

      expect(buttonLabelled(en.save), findsOneWidget,
          reason: 'on the step, so the absence below is the button and not '
              'the step');
      expect(find.bySemanticsIdentifier(kPnpAddNodesIdentifier), findsNothing);
      handle.dispose();
    });

    testWidgets('a mesh read that found nothing shows no empty list',
        (tester) async {
      // PnpService.fetchMeshTopology answers a failed read with no nodes, and
      // the step is shown regardless now.
      await pumpWizard(tester, nodes: const []);
      await toYourNetwork(tester);

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
      final next = words.next;
      await pumpWizard(tester, nodes: pnpMeshNodes, locale: zhTw);
      await runWithOverflowCollection((_) async {
        while (find.widgetWithText(AppButton, next).evaluate().isNotEmpty) {
          await tester.tap(find.widgetWithText(AppButton, next));
          await settle(tester);
        }
      });

      final descriptions = tester
          .widgetList<AppNodeListCard>(find.byType(AppNodeListCard))
          .map((card) => card.description)
          .toSet();
      expect(descriptions, {words.master, words.slave});
      expect(descriptions, isNot(contains('Master')));
    });
  });
}
