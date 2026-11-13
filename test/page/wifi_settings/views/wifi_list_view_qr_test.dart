import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/page/components/widgets/wifi_qr/wifi_qr_warning_card.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_view_provider.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../common/_index.dart';
import '../../../common/di.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/polling_notifier_mocks.dart';
import '../../../mocks/wifi_view_notifier_mocks.dart';
import '../../../test_data/_index.dart';

void main() {
  late MockWiFiViewNotifier mockWiFiViewNotifier;
  late MockWifiListNotifier mockWiFiListNotifier;
  late MockWifiAdvancedSettingsNotifier mockWiFiAdvancedSettingsNotifier;
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;
  late MockPollingNotifier mockPollingNotifier;

  // What the router broadcasts today: 2.4 GHz and 5 GHz share one name,
  // password and WPA2/WPA3 mixed security.
  final saved = WiFiState.fromMap(wifiListTestState);
  final warning = find.textContaining('will stop the QR codes');
  final newQRDialog = find.textContaining('Your new WiFi QR code');
  Finder inDialog(Finder matching) =>
      find.descendant(of: find.byType(AlertDialog), matching: matching);
  Finder dialogButton(String label) =>
      inDialog(find.widgetWithText(AppTextButton, label));

  mockDependencyRegister();

  setUp(() {
    mockWiFiViewNotifier = MockWiFiViewNotifier();
    mockWiFiListNotifier = MockWifiListNotifier();
    mockWiFiAdvancedSettingsNotifier = MockWifiAdvancedSettingsNotifier();
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    mockPollingNotifier = MockPollingNotifier();

    when(mockWiFiViewNotifier.build()).thenReturn(WiFiViewState());
    when(mockWiFiAdvancedSettingsNotifier.build()).thenReturn(
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockWiFiAdvancedSettingsNotifier.fetch(any)).thenAnswer((_) async =>
        WifiAdvancedSettingsState.fromMap(wifiAdvancedSettingsTestState));
    when(mockInstantPrivacyNotifier.build())
        .thenReturn(InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockInstantPrivacyNotifier.fetch(fetchRemote: anyNamed('fetchRemote')))
        .thenAnswer(
            (_) async => InstantPrivacyState.fromMap(instantPrivacyTestState));
    when(mockPollingNotifier.build()).thenReturn(
        const CoreTransactionData(lastUpdate: 0, isReady: true, data: {}));
  });

  // [edited] is the state the user is editing, [broadcast] what the router
  // reports today - the view compares the two.
  Future<void> pumpWiFiList(
    WidgetTester tester, {
    required WiFiState edited,
    WiFiState? broadcast,
  }) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    // Real fonts, since some tests compare where cards end up on screen.
    await loadTestFonts();
    when(mockWiFiListNotifier.build()).thenReturn(edited);
    when(mockWiFiListNotifier.fetch())
        .thenAnswer((_) async => broadcast ?? saved);

    await tester.pumpWidget(testableSingleRoute(
      overrides: [
        wifiViewProvider.overrideWith(() => mockWiFiViewNotifier),
        wifiListProvider.overrideWith(() => mockWiFiListNotifier),
        wifiAdvancedProvider
            .overrideWith(() => mockWiFiAdvancedSettingsNotifier),
        instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
        dashboardManagerProvider.overrideWith(_RouterIsBack.new),
        pollingProvider.overrideWith(() => mockPollingNotifier),
      ],
      locale: const Locale('en'),
      child: const WiFiMainView(),
    ));
    await tester.pumpAndSettle();
  }

  // Taps Save, then [answer] on the save confirmation.
  Future<void> saveAndAnswer(WidgetTester tester, String answer) async {
    await tester.tap(find.byType(AppFilledButton));
    await tester.pumpAndSettle();
    expect(dialogButton(answer), findsOneWidget);
    await tester.tap(dialogButton(answer));
    await tester.pumpAndSettle();
  }

  WiFiState simple({WifiSecurityType? securityType, String? ssid}) =>
      saved.copyWith(
        isSimpleMode: true,
        simpleModeWifi: saved.simpleModeWifi
            .copyWith(securityType: securityType, ssid: ssid),
      );

  testWidgets('a security mode change warns about the printed QR codes',
      (tester) async {
    await pumpWiFiList(
      tester,
      edited: simple(securityType: WifiSecurityType.wpa3Personal),
    );

    expect(warning, findsOneWidget);
  });

  // Right under the page description, the warning is read before the Quick
  // Setup switch and the band settings it is about.
  testWidgets('the warning sits between the page description and Quick Setup',
      (tester) async {
    await pumpWiFiList(tester, edited: simple(ssid: 'MyNewWiFi'));

    expect(
      tester.getBottomLeft(find.textContaining('Easily customize')).dy,
      lessThanOrEqualTo(tester.getTopLeft(warning).dy),
    );
    expect(
      tester.getBottomLeft(warning).dy,
      lessThanOrEqualTo(tester.getTopLeft(find.text('Quick Setup')).dy),
    );
  });

  // The page description leads with an info icon, so the warning's button that
  // explains the printed QR codes is a help icon - the two must not look alike.
  testWidgets('the warning explains the printed QR codes from a help button',
      (tester) async {
    await pumpWiFiList(tester, edited: simple(ssid: 'MyNewWiFi'));

    await tester.tap(find.descendant(
      of: find.byType(WiFiQRWarningCard),
      matching: find.byIcon(LinksysIcons.help),
    ));
    await tester.pumpAndSettle();

    expect(inDialog(find.text('About the printed QR codes')), findsOneWidget);
  });

  // Simple mode takes its security mode from 2.4 GHz, so a 5 GHz band on a
  // different mode would read as a change the moment the page opens - while
  // there is nothing to save yet.
  testWidgets('an untouched page warns about nothing', (tester) async {
    final broadcast = saved.copyWith(
      isSimpleMode: true,
      mainWiFi: [
        saved.mainWiFi[0],
        saved.mainWiFi[1].copyWith(securityType: WifiSecurityType.wpa2Personal),
      ],
    );

    await pumpWiFiList(tester, edited: broadcast, broadcast: broadcast);

    expect(warning, findsNothing);
  });

  testWidgets('cancelling the save confirmation saves nothing', (tester) async {
    await pumpWiFiList(tester, edited: simple(ssid: 'MyNewWiFi'));

    await saveAndAnswer(tester, 'Cancel');

    verifyNever(mockWiFiListNotifier.save());
    expect(newQRDialog, findsNothing);
  });

  // The dialog ends a save the way setup ends: same scan hint, and where to
  // find the code again later.
  testWidgets('the new QR code says where to find it again', (tester) async {
    final renamed = simple(ssid: 'MyNewWiFi');
    await pumpWiFiList(tester, edited: renamed);
    when(mockWiFiListNotifier.save()).thenAnswer((_) async => renamed.copyWith(
          mainWiFi: [
            for (final radio in renamed.mainWiFi)
              radio.copyWith(ssid: 'MyNewWiFi'),
          ],
        ));

    await saveAndAnswer(tester, 'Ok');

    expect(inDialog(find.text('Scan QR code or use password to connect')),
        findsOneWidget);
    expect(inDialog(find.textContaining('from Share WiFi on your dashboard')),
        findsOneWidget);
  });

  // A save that drops the connection only lands once the router is back, so
  // the new QR code waits for that and shows what the router reports then.
  testWidgets('a save that needs the router back still ends on the new QR code',
      (tester) async {
    final renamed = simple(ssid: 'MyNewWiFi');
    await pumpWiFiList(tester, edited: renamed);
    // A real save takes a while before the connection drops; failing at once
    // would beat the spinner to listening for it.
    when(mockWiFiListNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 500));
      throw const JNAPSideEffectError();
    });
    when(mockWiFiListNotifier.fetch(true))
        .thenAnswer((_) async => renamed.copyWith(mainWiFi: [
              for (final radio in renamed.mainWiFi)
                radio.copyWith(ssid: 'MyNewWiFi'),
            ]));

    await saveAndAnswer(tester, 'Ok');
    expect(newQRDialog, findsNothing, reason: 'the router is not back yet');

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(newQRDialog, findsOneWidget);
    expect(inDialog(find.byType(QrImageView)), findsOneWidget);
  });

  // Switching to Open leaves name and password alone, yet the printed codes
  // ask phones for a password the network no longer takes.
  testWidgets(
      'saving a switch to Open ends on a new QR code with no password to copy',
      (tester) async {
    final open = simple(securityType: WifiSecurityType.open);
    await pumpWiFiList(tester, edited: open);
    when(mockWiFiListNotifier.save()).thenAnswer((_) async => open.copyWith(
          mainWiFi: [
            for (final radio in open.mainWiFi)
              radio.copyWith(securityType: WifiSecurityType.open),
          ],
        ));

    await saveAndAnswer(tester, 'Ok');

    expect(newQRDialog, findsOneWidget);
    expect(inDialog(find.byIcon(LinksysIcons.fileCopy)), findsNothing);
  });

  testWidgets('bands saved with different names each get their own QR code',
      (tester) async {
    final perBand = saved.copyWith(mainWiFi: [
      saved.mainWiFi[0].copyWith(ssid: 'Home-2.4'),
      saved.mainWiFi[1].copyWith(ssid: 'Home-5'),
    ]);
    await pumpWiFiList(tester, edited: perBand);
    when(mockWiFiListNotifier.save()).thenAnswer((_) async => perBand);

    await saveAndAnswer(tester, 'Ok');

    expect(inDialog(find.byType(QrImageView)), findsNWidgets(2));
  });
}

// The generated dashboard manager mock predates checkRouterIsBack, so it cannot
// stub it; this fake answers that the router is back.
class _RouterIsBack extends DashboardManagerNotifier {
  @override
  DashboardManagerState build() => const DashboardManagerState();

  @override
  Future<NodeDeviceInfo> checkRouterIsBack() async =>
      NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']);
}
