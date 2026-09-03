// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import '../../common/di.dart';
import '../../common/testable_router.dart';
import '../../common/theme_data.dart';
import '../../mocks/pnp_notifier_mocks.dart' as mock;
import '../../test_data/device_info_test_data.dart';

void main() async {
  late mock.MockPnpNotifier mockPnpNotifier;
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockPnpNotifier = mock.MockPnpNotifier();
    when(mockServiceHelper.isSupportGuestNetwork(any)).thenReturn(true);
    when(mockServiceHelper.isSupportLedMode(any)).thenReturn(true);
    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: false,
        isPrePaired: true,
        stepStateList: const {
          0: PnpStepState(status: StepViewStatus.data, data: {}),
          1: PnpStepState(status: StepViewStatus.data, data: {}),
          2: PnpStepState(status: StepViewStatus.data, data: {}),
        }));
    when(mockPnpNotifier.fetchData()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 5));
    });
    when(mockPnpNotifier.getDefaultWiFiSettings()).thenReturn(
      const PnpWiFiSettings(
        isSplitMode: false,
        radios: [
          PnpWiFiRadio(
            radioId: 'RADIO_2.4GHz',
            band: 'RADIO_2.4GHz',
            ssid: 'Linksys1234567',
            password: 'Linksys123456@',
            security: 'WPA2/WPA3-Mixed-Personal',
            isEnabled: true,
          ),
        ],
      ),
    );
    when(mockPnpNotifier.getDefaultGuestWiFiNameAndPassPhrase()).thenReturn((
      name: 'Guest-Linksys1234567',
      password: 'GuestLinksys123456@',
    ));
  });

  // The defaults info modal holds six paragraphs, so it cannot be a plain
  // Column: on a short viewport, or in a locale with longer copy, the body
  // must scroll instead of overflowing.
  testWidgets('defaults info modal body scrolls instead of overflowing',
      (tester) async {
    // 420px tall leaves the six paragraphs no chance of fitting - an
    // unscrollable body fails here with a RenderFlex overflow.
    await tester.binding.setSurfaceSize(const Size(1280, 420));
    tester.view.physicalSize = const Size(1280, 420);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await loadTestFonts();

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: const Locale('en'),
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();

    final infoIcon = find.byIcon(LinksysIcons.infoCircle).last;
    await tester.ensureVisible(infoIcon);
    await tester.pumpAndSettle();
    await tester.tap(infoIcon);
    await tester.pumpAndSettle();

    expect(find.byType(AlertDialog), findsOneWidget);
    final scrollable = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(Scrollable),
    );
    expect(scrollable, findsOneWidget);

    // The title and the Close action sit outside the scroll view, so they stay
    // reachable no matter how long the body gets.
    expect(find.text('Personalize your WiFi name and password'), findsWidgets);
    expect(find.textContaining('Close'), findsWidgets);

    // The last paragraph starts off-screen and scrolling reaches it.
    final lastParagraph = find.textContaining('factory reset your router');
    await tester.scrollUntilVisible(lastParagraph, 300, scrollable: scrollable);
    await tester.pumpAndSettle();
    expect(lastParagraph, findsOneWidget);
  });

  // The QR warning must track the fields, not the visit: keeping the shipped
  // credentials changes nothing, so warning about the printed QR codes would be
  // wrong until something is actually edited.
  testWidgets('QR warning follows edits to the shipped WiFi credentials',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1200));
    tester.view.physicalSize = const Size(1280, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() async {
      await tester.binding.setSurfaceSize(null);
    });
    await loadTestFonts();

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: const Locale('en'),
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();

    final reminder = find.textContaining("what's printed on the Quick Start");
    final warning = find.textContaining('will stop the QR codes');
    final ssidField = find.descendant(
      of: find.byType(WiFiSSIDField),
      matching: find.byType(TextField),
    );

    // Untouched defaults - plain reminder only.
    expect(reminder, findsOneWidget);
    expect(warning, findsNothing);

    await tester.enterText(ssidField, 'MyHomeWiFi');
    await tester.pumpAndSettle();
    expect(warning, findsOneWidget);
    expect(reminder, findsNothing);
    // The defaults modal stays reachable from the warning card.
    expect(
      find.descendant(
        of: find.byType(AppSettingCard),
        matching: find.byIcon(LinksysIcons.infoCircle),
      ),
      findsOneWidget,
    );

    // Typing the shipped SSID back takes the warning away again.
    await tester.enterText(ssidField, 'Linksys1234567');
    await tester.pumpAndSettle();
    expect(warning, findsNothing);
    expect(reminder, findsOneWidget);
  });
}
