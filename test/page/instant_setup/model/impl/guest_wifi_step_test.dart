// The guest WiFi step, through the PnP setup page that lays it out, with the
// real PnpNotifier over a RouterBoundary: what the step offers, when it lets
// the user on, and what PnP saves from it (#1921: what PnP saves from a step,
// not the keys of its map).

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_password_widget.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/di.dart';
import '../../../../common/router_boundary.dart';
import '../../data/pnp_router_data.dart';
import 'pnp_setup_harness.dart';

void main() {
  mockDependencyRegister();
  final services = getIt.get<ServiceHelper>();

  late RouterBoundary router;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    // A router with guest WiFi and no night mode, auto-parented: setup asks
    // for the WiFi, then the guest WiFi, which saves, then lists the nodes.
    when(services.isSupportGuestNetwork(any)).thenReturn(true);
    when(services.isSupportLedMode(any)).thenReturn(false);
    router = RouterBoundary()
      ..refuses(JNAPAction.getAutoMasterStatus)
      ..holds(JNAPAction.getDevices, {
        'revision': 1,
        'devices': [pnpDevice('router', nodeType: 'Master')],
      });
    holdPnpReads(router,
        autoConfiguration: pnpAutoConfiguration(method: 'AutoParent'));
  });

  final guestSwitch = find.byType(AppSwitch);
  final nameField = find.descendant(
      of: find.byType(WiFiSSIDField), matching: find.byType(TextField));
  final passwordField = find.descendant(
      of: find.byType(WiFiPasswordField), matching: find.byType(TextField));

  /// Opens setup and moves past the WiFi step to the guest WiFi step.
  Future<void> openGuestStep(WidgetTester tester) async {
    await openPnpSetup(tester, router: router, pnp: ArrivedPnp());
    await tester.tap(nextButton('Next'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Turn on guest network'), findsOneWidget);
  }

  testWidgets('starts with guest WiFi off, and lets the user on',
      (tester) async {
    await openGuestStep(tester);

    expect(tester.widget<AppSwitch>(guestSwitch).value, isFalse);
    expect(nameField, findsNothing);
    expect(canTap(tester, 'Next'), isTrue);
  });

  testWidgets('turned on, offers the router\'s guest name and password',
      (tester) async {
    await openGuestStep(tester);

    await tester.tap(guestSwitch);
    await tester.pumpAndSettle();

    expect(tester.widget<TextField>(nameField).controller?.text,
        'Linksys00042-guest');
    expect(
        tester.widget<TextField>(passwordField).controller?.text, 'BeMyGuest');
  });

  testWidgets('holds the user back on a guest password under 8 characters',
      (tester) async {
    await openGuestStep(tester);
    await tester.tap(guestSwitch);
    await tester.pumpAndSettle();

    await tester.enterText(passwordField, 'short');
    await tester.pumpAndSettle();

    expect(canTap(tester, 'Next'), isFalse);

    await tester.enterText(passwordField, 'GuestPass1');
    await tester.pumpAndSettle();

    expect(canTap(tester, 'Next'), isTrue);
  });

  testWidgets('holds the user back on an empty guest name', (tester) async {
    await openGuestStep(tester);
    await tester.tap(guestSwitch);
    await tester.pumpAndSettle();

    await tester.enterText(nameField, '');
    await tester.pumpAndSettle();

    expect(canTap(tester, 'Next'), isFalse);
  });

  testWidgets('saves guest WiFi on, with the name and password typed',
      (tester) async {
    await openGuestStep(tester);
    await tester.tap(guestSwitch);
    await tester.pumpAndSettle();
    await tester.enterText(nameField, 'MyGuest');
    await tester.enterText(passwordField, 'GuestPass1');
    await tester.pumpAndSettle();

    await tapAndSave(tester, 'Next');

    final saved = router.payloadsOf(JNAPAction.setGuestRadioSettings).single;
    expect(saved['isGuestNetworkEnabled'], isTrue);
    expect(
        (saved['radios'] as List)
            .map((radio) => (radio['guestSSID'], radio['guestWPAPassphrase'])),
        everyElement(('MyGuest', 'GuestPass1')));
  });

  testWidgets('saves guest WiFi off when the user leaves it off',
      (tester) async {
    await openGuestStep(tester);

    await tapAndSave(tester, 'Next');

    expect(
        router
            .payloadsOf(JNAPAction.setGuestRadioSettings)
            .single['isGuestNetworkEnabled'],
        isFalse);
  });

  testWidgets('saves it off when the user turns it on and off again',
      (tester) async {
    await openGuestStep(tester);
    await tester.tap(guestSwitch);
    await tester.pumpAndSettle();
    await tester.tap(guestSwitch);
    await tester.pumpAndSettle();

    await tapAndSave(tester, 'Next');

    expect(
        router
            .payloadsOf(JNAPAction.setGuestRadioSettings)
            .single['isGuestNetworkEnabled'],
        isFalse);
  });
}
