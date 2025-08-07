import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/dual/dual_wan_settngs_view.dart';
import 'package:privacy_gui/page/dual/models/balance_ratio.dart';
import 'package:privacy_gui/page/dual/models/mode.dart';
import 'package:privacy_gui/page/dual/providers/dual_wan_settings_provider.dart';
import 'package:privacy_gui/page/firmware_update/views/firmware_update_detail_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:get_it/get_it.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/dual_wan_settings_notifier_mocks.dart';
import '../../../test_data/dual_wan_test_state.dart';

void main() {
  late MockDualWANSettingsNotifier mockDualWANSettingsNotifier;
  final screenList = [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 2960)).toList(),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1880)).toList()
  ];
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I<ServiceHelper>();

  setUp(() {
    mockDualWANSettingsNotifier = MockDualWANSettingsNotifier();

    when(mockDualWANSettingsNotifier.build())
        .thenReturn(testDualWANSettingsState);
    when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return testDualWANSettingsState;
    });
  });

  Widget testableWidget(Locale locale) => testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 12)),
        overrides: [
          dualWANSettingsProvider
              .overrideWith(() => mockDualWANSettingsNotifier),
        ],
        locale: locale,
        child: const DualWANSettingsView(),
      );

  testLocalizations('Dual WAN Settings View - disable', (tester, locale) async {
    when(mockDualWANSettingsNotifier.build())
        .thenReturn(testDualWANSettingsStateDisabled);
    when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return testDualWANSettingsStateDisabled;
    });
    final widget = testableWidget(locale);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }, screens: screenList);
  testLocalizations('Dual WAN Settings View - failover',
      (tester, locale) async {
    final widget = testableWidget(locale);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }, screens: screenList);
  testLocalizations(
      'Dual WAN Settings View - load balancing with 4:1 - Favor primary WAN',
      (tester, locale) async {
    when(mockDualWANSettingsNotifier.build()).thenReturn(
        testDualWANSettingsState.copyWith(
            mode: DualWANMode.loadBalancing,
            balanceRatio: DualWANBalanceRatio.favorPrimaryWAN));
    when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return testDualWANSettingsState.copyWith(
          mode: DualWANMode.loadBalancing,
          balanceRatio: DualWANBalanceRatio.favorPrimaryWAN);
    });
    final widget = testableWidget(locale);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }, screens: screenList);
  testLocalizations(
      'Dual WAN Settings View - load balancing with 1:1 - Eaual distribution (Default)',
      (tester, locale) async {
    when(mockDualWANSettingsNotifier.build()).thenReturn(
        testDualWANSettingsState.copyWith(mode: DualWANMode.loadBalancing));
    when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return testDualWANSettingsState.copyWith(mode: DualWANMode.loadBalancing);
    });
    final widget = testableWidget(locale);

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();
  }, screens: screenList);

  group('Dual WAN Settings View - primary WAN', () {
    testLocalizations('Dual WAN Settings View - primary WAN - static IP',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations('Dual WAN Settings View - primary WAN - PPPoE',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'PPPoE',
                  username: () => 'username',
                  password: () => 'password',
                  serviceName: () => 'serviceName')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'PPPoE',
                username: () => 'username',
                password: () => 'password',
                serviceName: () => 'serviceName'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations('Dual WAN Settings View - primary WAN - PPTP',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'PPTP',
                  username: () => 'username',
                  password: () => 'password',
                  serviceName: () => 'serviceName')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'PPTP',
                username: () => 'username',
                password: () => 'password',
                serviceName: () => 'serviceName'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - primary WAN - static IP - invalid ip',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final inputFieldFinder = find.byKey(ValueKey('primaryStaticIpAddress-2'));

      await tester.enterText(inputFieldFinder, '');
      await tester.tap(find.byKey(ValueKey('primaryStaticSubnet-0')));
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - primary WAN - static IP - invalid subnet',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final inputFieldFinder = find.byKey(ValueKey('primaryStaticSubnet-2'));

      await tester.enterText(inputFieldFinder, '');
      await tester.tap(find.byKey(ValueKey('primaryStaticIpAddress-0')));
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - primary WAN - static IP - invalid gateway',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final inputFieldFinder = find.byKey(ValueKey('primaryStaticGateway-2'));

      await tester.enterText(inputFieldFinder, '');
      await tester.tap(find.byKey(ValueKey('primaryStaticIpAddress-0')));
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - primary WAN - PPPoE - invalid username',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'PPPoE',
                  username: () => 'username',
                  password: () => 'password')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'PPPoE',
                username: () => 'username',
                password: () => 'password'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final primaryPPPoEUsernameFormFieldFinder =
          find.byKey(const ValueKey('primaryPPPoEUsername'));
      final primaryPPPoEPasswordFormFieldFinder =
          find.byKey(const ValueKey('primaryPPPoEPassword'));
      await tester.enterText(primaryPPPoEUsernameFormFieldFinder, '');
      await tester.tap(primaryPPPoEPasswordFormFieldFinder);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - primary WAN - PPPoE - invalid password',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'PPPoE',
                  username: () => 'username',
                  password: () => 'password')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'PPPoE',
                username: () => 'username',
                password: () => 'password'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final primaryPPPoEUsernameFormFieldFinder =
          find.byKey(const ValueKey('primaryPPPoEUsername'));
      final primaryPPPoEPasswordFormFieldFinder =
          find.byKey(const ValueKey('primaryPPPoEPassword'));
      await tester.enterText(primaryPPPoEPasswordFormFieldFinder, '');
      await tester.tap(primaryPPPoEUsernameFormFieldFinder);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - primary WAN - PPTP - invalid username',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'PPTP',
                  username: () => 'username',
                  password: () => 'password')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'PPTP',
                username: () => 'username',
                password: () => 'password'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final primaryPPTPUsernameFormFieldFinder =
          find.byKey(const ValueKey('primaryPPTPUsername'));
      final primaryPPTPPasswordFormFieldFinder =
          find.byKey(const ValueKey('primaryPPTPPassword'));
      await tester.enterText(primaryPPTPUsernameFormFieldFinder, '');
      await tester.tap(primaryPPTPPasswordFormFieldFinder);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - primary WAN - PPTP - invalid password',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'PPTP',
                  username: () => 'username',
                  password: () => 'password')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'PPTP',
                username: () => 'username',
                password: () => 'password'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final primaryPPTPUsernameFormFieldFinder =
          find.byKey(const ValueKey('primaryPPTPUsername'));
      final primaryPPTPPasswordFormFieldFinder =
          find.byKey(const ValueKey('primaryPPTPPassword'));
      await tester.enterText(primaryPPTPPasswordFormFieldFinder, '');
      await tester.tap(primaryPPTPUsernameFormFieldFinder);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations('Dual WAN Settings View - primary WAN - invalid MTU',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            primaryWAN: testDualWANSettingsState.primaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final mtuFieldFinder = find.byKey(ValueKey('primaryMtuSizeText'));

      final ipFieldFinder = find.byType(AppIPFormField);
      final primaryStaticIpFormFieldFinder = ipFieldFinder.at(0);

      await tester.enterText(mtuFieldFinder.last, '5');
      await tester.tap(find
          .descendant(
              of: primaryStaticIpFormFieldFinder,
              matching: find.byType(TextFormField))
          .first);
      await tester.pumpAndSettle();
    }, screens: screenList);
  });

  group('Dual WAN Settings View - secondary WAN', () {
    testLocalizations('Dual WAN Settings View - secondary WAN - static IP',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: screenList);
    testLocalizations('Dual WAN Settings View - secondary WAN - PPPoE',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'PPPoE',
                  username: () => 'username',
                  password: () => 'password',
                  serviceName: () => 'serviceName')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'PPPoE',
                username: () => 'username',
                password: () => 'password',
                serviceName: () => 'serviceName'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations('Dual WAN Settings View - secondary WAN - PPTP',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'PPTP',
                  username: () => 'username',
                  password: () => 'password',
                  serviceName: () => 'serviceName')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'PPTP',
                username: () => 'username',
                password: () => 'password',
                serviceName: () => 'serviceName'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - secondary WAN - static IP - invalid ip',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final inputFieldFinder =
          find.byKey(ValueKey('secondaryStaticIpAddress-2'));

      await tester.enterText(inputFieldFinder, '');
      await tester.tap(find.byKey(ValueKey('secondaryStaticSubnet-0')));
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - secondary WAN - static IP - invalid subnet',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final inputFieldFinder = find.byKey(ValueKey('secondaryStaticSubnet-2'));

      await tester.enterText(inputFieldFinder, '');
      await tester.tap(find.byKey(ValueKey('secondaryStaticIpAddress-0')));
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - secondary WAN - static IP - invalid gateway',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final inputFieldFinder = find.byKey(ValueKey('secondaryStaticGateway-2'));

      await tester.enterText(inputFieldFinder, '');
      await tester.tap(find.byKey(ValueKey('secondaryStaticIpAddress-0')));
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - secondary WAN - PPPoE - invalid username',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'PPPoE',
                  username: () => 'username',
                  password: () => 'password')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'PPPoE',
                username: () => 'username',
                password: () => 'password'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final secondaryPPPoEUsernameFormFieldFinder =
          find.byKey(const ValueKey('secondaryPPPoEUsername'));
      final secondaryPPPoEPasswordFormFieldFinder =
          find.byKey(const ValueKey('secondaryPPPoEPassword'));
      await tester.enterText(secondaryPPPoEUsernameFormFieldFinder, '');
      await tester.tap(secondaryPPPoEPasswordFormFieldFinder);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - secondary WAN - PPPoE - invalid password',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'PPPoE',
                  username: () => 'username',
                  password: () => 'password')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'PPPoE',
                username: () => 'username',
                password: () => 'password'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final secondaryPPPoEUsernameFormFieldFinder =
          find.byKey(const ValueKey('secondaryPPPoEUsername'));
      final secondaryPPPoEPasswordFormFieldFinder =
          find.byKey(const ValueKey('secondaryPPPoEPassword'));
      await tester.enterText(secondaryPPPoEPasswordFormFieldFinder, '');
      await tester.tap(secondaryPPPoEUsernameFormFieldFinder);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - secondary WAN - PPTP - invalid username',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'PPTP',
                  username: () => 'username',
                  password: () => 'password')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'PPTP',
                username: () => 'username',
                password: () => 'password'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final secondaryPPTPUsernameFormFieldFinder =
          find.byKey(const ValueKey('secondaryPPTPUsername'));
      final secondaryPPTPPasswordFormFieldFinder =
          find.byKey(const ValueKey('secondaryPPTPPassword'));
      await tester.enterText(secondaryPPTPUsernameFormFieldFinder, '');
      await tester.tap(secondaryPPTPPasswordFormFieldFinder);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations(
        'Dual WAN Settings View - secondary WAN - PPTP - invalid password',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'PPTP',
                  username: () => 'username',
                  password: () => 'password')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'PPTP',
                username: () => 'username',
                password: () => 'password'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final secondaryPPTPUsernameFormFieldFinder =
          find.byKey(const ValueKey('secondaryPPTPUsername'));
      final secondaryPPTPPasswordFormFieldFinder =
          find.byKey(const ValueKey('secondaryPPTPPassword'));
      await tester.enterText(secondaryPPTPPasswordFormFieldFinder, '');
      await tester.tap(secondaryPPTPUsernameFormFieldFinder);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations('Dual WAN Settings View - secondary WAN - invalid MTU',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                  ipv4ConnectionType: 'Static',
                  staticIpAddress: () => '10.123.1.89',
                  networkPrefixLength: () => 24,
                  staticGateway: () => '10.123.1.1',
                  staticDns1: () => '8.8.8.8')));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            secondaryWAN: testDualWANSettingsState.secondaryWAN.copyWith(
                ipv4ConnectionType: 'Static',
                staticIpAddress: () => '10.123.1.89',
                networkPrefixLength: () => 24,
                staticGateway: () => '10.123.1.1',
                staticDns1: () => '8.8.8.8'));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();

      final mtuFieldFinder = find.byKey(ValueKey('secondaryMtuSizeText'));

      final ipFieldFinder = find.byType(AppIPFormField);
      final secondaryStaticIpFormFieldFinder = ipFieldFinder.at(1);

      await tester.enterText(mtuFieldFinder.last, '5');
      await tester.tap(find
          .descendant(
              of: secondaryStaticIpFormFieldFinder,
              matching: find.byType(TextFormField))
          .first);
      await tester.pumpAndSettle();
    }, screens: screenList);
  });

  group('Dual WAN Settings View - logging options', () {
    testLocalizations('Dual WAN Settings View - logging options - disabled',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              loggingOptions: testDualWANSettingsState.loggingOptions.copyWith(
                  failoverEvents: false,
                  wanUptime: false,
                  speedChecks: false,
                  throughputData: false)));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            loggingOptions: testDualWANSettingsState.loggingOptions.copyWith(
                failoverEvents: false,
                wanUptime: false,
                speedChecks: false,
                throughputData: false));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: screenList);

    testLocalizations('Dual WAN Settings View - logging options - enabled',
        (tester, locale) async {
      when(mockDualWANSettingsNotifier.build()).thenReturn(
          testDualWANSettingsState.copyWith(
              loggingOptions: testDualWANSettingsState.loggingOptions.copyWith(
                  failoverEvents: true,
                  wanUptime: true,
                  speedChecks: true,
                  throughputData: true)));
      when(mockDualWANSettingsNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return testDualWANSettingsState.copyWith(
            loggingOptions: testDualWANSettingsState.loggingOptions.copyWith(
                failoverEvents: true,
                wanUptime: true,
                speedChecks: true,
                throughputData: true));
      });
      final widget = testableWidget(locale);

      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    }, screens: screenList);
  });
}
