import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/dyn_dns_settings.dart';
import 'package:privacy_gui/core/jnap/models/no_ip_settings.dart';
import 'package:privacy_gui/core/jnap/models/tzo_settings.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/views/dyn_ddns_form.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/input_field/app_text_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/tab_bar/linksys_tab_bar.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/ddns_test_state.dart';
import '../../../../../test_data/port_range_forwarding_test_state.dart';
import '../../../../../test_data/port_range_trigger_test_state.dart';
import '../../../../../test_data/single_port_forwarding_test_state.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    when(testHelper.mockDDNSNotifier.fetch()).thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return DDNSState.fromMap(ddnsTestState);
    });
    when(testHelper.mockSinglePortForwardingListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return SinglePortForwardingListState.fromMap(
          singlePortForwardingListTestState);
    });
    when(testHelper.mockPortRangeForwardingListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return PortRangeForwardingListState.fromMap(
          portRangeForwardingListTestState);
    });
    when(testHelper.mockPortRangeTriggeringListNotifier.fetch())
        .thenAnswer((realInvocation) async {
      await Future.delayed(const Duration(seconds: 1));
      return PortRangeTriggeringListState.fromMap(portRangeTriggerListTestState);
    });
  });

  group('Apps & Gaming - DDNS', () {
    testLocalizations('DDNS - disable', (tester, locale) async {
      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const AppsGamingSettingsView(),
      );
    });

    testLocalizations(
      'DDNS - dyn.com',
      (tester, locale) async {
        final state = DDNSState.fromMap(ddnsTestState);
        final settings =
            DDNSSettings(provider: DDNSProvider.create(dynDNSProviderName));
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
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
        final state = DDNSState.fromMap(ddnsTestState);
        final settings = DDNSSettings(
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
        );
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
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
        final state = DDNSState.fromMap(ddnsTestState);
        final settings = DDNSSettings(
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
        );

        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        final state = DDNSState.fromMap(ddnsTestState);
        final settings =
            DDNSSettings(provider: DDNSProvider.create(noIPDNSProviderName));
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
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
        final state = DDNSState.fromMap(ddnsTestState);
        final settings = DDNSSettings(
            provider: NoIPDNSProvider(
          settings: const NoIPSettings(
            username: 'username',
            password: 'password',
            hostName: 'hostname',
          ),
        ));

        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
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
        final state = DDNSState.fromMap(ddnsTestState);
        final settings =
            DDNSSettings(provider: DDNSProvider.create(tzoDNSProviderName));
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
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
        final state = DDNSState.fromMap(ddnsTestState);
        final settings = DDNSSettings(
            provider: TzoDNSProvider(
          settings: const TZOSettings(
            username: 'username',
            password: 'password',
            hostName: 'hostname',
          ),
        ));
        when(testHelper.mockDDNSNotifier.build()).thenReturn(state.copyWith(
            settings: Preservable(original: settings, current: settings)));
        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );
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
      when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
          SinglePortForwardingListState.fromMap(
              singlePortForwardingListTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const AppsGamingSettingsView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(1));
      await tester.pumpAndSettle();
    });

    testLocalizations('Single port forwarding - empty', (tester, locale) async {
      when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
          SinglePortForwardingListState.fromMap(
              singlePortForwardingEmptyListTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const AppsGamingSettingsView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(1));
      await tester.pumpAndSettle();
    });

    testLocalizations(
      'Single port forwarding - edit',
      (tester, locale) async {
        when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingListTestState));
        when(testHelper.mockSinglePortForwardingRuleNotifier.isPortConflict(any, any))
            .thenAnswer((invocation) => false);

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const SinglePortForwardingRuleView(),
        );
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Single port forwarding - edit error',
      (tester, locale) async {
        // For mobile layout
        when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const SinglePortForwardingRuleView(),
        );

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
        when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingListTestState));
        when(testHelper.mockSinglePortForwardingRuleNotifier.isPortConflict(any, any))
            .thenAnswer((invocation) => false);

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const SinglePortForwardingRuleView(),
        );

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
        when(testHelper.mockSinglePortForwardingListNotifier.build()).thenReturn(
            SinglePortForwardingListState.fromMap(
                singlePortForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const SinglePortForwardingRuleView(),
        );

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
      when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
          PortRangeForwardingListState.fromMap(
              portRangeForwardingListTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const AppsGamingSettingsView(),
      );

      final tabFinder = find.byType(Tab);
      await tester.tap(tabFinder.at(2));
      await tester.pumpAndSettle();
    });

    testLocalizations('Port range forwarding - empty', (tester, locale) async {
      when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
          PortRangeForwardingListState.fromMap(
              portRangeForwardingEmptyListTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const AppsGamingSettingsView(),
      );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build())
            .thenReturn(portRangeForwardingEmptyListState);

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingListTestState));
        when(testHelper.mockPortRangeForwardingRuleNotifier.isPortRangeValid(any, any))
            .thenAnswer((invocation) => false);
        when(testHelper.mockPortRangeForwardingRuleNotifier.isPortConflict(any, any, any))
            .thenAnswer((invocation) => false);

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range forwarding - edit error',
      (tester, locale) async {
        // For mobile layout
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingListTestState));
        when(testHelper.mockPortRangeForwardingRuleNotifier.isPortRangeValid(any, any))
            .thenAnswer((invocation) => false);
        when(testHelper.mockPortRangeForwardingRuleNotifier.isPortConflict(any, any, any))
            .thenAnswer((invocation) => false);

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );

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
        when(testHelper.mockPortRangeForwardingListNotifier.build()).thenReturn(
            PortRangeForwardingListState.fromMap(
                portRangeForwardingEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeForwardingRuleView(),
        );

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
      when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
          PortRangeTriggeringListState.fromMap(portRangeTriggerListTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const AppsGamingSettingsView(),
      );

      final tabFinder = find.byType(AppTabBar);
      final portRangeTriggeringFinder = find.byKey(Key('portRangeTriggering'));
      await tester.drag(tabFinder, Offset(-500, 0));
      await tester.pumpAndSettle();
      await tester.tap(portRangeTriggeringFinder);
      await tester.pumpAndSettle();
    });

    testLocalizations('Port range triggerring - empty', (tester, locale) async {
      when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
          PortRangeTriggeringListState.fromMap(
              portRangeTriggerEmptyListTestState));

      await testHelper.pumpView(
        tester,
        locale: locale,
        child: const AppsGamingSettingsView(),
      );

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
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerListTestState));
        when(testHelper.mockPortRangeTriggeringRuleNotifier.isTriggeredPortConflict(
                any, any))
            .thenAnswer((invocation) => false);

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const AppsGamingSettingsView(),
        );

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
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeTriggeringRuleView(),
        );
      },
      screens: [
        ...responsiveMobileScreens.map((e) => e.copyWith(height: 1280)).toList()
      ],
    );

    testLocalizations(
      'Port range triggerring - edit error',
      (tester, locale) async {
        // For mobile layout
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeTriggeringRuleView(),
        );

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
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerListTestState));
        when(testHelper.mockPortRangeTriggeringRuleNotifier.isTriggeredPortConflict(
                any, any))
            .thenAnswer((invocation) => false);

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeTriggeringRuleView(),
        );

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
        when(testHelper.mockPortRangeTriggeringListNotifier.build()).thenReturn(
            PortRangeTriggeringListState.fromMap(
                portRangeTriggerEmptyListTestState));

        await testHelper.pumpView(
          tester,
          locale: locale,
          child: const PortRangeTriggeringRuleView(),
        );

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
