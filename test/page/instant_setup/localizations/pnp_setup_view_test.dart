// ignore_for_file: invalid_use_of_protected_member

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import '../../../common/di.dart';
import '../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../mocks/pnp_notifier_mocks.dart' as Mock;
import 'package:privacy_gui/page/instant_setup/data/pnp_state.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../test_data/device_info_test_data.dart';

void main() async {
  late Mock.MockPnpNotifier mockPnpNotifier;
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockPnpNotifier = Mock.MockPnpNotifier();

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
    when(mockPnpNotifier.checkAdminPassword(null)).thenAnswer((_) {
      throw ExceptionInvalidAdminPassword();
    });
    when(mockPnpNotifier.fetchData()).thenAnswer((_) async {});
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

  testLocalizations('Instant Setup - PnP: Collecting data',
      (tester, locale) async {
    when(mockPnpNotifier.fetchData()).thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 5));
    });
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 6, centered: true),
          noNaviRail: true,
        ),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 1));
  });

  testLocalizations('Instant Setup - PnP: Personalize your wifi',
      (tester, locale) async {
    final view = testableSingleRoute(
      child: PnpSetupView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      locale: locale,
      overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
    );
    await tester.pumpWidget(view);
    await tester.pump(const Duration(seconds: 3));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Personalize your wifi (split SSID)',
      (tester, locale) async {
    when(mockPnpNotifier.getDefaultWiFiSettings()).thenReturn(
      const PnpWiFiSettings(
        isSplitMode: true,
        radios: [
          PnpWiFiRadio(
            radioId: 'RADIO_2.4GHz',
            band: 'RADIO_2.4GHz',
            ssid: 'DULinksys12294-2.4GHz',
            password: 'Linksys123456@',
            security: 'WPA2/WPA3-Mixed-Personal',
            isEnabled: true,
          ),
          PnpWiFiRadio(
            radioId: 'RADIO_5GHz',
            band: 'RADIO_5GHz',
            ssid: 'DULinksys12294-5GHz',
            password: 'Linksys567890@',
            security: 'WPA2/WPA3-Mixed-Personal',
            isEnabled: true,
          ),
          PnpWiFiRadio(
            radioId: 'RADIO_6GHz',
            band: 'RADIO_6GHz',
            ssid: 'DULinksys12294-6GHz',
            password: 'Linksys135790@',
            security: 'WPA3-Personal',
            isEnabled: true,
          ),
        ],
      ),
    );
    final view = testableSingleRoute(
      child: PnpSetupView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 6, centered: true),
        noNaviRail: true,
      ),
      locale: locale,
      overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
    );
    await tester.pumpWidget(view);
    await tester.pump(const Duration(seconds: 3));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
  });

  testLocalizations('Instant Setup - PnP: Personalize your wifi and tap info',
      (tester, locale) async {
    when(mockPnpNotifier.fetchData()).thenAnswer((_) async {
      await Future.delayed(Duration(seconds: 5));
    });
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    when(mockPnpNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    when(mockPnpNotifier.build()).thenReturn(PnpState(
      deviceInfo: NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
      isUnconfigured: true,
      stepStateList: const {
        0: PnpStepState(status: StepViewStatus.data, data: {}),
        1: PnpStepState(status: StepViewStatus.data, data: {}),
        2: PnpStepState(status: StepViewStatus.data, data: {}),
        3: PnpStepState(status: StepViewStatus.data, data: {}),
      },
    ));
    when(mockPnpNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
    });
    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    when(mockPnpNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    final mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    when(mockPnpNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });
    when(mockFirmwareUpdateNotifier.getAvailableUpdateNumber()).thenReturn(1);

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [
          pnpProvider.overrideWith(() => mockPnpNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        ],
      ),
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
    when(mockPnpNotifier.build()).thenReturn(PnpState(
      deviceInfo: NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
      isUnconfigured: false,
      isPrePaired: true,
      stepStateList: const {
        0: PnpStepState(
          status: StepViewStatus.data,
          data: {"ssid": "Linksys03056", "password": "8kRnxa257@"},
        ),
        1: PnpStepState(status: StepViewStatus.data, data: {}),
        2: PnpStepState(status: StepViewStatus.data, data: {}),
      },
    ));

    when(mockPnpNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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

  testLocalizations('Instant Setup - PnP: Wifi ready (split SSID)',
      (tester, locale) async {
    when(mockPnpNotifier.build()).thenReturn(PnpState(
      deviceInfo: NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
      isUnconfigured: false,
      isPrePaired: true,
      stepStateList: const {
        0: PnpStepState(
          status: StepViewStatus.data,
          data: {
            "isSplitMode": true,
            "perBandSettings": {
              "2.4GHz": {
                "ssid": "DULinksys12294-2.4GHz",
                "password": "8kRnxa257@"
              },
              "5GHz": {"ssid": "DULinksys12294-5GHz", "password": "8kRnxa257@"},
              "6GHz": {"ssid": "DULinksys12294-6GHz", "password": "8kRnxa257@"},
            },
            "ssid": "DULinksys12294-2.4GHz",
            "password": "8kRnxa257@",
          },
        ),
        1: PnpStepState(status: StepViewStatus.data, data: {}),
        2: PnpStepState(status: StepViewStatus.data, data: {}),
      },
    ));

    when(mockPnpNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 3));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
    );
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
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
    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: true,
        stepStateList: const {
          0: PnpStepState(status: StepViewStatus.data, data: {}),
          1: PnpStepState(status: StepViewStatus.data, data: {}),
          2: PnpStepState(status: StepViewStatus.data, data: {}),
          3: PnpStepState(status: StepViewStatus.data, data: {}),
        }));
    when(mockPnpNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      throw ExceptionNeedToReconnect();
    });
    when(mockPnpNotifier.fetchDevices()).thenAnswer((_) async {});

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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

  testLocalizations('Instant Setup - PnP: Auto Master running before save',
      (tester, locale) async {
    // First call returns idle (for initState), subsequent calls return running (for save)
    var callCount = 0;
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? AutoMasterStatus.idle : AutoMasterStatus.running;
    });
    // Use Stream.value for immediate emit to avoid pending timer
    when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) {
      return Stream.value(AutoMasterStatus.running);
    });
    when(mockPnpNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 2));
    });

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    await tester.pump(const Duration(seconds: 2));
  });

  testLocalizations('Instant Setup - PnP: Auto Master connection error',
      (tester, locale) async {
    // First call returns idle (for initState), subsequent calls return running (for save)
    var callCount = 0;
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? AutoMasterStatus.idle : AutoMasterStatus.running;
    });
    // Return null to simulate connection failure during polling (3 consecutive failures)
    when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) {
      return Stream<AutoMasterStatus?>.fromIterable([null, null, null]);
    });

    await tester.pumpWidget(
      testableSingleRoute(
        child: const PnpSetupView(),
        config: LinksysRouteConfig(
            column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
        locale: locale,
        overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
      ),
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
    await tester.pump(const Duration(seconds: 2));
  });
}
