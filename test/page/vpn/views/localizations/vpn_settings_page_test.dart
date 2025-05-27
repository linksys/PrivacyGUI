import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';
import 'package:privacy_gui/page/vpn/views/vpn_settings_page.dart';
import 'package:privacy_gui/route/route_model.dart';

import '../../../../common/config.dart';
import '../../../../common/di.dart';
import '../../../../common/test_responsive_widget.dart';
import '../../../../common/testable_router.dart';
import '../../../../mocks/vpn_notifier_mocks.dart';
import '../../../../test_data/vpn_test_state.dart';

void main() {
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  late MockVPNNotifier mockVPNNotifier;

  setUp(() {
    mockVPNNotifier = MockVPNNotifier();
    when(mockVPNNotifier.build()).thenReturn(VPNTestState.defaultState);
    when(mockVPNNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return VPNTestState.defaultState;
    });
    when(mockServiceHelper.isSupportVPN()).thenReturn(true);
  });

  group('VPN Settings Page Screenshots', () {
    testLocalizations('Default VPN State', (tester, locale) async {
      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Disconnected State', (tester, locale) async {
      when(mockVPNNotifier.build()).thenReturn(VPNTestState.disconnectedState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.disconnectedState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Failed Connection State', (tester, locale) async {
      when(mockVPNNotifier.build()).thenReturn(VPNTestState.failedState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.failedState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Connecting State', (tester, locale) async {
      when(mockVPNNotifier.build()).thenReturn(VPNTestState.connectingState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.connectingState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Test Result Success State', (tester, locale) async {
      when(mockVPNNotifier.build()).thenReturn(VPNTestState.testResultState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.testResultState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Test Result Failed State', (tester, locale) async {
      when(mockVPNNotifier.build())
          .thenReturn(VPNTestState.failedTestResultState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.failedTestResultState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Certificate Auth State', (tester, locale) async {
      when(mockVPNNotifier.build())
          .thenReturn(VPNTestState.certificateAuthState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.certificateAuthState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }, screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1080)).toList()
    ]);

    testLocalizations('VPN Service Disabled State', (tester, locale) async {
      when(mockVPNNotifier.build())
          .thenReturn(VPNTestState.serviceDisabledState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.serviceDisabledState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
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
      when(mockVPNNotifier.build()).thenReturn(editingState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return editingState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();
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
      when(mockVPNNotifier.build()).thenReturn(invalidGatewayState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidGatewayState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

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
      when(mockVPNNotifier.build()).thenReturn(invalidCredentialsState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidCredentialsState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

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
      when(mockVPNNotifier.build()).thenReturn(invalidDNSState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidDNSState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

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
      when(mockVPNNotifier.build()).thenReturn(invalidDNSState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidDNSState.copyWith(
          settings: invalidDNSState.settings.copyWith(
            tunneledUserIP: '2.2.2.2',
          ),
        );
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

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
      when(mockVPNNotifier.build()).thenReturn(invalidDNSState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return invalidDNSState.copyWith(
          settings: invalidDNSState.settings.copyWith(
            tunneledUserIP: '2.1.1.1',
          ),
        );
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

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
      when(mockVPNNotifier.build()).thenReturn(VPNTestState.testResultState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.testResultState;
      });
      when(mockVPNNotifier.testVPNConnection()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return VPNTestState.testResultState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

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
      when(mockVPNNotifier.build())
          .thenReturn(VPNTestState.failedTestResultState);
      when(mockVPNNotifier.fetch()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return VPNTestState.failedTestResultState;
      });
      when(mockVPNNotifier.testVPNConnection()).thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 2));
        return VPNTestState.failedTestResultState;
      });

      await tester.pumpWidget(
        testableSingleRoute(
          config: LinksysRouteConfig(
            column: ColumnGrid(column: 12),
            noNaviRail: true,
          ),
          child: const VPNSettingsPage(),
          locale: locale,
          overrides: [
            vpnProvider.overrideWith(() => mockVPNNotifier),
          ],
        ),
      );
      await tester.pumpAndSettle();

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
