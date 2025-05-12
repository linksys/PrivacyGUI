import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../../common/config.dart';
import '../../../../../common/di.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/internet_settings_state_data.dart';
import '../../../../../mocks/internet_settings_notifier_mocks.dart';

Future<void> main() async {
  late MockInternetSettingsNotifier mockInternetSettingsNotifier;
  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
  });

  group('InternetSettings - Ipv4', () {
    testLocalizations(
      'InternetSettings - dhcp',
      (tester, locale) async {
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateDHCP));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateDHCP);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);
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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateStatic));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateStatic);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);
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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStatePppoe));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStatePppoe);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);
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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStatePptp));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStatePptp);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);
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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(
                internetSettingsStatePptpWithStaticIp));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStatePptpWithStaticIp);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);
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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateL2tp));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateL2tp);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);
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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateBridge));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateBridge);
        });
        when(mockInternetSettingsNotifier.hostname)
            .thenAnswer((realInvocation) {
          return 'Linksys00000';
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);
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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateDHCP));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateDHCP);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateStatic));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateStatic);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStatePppoe));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStatePppoe);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStatePptp));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStatePptp);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateL2tp));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateL2tp);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateBridge));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateBridge);
        });
        when(mockInternetSettingsNotifier.hostname)
            .thenAnswer((realInvocation) {
          return 'Linksys00000';
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateStatic));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateStatic);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStateIpv6Automatic);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStateIpv6Automatic);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        final newState = state.copyWith(
            ipv6Setting: state.ipv6Setting.copyWith(
          isIPv6AutomaticEnabled: false,
          ipv6rdTunnelMode: () => IPv6rdTunnelMode.disabled,
        ));
        when(mockInternetSettingsNotifier.build()).thenReturn(newState);
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return newState;
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        final newState = state.copyWith(
            ipv6Setting: state.ipv6Setting.copyWith(
          isIPv6AutomaticEnabled: false,
          ipv6rdTunnelMode: () => IPv6rdTunnelMode.automatic,
        ));
        when(mockInternetSettingsNotifier.build()).thenReturn(newState);
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return newState;
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        final newState = state.copyWith(
            ipv6Setting: state.ipv6Setting.copyWith(
          isIPv6AutomaticEnabled: false,
          ipv6rdTunnelMode: () => IPv6rdTunnelMode.manual,
        ));
        when(mockInternetSettingsNotifier.build()).thenReturn(newState);
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return newState;
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(
                internetSettingsStateIpv6PassThrough));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStateIpv6PassThrough);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(
                internetSettingsStateIpv6PassThrough));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(
              internetSettingsStateIpv6PassThrough);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateDHCP));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateDHCP);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

        final releaseAndRenewTabFinder = find.byType(Tab);
        await tester.tap(releaseAndRenewTabFinder.at(2));
        await tester.pumpAndSettle();
      },
    );

    testLocalizations(
      'InternetSettings - release & renew with bridge mode',
      (tester, locale) async {
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateBridge));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateBridge);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

        final releaseAndRenewTabFinder = find.byType(Tab);
        await tester.tap(releaseAndRenewTabFinder.at(2));
        await tester.pumpAndSettle();
      },
    );

    testLocalizations(
      'InternetSettings - release & renew dialog',
      (tester, locale) async {
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateDHCP));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateDHCP);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE)
              .copyWith(macClone: true);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
        when(mockInternetSettingsNotifier.build()).thenReturn(
            InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE));
        when(mockInternetSettingsNotifier.fetch())
            .thenAnswer((realInvocation) async {
          await Future.delayed(const Duration(seconds: 1));
          return InternetSettingsState.fromMap(internetSettingsStateIpv6PPPoE)
              .copyWith(macClone: true);
        });
        final widget = testableSingleRoute(
          overrides: [
            internetSettingsProvider
                .overrideWith(() => mockInternetSettingsNotifier),
          ],
          locale: locale,
          child: const InternetSettingsView(),
        );
        await tester.pumpWidget(widget);

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
