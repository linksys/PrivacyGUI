import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/internet_settings_state_data.dart';

Future<void> main() async {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
  });

  group('InternetSettings - Ipv4', () {
    testLocalizations(
      'InternetSettings - dhcp',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateDHCP));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateDHCP);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - static',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateStatic));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateStatic);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1680))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - pppoe',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStatePppoe));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStatePppoe);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - pptp',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStatePptp));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStatePptp);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - pptp with static ip',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(
                internetSettingsStatePptpWithStaticIp));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStatePptpWithStaticIp);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1680))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - l2tp',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateL2tp));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateL2tp);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - bridge',
      (tester, locale) async {
        final state =
            InternetSettingsState.fromMap(internetSettingsStateBridge);
        final status = state.status.copyWith(hostname: () => 'Linksys00000');
        when(testHelper.mockInternetSettingsNotifier.build())
            .thenReturn(state.copyWith(status: status));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateBridge);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - dhcp editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateDHCP));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateDHCP);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - static editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateStatic));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateStatic);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - pppoe editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStatePppoe));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStatePppoe);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - pptp editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStatePptp));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStatePptp);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 2080))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - l2tp editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateL2tp));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateL2tp);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - bridge editing',
      (tester, locale) async {
        final state =
            InternetSettingsState.fromMap(internetSettingsStateBridge);
        final status = state.status.copyWith(hostname: () => 'Linksys00000');
        when(testHelper.mockInternetSettingsNotifier.build())
            .thenReturn(state.copyWith(status: status));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return state.copyWith(status: status);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1280))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - domain name, mtu and mac address clone editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateStatic));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateStatic);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );
  });

  group('InternetSettings - Ipv6', () {
    testLocalizations(
      'InternetSettings - ipv6 automatic',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStateIpv6Automatic);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1680))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv6 automatic editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStateIpv6Automatic);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv6 automatic ipv6rdTunnelMode diable editing',
      (tester, locale) async {
        final state =
            InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
        final settings = state.settings.current;
        final newState = state.copyWith(
            settings: state.settings.copyWith(
          current: settings.copyWith(
            ipv6Setting: settings.ipv6Setting.copyWith(
              isIPv6AutomaticEnabled: false,
              ipv6rdTunnelMode: () => IPv6rdTunnelMode.disabled,
            ),
          ),
        ));
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(newState);
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return newState;
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv6 automatic ipv6rdTunnelMode automatic editing',
      (tester, locale) async {
        final state =
            InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
        final settings = state.settings.current;
        final newState = state.copyWith(
            settings: state.settings.copyWith(
          current: settings.copyWith(
            ipv6Setting: settings.ipv6Setting.copyWith(
              isIPv6AutomaticEnabled: false,
              ipv6rdTunnelMode: () => IPv6rdTunnelMode.automatic,
            ),
          ),
        ));
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(newState);
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return newState;
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv6 automatic ipv6rdTunnelMode manual editing',
      (tester, locale) async {
        final state =
            InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
        final settings = state.settings.current;
        final newState = state.copyWith(
            settings: state.settings.copyWith(
          current: settings.copyWith(
            ipv6Setting: settings.ipv6Setting.copyWith(
              isIPv6AutomaticEnabled: false,
              ipv6rdTunnelMode: () => IPv6rdTunnelMode.manual,
            ),
          ),
        ));
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(newState);
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return newState;
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv6 pass-through',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(
                internetSettingsStateIpv6PassThrough));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStateIpv6PassThrough);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1680))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv6 pass-through editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(
                internetSettingsStateIpv6PassThrough));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStateIpv6PassThrough);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv6 pppoe',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1680))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv6 pppoe editing',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final ipv6TabFinder = find.byType(Tab);
        await tester.tap(ipv6TabFinder.at(1));
        await tester.pumpAndSettle();

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1880))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );
  });

  group('InternetSettings - Release & Renew', () {
    testLocalizations(
      'InternetSettings - release & renew',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateDHCP));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateDHCP);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final releaseAndRenewTabFinder = find.byType(Tab);
        await tester.tap(releaseAndRenewTabFinder.at(2));
        await tester.pumpAndSettle();
      },
    );

    testLocalizations(
      'InternetSettings - release & renew with bridge mode',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateBridge));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateBridge);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final releaseAndRenewTabFinder = find.byType(Tab);
        await tester.tap(releaseAndRenewTabFinder.at(2));
        await tester.pumpAndSettle();
      },
    );

    testLocalizations(
      'InternetSettings - release & renew dialog',
      (tester, locale) async {
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateDHCP));
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateDHCP);
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final releaseAndRenewTabFinder = find.byType(Tab);
        await tester.tap(releaseAndRenewTabFinder.at(2));
        await tester.pumpAndSettle();

        final saveBtnFinder = find.byType(AppTextButton);
        await tester.tap(saveBtnFinder.first);
        await tester.pumpAndSettle();
      },
    );
  });

  group('InternetSettings - Save', () {
    testLocalizations(
      'InternetSettings - restart dialog',
      (tester, locale) async {
        final state =
            InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE);
        final settings = state.settings.current;
        final newState = state.copyWith(
            settings: state.settings.copyWith(
          current: settings.copyWith(
            macClone: true,
          ),
        ));
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(newState);
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return newState;
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();

        final switchBtnFinder = find.byType(AppSwitch);
        await tester.tap(switchBtnFinder.first);
        await tester.pumpAndSettle();

        final saveBtnFinder = find.byType(AppFilledButton);
        await tester.tap(saveBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1680))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );

    testLocalizations(
      'InternetSettings - ipv4 and ipv6 combination dialog',
      (tester, locale) async {
        final state =
            InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE);
        final settings = state.settings.current;
        final newState = state.copyWith(
            settings: state.settings.copyWith(
          current: settings.copyWith(
            macClone: true,
          ),
        ));
        when(testHelper.mockInternetSettingsNotifier.build()).thenReturn(newState);
        when(testHelper.mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return newState;
        });
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const InternetSettingsView(),
        );

        final editBtnFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editBtnFinder);
        await tester.pumpAndSettle();

        final saveBtnFinder = find.byType(AppFilledButton);
        await tester.tap(saveBtnFinder);
        await tester.pumpAndSettle();

        final restartBtnFinder = find.byType(AppTextButton);
        await tester.tap(restartBtnFinder.last);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1680))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1680))
            .toList()
      ],
    );
  });
}
