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

import '../../../../../common/test_responsive_widget.dart';
import '../../../../../common/testable_router.dart';
import '../../../../../test_data/device_list_test_state.dart';
import '../../../../../test_data/dmz_settings_test_state.dart';
import '../../../../../mocks/device_list_notifier_mock.dart';
import '../../../../../mocks/dmz_setting_notifier_mocks.dart';

void main() {
  late DMZSettingNotifier mockDMZSettingNotifier;

  setUp(() {
    mockDMZSettingNotifier = MockDMZSettingNotifier();
    when(mockDMZSettingNotifier.build())
        .thenReturn(DMZSettingsState.fromMap(dmzSettingsTestState));
    when(mockDMZSettingNotifier.fetch()).thenAnswer((_) async {
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
      testableSingleRoute(
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
  });
  testLocalizations('DMZ settings view - enabled', (tester, locale) async {
    await tester.pumpWidget(
      testableSingleRoute(
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
  });

  testLocalizations('DMZ settings view - enabled with specific range source',
      (tester, locale) async {
    var state = DMZSettingsState.fromMap(dmzSettingsTestState);
    state = state.copyWith(sourceType: DMZSourceType.range);
    when(mockDMZSettingNotifier.build()).thenReturn(state);
    when(mockDMZSettingNotifier.fetch()).thenAnswer((_) async {
      await Future.delayed(const Duration(seconds: 1));
      return state;
    });
    await tester.pumpWidget(
      testableSingleRoute(
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
  });

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
      testableSingleRoute(
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
  });

  testLocalizations('DMZ settings view - view DHCP client table',
      (tester, locale) async {
    final mockDeviceListNotifier = MockDeviceListNotifier();
    when(mockDeviceListNotifier.build())
        .thenReturn(DeviceListState.fromMap(deviceListTestState));
    await tester.pumpWidget(
      testableSingleRoute(
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
  });

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
      testableSingleRoute(
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
  });

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
      testableSingleRoute(
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
  });
}
