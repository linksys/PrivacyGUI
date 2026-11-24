// The DHCP Reservations link on `usp_local_network_view` with unsaved changes
// (linksys/PrivacyGUI#1433).
//
// The link goes through `pushNamedPastUnsavedChanges`, so with unsaved changes
// it asks Go back / Discard changes / Save first (the verb itself is pinned in
// `test/route/navigation_extensions_test.dart`). What is this page's own is the
// decision recorded on #1433 for Save:
//
//   - only DHCP fields changed: save, then open DHCP Reservations;
//   - the router IP or subnet changed: save the way the page always does — the
//     "may disconnect" question first, then the redirect when the IP changed —
//     and do not open it, because the LAN restarts or the router has moved;
//   - a field with a validation error: Save is disabled, as on the bottom bar.
//
// Scope, stated plainly: `save()` is stubbed (see [_CountingLocalNetworkNotifier]),
// so the write, the SSE drop and the read-back are the notifier's own tests.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/local_network/models/local_network_feature_state.dart';
import 'package:privacy_gui/page/local_network/providers/usp_local_network_notifier.dart';
import 'package:privacy_gui/page/local_network/views/usp_local_network_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../mocks/provider_overrides/mock_local_network.dart';
import '../../../mocks/test_data/scenes/local_network_scene_data.dart';

/// [FixedLocalNetworkNotifier] with a counted `save()` that settles the page
/// as a successful save does.
class _CountingLocalNetworkNotifier extends FixedLocalNetworkNotifier {
  _CountingLocalNetworkNotifier(super.state);

  int saveCalls = 0;

  @override
  Future<LocalNetworkFeatureState> save() async {
    saveCalls++;
    markAsSaved();
    return state;
  }
}

/// The English copy this file matches on, from `app_en.arb`.
const _unsavedTitle = 'You have unsaved changes on this page';
const _networkQuestionTitle = 'Change Network Settings?';
const _redirectTitle = 'Reconnect to your router';
const _reservationsStub = 'DHCP Reservations stub';

Finder _button(String identifier) => find.byWidgetPredicate(
      (w) => w is AppButton && w.identifier == identifier,
      description: "AppButton(identifier: '$identifier')",
    );

Finder _reservationsLink() => find.byWidgetPredicate(
      (w) =>
          w is LayoutBlock && w.identifier == 'local-network-dhcp-reservations',
      description: 'the DHCP Reservations link',
    );

void main() {
  Future<_CountingLocalNetworkNotifier> pumpPage(
    WidgetTester tester,
    LocalNetworkFeatureState state,
  ) async {
    final notifier = _CountingLocalNetworkNotifier(state);
    await setLayoutSurface(tester, const Size(1200, 1600));
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspLocalNetworkView(),
      locale: const Locale('en'),
      overrides: [uspLocalNetworkProvider.overrideWith(() => notifier)],
      childRoutes: [
        GoRoute(
          path: 'dhcp-reservations',
          name: RouteNamed.uspDhcpDetail,
          builder: (_, __) => const Scaffold(body: Text(_reservationsStub)),
        ),
      ],
    ));
    await tester.pumpAndSettle();
    return notifier;
  }

  Future<void> tapReservations(WidgetTester tester) async {
    await tester.ensureVisible(_reservationsLink());
    await tester.tap(_reservationsLink());
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String identifier) async {
    await tester.tap(_button(identifier));
    await tester.pumpAndSettle();
  }

  bool pageIsDirty(WidgetTester tester) => ProviderScope.containerOf(
          tester.element(find.byType(UspLocalNetworkView, skipOffstage: false)))
      .read(uspLocalNetworkProvider)
      .isDirty;

  group('UspLocalNetworkView - DHCP Reservations link with unsaved changes',
      () {
    testWidgets('asks before opening, and opens nothing yet', (tester) async {
      await pumpPage(tester, dirtyDhcpOnlyState());

      await tapReservations(tester);

      expect(find.text(_unsavedTitle), findsOneWidget);
      expect(find.text(_reservationsStub), findsNothing);
    });

    testWidgets('Save with only DHCP fields changed saves, then opens it',
        (tester) async {
      final notifier = await pumpPage(tester, dirtyDhcpOnlyState());
      await tapReservations(tester);

      await tap(tester, 'unsaved-open-save');

      expect(find.text(_networkQuestionTitle), findsNothing,
          reason: 'nothing about the network changed, so nothing to ask');
      expect(notifier.saveCalls, 1);
      expect(find.text(_reservationsStub), findsOneWidget);
    });

    testWidgets(
        'Save with a router IP change asks, saves, shows the redirect and '
        'does not open it', (tester) async {
      final notifier = await pumpPage(tester, dirtyState()); // 192.168.2.1
      await tapReservations(tester);

      await tap(tester, 'unsaved-open-save');
      expect(find.text(_networkQuestionTitle), findsOneWidget);
      await tap(tester, 'network-change-continue');

      expect(notifier.saveCalls, 1);
      expect(find.text(_redirectTitle), findsOneWidget,
          reason: 'the router has moved; the redirect is the next step');
      expect(find.text(_reservationsStub), findsNothing);
    });

    testWidgets(
        'Save with only the subnet mask changed asks, saves and stays on '
        'Local Network', (tester) async {
      final notifier = await pumpPage(tester, dirtySubnetMaskOnlyState());
      await tapReservations(tester);

      await tap(tester, 'unsaved-open-save');
      expect(find.text(_networkQuestionTitle), findsOneWidget);
      await tap(tester, 'network-change-continue');

      expect(notifier.saveCalls, 1);
      expect(find.text(_redirectTitle), findsNothing,
          reason: 'the IP is unchanged, so there is nowhere to redirect to');
      expect(find.text(_reservationsStub), findsNothing,
          reason: 'the LAN restarts after a mask change');
      expect(find.byType(UspLocalNetworkView), findsOneWidget);
    });

    testWidgets(
        'cancelling the network question saves nothing and keeps the '
        'changes', (tester) async {
      final notifier = await pumpPage(tester, dirtyState());
      await tapReservations(tester);

      await tap(tester, 'unsaved-open-save');
      await tap(tester, 'network-change-cancel');

      expect(notifier.saveCalls, 0);
      expect(find.text(_reservationsStub), findsNothing);
      expect(find.byType(UspLocalNetworkView), findsOneWidget);
      expect(pageIsDirty(tester), isTrue);
    });

    testWidgets('Save is disabled while a field has a validation error',
        (tester) async {
      final withError = dirtyDhcpOnlyState();
      await pumpPage(
        tester,
        withError.copyWith(
          status: withError.status
              .copyWith(validationErrors: {'leaseTime': 'Must be 1–525600'}),
        ),
      );
      await tapReservations(tester);

      expect(
          tester.widget<AppButton>(_button('unsaved-open-save')).onTap, isNull);
      expect(tester.widget<AppButton>(_button('unsaved-open-discard')).onTap,
          isNotNull);
    });

    testWidgets('with nothing unsaved the link opens it without asking',
        (tester) async {
      final notifier = await pumpPage(tester, dataState(dhcpEnabledModel));

      await tapReservations(tester);

      expect(find.text(_unsavedTitle), findsNothing);
      expect(notifier.saveCalls, 0);
      expect(find.text(_reservationsStub), findsOneWidget);
    });

    testWidgets('Discard changes reverts the page, then opens it',
        (tester) async {
      final notifier = await pumpPage(tester, dirtyState());
      await tapReservations(tester);

      await tap(tester, 'unsaved-open-discard');

      expect(notifier.saveCalls, 0);
      expect(find.text(_reservationsStub), findsOneWidget);
      expect(pageIsDirty(tester), isFalse);
    });
  });
}
