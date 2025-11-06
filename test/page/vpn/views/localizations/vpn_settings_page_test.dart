import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/vpn/views/vpn_settings_page.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/vpn_test_state.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockVPNNotifier.build()).thenReturn(VPNTestState.defaultState);
    when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return VPNTestState.defaultState;
    });
    when(testHelper.mockServiceHelper.isSupportVPN()).thenReturn(true);
  });

  group('VPN Settings Page Screenshots', () {
    testLocalizations('Default VPN State', (tester, locale) async {
      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Disconnected State', (tester, locale) async {
      when(testHelper.mockVPNNotifier.build()).thenReturn(VPNTestState.disconnectedState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.disconnectedState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Failed Connection State', (tester, locale) async {
      when(testHelper.mockVPNNotifier.build()).thenReturn(VPNTestState.failedState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.failedState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Connecting State', (tester, locale) async {
      when(testHelper.mockVPNNotifier.build()).thenReturn(VPNTestState.connectingState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.connectingState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Test Result Success State', (tester, locale) async {
      when(testHelper.mockVPNNotifier.build()).thenReturn(VPNTestState.testResultState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.testResultState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Test Result Failed State', (tester, locale) async {
      when(testHelper.mockVPNNotifier.build())
          .thenReturn(VPNTestState.failedTestResultState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.failedTestResultState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Certificate Auth State', (tester, locale) async {
      when(testHelper.mockVPNNotifier.build())
          .thenReturn(VPNTestState.certificateAuthState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.certificateAuthState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Service Disabled State', (tester, locale) async {
      when(testHelper.mockVPNNotifier.build())
          .thenReturn(VPNTestState.serviceDisabledState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.serviceDisabledState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Editing Credentials State', (tester, locale) async {
      final editingState = VPNTestState.defaultState.copyWith(
        settings: VPNTestState.defaultState.settings.copyWith(
          isEditingCredentials: true,
        ),
      );
      when(testHelper.mockVPNNotifier.build()).thenReturn(editingState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return editingState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Invalid Gateway Address State',
        (tester, locale) async {
      final invalidGatewayState = VPNTestState.disconnectedState.copyWith(
        settings: VPNTestState.defaultState.settings.copyWith(
          gatewaySettings:
              VPNTestState.defaultState.settings.gatewaySettings!.copyWith(
            gatewayAddress: 'invalid.address',
          ),
          isEditingCredentials: true,
        ),
      );
      when(testHelper.mockVPNNotifier.build()).thenReturn(invalidGatewayState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidGatewayState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );

      final gatewayInputFinder = find.byKey(const ValueKey('gateway'));
      await tester.enterText(gatewayInputFinder, 'not.a.valid.address');
      await tester.pumpAndSettle();
      final tunneledUserInputFinder =
          find.byKey(const ValueKey('tunneledUser'));
      final ipInputFinder = find.descendant(
          of: tunneledUserInputFinder, matching: find.byType(TextFormField));
      await tester.enterText(ipInputFinder.first, '');
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Invalid Credentials State', (tester, locale) async {
      final invalidCredentialsState = VPNTestState.disconnectedState.copyWith(
        settings: VPNTestState.defaultState.settings.copyWith(
          userCredentials:
              VPNTestState.defaultState.settings.userCredentials!.copyWith(
            username: '',
            secret: '',
          ),
          isEditingCredentials: true,
        ),
      );
      when(testHelper.mockVPNNotifier.build()).thenReturn(invalidCredentialsState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidCredentialsState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );

      final usernameInputFinder = find.byKey(const ValueKey('username'));
      await tester.enterText(usernameInputFinder, '');
      await tester.pumpAndSettle();
      final passwordInputFinder = find.byKey(const ValueKey('password'));
      await tester.enterText(passwordInputFinder, '');
      await tester.pumpAndSettle();
      final gatewayInputFinder = find.byKey(const ValueKey('gateway'));
      await tester.enterText(gatewayInputFinder, '');
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Tunneled User IP Address State',
        (tester, locale) async {
      final invalidDNSState = VPNTestState.disconnectedState.copyWith(
        settings: VPNTestState.disconnectedState.settings.copyWith(
          tunneledUserIP: '1.1.1.1',
          isEditingCredentials: false,
        ),
      );
      when(testHelper.mockVPNNotifier.build()).thenReturn(invalidDNSState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidDNSState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );

      final tunneledUserInputFinder =
          find.byKey(const ValueKey('tunneledUser'));
      final ipInputFinder = find.descendant(
          of: tunneledUserInputFinder, matching: find.byType(TextFormField));
      await tester.enterText(ipInputFinder.first, '');
      await tester.pumpAndSettle();
      final gatewayInputFinder = find.byKey(const ValueKey('gateway'));
      await tester.enterText(gatewayInputFinder, '');
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Test Connection when settings changes',
        (tester, locale) async {
      final invalidDNSState = VPNTestState.disconnectedState.copyWith(
        settings: VPNTestState.disconnectedState.settings.copyWith(
          tunneledUserIP: '1.1.1.1',
          isEditingCredentials: false,
        ),
      );
      when(testHelper.mockVPNNotifier.build()).thenReturn(invalidDNSState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidDNSState.copyWith(
          settings: invalidDNSState.settings.copyWith(
            tunneledUserIP: '2.2.2.2',
          ),
        );
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );

      final testAgainButtonFinder = find.byKey(const ValueKey('testAgain'));
      await tester.tap(testAgainButtonFinder);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Test Connection when settings are invalid',
        (tester, locale) async {
      final invalidDNSState = VPNTestState.disconnectedState.copyWith(
        settings: VPNTestState.disconnectedState.settings.copyWith(
          tunneledUserIP: '1.1.1.1',
          isEditingCredentials: false,
        ),
      );
      when(testHelper.mockVPNNotifier.build()).thenReturn(invalidDNSState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidDNSState.copyWith(
          settings: invalidDNSState.settings.copyWith(
            tunneledUserIP: '2.1.1.1',
          ),
        );
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );

      final tunneledUserInputFinder =
          find.byKey(const ValueKey('tunneledUser'));
      final ipInputFinder = find.descendant(
          of: tunneledUserInputFinder, matching: find.byType(TextFormField));
      await tester.enterText(ipInputFinder.first, '');
      await tester.pumpAndSettle();
      final gatewayInputFinder = find.byKey(const ValueKey('gateway'));
      await tester.enterText(gatewayInputFinder, '');
      await tester.pumpAndSettle();

      final testAgainButtonFinder = find.byKey(const ValueKey('testAgain'));
      await tester.tap(testAgainButtonFinder);

      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Test Connection Success toast',
        (tester, locale) async {
      // Start with a successful test
      when(testHelper.mockVPNNotifier.build()).thenReturn(VPNTestState.testResultState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.testResultState;
      });
      when(testHelper.mockVPNNotifier.testVPNConnection()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return VPNTestState.testResultState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );

      // Tap test again button
      final testAgainButtonFinder = find.byKey(const ValueKey('testAgain'));
      await tester.tap(testAgainButtonFinder);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Test Connection Failed toast',
        (tester, locale) async {
      // Start with a successful test
      when(testHelper.mockVPNNotifier.build())
          .thenReturn(VPNTestState.failedTestResultState);
      when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.failedTestResultState;
      });
      when(testHelper.mockVPNNotifier.testVPNConnection()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return VPNTestState.failedTestResultState;
      });

      await testHelper.pumpView(
        tester,
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 12),
          noNaviRail: true,
        ),
        child: const VPNSettingsPage(),
        locale: locale,
      );

      // Tap test again button
      final testAgainButtonFinder = find.byKey(const ValueKey('testAgain'));
      await tester.tap(testAgainButtonFinder);
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);
  });
}