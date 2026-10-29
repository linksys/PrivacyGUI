import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/cards/usp_port_forwarding_card.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/views/usp_port_forwarding_detail_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_dashboard_cards.dart';
import '../../../mocks/provider_overrides/mock_port_forwarding.dart';
import '../../../mocks/test_data/scenes/cards_scene_data.dart';
import '../../../mocks/test_data/scenes/port_forwarding_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// FWDEV#204's rule limits on the real Port Forwarding page: 50 single-port,
/// 25 range and 25 triggering rules. FW refuses a rule past them only on its
/// own Set, so the page stops at the limit and says why.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  AppIconButton addButton(WidgetTester tester, String identifier) =>
      tester.widget<AppIconButton>(find.byWidgetPredicate(
          (w) => w is AppIconButton && w.identifier == identifier));

  Future<void> pumpTab(
    WidgetTester tester, {
    required int tab,
    required bool full,
  }) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: UspPortForwardingDetailView(initialTab: tab),
      locale: const Locale('en'),
      overrides: portForwardingOverrides(full ? fullDataState : dataState()),
    ));
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  // The dialogs check overlap and the LAN host only with what their tab hands
  // them, so a tab that forgets to pass it turns both checks off.
  //
  // Run as macOS, like the dialog suite: an error shows on focus-loss, and a
  // tap outside a field unfocuses it on desktop but not on the default Android
  // test target.
  group('what a tab hands its dialog', () {
    final onDesktop = TargetPlatformVariant.only(TargetPlatform.macOS);

    Future<String?> externalPortErrorAfterTyping(
        WidgetTester tester, String port) async {
      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppIconButton && w.identifier == 'pf-add-single-port'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final field = find.descendant(
        of: find.bySemanticsIdentifier('pf-single-external-port'),
        matching: find.byType(EditableText),
      );
      // Focus first: `enterText` alone does not focus the field, so leaving it
      // would raise no focus-loss and the error would never refresh.
      await tester.tap(field);
      await tester.enterText(field, port);
      await tester.tap(find.text('Add Port Forwarding'));
      await tester.pump();
      return tester
          .widget<AppTextField>(find.ancestor(
            of: find.bySemanticsIdentifier('pf-single-external-port'),
            matching: find.byType(AppTextField),
          ))
          .errorText;
    }

    testWidgets('a single port inside a range rule shows the overlap',
        (tester) async {
      await pumpTab(tester, tab: 0, full: false);

      // 3076 is inside the scene's Game Server range, 3074-3080 Both.
      expect(await externalPortErrorAfterTyping(tester, '3076'),
          startsWith('The rules cannot be created'));
    }, variant: onDesktop);

    testWidgets('the router address is refused as a destination',
        (tester) async {
      await pumpTab(tester, tab: 0, full: false);
      await externalPortErrorAfterTyping(tester, '6000');

      final ip = find.descendant(
        of: find.bySemanticsIdentifier('pf-single-internal-ip'),
        matching: find.byType(EditableText),
      );
      await tester.tap(ip);
      await tester.enterText(ip, '192.168.1.1');
      await tester.tap(find.text('Add Port Forwarding'));
      await tester.pump();

      expect(
        tester
            .widget<AppTextField>(find.ancestor(
              of: find.bySemanticsIdentifier('pf-single-internal-ip'),
              matching: find.byType(AppTextField),
            ))
            .errorText,
        'Invalid IP address',
      );
    }, variant: onDesktop);
  });

  for (final (tab, identifier, limit) in const [
    (0, 'pf-add-single-port', 50),
    (1, 'pf-add-port-range', 25),
    (2, 'pf-add-port-triggering', 25),
  ]) {
    group('tab $tab', () {
      testWidgets('Add is enabled below the limit', (tester) async {
        await pumpTab(tester, tab: tab, full: false);

        expect(addButton(tester, identifier).onTap, isNotNull);
        expect(find.text('Maximum number of rules reached'), findsNothing);
      });

      testWidgets('Add is disabled at $limit rules, and says why',
          (tester) async {
        await pumpTab(tester, tab: tab, full: true);

        expect(addButton(tester, identifier).onTap, isNull);
        expect(find.text('Maximum number of rules reached'), findsOneWidget);
      });
    });
  }

  // The dashboard card adds a single-port rule through the same dialog and
  // writes it at once (`immediateAddForwarding`), so it needs the same limit
  // and the same data as the Single Port tab.
  group('dashboard card', () {
    final onDesktop = TargetPlatformVariant.only(TargetPlatform.macOS);

    Future<void> pumpCard(
        WidgetTester tester, List<PortForwardingRuleUIModel> rules) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(pageSurfaceHost(
        view: const Scaffold(body: UspPortForwardingCard()),
        locale: const Locale('en'),
        overrides: cardOverrides(
          portForwardingData: PortForwardingData(ruleModels: rules),
          portTriggeringData: testPortTriggeringEmptyData,
          lanData: testLanData,
        ),
      ));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    testWidgets('Add is disabled at 50 single-port rules', (tester) async {
      final singles = fullDataState.settings.current.forwardingRules
          .where((r) => r.isSinglePort)
          .toList();
      expect(singles, hasLength(50));
      await pumpCard(tester, singles);

      expect(addButton(tester, 'pf-card-add').onTap, isNull);
    });

    testWidgets('a port inside another rule\'s range shows the overlap',
        (tester) async {
      await pumpCard(tester, testPortForwardingRules);
      expect(addButton(tester, 'pf-card-add').onTap, isNotNull);

      await tester.tap(find.byWidgetPredicate(
          (w) => w is AppIconButton && w.identifier == 'pf-card-add'));
      for (var i = 0; i < 8; i++) {
        await tester.pump(const Duration(milliseconds: 50));
      }
      final field = find.descendant(
        of: find.bySemanticsIdentifier('pf-single-external-port'),
        matching: find.byType(EditableText),
      );
      await tester.tap(field);
      // 8080 is the scene's Web Server, TCP; the dialog defaults to TCP.
      await tester.enterText(field, '8080');
      await tester.tap(find.text('Add Port Forwarding'));
      await tester.pump();

      expect(
        tester
            .widget<AppTextField>(find.ancestor(
              of: find.bySemanticsIdentifier('pf-single-external-port'),
              matching: find.byType(AppTextField),
            ))
            .errorText,
        startsWith('The rules cannot be created'),
      );
    }, variant: onDesktop);
  });
}
