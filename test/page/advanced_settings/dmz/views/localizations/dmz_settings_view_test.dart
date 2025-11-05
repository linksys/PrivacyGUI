import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/instant_device/providers/device_list_state.dart';
import 'package:privacy_gui/page/instant_device/views/select_device_view.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacy_gui/route/route_model.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';

import '../../../../../common/config.dart';
import '../../../../../common/test_helper.dart';
import '../../../../../common/test_responsive_widget.dart';
import '../../../../../test_data/device_list_test_state.dart';
import '../../../../../test_data/dmz_settings_test_state.dart';

void main() {
  final testHelper = TestHelper();

  setUp(() {
    testHelper.setup();
    final state = DMZSettingsState.fromMap(dmzSettingsTestState);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
  });
  testLocalizations('DMZ settings view - disabled', (tester, locale) async {
    const settings = DMZUISettings(
        isDMZEnabled: false,
        sourceType: DMZSourceType.auto,
        destinationType: DMZDestinationType.ip);
    final state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));
    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);
  testLocalizations('DMZ settings view - enabled', (tester, locale) async {
    const settings = DMZUISettings(
        isDMZEnabled: true,
        sourceType: DMZSourceType.auto,
        destinationType: DMZDestinationType.ip);
    final state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));
    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations('DMZ settings view - enabled with specific range source',
      (tester, locale) async {
    const settings = DMZUISettings(
        isDMZEnabled: true,
        sourceType: DMZSourceType.range,
        destinationType: DMZDestinationType.ip,
        sourceRestriction: DMZSourceRestriction(
            firstIPAddress: '192.168.1.23', lastIPAddress: '192.168.1.78'));
    final state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));

    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations(
      'DMZ settings view - enabled with specific range source - error state',
      (tester, locale) async {
    const settings = DMZUISettings(
        isDMZEnabled: true,
        sourceType: DMZSourceType.range,
        destinationType: DMZDestinationType.ip,
        sourceRestriction: DMZSourceRestriction(
            firstIPAddress: '192.168.1.23', lastIPAddress: '192.168.1.78'));
    var state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));

    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppIPFormField).at(1));
    final startIPInputForm = find.descendant(
        of: find.byType(AppIPFormField).at(1),
        matching: find.byType(TextFormField));
    await tester.enterText(startIPInputForm.at(3), '1');
    await tester.pumpAndSettle();
    await tester.tap(find.byType(AppCard).first);
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations(
      'DMZ settings view - enabled with IP address destination - error state',
      (tester, locale) async {
    const settings = DMZUISettings(
        isDMZEnabled: true,
        sourceType: DMZSourceType.auto,
        destinationType: DMZDestinationType.ip,
        destinationIPAddress: '192.168.1.1');
    var state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));
    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
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
    const settings = DMZUISettings(
        isDMZEnabled: true,
        sourceType: DMZSourceType.auto,
        destinationType: DMZDestinationType.mac,
        destinationMACAddress: '00:11:22:33:44:55');
    var state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));
    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations(
      'DMZ settings view - enabled with mac address destination - error state',
      (tester, locale) async {
    const settings = DMZUISettings(
        isDMZEnabled: true,
        sourceType: DMZSourceType.auto,
        destinationType: DMZDestinationType.mac,
        destinationMACAddress: '00:11:22:33:44:55');
    var state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));
    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
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
    when(testHelper.mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(deviceListTestState));
    await testHelper.pumpShellView(
      tester,
      child: const SelectDeviceView(args: {
        'type': 'ipv4AndMac',
        'selectMode': 'single',
        'onlineOnly': true,
      }),
      locale: locale,
    );
    await tester.pumpAndSettle();
  }, screens: [
    ...responsiveMobileScreens.map((e) => e.copyWith(height: 1024)),
    ...responsiveDesktopScreens.map((e) => e.copyWith(height: 1024)),
  ]);

  testLocalizations('DMZ settings view - Saved', (tester, locale) async {
    final settings = const DMZUISettings(
        isDMZEnabled: true,
        sourceType: DMZSourceType.auto,
        destinationType: DMZDestinationType.ip);
    final state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));
    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(testHelper.mockDMZSettingsNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
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
    final settings = const DMZUISettings(
        isDMZEnabled: true,
        sourceType: DMZSourceType.auto,
        destinationType: DMZDestinationType.ip);
    final state = DMZSettingsState.fromMap(dmzSettingsTestState)
        .copyWith(settings: Preservable(original: settings, current: settings));
    when(testHelper.mockDMZSettingsNotifier.build()).thenReturn(state);
    when(testHelper.mockDMZSettingsNotifier.fetch(forceRemote: anyNamed('forceRemote')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    when(testHelper.mockDMZSettingsNotifier.save()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      throw const JNAPError(result: 'ErrorMissingDestination');
    });
    await testHelper.pumpShellView(
      tester,
      child: const DMZSettingsView(),
      config: LinksysRouteConfig(
        column: ColumnGrid(column: 9),
      ),
      locale: locale,
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
