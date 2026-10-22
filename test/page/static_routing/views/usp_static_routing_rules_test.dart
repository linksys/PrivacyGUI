import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_feature_state.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/static_routing/views/dialogs/static_route_dialog.dart';
import 'package:privacy_gui/page/static_routing/views/usp_static_routing_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../mocks/provider_overrides/mock_dashboard_cards.dart'
    show FixedLanDataNotifier;
import '../../../mocks/provider_overrides/mock_static_routing.dart';
import '../../../mocks/test_data/scenes/cards_scene_data.dart' show testLanData;
import '../../../mocks/test_data/scenes/static_routing_scene_data.dart';
import '../../../util/app_test_fonts.dart';

/// FWDEV#213's static routing checks and the NAT / Dynamic routing radio on
/// the real page (#1100): at most 20 routes, a dialog that does not submit a
/// route FW would refuse, and the radio only where the router offers it.
///
/// Run as macOS, like the IPv6 port service suite: an error shows on
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
      WidgetTester tester, StaticRoutingFeatureState state) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(pageSurfaceHost(
      view: const UspStaticRoutingView(),
      locale: const Locale('en'),
      overrides: [
        ...staticRoutingOverrides(state),
        // 192.168.1.1/24, which the dialog checks addresses against.
        lanDataProvider.overrideWith(() => FixedLanDataNotifier(testLanData)),
      ],
    ));
    await settle(tester);
  }

  AppIconButton iconButton(WidgetTester tester, String identifier) =>
      tester.widget<AppIconButton>(find.byWidgetPredicate(
          (w) => w is AppIconButton && w.identifier == identifier));

  AppButton submit(WidgetTester tester) =>
      tester.widget<AppButton>(find.byWidgetPredicate(
          (w) => w is AppButton && w.identifier == 'static-route-submit'));

  Future<void> openAdd(WidgetTester tester) async {
    await tester.tap(find.byWidgetPredicate(
        (w) => w is AppIconButton && w.identifier == 'static-route-add'));
    await settle(tester);
  }

  /// Leave the field being typed in, so its error refreshes.
  Future<void> blur(WidgetTester tester) async {
    await tester.tap(find.text('Add static route'));
    await settle(tester);
  }

  Future<void> typeName(WidgetTester tester, String name) async {
    final box = find.descendant(
      of: find.bySemanticsIdentifier('static-route-name'),
      matching: find.byType(EditableText),
    );
    await tester.tap(box);
    await tester.enterText(box, name);
    await blur(tester);
  }

  /// An [AppIpv4TextField] is four octet boxes.
  Future<void> typeIpv4(
      WidgetTester tester, String identifier, String address) async {
    final boxes = find.descendant(
      of: find.byWidgetPredicate(
          (w) => w is AppIpv4TextField && w.identifier == identifier),
      matching: find.byType(EditableText),
    );
    final octets = address.split('.');
    for (var i = 0; i < 4; i++) {
      await tester.tap(boxes.at(i));
      await tester.enterText(boxes.at(i), octets[i]);
    }
    await blur(tester);
  }

  Future<void> fillRoute(
    WidgetTester tester, {
    required String name,
    String destination = '10.20.0.0',
    String mask = '255.255.0.0',
    String gateway = '192.168.1.50',
  }) async {
    await typeName(tester, name);
    await typeIpv4(tester, 'static-route-dest-ip', destination);
    await typeIpv4(tester, 'static-route-subnet-mask', mask);
    await typeIpv4(tester, 'static-route-gateway', gateway);
  }

  String? nameError(WidgetTester tester) => tester
      .widget<AppTextField>(find.ancestor(
        of: find.bySemanticsIdentifier('static-route-name'),
        matching: find.byType(AppTextField),
      ))
      .errorText;

  String? ipv4Error(WidgetTester tester, String identifier) => tester
      .widget<AppIpv4TextField>(find.byWidgetPredicate(
          (w) => w is AppIpv4TextField && w.identifier == identifier))
      .errorText;

  group('NAT / Dynamic routing', () {
    testWidgets('shows the choice the router reports', (tester) async {
      await pumpPage(
          tester, dataState(const [route1, route2], ripEnabled: true));

      final radio =
          tester.widget<AppRadioList<bool>>(find.byType(AppRadioList<bool>));
      expect(radio.selected, isTrue);
      expect(find.text('NAT'), findsOneWidget);
      expect(find.text('Dynamic routing (RIP)'), findsOneWidget);
    });

    testWidgets('is hidden on a router without RIP', (tester) async {
      await pumpPage(tester, dataState(const [route1, route2]));

      expect(find.byType(AppRadioList<bool>), findsNothing);
      expect(find.text('Dynamic routing (RIP)'), findsNothing);
    });
  });

  group('route limit', () {
    final full = [
      for (var i = 1; i <= kMaxStaticRoutes; i++)
        route1.copyWith(
          instancePath: 'Device.Routing.Router.1.IPv4Forwarding.$i.',
          name: 'Route $i',
        ),
    ];

    testWidgets('Add is enabled below 20 routes', (tester) async {
      await pumpPage(tester, dataState(const [route1, route2]));

      expect(iconButton(tester, 'static-route-add').onTap, isNotNull);
      expect(find.text('Maximum number of rules reached'), findsNothing);
    });

    testWidgets('Add is disabled at 20 routes, and says why', (tester) async {
      await pumpPage(tester, dataState(full));

      expect(iconButton(tester, 'static-route-add').onTap, isNull);
      expect(find.text('Maximum number of rules reached'), findsOneWidget);
    });

    // FW keeps routes past 20 that an older build saved editable.
    testWidgets('routes stay editable at the limit', (tester) async {
      await pumpPage(tester, dataState(full));

      expect(iconButton(tester, 'static-route-edit-route-1').onTap, isNotNull);
    });
  });

  group('the add dialog', () {
    // route1 is "Corporate LAN".
    testWidgets('the name of another route is not submitted', (tester) async {
      await pumpPage(tester, dataState(const [route1, route2]));
      await openAdd(tester);

      await fillRoute(tester, name: 'Corporate LAN');

      expect(nameError(tester), 'Another rule already has this name');
      expect(submit(tester).onTap, isNull);
    }, variant: onDesktop);

    testWidgets('a reserved destination is not submitted', (tester) async {
      await pumpPage(tester, dataState(const [route1, route2]));
      await openAdd(tester);

      await fillRoute(tester, name: 'Loopback', destination: '127.20.0.0');

      expect(ipv4Error(tester, 'static-route-dest-ip'),
          'Reserved IP address is not allowed');
      expect(submit(tester).onTap, isNull);
    }, variant: onDesktop);

    testWidgets('a route with no gateway is not submitted', (tester) async {
      await pumpPage(tester, dataState(const [route1, route2]));
      await openAdd(tester);

      await typeName(tester, 'No gateway');
      await typeIpv4(tester, 'static-route-dest-ip', '10.20.0.0');
      await typeIpv4(tester, 'static-route-subnet-mask', '255.255.0.0');

      expect(submit(tester).onTap, isNull);
    }, variant: onDesktop);

    testWidgets('a valid route can be submitted', (tester) async {
      await pumpPage(tester, dataState(const [route1, route2]));
      await openAdd(tester);

      await fillRoute(tester, name: 'Lab');

      expect(nameError(tester), isNull);
      expect(submit(tester).onTap, isNotNull);
    }, variant: onDesktop);
  });

  group('the edit dialog', () {
    // Saving a route unchanged must not report it sharing a name with itself.
    testWidgets('a route unchanged can be saved', (tester) async {
      await pumpPage(tester, dataState(const [route2]));
      await tester.tap(find.byWidgetPredicate((w) =>
          w is AppIconButton &&
          w.identifier == 'static-route-edit-guest-network'));
      await settle(tester);

      expect(submit(tester).onTap, isNotNull);
    });
  });

  // A refused save shows FW's own reason, through the same mapper the dialog
  // uses for the same check.
  group('the message for each FW error name', () {
    testWidgets('is the matching check message, never the fallback',
        (tester) async {
      late BuildContext context;
      await tester.pumpWidget(MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(builder: (c) {
          context = c;
          return const SizedBox();
        }),
      ));

      final messages = {
        for (final name in StaticRouteRefusalNames.all)
          name: localizeStaticRoutingError(context, name),
      };
      expect(messages, {
        StaticRouteRefusalNames.tooManyEntries:
            'Maximum number of rules reached',
        StaticRouteRefusalNames.invalidIpAddress:
            'Reserved IP address is not allowed',
        StaticRouteRefusalNames.invalidNetworkPrefixLength: 'Invalid input',
        StaticRouteRefusalNames.invalidGateway: 'Invalid gateway IP address',
        StaticRouteRefusalNames.duplicateEntryName:
            'Another rule already has this name',
      });
    });
  });
}
