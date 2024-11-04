import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/connection_type_view.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/views/internet_settings_view.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/internet_settings_state_data.dart';
import '../../../../../mocks/internet_settings_notifier_mocks.dart';

Future<void> main() async {
  late InternetSettingsNotifier mockInternetSettingsNotifier;

  setUp(() {
    mockInternetSettingsNotifier = MockInternetSettingsNotifier();
  });

  group('InternetSettings - ipv4 connection type - dhcp', () {
    testLocalizations('InternetSettings - ipv4 connection type - dhcp',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build())
          .thenReturn(InternetSettingsState.fromMap(internetSettingsStateDHCP));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - dhcp whit mtu manul',
        (tester, locale) async {
      final state = InternetSettingsState.fromMap(internetSettingsStateDHCP);
      when(mockInternetSettingsNotifier.build()).thenReturn(
          state.copyWith(ipv4Setting: state.ipv4Setting.copyWith(mtu: 1500)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('InternetSettings - ipv4 connection type - dhcp editing',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build())
          .thenReturn(InternetSettingsState.fromMap(internetSettingsStateDHCP));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - dhcp editing whit mtu manul',
        (tester, locale) async {
      final state = InternetSettingsState.fromMap(internetSettingsStateDHCP);
      when(mockInternetSettingsNotifier.build()).thenReturn(
          state.copyWith(ipv4Setting: state.ipv4Setting.copyWith(mtu: 1500)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });
  });

  group('InternetSettings - ipv4 connection type - static', () {
    testLocalizations('InternetSettings - ipv4 connection type - static',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStateStatic));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - static editing',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStateStatic));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - static editing 2',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStateStatic));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();

      final mtuFinder = find.byKey(const Key('mtu'));
      await tester.scrollUntilVisible(mtuFinder, 10,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();
    });
  });

  group('InternetSettings - ipv4 connection type - pppoe', () {
    testLocalizations('InternetSettings - ipv4 connection type - pppoe',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStatePppoe));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('InternetSettings - ipv4 connection type - pppoe editing',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStatePppoe));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - pppoe editing 2',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStatePppoe));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();

      final mtuFinder = find.byKey(const Key('mtu'));
      await tester.scrollUntilVisible(mtuFinder, 10,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - pppoe editing 2 with connect on demand connection mode',
        (tester, locale) async {
      final state = InternetSettingsState.fromMap(internetSettingsStatePppoe);
      when(mockInternetSettingsNotifier.build()).thenReturn(state.copyWith(
          ipv4Setting: state.ipv4Setting
              .copyWith(behavior: () => PPPConnectionBehavior.connectOnDemand)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();

      final mtuFinder = find.byKey(const Key('mtu'));
      await tester.scrollUntilVisible(mtuFinder, 10,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();
    });
  });

  group('InternetSettings - ipv4 connection type - pptp', () {
    testLocalizations('InternetSettings - ipv4 connection type - pptp',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build())
          .thenReturn(InternetSettingsState.fromMap(internetSettingsStatePptp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - pptp with static ip',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStatePptpWithStaticIp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('InternetSettings - ipv4 connection type - pptp editing',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build())
          .thenReturn(InternetSettingsState.fromMap(internetSettingsStatePptp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - pptp editing 2',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build())
          .thenReturn(InternetSettingsState.fromMap(internetSettingsStatePptp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();

      final mtuFinder = find.byKey(const Key('mtu'));
      await tester.scrollUntilVisible(mtuFinder, 10,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - pptp with static ip editing',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStatePptpWithStaticIp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - pptp with static ip editing 2',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStatePptpWithStaticIp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();

      final subnetFinder = find.byKey(const Key('staticSubnet'));
      await tester.scrollUntilVisible(subnetFinder, 10,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - pptp with static ip editing 3',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStatePptpWithStaticIp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();

      final mtuFinder = find.byKey(const Key('mtu'));
      await tester.scrollUntilVisible(mtuFinder, 10,
          scrollable: find
              .descendant(
                  of: find.byType(StyledAppPageView),
                  matching: find.byType(Scrollable))
              .last);
      await tester.pumpAndSettle();
    });
  });

  group('InternetSettings - ipv4 connection type - l2tp', () {
    testLocalizations('InternetSettings - ipv4 connection type - l2tp',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build())
          .thenReturn(InternetSettingsState.fromMap(internetSettingsStateL2tp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations('InternetSettings - ipv4 connection type - l2tp editing',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build())
          .thenReturn(InternetSettingsState.fromMap(internetSettingsStateL2tp));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });
  });

  group('InternetSettings - ipv4 connection type - bridge', () {
    testLocalizations('InternetSettings - ipv4 connection type - bridge',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStateBridge));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv4 connection type - bridge editing',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStateBridge));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });
  });

  group('InternetSettings - ipv6 connection type - automatic', () {
    testLocalizations('InternetSettings - ipv6 connection type - automatic',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv6,
          },
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv6 connection type - automatic editing',
        (tester, locale) async {
      when(mockInternetSettingsNotifier.build()).thenReturn(
          InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv6,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv6 connection type - automatic disable',
        (tester, locale) async {
      final state =
          InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
      when(mockInternetSettingsNotifier.build()).thenReturn(state.copyWith(
          ipv6Setting:
              state.ipv6Setting.copyWith(isIPv6AutomaticEnabled: false)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv6,
          },
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv6 connection type - automatic editing disable',
        (tester, locale) async {
      final state =
          InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
      when(mockInternetSettingsNotifier.build()).thenReturn(state.copyWith(
          ipv6Setting:
              state.ipv6Setting.copyWith(isIPv6AutomaticEnabled: false)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv6,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv6 connection type - automatic disable with 6rd tunnel auto',
        (tester, locale) async {
      final state =
          InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
      when(mockInternetSettingsNotifier.build()).thenReturn(state.copyWith(
          ipv6Setting: state.ipv6Setting.copyWith(
              isIPv6AutomaticEnabled: false,
              ipv6rdTunnelMode: () => IPv6rdTunnelMode.automatic)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv6,
          },
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv6 connection type - automatic editing disable with 6rd tunnel auto',
        (tester, locale) async {
      final state =
          InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
      when(mockInternetSettingsNotifier.build()).thenReturn(state.copyWith(
          ipv6Setting: state.ipv6Setting.copyWith(
              isIPv6AutomaticEnabled: false,
              ipv6rdTunnelMode: () => IPv6rdTunnelMode.automatic)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv6,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv6 connection type - automatic disable with 6rd tunnel manual',
        (tester, locale) async {
      final state =
          InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
      when(mockInternetSettingsNotifier.build()).thenReturn(state.copyWith(
          ipv6Setting: state.ipv6Setting.copyWith(
              isIPv6AutomaticEnabled: false,
              ipv6rdTunnelMode: () => IPv6rdTunnelMode.manual)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv6,
          },
        ),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
    });

    testLocalizations(
        'InternetSettings - ipv6 connection type - automatic editing disable with 6rd tunnel manual',
        (tester, locale) async {
      final state =
          InternetSettingsState.fromMap(internetSettingsStateIpv6Automatic);
      when(mockInternetSettingsNotifier.build()).thenReturn(state.copyWith(
          ipv6Setting: state.ipv6Setting.copyWith(
              isIPv6AutomaticEnabled: false,
              ipv6rdTunnelMode: () => IPv6rdTunnelMode.manual)));

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv6,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();
    });
  });

  testLocalizations(
        'InternetSettings - ipv4 connection type - unsaved alert',
        (tester, locale) async {
      final state = InternetSettingsState.fromMap(internetSettingsStatePppoe);
      when(mockInternetSettingsNotifier.build()).thenReturn(state);

      final widget = testableSingleRoute(
        config: LinksysRouteConfig(column: ColumnGrid(column: 9)),
        overrides: [
          internetSettingsProvider
              .overrideWith(() => mockInternetSettingsNotifier),
        ],
        locale: locale,
        child: const ConnectionTypeView(
          args: {
            'viewType': InternetSettingsViewType.ipv4,
          },
        ),
      );
      await tester.pumpWidget(widget);

      final editBtnFinder = find.byType(AppTextButton);
      await tester.tap(editBtnFinder);
      await tester.pumpAndSettle();

      final usernameFinder = find.byKey(const Key('pppoeUsername'));
      await tester.enterText(usernameFinder, 'text');
      await tester.pumpAndSettle();

      final passwordFinder = find.byKey(const Key('pppoePassword'));
      await tester.tap(passwordFinder);
      await tester.pumpAndSettle();

      final backBtnFinder = find.byIcon(LinksysIcons.arrowBack);
      await tester.tap(backBtnFinder);
      await tester.pumpAndSettle();
    });
}
