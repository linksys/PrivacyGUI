import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/card_density_scope.dart';
import 'package:privacy_gui/page/_shared/models/card_density.dart';
import 'package:privacy_gui/page/administration/providers/upnp_data_provider.dart';
import 'package:privacy_gui/page/dmz/models/dmz_ui_model.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/firewall/cards/usp_firewall_overview_card.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_forwarding_data_provider.dart';
import 'package:privacy_gui/page/port_forwarding/providers/port_triggering_data_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../mocks/provider_overrides/mock_dashboard_cards.dart';
import '../../../mocks/test_data/firewall_test_data.dart';
import '../../../mocks/test_data/port_forwarding_test_data.dart';

final _theme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// The pages the card's rows open, as stubs that say which they are.
const _pages = {
  RouteNamed.uspFirewall: 'firewall page',
  RouteNamed.uspDmz: 'dmz page',
  RouteNamed.uspPortForwardingDetail: 'port forwarding page',
  RouteNamed.uspAdministration: 'administration page',
};

/// The dashboard's Firewall card (#1130), on a router that is [firewall] with
/// [forwarding] and [triggering] rules and UPnP [upnp].
Future<void> pumpCard(
  WidgetTester tester, {
  FirewallData? firewall,
  List<PortForwardingRuleUIModel> forwarding = const [],
  List<PortTriggeringRuleUIModel> triggering = const [],
  bool upnp = true,
  bool upnpRead = true,
  CardDensity density = CardDensity.normal,
}) async {
  final router = GoRouter(routes: [
    GoRoute(
      path: '/',
      builder: (_, __) => Scaffold(
        body: SizedBox(
          width: 500,
          height: 600,
          child: CardDensityScope(
            density: density,
            child: const UspFirewallOverviewCard(),
          ),
        ),
      ),
      routes: [
        for (final MapEntry(key: name, value: text) in _pages.entries)
          GoRoute(
            path: name,
            name: name,
            builder: (_, __) => Scaffold(body: Text(text)),
          ),
      ],
    ),
  ]);
  addTearDown(router.dispose);
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ...cardOverrides(
        firewallData: firewall ?? FirewallTestData.createFirewallData(),
        portForwardingData: PortForwardingData(ruleModels: forwarding),
        portTriggeringData: PortTriggeringData(ruleModels: triggering),
        upnpEnabled: upnpRead ? upnp : null,
      ),
      // A UPnP read that failed: the router answered nothing for it.
      if (!upnpRead)
        upnpDataProvider
            .overrideWith((ref) async => throw const TimeoutError()),
    ],
    child: MaterialApp.router(
      theme: _theme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    ),
  ));
  await tester.pumpAndSettle();
}

void main() {
  group('a new router', () {
    testWidgets('says nothing is opened, and shows DMZ, port rules and UPnP',
        (tester) async {
      await pumpCard(tester);

      expect(find.text('Protected'), findsOneWidget);
      expect(find.text("You haven't opened any device to the internet"),
          findsOneWidget);
      expect(find.text('DMZ'), findsOneWidget);
      expect(find.text('Off'), findsOneWidget);
      expect(find.text('Port Forwarding'), findsOneWidget);
      expect(find.text('0 rules'), findsOneWidget);
      expect(find.text('UPnP'), findsOneWidget);
      expect(find.text('On'), findsOneWidget);
      expect(find.textContaining('SPI'), findsNothing);
    });
  });

  group('DMZ and port forwarding in use', () {
    testWidgets('names the DMZ host by MAC, as the DMZ page does',
        (tester) async {
      // A host given by MAC leaves DestIP empty; the old card printed that IP
      // and read "Target: " with nothing after it (#1775).
      await pumpCard(
        tester,
        firewall: FirewallTestData.createFirewallData(
          dmzModel: FirewallTestData.createDmzUIModel(
            isEnabled: true,
            destinationType: DmzDestinationType.mac,
            destMac: 'AA:BB:CC:DD:EE:01',
          ),
        ),
      );

      expect(find.text('DMZ Active'), findsOneWidget);
      expect(find.text('On · AA:BB:CC:DD:EE:01'), findsOneWidget);
      expect(find.text("You haven't opened any device to the internet"),
          findsNothing);
    });

    testWidgets('counts the port rules that are on, triggering included',
        (tester) async {
      await pumpCard(
        tester,
        forwarding: [
          PortForwardingTestData.createRule(enabled: true),
          PortForwardingTestData.createRangeRule(enabled: false),
        ],
        triggering: [PortForwardingTestData.createTriggerRule(enabled: true)],
      );

      expect(find.text('2 of 3 on'), findsOneWidget);
    });

    testWidgets('shows a plain count when every rule is on', (tester) async {
      await pumpCard(
        tester,
        forwarding: [PortForwardingTestData.createRule(enabled: true)],
      );

      expect(find.text('1 rule'), findsOneWidget);
    });
  });

  group('SPI firewall off', () {
    testWidgets('adds one warning row saying which is off', (tester) async {
      await pumpCard(
        tester,
        firewall: FirewallTestData.createFirewallData(
          firewallModel: FirewallTestData.createFirewallUIModel(
            isIPv4FirewallEnabled: false,
            isIPv6FirewallEnabled: false,
          ),
          dmzModel: FirewallTestData.createEnabledDmzUIModel(),
        ),
      );

      expect(find.text('At Risk'), findsOneWidget);
      expect(find.text('SPI Firewall'), findsOneWidget);
      expect(find.text('IPv4 and IPv6 off'), findsOneWidget);
      // DMZ keeps its own flag beside the SPI row.
      expect(find.byIcon(Icons.error_outline), findsNWidgets(2));
    });

    testWidgets('IPv6 off on its own is Basic', (tester) async {
      await pumpCard(
        tester,
        firewall: FirewallTestData.createFirewallData(
          firewallModel: FirewallTestData.createFirewallUIModel(
            isIPv6FirewallEnabled: false,
          ),
        ),
      );

      expect(find.text('Basic'), findsOneWidget);
      expect(find.text('IPv6 off'), findsOneWidget);
    });
  });

  group('(i)', () {
    Finder tooltip(String startsWith) => find.byWidgetPredicate(
        (w) => w is AppTooltip && (w.message ?? '').startsWith(startsWith));

    testWidgets('on a new router: the sentence and UPnP only', (tester) async {
      await pumpCard(tester);

      expect(find.byType(AppTooltip), findsNWidgets(2));
      expect(tooltip('The firewall blocks connections'), findsOneWidget);
      expect(tooltip('Lets game consoles'), findsOneWidget);
    });

    testWidgets('on every row that lets something in', (tester) async {
      await pumpCard(
        tester,
        firewall: FirewallTestData.createFirewallData(
          firewallModel: FirewallTestData.createFirewallUIModel(
            isIPv4FirewallEnabled: false,
          ),
          dmzModel: FirewallTestData.createEnabledDmzUIModel(),
        ),
        forwarding: [PortForwardingTestData.createRule(enabled: true)],
        upnp: false,
      );

      expect(tooltip('The router no longer blocks'), findsOneWidget);
      expect(tooltip('This device is fully open'), findsOneWidget);
      expect(tooltip('These rules let connections'), findsOneWidget);
      expect(tooltip('Lets game consoles'), findsNothing,
          reason: 'UPnP is off');
    });
  });

  group('a row', () {
    for (final (label, page, setUp) in [
      ('SPI Firewall', 'firewall page', true),
      ('DMZ', 'dmz page', false),
      ('Port Forwarding', 'port forwarding page', false),
      ('UPnP', 'administration page', false),
    ]) {
      testWidgets('$label opens the $page', (tester) async {
        await pumpCard(
          tester,
          firewall: setUp
              ? FirewallTestData.createFirewallData(
                  firewallModel: FirewallTestData.createFirewallUIModel(
                    isIPv4FirewallEnabled: false,
                  ),
                )
              : null,
        );

        await tester.tap(find.text(label));
        await tester.pumpAndSettle();

        expect(find.text(page), findsOneWidget);
      });
    }

    testWidgets('tapping (i) opens the tooltip, not the page', (tester) async {
      await pumpCard(tester);

      await tester.tap(find.byIcon(Icons.info_outline).last);
      await tester.pumpAndSettle();

      expect(find.text('administration page'), findsNothing);
      expect(find.textContaining('Lets game consoles'), findsOneWidget);
    });
  });

  group('a value the router has not answered', () {
    testWidgets('is a dash, and the card claims nothing about it',
        (tester) async {
      await pumpCard(tester, upnpRead: false);

      expect(find.text('—'), findsOneWidget);
      expect(find.text('On'), findsNothing);
      expect(find.text('Off'), findsOneWidget, reason: 'DMZ is still read');
    });
  });

  testWidgets('the popup form shows the badge', (tester) async {
    await pumpCard(
      tester,
      density: CardDensity.popup,
      firewall: FirewallTestData.createFirewallData(
        dmzModel: FirewallTestData.createEnabledDmzUIModel(),
      ),
    );

    expect(find.text('DMZ Active'), findsOneWidget);
    expect(find.text('Firewall Overview'), findsOneWidget);
    expect(find.text('DMZ'), findsNothing);
  });

  testWidgets('the compact form drops (i), keeps the chevron, and navigates',
      (tester) async {
    await pumpCard(
      tester,
      density: CardDensity.compact,
      firewall: FirewallTestData.createFirewallData(
        dmzModel: FirewallTestData.createEnabledDmzUIModel(),
      ),
    );

    expect(find.byIcon(Icons.info_outline), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsNWidgets(3),
        reason: 'every row opens a page, so every row has one');
    expect(find.byIcon(Icons.error_outline), findsOneWidget,
        reason: 'DMZ keeps its flag');

    await tester.tap(find.text('DMZ'));
    await tester.pumpAndSettle();

    expect(find.text('dmz page'), findsOneWidget);
  });
}
