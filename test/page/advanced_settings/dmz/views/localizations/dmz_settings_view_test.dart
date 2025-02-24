import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/views/dmz_settings_view.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_provider.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/device_list_test_state.dart';
import '../../../../../test_data/dmz_settings_test_state.dart';
import '../../../../../mocks/device_list_notifier_mock.dart';
import '../../../../../mocks/dmz_setting_notifier_mocks.dart';

void main() {
  late MockDMZSettingNotifier mockDMZSettingNotifier;

  setUp(() {
    mockDMZSettingNotifier = MockDMZSettingNotifier();
    when(mockDMZSettingNotifier.build())
        .thenReturn(DMZSettingsState.fromMap(dmzSettingsTestState));
    when(mockDMZSettingNotifier.fetch(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return DMZSettingsState.fromMap(dmzSettingsTestState);
    });
    when(mockDMZSettingNotifier.subnetMask).thenReturn('255.255.0.0');
    when(mockDMZSettingNotifier.ipAddress).thenReturn('192.168.1.1');
  });
  testLocalizations('DMZ settings view - disabled', (tester, locale) async {
    final state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: const DMZSettings(isDMZEnabled: false));
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);
  testLocalizations('DMZ settings view - enabled', (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations('DMZ settings view - enabled with specific range source',
      (tester, locale) async {
    var state = DMZSettingsState.fromMap(dmzSettingsTestState);
    state = state.copyWith(
      sourceType: DMZSourceType.range,
      settings: state.settings.copyWith(
        sourceRestriction: () => DMZSourceRestriction(
          firstIPAddress: '192.168.1.23',
          lastIPAddress: '192.168.1.78',
        ),
      ),
    );
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch(any)).thenAnswer((_) async {
      return state;
    });
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations(
      'DMZ settings view - enabled with specific range source - error state',
      (tester, locale) async {
    var state = DMZSettingsState.fromMap(dmzSettingsTestState);
    state = state.copyWith(
      sourceType: DMZSourceType.range,
      settings: state.settings.copyWith(
        sourceRestriction: () => DMZSourceRestriction(
          firstIPAddress: '192.168.1.23',
          lastIPAddress: '192.168.1.78',
        ),
      ),
    );
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch(any)).thenAnswer((_) async {
      return state;
    });
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppIPFormField).at(1));
    final startIPInputForm = find.descendant(
        of: find.byType(AppIPFormField).at(1),
        matching: find.byType(TextFormField));
    await tester.enterText(startIPInputForm.at(3), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppIPFormField).at(0));
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations(
      'DMZ settings view - enabled with IP address destination - error state',
      (tester, locale) async {
    var state = DMZSettingsState.fromMap(dmzSettingsTestState);
    state = state.copyWith(destinationType: DMZDestinationType.ip);
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(AppIPFormField).at(0));
    final startIPInputForm = find.descendant(
        of: find.byType(AppIPFormField).at(0),
        matching: find.byType(TextFormField));
    await tester.enterText(startIPInputForm.at(0), '');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppCard).first);
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations('DMZ settings view - enabled with mac address destination',
      (tester, locale) async {
    var state = DMZSettingsState.fromMap(dmzSettingsTestState);
    state = state.copyWith(destinationType: DMZDestinationType.mac);
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations(
      'DMZ settings view - enabled with mac address destination - error state',
      (tester, locale) async {
    var state = DMZSettingsState.fromMap(dmzSettingsTestState);
    state = state.copyWith(destinationType: DMZDestinationType.mac);
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(TextField).at(0));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppCard).first);
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations('DMZ settings view - view DHCP client table',
      (tester, locale) async {
    final mockDeviceListNotifier = MockDeviceListNotifier();
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(deviceListTestState));
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const SelectDeviceView(args: {
          'type': 'ipv4AndMac',
          'selectMode': 'single',
          'onlineOnly': true,
        }),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
          deviceListProvider.overrideWith(() => mockDeviceListNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations('DMZ settings view - Saved', (tester, locale) async {
    final state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: const DMZSettings(isDMZEnabled: true));
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(mockDMZSettingNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppFilledButton));
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations('DMZ settings view - Save failed', (tester, locale) async {
    final state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: const DMZSettings(isDMZEnabled: true));
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(mockDMZSettingNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      throw const JNAPError(result: 'ErrorMissingDestination');
    });
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: const DMZSettingsView(),
        config: LinksysRouteConfig(
          column: ColumnGrid(column: 9),
        ),
        locale: locale,
        overrides: [
          dmzSettingsProvider.overrideWith(() => mockDMZSettingNotifier),
        ],
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppSwitch));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppFilledButton));
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);
}
