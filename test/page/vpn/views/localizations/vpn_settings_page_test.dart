import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/vpn/views/vpn_settings_page.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/test_helper.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../test_data/vpn_test_state.dart';

// View ID: VPN
// Implementation: lib/page/vpn/views/vpn_settings_page.dart
//
// | Test ID               | Description                                           |
// | :-------------------- | :---------------------------------------------------- |
// | `VPN-DEFAULT`         | Default VPN state.                                    |
// | `VPN-DISCONNECTED`    | VPN disconnected state.                               |
// | `VPN-FAILED`          | VPN connection failed state.                          |
// | `VPN-CONNECTING`      | VPN connecting state.                                 |
// | `VPN-SUCCESS`         | VPN connection test success.                          |
// | `VPN-TEST_FAILED`     | VPN connection test failed.                           |
// | `VPN-CERT_AUTH`       | VPN using certificate authentication.                 |
// | `VPN-DISABLED`        | VPN service disabled.                                 |
// | `VPN-EDITING`         | Editing VPN credentials.                              |
// | `VPN-INV_GATEWAY`     | Invalid gateway address error.                        |
// | `VPN-INV_CRED`        | Invalid credentials error.                            |
// | `VPN-TUNNEL_IP`       | Tunneled User IP input state.                         |
// | `VPN-RETEST`          | Retest connection after settings change.              |
// | `VPN-RETEST_INV`      | Retest connection with invalid settings.              |
// | `VPN-TOAST_SUCCESS`   | Success toast after connection test.                  |
// | `VPN-TOAST_FAILED`    | Failed toast after connection test.                   |

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    when(testHelper.mockVPNNotifier.build())
        .thenReturn(VPNTestState.defaultState);
    when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return VPNTestState.defaultState;
    });
    when(testHelper.mockServiceHelper.isSupportVPN()).thenReturn(true);
    // Stub Future<void> methods to prevent null return error
    when(testHelper.mockVPNNotifier.setVPNGateway(any))
        .thenAnswer((_) async {});
    when(testHelper.mockVPNNotifier.setTunneledUser(any))
        .thenAnswer((_) async {});
    when(testHelper.mockVPNNotifier.setVPNUser(any)).thenAnswer((_) async {});
    when(testHelper.mockVPNNotifier.setVPNService(any))
        .thenAnswer((_) async {});
    when(testHelper.mockVPNNotifier.setEditingCredentials(any))
        .thenAnswer((_) async {});
  });

  final screens = [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
  ];

  group('VPN Settings Page Screenshots', () {
    // Test ID: VPN-DEFAULT
    testThemeLocalizations(
      'Default VPN State',
      (tester, screen) async {
        await testHelper.pumpView(
          tester,
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-DEFAULT_01_default',
      helper: testHelper,
    );

    // Test ID: VPN-DISCONNECTED
    testThemeLocalizations(
      'VPN Disconnected State',
      (tester, screen) async {
        when(testHelper.mockVPNNotifier.build())
            .thenReturn(VPNTestState.disconnectedState);
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
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-DISCONNECTED_01_disconnected',
      helper: testHelper,
    );

    // Test ID: VPN-FAILED
    testThemeLocalizations(
      'VPN Failed Connection State',
      (tester, screen) async {
        when(testHelper.mockVPNNotifier.build())
            .thenReturn(VPNTestState.failedState);
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
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-FAILED_01_failed',
      helper: testHelper,
    );

    // Test ID: VPN-CONNECTING
    testThemeLocalizations(
      'VPN Connecting State',
      (tester, screen) async {
        when(testHelper.mockVPNNotifier.build())
            .thenReturn(VPNTestState.connectingState);
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
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-CONNECTING_01_connecting',
      helper: testHelper,
    );

    // Test ID: VPN-SUCCESS
    testThemeLocalizations(
      'VPN Test Result Success State',
      (tester, screen) async {
        when(testHelper.mockVPNNotifier.build())
            .thenReturn(VPNTestState.testResultState);
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
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-SUCCESS_01_success',
      helper: testHelper,
    );

    // Test ID: VPN-TEST_FAILED
    testThemeLocalizations(
      'VPN Test Result Failed State',
      (tester, screen) async {
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
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-TEST_FAILED_01_failed_result',
      helper: testHelper,
    );

    // Test ID: VPN-CERT_AUTH
    testThemeLocalizations(
      'VPN Certificate Auth State',
      (tester, screen) async {
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
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-CERT_AUTH_01_cert_auth',
      helper: testHelper,
    );

    // Test ID: VPN-DISABLED
    testThemeLocalizations(
      'VPN Service Disabled State',
      (tester, screen) async {
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
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-DISABLED_01_disabled',
      helper: testHelper,
    );

    // Test ID: VPN-EDITING
    testThemeLocalizations(
      'VPN Editing Credentials State',
      (tester, screen) async {
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
          locale: screen.locale,
        );
      },
      screens: screens,
      goldenFilename: 'VPN-EDITING_01_editing',
      helper: testHelper,
    );

    // Test ID: VPN-INV_GATEWAY
    testThemeLocalizations(
      'VPN Invalid Gateway Address State',
      (tester, screen) async {
        final invalidGatewayState = VPNTestState.disconnectedState.copyWith(
          settings: VPNTestState.defaultState.settings.copyWith(
            gatewaySettings:
                VPNTestState.defaultState.settings.gatewaySettings!.copyWith(
              gatewayAddress: 'invalid.address',
            ),
            isEditingCredentials: true,
          ),
        );
        when(testHelper.mockVPNNotifier.build())
            .thenReturn(invalidGatewayState);
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
          locale: screen.locale,
        );

        final gatewayInputFinder = find.byKey(const ValueKey('gateway'));
        await tester.enterText(gatewayInputFinder, 'not.a.valid.address');
        await tester.pumpAndSettle();
        final tunneledUserInputFinder = find.descendant(
            of: find.byKey(const ValueKey('tunneledUser')),
            matching: find.byType(EditableText));
        await tester.enterText(tunneledUserInputFinder, '');
        await tester.pumpAndSettle();
      },
      screens: screens,
      goldenFilename: 'VPN-INV_GATEWAY_01_invalid_gateway',
      helper: testHelper,
    );

    // Test ID: VPN-INV_CRED
    testThemeLocalizations(
      'VPN Invalid Credentials State',
      (tester, screen) async {
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
        when(testHelper.mockVPNNotifier.build())
            .thenReturn(invalidCredentialsState);
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
          locale: screen.locale,
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
      },
      screens: screens,
      goldenFilename: 'VPN-INV_CRED_01_invalid_cred',
      helper: testHelper,
    );

    // Test ID: VPN-TUNNEL_IP
    testThemeLocalizations(
      'VPN Tunneled User IP Address State',
      (tester, screen) async {
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
          locale: screen.locale,
        );

        final tunneledUserInputFinder =
            find.byKey(const ValueKey('tunneledUser'));
        await tester.enterText(tunneledUserInputFinder, '');
        await tester.pumpAndSettle();
      },
      screens: screens,
      goldenFilename: 'VPN-TUNNEL_IP_01_tunneled_ip',
      helper: testHelper,
    );

    // Test ID: VPN-RETEST
    testThemeLocalizations(
      'VPN Test Connection when settings changes',
      (tester, screen) async {
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
          locale: screen.locale,
        );

        when(testHelper.mockVPNNotifier.testVPNConnection())
            .thenAnswer((_) async => VPNTestState.testResultState);
        final testAgainButtonFinder = find.byKey(const ValueKey('testAgain'));
        await tester.tap(testAgainButtonFinder);
        await tester.pumpAndSettle();
      },
      screens: screens,
      goldenFilename: 'VPN-RETEST_01_retest',
      helper: testHelper,
    );

    // Test ID: VPN-RETEST_INV
    testThemeLocalizations(
      'VPN Test Connection when settings are invalid',
      (tester, screen) async {
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
          locale: screen.locale,
        );

        final tunneledUserInputFinder =
            find.byKey(const ValueKey('tunneledUser'));
        await tester.enterText(tunneledUserInputFinder, '');
        await tester.pumpAndSettle();

        final testAgainButtonFinder = find.byKey(const ValueKey('testAgain'));
        await tester.tap(testAgainButtonFinder);

        await tester.pumpAndSettle();
      },
      screens: screens,
      goldenFilename: 'VPN-RETEST_INV_01_retest_invalid',
      helper: testHelper,
    );

    // Test ID: VPN-TOAST_SUCCESS
    testThemeLocalizations(
      'VPN Test Connection Success toast',
      (tester, screen) async {
        when(testHelper.mockVPNNotifier.build())
            .thenReturn(VPNTestState.testResultState);
        when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return VPNTestState.testResultState;
        });
        when(testHelper.mockVPNNotifier.testVPNConnection())
            .thenAnswer((_) async {
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
          locale: screen.locale,
        );

        final testAgainButtonFinder = find.byKey(const ValueKey('testAgain'));
        await tester.tap(testAgainButtonFinder);
        await tester.pumpAndSettle();
      },
      screens: screens,
      goldenFilename: 'VPN-TOAST_SUCCESS_01_toast_success',
      helper: testHelper,
    );

    // Test ID: VPN-TOAST_FAILED
    testThemeLocalizations(
      'VPN Test Connection Failed toast',
      (tester, screen) async {
        when(testHelper.mockVPNNotifier.build())
            .thenReturn(VPNTestState.failedTestResultState);
        when(testHelper.mockVPNNotifier.fetch()).thenAnswer((_) async {
          await Future.delayed(const Duration(seconds: 1));
          return VPNTestState.failedTestResultState;
        });
        when(testHelper.mockVPNNotifier.testVPNConnection())
            .thenAnswer((_) async {
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
          locale: screen.locale,
        );

        final testAgainButtonFinder = find.byKey(const ValueKey('testAgain'));
        await tester.tap(testAgainButtonFinder);
        await tester.pumpAndSettle();
      },
      screens: screens,
      goldenFilename: 'VPN-TOAST_FAILED_01_toast_failed',
      helper: testHelper,
    );
  });
}
