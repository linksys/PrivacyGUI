import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_feature_state.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_status.dart';
import 'package:privacy_gui/page/ipv6_port_service/views/usp_ipv6_port_service_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_ipv6_port_service.dart';
import '../../../mocks/test_data/scenes/ipv6_port_service_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// FWDEV#204's IPv6 port service checks on the real page (feed_usp#50): at
/// most 15 rules, and a dialog that does not submit a rule FW would refuse.
///
/// Run as macOS, like the port forwarding dialog suite: an error shows on
/// focus-loss, and a tap outside a field unfocuses it on desktop but not on
/// the default Android test target.
///
/// **Untagged on purpose** so `run_tests.sh` runs it.
void main() {
  final onDesktop = TargetPlatformVariant.only(TargetPlatform.macOS);

  setUpAll(() async {
    await loadAppFonts();
  });

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> pumpPage(
      WidgetTester tester, Ipv6PortServiceFeatureState state) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspIpv6PortServiceView(),
      locale: const Locale('en'),
      overrides: ipv6PortServiceOverrides(state),
    ));
    await settle(tester);
  }

  AppIconButton iconButton(WidgetTester tester, String identifier) =>
      tester.widget<AppIconButton>(find.byWidgetPredicate(
          (w) => w is AppIconButton && w.identifier == identifier));

  AppButton submit(WidgetTester tester) =>
      tester.widget<AppButton>(find.byWidgetPredicate(
          (w) => w is AppButton && w.identifier == 'ipv6-rule-submit'));

  Finder field(String identifier) => find.descendant(
        of: find.bySemanticsIdentifier(identifier),
        matching: find.byType(EditableText),
      );

  /// Type into a field, then tap the dialog title so it loses focus and its
  /// error refreshes.
  Future<void> typeInto(
      WidgetTester tester, String identifier, String text) async {
    await tester.tap(field(identifier));
    await tester.enterText(field(identifier), text);
    await tester.tap(find.text('Add rule'));
    await tester.pump();
  }

  String? errorOf(WidgetTester tester, String identifier) => tester
      .widget<AppTextField>(find.ancestor(
        of: find.bySemanticsIdentifier(identifier),
        matching: find.byType(AppTextField),
      ))
      .errorText;

  /// The port pair is one [AppRangeInput] with one error line for both.
  String? portError(WidgetTester tester) =>
      tester.widget<AppRangeInput>(find.byType(AppRangeInput)).errorText;

  Future<void> openAdd(WidgetTester tester) async {
    await tester.tap(find.byWidgetPredicate(
        (w) => w is AppIconButton && w.identifier == 'ipv6-rule-add'));
    await settle(tester);
  }

  Future<void> fillRule(
    WidgetTester tester, {
    required String description,
    String address = '2001:db8::5',
    String start = '7000',
    String end = '7000',
  }) async {
    await typeInto(tester, 'ipv6-rule-description', description);
    await typeInto(tester, 'ipv6-rule-address', address);
    await typeInto(tester, 'ipv6-rule-start-port', start);
    await typeInto(tester, 'ipv6-rule-end-port', end);
  }

  group('rule limit', () {
    testWidgets('Add is enabled below 15 rules', (tester) async {
      await pumpPage(tester, dataState());

      expect(iconButton(tester, 'ipv6-rule-add').onTap, isNotNull);
      expect(find.text('Maximum number of rules reached'), findsNothing);
    });

    testWidgets('Add is disabled at 15 rules, and says why', (tester) async {
      await pumpPage(tester, fullState);

      expect(iconButton(tester, 'ipv6-rule-add').onTap, isNull);
      expect(find.text('Maximum number of rules reached'), findsOneWidget);
    });

    // FW keeps rules past 15 that an older build saved editable.
    testWidgets('rules stay editable at the limit', (tester) async {
      await pumpPage(tester, fullState);

      expect(iconButton(tester, 'ipv6-rule-edit-service-1').onTap, isNotNull);
    });
  });

  group('the add dialog', () {
    // dataState's Web Server is 80 TCP to 2001:db8::1.
    testWidgets('a port another rule opens to the same host shows the overlap',
        (tester) async {
      await pumpPage(tester, dataState());
      await openAdd(tester);

      await fillRule(tester,
          description: 'Web 2', address: '2001:db8::1', start: '80', end: '80');

      expect(portError(tester), startsWith('The rules cannot be created'));
      expect(submit(tester).onTap, isNull);
    }, variant: onDesktop);

    testWidgets('the name of a rule the page hides is not submitted',
        (tester) async {
      await pumpPage(
        tester,
        dataState().copyWith(
          status: const Ipv6PortServiceStatus(
              hiddenRuleDescriptions: {'RULE_IDENT'}),
        ),
      );
      await openAdd(tester);

      await fillRule(tester, description: 'RULE_IDENT');

      expect(errorOf(tester, 'ipv6-rule-description'),
          'Another rule already has this name');
      expect(submit(tester).onTap, isNull);
    }, variant: onDesktop);

    testWidgets('a name over 64 bytes is not submitted', (tester) async {
      await pumpPage(tester, dataState());
      await openAdd(tester);

      // 22 CJK characters: 66 bytes.
      await fillRule(tester, description: '規' * 22);

      expect(errorOf(tester, 'ipv6-rule-description'), 'Max 64 characters');
      expect(submit(tester).onTap, isNull);
    }, variant: onDesktop);

    testWidgets('a valid rule can be submitted', (tester) async {
      await pumpPage(tester, dataState());
      await openAdd(tester);

      await fillRule(tester, description: 'Game');

      expect(errorOf(tester, 'ipv6-rule-description'), isNull);
      expect(submit(tester).onTap, isNotNull);
    }, variant: onDesktop);
  });

  group('the edit dialog', () {
    // A rule saved before FW checked descriptions can already break a check:
    // the page used to allow 32 characters, so 22 CJK ones (66 bytes) were
    // saved. Its Save is disabled from the first frame, so the reason has to
    // show from the first frame too.
    testWidgets('a stored rule that breaks a check says why at once',
        (tester) async {
      await pumpPage(
        tester,
        dataState(rules: [
          testRules.first.copyWith(description: '規' * 22),
        ]),
      );
      await tester.tap(find.byWidgetPredicate((w) =>
          w is AppIconButton &&
          (w.identifier ?? '').startsWith('ipv6-rule-edit-')));
      await settle(tester);

      expect(errorOf(tester, 'ipv6-rule-description'), 'Max 64 characters');
      expect(submit(tester).onTap, isNull);
    });

    // An empty form is not an error until the user leaves a field.
    testWidgets('the add dialog opens without errors', (tester) async {
      await pumpPage(tester, dataState());
      await openAdd(tester);

      expect(errorOf(tester, 'ipv6-rule-description'), isNull);
      expect(errorOf(tester, 'ipv6-rule-address'), isNull);
      expect(portError(tester), isNull);
    });

    // Saving a rule unchanged must not report it overlapping, or sharing a
    // name with, itself.
    testWidgets('a rule unchanged can be saved', (tester) async {
      await pumpPage(tester, dataState());
      await tester.tap(find.byWidgetPredicate((w) =>
          w is AppIconButton && w.identifier == 'ipv6-rule-edit-web-server'));
      await settle(tester);

      expect(submit(tester).onTap, isNotNull);
    });
  });
}
