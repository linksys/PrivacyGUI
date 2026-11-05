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
import 'package:privacy_gui/page/wifi_settings/views/widgets/wifi_qr_warning_card.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
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

  // Pumps the setup flow at [size] until the personalization step shows.
  Future<void> pumpPersonalizeStep(WidgetTester tester, Size size) async {
    await tester.binding.setSurfaceSize(size);
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.binding.setSurfaceSize(null));
    addTearDown(tester.view.reset);
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
    tester
        .state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView))
        .setState(() {});
    await tester.pumpAndSettle();
  }

  final ssidField = find.descendant(
    of: find.byType(WiFiSSIDField),
    matching: find.byType(TextField),
  );

  // The defaults info modal holds six paragraphs, so it cannot be a plain
  // Column: on a short viewport, or in a locale with longer copy, the body
  // must scroll instead of overflowing.
  testWidgets('defaults info modal body scrolls instead of overflowing',
      (tester) async {
    // 420px tall leaves the six paragraphs no chance of fitting - an
    // unscrollable body fails here with a RenderFlex overflow.
    await pumpPersonalizeStep(tester, const Size(1280, 420));

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
    await pumpPersonalizeStep(tester, const Size(1280, 1200));

    final reminder = find.textContaining('Keep in mind');
    final warning = find.textContaining('will stop the QR codes');

    // Untouched defaults - plain reminder only.
    expect(reminder, findsOneWidget);
    expect(warning, findsNothing);

    await tester.enterText(ssidField, 'MyHomeWiFi');
    await tester.pumpAndSettle();
    expect(warning, findsOneWidget);
    expect(reminder, findsNothing);

    // Typing the shipped SSID back takes the warning away again.
    await tester.enterText(ssidField, 'Linksys1234567');
    await tester.pumpAndSettle();
    expect(warning, findsNothing);
    expect(reminder, findsOneWidget);
  });

  // The warning is about the printed QR codes, so its info button explains
  // those - in the same words WiFi Settings uses for the same warning.
  testWidgets('the QR warning explains the printed QR codes', (tester) async {
    await pumpPersonalizeStep(tester, const Size(1280, 1200));

    await tester.enterText(ssidField, 'MyHomeWiFi');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(WiFiQRWarningCard),
      matching: find.byIcon(LinksysIcons.infoCircle),
    ));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('About the printed QR codes'),
      ),
      findsOneWidget,
    );
  });
}
