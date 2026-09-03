// ignore_for_file: invalid_use_of_protected_member

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_master_status.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:privacy_gui/page/instant_setup/pnp_setup_view.dart';
import 'package:privacy_gui/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart';
import 'package:privacy_gui/page/instant_setup/widgets/wifi_ssid_widget.dart';
import 'package:privacy_gui/route/constants.dart';
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

/// A stub destination for `RouteNamed.pnp` so the back-to-PnP paths can
/// navigate inside the single-route test harness (which otherwise only knows
/// the '/' route and throws "unknown route name").
///
/// Every abandoned-save path in this view lands here — a credential rotation
/// mid-setup, and a 401 from the write itself. Not `localLoginPassword`: that
/// page belongs to a setup that finished
/// (`userAcknowledgedAutoConfiguration == true`), and none of these did.
LinksysRoute _pnpStubRoute() => LinksysRoute(
      name: RouteNamed.pnp,
      path: RoutePath.pnp,
      config: const LinksysRouteConfig(noNaviRail: true),
      builder: (context, state) => const SizedBox.shrink(key: Key('pnpStub')),
    );

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

  testLocalizations(
      'Instant Setup - PnP: Personalize your wifi (edited, QR warning)',
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
    // Editing the shipped SSID is what escalates the reminder into the warning
    // that the printed QR codes will stop working.
    await tester.enterText(
      find.descendant(
        of: find.byType(WiFiSSIDField),
        matching: find.byType(TextField),
      ),
      'MyHomeWiFi',
    );
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

  // Named "before save" like its sibling above, and not just "connection
  // error": the golden filename is derived from this description alone, and
  // pnp_admin_view_test.dart has its own connection-error screenshot in the
  // same goldens/ directory. Two tests sharing a description quietly overwrite
  // each other's screenshot, and whichever runs second fails the comparison.
  testLocalizations(
      'Instant Setup - PnP: Auto Master connection error before save',
      (tester, locale) async {
    // First call returns idle (for initState), subsequent calls return running (for save)
    var callCount = 0;
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? AutoMasterStatus.idle : AutoMasterStatus.running;
    });
    // Nulls alone no longer condemn the connection — the poll runs its whole
    // budget and only then does the reachability test decide. Spend the budget
    // (stream ends with no terminal status) and fail that test, which is what
    // actually renders this view.
    when(mockPnpNotifier.pollAutoMasterStatus()).thenAnswer((_) {
      return Stream<AutoMasterStatus?>.fromIterable([null, null, null]);
    });
    when(mockPnpNotifier.testConnectionReconnected())
        .thenAnswer((_) async => throw ExceptionNeedToReconnect());

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

  // ---------------------------------------------------------------------------
  // `_saveChanges` Auto Master "second defense" — behavior/flow tests.
  //
  // The golden tests above capture pixels; these assert on the actual save-time
  // decisions the #1180 fix hinges on. `_saveChanges` re-checks Auto Master
  // right before writing settings, because make-Master can rotate the admin
  // credential during the (potentially long) WiFi-config step:
  //   - pre-check 401                     -> go to login (session already dead)
  //   - status == running                 -> park on the waiting view and poll
  //   - poll -> complete/idle             -> go to login (credential rotated)
  //   - poll -> failed (found a Master)   -> credential intact, continue to save
  //   - idle on entry but complete now    -> go to login (rotated during config)
  //
  // These are pure flow/checkpoint tests (route stubs + the waiting view, not
  // pixels), so they use plain `testWidgets` — no golden image is meaningful,
  // matching the sibling pnp_auto_master_flow_test.dart.
  // ---------------------------------------------------------------------------

  // Gives the stepper + WiFi form room so nothing overflows the default surface.
  void useLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1440, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  // checkAutoMasterStatus is called once in initState (record-on-entry) and
  // again at the top of _saveChanges. Return [entry] on the first call and
  // [duringSave] on every later call, so a test keeps initState benign while
  // forcing the save-time branch under test.
  void stubCheckAutoMaster({
    required AutoMasterStatus? entry,
    required AutoMasterStatus? duringSave,
  }) {
    var callCount = 0;
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      callCount++;
      return callCount == 1 ? entry : duringSave;
    });
  }

  Future<void> pumpSetup(
    WidgetTester tester, {
    List<RouteBase> extraRoutes = const [],
  }) =>
      tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
              column: ColumnGrid(column: 6, centered: true), noNaviRail: true),
          child: const PnpSetupView(),
          overrides: [pnpProvider.overrideWith(() => mockPnpNotifier)],
          extraRoutes: extraRoutes,
        ),
      );

  // Drives the configured+prePaired stepper (Personal -> Guest -> NightMode) to
  // its last step, whose "Next" fires onLastStep = _saveChanges. Mirrors the
  // golden tests' tap sequence. The caller pumps the Auto Master flow that
  // follows (which may park on the waiting spinner), so this deliberately does
  // NOT settle after the final tap.
  Future<void> driveToSave(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 6));
    // Trick - setState to trigger build (same as the golden tests).
    final state =
        tester.state<ConsumerState<PnpSetupView>>(find.byType(PnpSetupView));
    state.setState(() {});
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'MyAwesomeWiFiName');
    await tester.pumpAndSettle();
    await tester.enterText(
        find.byType(TextField).last, 'MyAwesomeWiFiPassword!');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first); // Personal -> Guest
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first); // Guest -> NightMode
    await tester.pumpAndSettle();
    await tester.tap(find.byType(FilledButton).first); // NightMode -> save
  }

  // running: make-Master is still electing when the user reaches save. The flow
  // must park on the waiting view and NOT write settings (save) yet. The poll
  // stream stays open (never emits) so it parks without a pending timer.
  testWidgets(
      'Instant Setup - PnP: Auto Master running before save stays on waiting view',
      (tester) async {
    useLargeScreen(tester);
    stubCheckAutoMaster(
        entry: AutoMasterStatus.idle, duringSave: AutoMasterStatus.running);
    // Deliberately leave this controller open (no tearDown close): the flow is
    // meant to park on the waiting view with the poll `await for` still pending.
    // Closing it would end the loop and drive the (un-mounted-after-teardown)
    // timeout branch, which setStates without a mounted guard -> crash. An open
    // StreamController is fine in a widget test (unlike a dangling Timer).
    final poll = StreamController<AutoMasterStatus?>();
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => poll.stream);

    await pumpSetup(tester);
    await driveToSave(tester);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(PnpAutoMasterWaitingView), findsOneWidget);
    verifyNever(mockPnpNotifier.save());
  });

  // running -> poll resolves complete: make-Master finished and rotated the
  // admin password. The GUI session is dead, so save must NOT be attempted;
  // go back to PnP so its precheck can ask for the new password.
  testWidgets(
      'Instant Setup - PnP: Auto Master poll complete before save redirects to pnp',
      (tester) async {
    useLargeScreen(tester);
    stubCheckAutoMaster(
        entry: AutoMasterStatus.idle, duringSave: AutoMasterStatus.running);
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => Stream.value(AutoMasterStatus.complete));

    await pumpSetup(tester, extraRoutes: [_pnpStubRoute()]);
    await driveToSave(tester);
    // Drain on the real event loop, as the sibling tests below do. The flow
    // leaves the poll by returning out of its `await for`, which cancels the
    // subscription — and the mock's Stream.value only settles that cancellation
    // on real event-loop turns, so pumping fake time alone never gets past it.
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('pnpStub')), findsOneWidget);
    verifyNever(mockPnpNotifier.save());
  });

  // running -> poll resolves failed: make-Master found another Master, so the
  // admin credential is intact. The flow must fall through and actually save.
  // save() is left pending so the whenComplete tail (which would schedule a
  // post-save timer) never runs; we only assert save was reached.
  testWidgets(
      'Instant Setup - PnP: Auto Master poll failed before save continues to save',
      (tester) async {
    useLargeScreen(tester);
    stubCheckAutoMaster(
        entry: AutoMasterStatus.idle, duringSave: AutoMasterStatus.running);
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => Stream.value(AutoMasterStatus.failed));
    final saveCompleter = Completer<void>();
    when(mockPnpNotifier.save()).thenAnswer((_) => saveCompleter.future);

    await pumpSetup(tester);
    await driveToSave(tester);
    // Drain the poll stream on the real event loop so the `failed` event is
    // delivered and the flow falls through to save(). We must NOT pumpAndSettle
    // here: the failed path calls setState(saving), whose _loadingSpinner runs
    // an endless AppSpinner animation that would time out pumpAndSettle.
    await tester.runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    verify(mockPnpNotifier.save()).called(1);
  });

  // Pre-save check undetermined (null): the router is unreachable, or its
  // firmware still requires auth for GetAutoMasterStatus and answers 401 to the
  // unauthed read. The gate cannot tell, so it must not block the user — the
  // save proceeds. If the credential really was rotated, the save itself 401s
  // and the ExceptionSavingChanges handler routes back to PnP.
  testWidgets(
      'Instant Setup - PnP: Auto Master status unavailable before save continues to save',
      (tester) async {
    useLargeScreen(tester);
    stubCheckAutoMaster(entry: AutoMasterStatus.idle, duringSave: null);
    // Left pending so the whenComplete tail (which schedules a post-save timer)
    // never runs; we only assert save was reached.
    final saveCompleter = Completer<void>();
    when(mockPnpNotifier.save()).thenAnswer((_) => saveCompleter.future);

    await pumpSetup(tester, extraRoutes: [_pnpStubRoute()]);
    await driveToSave(tester);
    // Not pumpAndSettle: setState(saving) starts an endless AppSpinner.
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 50)));
    await tester.pump();

    verify(mockPnpNotifier.save()).called(1);
    // null is not `running`, so there was nothing to poll or wait for.
    verifyNever(mockPnpNotifier.pollAutoMasterStatus());
    expect(find.byKey(const Key('pnpStub')), findsNothing);
  });

  // Edge case (idle on entry, complete now): Auto Master was idle when PnP
  // started but completed during the WiFi-config step, so it never showed as
  // running at save time. The entry-vs-current comparison must still catch the
  // credential rotation and go back to PnP. The entry status lives in PnpState
  // (the mock's setAutoMasterStatusOnEntry is a no-op), so seed build() with it.
  testWidgets(
      'Instant Setup - PnP: Auto Master idle on entry but complete during config redirects to pnp',
      (tester) async {
    useLargeScreen(tester);
    when(mockPnpNotifier.build()).thenReturn(PnpState(
        deviceInfo:
            NodeDeviceInfo.fromJson(jsonDecode(testDeviceInfo)['output']),
        isUnconfigured: false,
        isPrePaired: true,
        autoMasterStatusOnEntry: AutoMasterStatus.idle,
        stepStateList: const {
          0: PnpStepState(status: StepViewStatus.data, data: {}),
          1: PnpStepState(status: StepViewStatus.data, data: {}),
          2: PnpStepState(status: StepViewStatus.data, data: {}),
        }));
    stubCheckAutoMaster(
        entry: AutoMasterStatus.idle, duringSave: AutoMasterStatus.complete);

    await pumpSetup(tester, extraRoutes: [_pnpStubRoute()]);
    await driveToSave(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pnpStub')), findsOneWidget);
    verifyNever(mockPnpNotifier.save());
  });

  // save() itself 401s: Auto Master completed in the narrow window between the
  // pre-check and the write. The JNAP unauthorized error is unwrapped and the
  // user is routed to the pnp entry (re-login) rather than shown a raw error.
  testWidgets(
      'Instant Setup - PnP: Unauthorized during save redirects to pnp',
      (tester) async {
    useLargeScreen(tester);
    // Unconfigured so the save whenComplete tail takes the stepContinue branch
    // (no post-save 3s timer), keeping the test free of dangling timers.
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
    stubCheckAutoMaster(
        entry: AutoMasterStatus.idle, duringSave: AutoMasterStatus.idle);
    when(mockPnpNotifier.save()).thenAnswer((_) async {
      throw ExceptionSavingChanges(
          const JNAPError(result: errorJNAPUnauthorized));
    });

    await pumpSetup(tester, extraRoutes: [_pnpStubRoute()]);
    await driveToSave(tester);
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pnpStub')), findsOneWidget);
  });

  // ---------------------------------------------------------------------------
  // Budget-exhausted branch of `_saveChanges`. Reached when the poll stream ends
  // WITHOUT a terminal status — Auto Master neither finished (complete/idle) nor
  // gave up (failed) inside the poll's bounded budget. Nulls along the way are
  // NOT a trigger: the poll's own length is the only give-up rule, and only then
  // does testConnectionReconnected() decide.
  //
  //   - budget spent -> testConnectionReconnected() OK -> re-check from the top;
  //       on the second pass Auto Master has settled (idle), so the write goes
  //   - budget spent -> testConnectionReconnected() throws -> connection error
  //       view, never save (router unreachable)
  //   - still unresolved after _maxAutoMasterWaits (2) waits -> connection error
  //       view, never save
  //
  // This caller is the only one that re-checks rather than proceeding on
  // budgetExhausted: it has a save pending that a credential rotation would
  // break. The connection-error sub-view is identified by its wifi-off icon,
  // which only the error branch of PnpAutoMasterWaitingView renders.
  // ---------------------------------------------------------------------------

  // Poll ends on `running` (never a terminal status) -> budget spent. Reconnect
  // succeeds, so the flow re-checks; the status has settled to idle by then, so
  // it falls through and actually writes settings.
  testWidgets(
      'Instant Setup - PnP: Auto Master budget spent then reconnect re-checks and saves',
      (tester) async {
    useLargeScreen(tester);
    // initState -> idle; first save -> running (enters the poll); re-check ->
    // idle (Auto Master settled) so the write proceeds. stubCheckAutoMaster
    // can't express three distinct answers, so stub the call counter inline.
    var callCount = 0;
    when(mockPnpNotifier.checkAutoMasterStatus()).thenAnswer((_) async {
      callCount++;
      if (callCount == 1) return AutoMasterStatus.idle; // initState
      if (callCount == 2) return AutoMasterStatus.running; // first save
      return AutoMasterStatus.idle; // re-check
    });
    // Emits one running then completes -> the await-for ends without a terminal
    // status -> budget-spent branch.
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
    // testConnectionReconnected returns Future.value() (success) by default.
    // Leave save() pending so the whenComplete tail (and its post-save 3s timer)
    // never runs; we only assert save() was reached on the second pass.
    final saveCompleter = Completer<void>();
    when(mockPnpNotifier.save()).thenAnswer((_) => saveCompleter.future);

    await pumpSetup(tester);
    await driveToSave(tester);
    // Drain poll-end -> reconnect -> re-check -> save on the real event loop. No
    // pumpAndSettle: the second pass ends in setState(saving), whose endless
    // AppSpinner animation would time out pumpAndSettle.
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    verify(mockPnpNotifier.testConnectionReconnected()).called(1);
    verify(mockPnpNotifier.save()).called(1);
  });

  // Poll ends on `running` -> budget spent, but the router is unreachable
  // (testConnectionReconnected throws). The flow must surface the connection
  // error view and never write settings.
  testWidgets(
      'Instant Setup - PnP: Auto Master budget spent then reconnect fails shows connection error',
      (tester) async {
    useLargeScreen(tester);
    stubCheckAutoMaster(
        entry: AutoMasterStatus.idle, duringSave: AutoMasterStatus.running);
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
    when(mockPnpNotifier.testConnectionReconnected())
        .thenAnswer((_) async => throw ExceptionNeedToReconnect());

    await pumpSetup(tester);
    await driveToSave(tester);
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 100)));
    await tester.pump();

    // Connection-error sub-view (the wifi-off icon is unique to it).
    expect(find.byIcon(LinksysIcons.signalWifiOff), findsOneWidget);
    verifyNever(mockPnpNotifier.save());
  });

  // Every wait ends with the status still `running` while reconnect keeps
  // succeeding, so _saveChanges re-checks until autoMasterWaitsSpent reaches
  // _maxAutoMasterWaits (2) and gives up with the connection error view. Each
  // wait costs a full poll budget (~3 min), which is why the cap is this low.
  testWidgets(
      'Instant Setup - PnP: Auto Master unresolved after the wait limit shows connection error',
      (tester) async {
    useLargeScreen(tester);
    // idle on entry, running on every save-time check so each pass re-enters the
    // poll and spends another wait.
    stubCheckAutoMaster(
        entry: AutoMasterStatus.idle, duringSave: AutoMasterStatus.running);
    when(mockPnpNotifier.pollAutoMasterStatus())
        .thenAnswer((_) => Stream.value(AutoMasterStatus.running));
    // Reconnect succeeds each time, so the only thing that stops the recursion
    // is the wait limit.
    when(mockPnpNotifier.testConnectionReconnected()).thenAnswer((_) async {});

    await pumpSetup(tester);
    await driveToSave(tester);
    await tester
        .runAsync(() => Future.delayed(const Duration(milliseconds: 150)));
    await tester.pump();

    expect(find.byIcon(LinksysIcons.signalWifiOff), findsOneWidget);
    // One reconnect test per wait; the 2nd wait hits the limit and stops there.
    verify(mockPnpNotifier.testConnectionReconnected()).called(2);
    verifyNever(mockPnpNotifier.save());
  });
}
