import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/local_network_settings_state.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  testLocalizations('LocalNetwork - host name', (tester, locale) async {
    when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
    });
    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const LocalNetworkSettingsView(),
    );
  });

  testLocalizations('LocalNetwork - host name error', (tester, locale) async {
    when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsErrorState)
            .copyWith(
      hasErrorOnHostNameTab: true,
    ));
    when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return LocalNetworkSettingsState.fromMap(
          mockLocalNetworkSettingsErrorState);
    });
    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const LocalNetworkSettingsView(),
    );
  });

  testLocalizations('LocalNetwork - lan ip address', (tester, locale) async {
    when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
    });
    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const LocalNetworkSettingsView(),
    );

    final lanIpAddressTabFinder = find.byType(Tab);
    await tester.tap(lanIpAddressTabFinder.at(1));
    await tester.pumpAndSettle();
  });

  testLocalizations('LocalNetwork - lan ip address error',
      (tester, locale) async {
    when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
        LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsErrorState)
            .copyWith(
      hasErrorOnIPAddressTab: true,
    ));
    when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return LocalNetworkSettingsState.fromMap(
          mockLocalNetworkSettingsErrorState);
    });
    await testHelper.pumpView(
      tester,
      locale: locale,
      child: const LocalNetworkSettingsView(),
    );

    final lanIpAddressTabFinder = find.byType(Tab);
    await tester.tap(lanIpAddressTabFinder.at(1));
    await tester.pumpAndSettle();
  });

  testLocalizations(
    'LocalNetwork - dhcp server',
    (tester, locale) async {
      when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const LocalNetworkSettingsView(),
      );

      final dhcpServerTabFinder = find.byType(Tab);
      await tester.tap(dhcpServerTabFinder.at(2));
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
  );

  testLocalizations(
    'LocalNetwork - dhcp server error',
    (tester, locale) async {
      when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsErrorState)
              .copyWith(
        hasErrorOnDhcpServerTab: true,
      ));
      when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return LocalNetworkSettingsState.fromMap(
            mockLocalNetworkSettingsErrorState);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const LocalNetworkSettingsView(),
      );

      final dhcpServerTabFinder = find.byType(Tab);
      await tester.tap(dhcpServerTabFinder.at(2));
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
  );

  testLocalizations(
    'LocalNetwork - dhcp server ip range error',
    (tester, locale) async {
      when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsErrorState)
              .copyWith(
        errorTextMap: {"startIpAddress": "startIpAddressRange"},
        hasErrorOnDhcpServerTab: true,
      ));
      when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return LocalNetworkSettingsState.fromMap(
            mockLocalNetworkSettingsErrorState);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const LocalNetworkSettingsView(),
      );

      final dhcpServerTabFinder = find.byType(Tab);
      await tester.tap(dhcpServerTabFinder.at(2));
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
  );

  testLocalizations(
    'LocalNetwork - dhcp server off',
    (tester, locale) async {
      when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState)
              .copyWith(
        isDHCPEnabled: false,
      ));
      when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const LocalNetworkSettingsView(),
      );

      final dhcpServerTabFinder = find.byType(Tab);
      await tester.tap(dhcpServerTabFinder.at(2));
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1480)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
  );

  testLocalizations(
    'LocalNetwork - save change dialog before enter dhcp reservertion view',
    (tester, locale) async {
      when(testHelper.mockLocalNetworkSettingsNotifier.build()).thenReturn(
          LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState)
              .copyWith(firstIPAddress: "10.11.1.15"));
      when(testHelper.mockLocalNetworkSettingsNotifier.fetch(fetchRemote: true))
          .thenAnswer((_) async {
        await Future.delayed(const Duration(seconds: 1));
        return LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState);
      });
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const LocalNetworkSettingsView(),
      );

      await tester.pump(Duration(seconds: 2));
      await tester.fling(
          find.byType(TabBar), const Offset(-200.0, 0.0), 10000.0);
      await tester.pumpAndSettle();
      final dhcpServerTabFinder = find.byType(Tab);
      await tester.tap(dhcpServerTabFinder.at(2));
      await tester.pumpAndSettle();

      final dhcpResevationBtnFinder = find.byIcon(LinksysIcons.chevronRight);
      await tester.tap(dhcpResevationBtnFinder.first);
      await tester.pumpAndSettle();
    },
    screens: [
      ...responsiveMobileScreens.map((e) => e.copyWith(height: 1680)).toList(),
      ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1680)).toList()
    ],
  );
}
