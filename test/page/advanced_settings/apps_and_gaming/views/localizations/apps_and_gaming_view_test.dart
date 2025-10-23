import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/dyn_ddns_form.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/providers/apps_and_gaming_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/tab_bar/linksys_tab_bar.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:get_it/get_it.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../common/di.dart';
import '../../../../../mocks/apps_and_gaming_view_notifier_spec_mocks.dart';
import '../../../../../mocks/ddns_notifier_spec_mocks.dart';
import '../../../../../mocks/port_range_forwarding_list_notifier_mocks.dart';
import '../../../../../mocks/port_range_forwarding_rule_notifier_mocks.dart';
import '../../../../../mocks/port_range_triggering_list_notifier_mocks.dart';
import '../../../../../mocks/port_range_triggering_rule_notifier_mocks.dart';
import '../../../../../mocks/single_port_forwarding_list_notifier_mocks.dart';
import '../../../../../mocks/single_port_forwarding_rule_notifier_mocks.dart';
import '../../../../../test_data/ddns_test_state.dart';
import '../../../../../test_data/port_range_forwarding_test_state.dart';
import '../../../../../test_data/port_range_trigger_test_state.dart';
import '../../../../../test_data/single_port_forwarding_test_state.dart';

void main() {
  late MockAppsAndGamingViewNotifier mockAppsAndGamingViewNotifier;
  late MockDDNSNotifier mockDDNSNotifier;
  late MockSinglePortForwardingListNotifier
      mockSinglePortForwardingListNotifier;
  late MockSinglePortForwardingRuleNotifier
      mockSinglePortForwardingRuleNotifier;
  late MockPortRangeForwardingListNotifier mockPortRangeForwardingListNotifier;
  late MockPortRangeForwardingRuleNotifier mockPortRangeForwardingRuleNotifier;
  late MockPortRangeTriggeringListNotifier mockPortRangeTriggeringListNotifier;
  late MockPortRangeTriggeringRuleNotifier mockPortRangeTriggeringRuleNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = GetIt.I.get<ServiceHelper>();
  setUp(() {
    mockAppsAndGamingViewNotifier = MockAppsAndGamingViewNotifier();
    mockDDNSNotifier = MockDDNSNotifier();
    mockSinglePortForwardingListNotifier =
        MockSinglePortForwardingListNotifier();
    mockSinglePortForwardingRuleNotifier =
        MockSinglePortForwardingRuleNotifier();
    mockPortRangeForwardingRuleNotifier = MockPortRangeForwardingRuleNotifier();
    mockPortRangeForwardingListNotifier = MockPortRangeForwardingListNotifier();
    mockPortRangeTriggeringListNotifier = MockPortRangeTriggeringListNotifier();

    when(mockAppsAndGamingViewNotifier.build())
        .thenReturn(AppsAndGamingViewState.fromMap({}));
    when(mockDDNSNotifier.build()).thenReturn(DDNSState.fromMap(ddnsTestState));
    when(mockDDNSNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return DDNSState.fromMap(ddnsTestState);
    });
    when(mockSinglePortForwardingListNotifier.build()).thenReturn(
        SinglePortForwardingListState.fromMap(
            singlePortForwardingListTestState));
    when(mockSinglePortForwardingListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return SinglePortForwardingListState();
    });
    when(mockSinglePortForwardingRuleNotifier.build()).thenReturn(
        const SinglePortForwardingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    when(mockPortRangeForwardingRuleNotifier.build()).thenReturn(
        const PortRangeForwardingRuleState(
            routerIp: '192.168.1.1', subnetMask: '255.255.255.0'));
    when(mockPortRangeForwardingListNotifier.build()).thenReturn(
        PortRangeForwardingListState.fromMap(portRangeForwardingListTestState));
    when(mockPortRangeForwardingListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return PortRangeForwardingListState();
    });
    when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
        PortRangeTriggeringListState.fromMap(portRangeTriggerListTestState));
    when(mockPortRangeTriggeringListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return PortRangeTriggeringListState();
    });
    mockPortRangeTriggeringRuleNotifier = MockPortRangeTriggeringRuleNotifier();
    when(mockPortRangeTriggeringRuleNotifier.build())
        .thenReturn(const PortRangeTriggeringRuleState());
  });

  group('Apps & Gaming - DDNS', () {
    testLocalizations('DDNS - disable', (tester, locale) async {
      final widget = testableSingleRoute(
        overrides: [
          appsAndGamingProvider
              .overrideWith(() => mockAppsAndGamingViewNotifier),
          ddnsProvider.overrideWith(() => mockDDNSNotifier),
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier),
          portRangeTriggeringListProvider
              .overrideWith(() => mockPortRangeTriggeringListNotifier),
        ],
        locale: locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpWidget(widget);
    });

    testLocalizations(
      'DDNS - dyn.com',
      (tester, locale) async {
        when(mockDDNSNotifier.build()).thenReturn(
            DDNSState.fromMap(ddnsTestState)
                .copyWith(provider: DDNSProvider.create(dynDNSProviderName)));
        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'DDNS - dyn.com filled up',
      (tester, locale) async {
        when(mockDDNSNotifier.build())
            .thenReturn(DDNSState.fromMap(ddnsTestState).copyWith(
          provider: DynDNSProvider(
            settings: const DynDNSSettings(
              username: 'username',
              password: 'password',
              hostName: 'hostname',
              isWildcardEnabled: true,
              mode: 'Dynamic',
              isMailExchangeEnabled: true,
              mailExchangeSettings: DynDNSMailExchangeSettings(
                hostName: 'mail exchange',
                isBackup: true,
              ),
            ),
          ),
        ));
        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'DDNS - dyn.com system type',
      (tester, locale) async {
        when(mockDDNSNotifier.build())
            .thenReturn(DDNSState.fromMap(ddnsTestState).copyWith(
          provider: DynDNSProvider(
            settings: const DynDNSSettings(
              username: 'username',
              password: 'password',
              hostName: 'hostname',
              isWildcardEnabled: true,
              mode: 'Dynamic',
              isMailExchangeEnabled: true,
              mailExchangeSettings: DynDNSMailExchangeSettings(
                hostName: 'mail exchange',
                isBackup: true,
              ),
            ),
          ),
        ));
        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final systemTypeFinder = find.byType(AppDropdownButton<DynDDNSSystem>);
        await tester.tap(systemTypeFinder.first);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'DDNS - No-IP.com',
      (tester, locale) async {
        when(mockDDNSNotifier.build()).thenReturn(
            DDNSState.fromMap(ddnsTestState)
                .copyWith(provider: DDNSProvider.create(noIPDNSProviderName)));
        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'DDNS - No-IP.com filled up',
      (tester, locale) async {
        when(mockDDNSNotifier.build())
            .thenReturn(DDNSState.fromMap(ddnsTestState).copyWith(
          provider: NoIPDNSProvider(
            settings: const NoIPSettings(
              username: 'username',
              password: 'password',
              hostName: 'hostname',
            ),
          ),
        ));
        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'DDNS - TZO',
      (tester, locale) async {
        when(mockDDNSNotifier.build()).thenReturn(
            DDNSState.fromMap(ddnsTestState)
                .copyWith(provider: DDNSProvider.create(tzoDNSProviderName)));
        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'DDNS - TZO filled up',
      (tester, locale) async {
        when(mockDDNSNotifier.build())
            .thenReturn(DDNSState.fromMap(ddnsTestState).copyWith(
          provider: TzoDNSProvider(
            settings: const TZOSettings(
              username: 'username',
              password: 'password',
              hostName: 'hostname',
            ),
          ),
        ));
        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens
            .map((e) => e.copyWith(height: 1280))
            .toList(),
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );
  });

  group('Apps & Gaming - Single port forwarding', () {
    testLocalizations('Single port forwarding - with data',
        (tester, locale) async {
      when(mockSinglePortForwardingListNotifier.build()).thenReturn(
          SinglePortForwardingListState.fromMap(
              singlePortForwardingListTestState));

      final widget = testableSingleRoute(
        overrides: [
          appsAndGamingProvider
              .overrideWith(() => mockAppsAndGamingViewNotifier),
          ddnsProvider.overrideWith(() => mockDDNSNotifier),
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier),
          portRangeTriggeringListProvider
              .overrideWith(() => mockPortRangeTriggeringListNotifier),
        ],
        locale: locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpWidget(widget);

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(1));
      await tester.pumpAndSettle();
    });

    testLocalizations('Single port forwarding - empty', (tester, locale) async {
      when(mockSinglePortForwardingListNotifier.build()).thenReturn(
          SinglePortForwardingListState.fromMap(
              singlePortForwardingEmptyListTestState));

      final widget = testableSingleRoute(
        overrides: [
          appsAndGamingProvider
              .overrideWith(() => mockAppsAndGamingViewNotifier),
          ddnsProvider.overrideWith(() => mockDDNSNotifier),
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier),
          portRangeTriggeringListProvider
              .overrideWith(() => mockPortRangeTriggeringListNotifier),
        ],
        locale: locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpWidget(widget);

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(1));
      await tester.pumpAndSettle();
    });

    testLocalizations(
      'Single port forwarding - edit',
      (tester, locale) async {
        when(mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(1));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Single port forwarding - edit error',
      (tester, locale) async {
        // TODO: preserve test case for the error message on dektop table
        when(mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(1));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Single port forwarding - edit overlap error',
      (tester, locale) async {
        // TODO: preserve test case for the error message on dektop table
        when(mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingListTestState));
        when(mockSinglePortForwardingRuleNotifier.isPortConflict(any, any))
            .thenAnswer((invocation) => false);

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            singlePortForwardingRuleProvider
                .overrideWith(() => mockSinglePortForwardingRuleNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(1));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '3333');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '22');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).at(0);
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '123');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Single port forwarding - edit filled up',
      (tester, locale) async {
        when(mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(1));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '40');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).at(0);
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '15');
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Single port forwarding - edit',
      (tester, locale) async {
        // For mobile layout
        when(mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
          ],
          locale: locale,
          child: const SinglePortForwardingRuleView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Single port forwarding - edit error',
      (tester, locale) async {
        // For mobile layout
        when(mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
          ],
          locale: locale,
          child: const SinglePortForwardingRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '40');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).at(0);
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '1');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Single port forwarding - edit overlap error',
      (tester, locale) async {
        // For mobile layout
        when(mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingListTestState));
        when(mockSinglePortForwardingRuleNotifier.isPortConflict(any, any))
            .thenAnswer((invocation) => false);

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            singlePortForwardingRuleProvider
                .overrideWith(() => mockSinglePortForwardingRuleNotifier),
          ],
          locale: locale,
          child: const SinglePortForwardingRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '3333');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '22');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).at(0);
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '123');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Single port forwarding - edit filled up',
      (tester, locale) async {
        // For mobile layout
        when(mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
          ],
          locale: locale,
          child: const SinglePortForwardingRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '40');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).at(0);
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '15');
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );
  });

  group('Apps & Gaming - Port range forwarding', () {
    testLocalizations('Port range forwarding - with data',
        (tester, locale) async {
      when(mockPortRangeForwardingListNotifier.build()).thenReturn(
          PortRangeForwardingListState.fromMap(
              portRangeForwardingListTestState));

      final widget = testableSingleRoute(
        overrides: [
          appsAndGamingProvider
              .overrideWith(() => mockAppsAndGamingViewNotifier),
          ddnsProvider.overrideWith(() => mockDDNSNotifier),
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier),
          portRangeTriggeringListProvider
              .overrideWith(() => mockPortRangeTriggeringListNotifier),
        ],
        locale: locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpWidget(widget);

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(2));
      await tester.pumpAndSettle();
    });

    testLocalizations('Port range forwarding - empty', (tester, locale) async {
      when(mockPortRangeForwardingListNotifier.build()).thenReturn(
          PortRangeForwardingListState.fromMap(
              portRangeForwardingEmptyListTestState));

      final widget = testableSingleRoute(
        overrides: [
          appsAndGamingProvider
              .overrideWith(() => mockAppsAndGamingViewNotifier),
          ddnsProvider.overrideWith(() => mockDDNSNotifier),
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier),
          portRangeTriggeringListProvider
              .overrideWith(() => mockPortRangeTriggeringListNotifier),
        ],
        locale: locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpWidget(widget);

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(2));
      await tester.pumpAndSettle();
    });

    testLocalizations(
      'Port range forwarding - edit',
      (tester, locale) async {
        final portRangeForwardingEmptyListState =
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState);
        when(mockPortRangeForwardingListNotifier.build())
            .thenReturn(portRangeForwardingEmptyListState);
        // when(mockPortRangeForwardingRuleNotifier.build())
        //     .thenReturn(PortRangeForwardingRuleState(
        //   rules: portRangeForwardingEmptyListState.rules,
        //   routerIp: portRangeForwardingEmptyListState.routerIp,
        //   subnetMask: portRangeForwardingEmptyListState.subnetMask,
        // ));
        // when(mockPortRangeForwardingRuleNotifier.isRuleValid())
        //     .thenAnswer((invocation) => true);

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            // portRangeForwardingRuleProvider
            //     .overrideWith(() => mockPortRangeForwardingRuleNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - edit error',
      (tester, locale) async {
        // TODO: preserve test case for the error message on dektop table
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '10');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).first;
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '1');
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - edit overlap error',
      (tester, locale) async {
        // TODO: preserve test case for the error message on dektop table
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingListTestState));
        when(mockPortRangeForwardingRuleNotifier.isPortRangeValid(any, any))
            .thenAnswer((invocation) => false);
        when(mockPortRangeForwardingRuleNotifier.isPortConflict(any, any, any))
            .thenAnswer((invocation) => false);

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeForwardingRuleProvider
                .overrideWith(() => mockPortRangeForwardingRuleNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '5000');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '5005');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).first;
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '1');
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - edit filled up',
      (tester, locale) async {
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '40');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).first;
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '15');
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - protocol',
      (tester, locale) async {
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(Tab);
        await tester.tap(tabFinder.at(2));
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final protocolTypeFinder = find.byType(AppDropdownButton<String>).first;
        await tester.tap(protocolTypeFinder.first);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - edit',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
          ],
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - edit error',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
          ],
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '10');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).at(0);
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '1');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - edit overlap error',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingListTestState));
        when(mockPortRangeForwardingRuleNotifier.isPortRangeValid(any, any))
            .thenAnswer((invocation) => false);
        when(mockPortRangeForwardingRuleNotifier.isPortConflict(any, any, any))
            .thenAnswer((invocation) => false);

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeForwardingRuleProvider
                .overrideWith(() => mockPortRangeForwardingRuleNotifier),
          ],
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '5000');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '5005');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).at(0);
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '1');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - edit filled up',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
          ],
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '40');
        await tester.pumpAndSettle();

        // Tap IP address form
        final ipAddressForm = find.byType(AppIPFormField).at(0);
        await tester.tap(ipAddressForm);
        // Input
        final ipAddressTextFormField = find.descendant(
            of: ipAddressForm, matching: find.byType(TextFormField));
        await tester.enterText(ipAddressTextFormField.at(0), '15');
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - protocol',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
          ],
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );
        await tester.pumpWidget(widget);

        final protocolTypeFinder = find.byType(AppDropdownButton<String>);
        await tester.tap(protocolTypeFinder.first);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );
  });

  group('Apps & Gaming - Port range triggerring', () {
    testLocalizations('Port range triggerring - with data',
        (tester, locale) async {
      when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
          PortRangeTriggeringListState.fromMap(portRangeTriggerListTestState));

      final widget = testableSingleRoute(
        overrides: [
          appsAndGamingProvider
              .overrideWith(() => mockAppsAndGamingViewNotifier),
          ddnsProvider.overrideWith(() => mockDDNSNotifier),
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier),
          portRangeTriggeringListProvider
              .overrideWith(() => mockPortRangeTriggeringListNotifier),
        ],
        locale: locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpWidget(widget);

      final tabFinder = find.byType(AppTabBar);
      final portRangeTriggeringFinder = find.byKey(Key('portRangeTriggering'));
      await tester.drag(tabFinder, Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(portRangeTriggeringFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations('Port range triggerring - empty', (tester, locale) async {
      when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
          PortRangeTriggeringListState.fromMap(
              portRangeTriggerEmptyListTestState));

      final widget = testableSingleRoute(
        overrides: [
          appsAndGamingProvider
              .overrideWith(() => mockAppsAndGamingViewNotifier),
          ddnsProvider.overrideWith(() => mockDDNSNotifier),
          singlePortForwardingListProvider
              .overrideWith(() => mockSinglePortForwardingListNotifier),
          portRangeForwardingListProvider
              .overrideWith(() => mockPortRangeForwardingListNotifier),
          portRangeTriggeringListProvider
              .overrideWith(() => mockPortRangeTriggeringListNotifier),
        ],
        locale: locale,
        child: const AppsGamingSettingsView(),
      );
      await tester.pumpWidget(widget);

      final tabFinder = find.byType(AppTabBar);
      final portRangeTriggeringFinder = find.byKey(Key('portRangeTriggering'));
      await tester.drag(tabFinder, Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(portRangeTriggeringFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations(
      'Port range triggerring - edit',
      (tester, locale) async {
        when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(AppTabBar);
        final portRangeTriggeringFinder =
            find.byKey(Key('portRangeTriggering'));
        await tester.drag(tabFinder, Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(portRangeTriggeringFinder);
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range triggerring - edit error',
      (tester, locale) async {
        // TODO: preserve test case for the error message on dektop table
        when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(AppTabBar);
        final portRangeTriggeringFinder =
            find.byKey(Key('portRangeTriggering'));
        await tester.drag(tabFinder, Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(portRangeTriggeringFinder);
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '10');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(3), '40');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(4), '30');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range triggerring - edit overlap error',
      (tester, locale) async {
        // TODO: preserve test case for the error message on dektop table
        when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerListTestState));
        when(mockPortRangeTriggeringRuleNotifier.isTriggeredPortConflict(
                any, any))
            .thenAnswer((invocation) => false);

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
            portRangeTriggeringRuleProvider
                .overrideWith(() => mockPortRangeTriggeringRuleNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(AppTabBar);
        final portRangeTriggeringFinder =
            find.byKey(Key('portRangeTriggering'));
        await tester.drag(tabFinder, Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(portRangeTriggeringFinder);
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '6000');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '6001');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(3), '7000');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(4), '7001');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range triggerring - edit filled up',
      (tester, locale) async {
        when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
        await tester.pumpWidget(widget);

        final tabFinder = find.byType(AppTabBar);
        final portRangeTriggeringFinder =
            find.byKey(Key('portRangeTriggering'));
        await tester.drag(tabFinder, Offset(-500, 0));
        await tester.pumpAndSettle();
        await tester.tap(portRangeTriggeringFinder);
        await tester.pumpAndSettle();

        final addBtnFinder = find.byIcon(LinksysIcons.add);
        await tester.tap(addBtnFinder);
        await tester.pumpAndSettle();

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '10');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(3), '30');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(4), '40');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveDesktopScreens
            .map((e) => e.copyWith(height: 1080))
            .toList()
      ],
    );

    testLocalizations(
      'Port range triggerring - edit',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const PortRangeTriggeringRuleView(),
        );
        await tester.pumpWidget(widget);
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range triggerring - edit error',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const PortRangeTriggeringRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '10');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(3), '40');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(4), '30');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range triggerring - edit overlap error',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerListTestState));
        when(mockPortRangeTriggeringRuleNotifier.isTriggeredPortConflict(
                any, any))
            .thenAnswer((invocation) => false);

        final widget = testableSingleRoute(
          overrides: [
            appsAndGamingProvider
                .overrideWith(() => mockAppsAndGamingViewNotifier),
            ddnsProvider.overrideWith(() => mockDDNSNotifier),
            singlePortForwardingListProvider
                .overrideWith(() => mockSinglePortForwardingListNotifier),
            portRangeForwardingListProvider
                .overrideWith(() => mockPortRangeForwardingListNotifier),
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
            portRangeTriggeringRuleProvider
                .overrideWith(() => mockPortRangeTriggeringRuleNotifier),
          ],
          locale: locale,
          child: const PortRangeTriggeringRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '6000');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '6001');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(3), '7000');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(4), '7001');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range triggerring - edit filled up',
      (tester, locale) async {
        // For mobile layout
        when(mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        final widget = testableSingleRoute(
          overrides: [
            portRangeTriggeringListProvider
                .overrideWith(() => mockPortRangeTriggeringListNotifier),
          ],
          locale: locale,
          child: const PortRangeTriggeringRuleView(),
        );
        await tester.pumpWidget(widget);

        final textFieldFinder = find.byType(AppTextField);
        await tester.enterText(textFieldFinder.at(0), 'name');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(1), '10');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(2), '20');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(3), '30');
        await tester.pumpAndSettle();

        await tester.enterText(textFieldFinder.at(4), '40');
        await tester.pumpAndSettle();

        await tester.tap(textFieldFinder.at(0));
        await tester.pumpAndSettle();
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );
  });
}
