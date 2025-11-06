// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_ui_models.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_step_state.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/test_helper.dart';
import '../../../common/test_responsive_widget.dart';

void main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();

    when(testHelper.mockServiceHelper.isSupportGuestNetwork(any)).thenReturn(true);
    when(testHelper.mockServiceHelper.isSupportLedMode(any)).thenReturn(true);

    when(testHelper.mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
        isUnconfigured: false,
        stepStateList: const {
          PnpStepId.personalWifi:
              PnpStepState(status: StepViewStatus.data, data: {}),
          PnpStepId.guestWifi:
              PnpStepState(status: StepViewStatus.data, data: {}),
          PnpStepId.nightMode:
              PnpStepState(status: StepViewStatus.data, data: {}),
        }));
    when(testHelper.mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {});
    when(testHelper.mockPnpNotifier.getDefaultWiFiNameAndPassphrase()).thenReturn(( 
      name: 'Linksys1234567',
      password: 'Linksys123456@',
      security: 'WPA2/WPA3-Mixed-Personal'
    ));
    when(testHelper.mockPnpNotifier.getDefaultGuestWiFiNameAndPassPhrase()).thenReturn(( 
      name: 'Guest-Linksys1234567',
      password: 'GuestLinksys123456@',
    ));
  });

  testLocalizations('Instant Setup - PnP: Collecting data',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 5));
    });
    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Personalize your wifi',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: PnpSetupView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 3));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Personalize your wifi and tap info',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.fetchDeviceInfo()).thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 5));
    });
    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final btnFinder = find.byIcon(LinksysIcons.infoCircle);
    await tester.tap(btnFinder.last);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Guest wifi disabled',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Guest wifi enabled',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));

    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle();
    final toggleFinder = find.byType(AppSwitch);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Night mode disabled',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle();
    final btnFinder2 = find.byType(FilledButton);
    await tester.tap(btnFinder2.first);
    await tester.pumpAndSettle();
  });
  testLocalizations('Instant Setup - PnP: Night mode enabled',
      (tester, locale) async {
    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle();
    final btnFinder2 = find.byType(FilledButton);
    await tester.tap(btnFinder2.first);
    await tester.pumpAndSettle();
    final toggleFinder = find.byType(AppSwitch);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Saving changes',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.savePnpSettings()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
    });

    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle(); // Guest Wifi
    final btnFinder2 = find.byType(FilledButton);
    await tester.tap(btnFinder2.first);
    await tester.pumpAndSettle(); // Night mode
    final btnFinder3 = find.byType(FilledButton);
    await tester.tap(btnFinder3.first);
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Your network',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(PnpState(
      deviceInfo: PnpDeviceInfoUIModel(
        modelName: 'LN16',
        image: 'routerLn16',
        serialNumber: 'serialNumber',
        firmwareVersion: 'firmwareVersion',
      ),
      isUnconfigured: true,
      stepStateList: const {
        PnpStepId.personalWifi:
            PnpStepState(status: StepViewStatus.data, data: {}),
        PnpStepId.guestWifi:
            PnpStepState(status: StepViewStatus.data, data: {}),
        PnpStepId.nightMode:
            PnpStepState(status: StepViewStatus.data, data: {}),
        PnpStepId.yourNetwork:
            PnpStepState(status: StepViewStatus.data, data: {}),
      },
    ));
    when(testHelper.mockPnpNotifier.savePnpSettings()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
    });
    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle(); // Guest Wifi
    final btnFinder2 = find.byType(FilledButton);
    await tester.tap(btnFinder2.first);
    await tester.pumpAndSettle(); // Night mode
    final btnFinder3 = find.byType(FilledButton);
    await tester.tap(btnFinder3.first);
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Saved', (tester, locale) async {
    when(testHelper.mockPnpNotifier.savePnpSettings()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle();
    final btnFinder2 = find.byType(FilledButton);
    await tester.tap(btnFinder2.first);
    await tester.pumpAndSettle();
    final toggleFinder = find.byType(AppSwitch);
    await tester.tap(toggleFinder);
    await tester.pumpAndSettle();
    final btnFinder3 = find.byType(FilledButton);
    await tester.tap(btnFinder3.first);
    await tester.pump(const Duration(seconds: 3));
  });

  testLocalizations('Instant Setup - PnP: Check and update firmware version',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.savePnpSettings()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });
    when(testHelper.mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);

    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
      overrides: [
        firmwareUpdateProvider.overrideWith(() => testHelper.mockFirmwareUpdateNotifier),
      ],
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle();
    final btnFinder2 = find.byType(FilledButton);
    await tester.tap(btnFinder2.first);
    await tester.pumpAndSettle();
    final btnFinder3 = find.byType(FilledButton);
    await tester.tap(btnFinder3.first);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
  });

  testLocalizations('Instant Setup - PnP: Wifi ready', (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(PnpState(
      deviceInfo: PnpDeviceInfoUIModel(
        modelName: 'LN16',
        image: 'routerLn16',
        serialNumber: 'serialNumber',
        firmwareVersion: 'firmwareVersion',
      ),
      isUnconfigured: false,
      stepStateList: const {
        PnpStepId.personalWifi: PnpStepState(
          status: StepViewStatus.data,
          data: {"ssid": "Linksys03056", "password": "8kRnxa257@"},
        ),
        PnpStepId.guestWifi:
            PnpStepState(status: StepViewStatus.data, data: {}),
        PnpStepId.nightMode:
            PnpStepState(status: StepViewStatus.data, data: {}),
      },
    ));

    when(testHelper.mockPnpNotifier.savePnpSettings()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle();
    final btnFinder2 = find.byType(FilledButton);
    await tester.tap(btnFinder2.first);
    await tester.pumpAndSettle();
    final btnFinder3 = find.byType(FilledButton);
    await tester.tap(btnFinder3.first);
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 3));
  });

  testLocalizations('Instant Setup - PnP: Reconnect to your router wifi',
      (tester, locale) async {
    when(testHelper.mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo: PnpDeviceInfoUIModel(
          modelName: 'LN16',
          image: 'routerLn16',
          serialNumber: 'serialNumber',
          firmwareVersion: 'firmwareVersion',
        ),
        isUnconfigured: true,
        stepStateList: const {
          PnpStepId.personalWifi:
              PnpStepState(status: StepViewStatus.data, data: {}),
          PnpStepId.guestWifi:
              PnpStepState(status: StepViewStatus.data, data: {}),
          PnpStepId.nightMode:
              PnpStepState(status: StepViewStatus.data, data: {}),
          PnpStepId.yourNetwork:
              PnpStepState(status: StepViewStatus.data, data: {}),
        }));
    when(testHelper.mockPnpNotifier.savePnpSettings()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      throw ExceptionNeedToReconnect();
    });
    when(testHelper.mockPnpNotifier.fetchDevices()).thenAnswer((_) async {});

    await testHelper.pumpView(
      tester,
      child: const PnpSetupView(),
      config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
      locale: locale,
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    final ssidEditFinder = find.byType(TextField).first;
    final passwordEditFinder = find.byType(TextField).last;
    await tester.enterText(ssidEditFinder, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(passwordEditFinder, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    final btnFinder = find.byType(FilledButton);
    await tester.tap(btnFinder.first);
    await tester.pumpAndSettle();
    final btnFinder2 = find.byType(FilledButton);
    await tester.tap(btnFinder2.first);
    await tester.pumpAndSettle();
    final btnFinder3 = find.byType(FilledButton);
    await tester.tap(btnFinder3.first);
    await tester.pump(const Duration(seconds: 1));
  });
}