import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/dashboard_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/_advanced_settings.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/dashboard_manager_notifier_mocks.dart';
import '../../../mocks/device_filter_config_notifier_mocks.dart';
import '../../../mocks/wifi_list_notifier_mocks.dart';
import '../../../mocks/external_device_detail_notifier_mocks.dart';
import '../../../test_data/_index.dart';

const _refused = ReadOnlyAccessException(JNAPAction.setDMZSettings);
const _invalidIp = JNAPError(result: 'ErrorInvalidIPAddress');

/// The real notifier with the router taken out: it loads a fixed state, keeps
/// the real setters the page edits through, and its save fails with [error].
class _FailingDMZ extends DMZSettingNotifier {
  _FailingDMZ(this.error);
  final Object error;

  @override
  DMZSettingsState build() => DMZSettingsState.fromMap(dmzSettingsTestState);

  @override
  Future<DMZSettingsState> fetch([bool force = false]) async => state;

  @override
  Future<DMZSettingsState> save() async {
    // Fails after a round trip, as a real save does. doSomethingWithSpinner
    // only attaches to the task once its spinner is up, about 100 ms in.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw error;
  }
}

class _FailingAdministration extends AdministrationSettingsNotifier {
  _FailingAdministration(this.error);
  final Object error;

  @override
  AdministrationSettingsState build() =>
      AdministrationSettingsState.fromMap(administrationSettingsTestState);

  @override
  Future<AdministrationSettingsState> fetch([bool force = false]) async =>
      state;

  @override
  Future<AdministrationSettingsState> save() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw error;
  }
}

class _FailingDeviceManager extends DeviceManagerNotifier {
  _FailingDeviceManager(this.error);
  final Object error;

  @override
  DeviceManagerState build() =>
      DeviceManagerState.fromMap(deviceManagerCherry7TestState);

  @override
  Future<void> deauthClient({required String macAddress}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw error;
  }

  @override
  Future<void> deleteDevices({required List<String> deviceIds}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw error;
  }
}

/// The real notifier with the router taken out; its save fails with [error].
class _FailingLocalNetwork extends LocalNetworkSettingsNotifier {
  _FailingLocalNetwork(this.error);
  final Object error;

  @override
  LocalNetworkSettingsState build() =>
      LocalNetworkSettingsState.fromMap(mockLocalNetworkSettingsState)
          .copyWith(dhcpReservationList: []);

  @override
  Future<LocalNetworkSettingsState> fetch({bool fetchRemote = false}) async =>
      state;

  @override
  Future<void> saveSettings(LocalNetworkSettingsState settings,
      {String? previousIPAddress}) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    throw error;
  }
}

// #1637: these pages report a failed save through PageSnackbarMixin instead of
// each building its own message. A known error code keeps its own message, and
// a write refused in read-only mode adds nothing: the app root explains it.
void main() {
  mockDependencyRegister();

  Future<void> pumpPage(WidgetTester tester, Widget page, overrides) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: overrides,
      child: page,
    ));
    await tester.pumpAndSettle();
  }

  Finder switchLabelled(String label) =>
      find.byWidgetPredicate((w) => w is AppSwitch && w.semanticLabel == label);

  Future<void> save(WidgetTester tester) async {
    await tester.tap(find.text('Save'));
    await tester.pump(const Duration(seconds: 1));
  }

  group('DMZ', () {
    Future<void> failSave(WidgetTester tester, Object error) async {
      await pumpPage(tester, const DMZSettingsView(), [
        dmzSettingsProvider.overrideWith(() => _FailingDMZ(error)),
      ]);
      // Any change enables Save; turning DMZ off needs no valid form.
      await tester.tap(switchLabelled('dmz'));
      await tester.pumpAndSettle();
      await save(tester);
    }

    testWidgets('a known error code keeps its message', (tester) async {
      await failSave(tester, _invalidIp);

      expect(find.text('Invalid IP address'), findsOneWidget);
    });

    testWidgets('a refused write adds no message of its own', (tester) async {
      await failSave(tester, _refused);

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('Administration', () {
    Future<void> failSave(WidgetTester tester, Object error) async {
      await pumpPage(tester, const AdministrationSettingsView(), [
        administrationSettingsProvider
            .overrideWith(() => _FailingAdministration(error)),
      ]);
      await tester.tap(switchLabelled('upnp switch'));
      await tester.pumpAndSettle();
      await save(tester);
    }

    // The page said "Unknown error: JNAPError" for every failure: a release
    // build prints a JNAPError as its type name only.
    testWidgets('a known error code gets its own message', (tester) async {
      await failSave(tester, _invalidIp);

      expect(find.text('Invalid IP address'), findsOneWidget);
    });

    testWidgets('a refused write adds no message of its own', (tester) async {
      await failSave(tester, _refused);

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  // Delete runs through the same handler on the offline list; deauth is the one
  // an online device offers.
  group('device list', () {
    Future<void> failDeauth(WidgetTester tester, Object error) async {
      final filter = MockDeviceFilterConfigNotifier();
      when(filter.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final wifiList = MockWifiListNotifier();
      when(wifiList.build()).thenReturn(WiFiState.fromMap(wifiListTestState));
      final dashboardManager = MockDashboardManagerNotifier();
      when(dashboardManager.build()).thenReturn(
          DashboardManagerState.fromMap(dashboardManagerChrry7TestState));
      when(serviceHelper.isSupportClientDeauth()).thenReturn(true);
      await pumpPage(tester, const InstantDeviceView(), [
        deviceFilterConfigProvider.overrideWith(() => filter),
        wifiListProvider.overrideWith(() => wifiList),
        dashboardManagerProvider.overrideWith(() => dashboardManager),
        deviceManagerProvider.overrideWith(() => _FailingDeviceManager(error)),
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .take(1)
            .toList()),
      ]);
      await tester.tap(find.byIcon(LinksysIcons.bidirectional));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Disconnect'));
      await tester.pump(const Duration(seconds: 1));
    }

    // The page said "Oops, something wrong here!" for every failure.
    testWidgets('a known error code gets its own message', (tester) async {
      await failDeauth(tester, _invalidIp);

      expect(find.text('Invalid IP address'), findsOneWidget);
    });

    testWidgets('a refused write adds no message of its own', (tester) async {
      await failDeauth(tester, _refused);

      expect(find.byType(SnackBar), findsNothing);
    });
  });

  group('Reserve IP', () {
    Future<void> failReserve(WidgetTester tester, Object error) async {
      final device = MockExternalDeviceDetailNotifier();
      when(device.build()).thenReturn(
          ExternalDeviceDetailState.fromMap(deviceDetailsTestState1));
      await pumpPage(tester, const DeviceDetailView(), [
        externalDeviceDetailProvider.overrideWith(() => device),
        localNetworkSettingProvider
            .overrideWith(() => _FailingLocalNetwork(error)),
      ]);
      await tester.tap(find.text('Reserve IP'));
      await tester.pumpAndSettle();
      // The confirm dialog's own Reserve IP button.
      await tester.tap(find.text('Reserve IP').last);
      await tester.pump(const Duration(seconds: 1));
    }

    // The page showed the raw result code, "ErrorInvalidIPAddress".
    testWidgets('a known error code gets its own message', (tester) async {
      await failReserve(tester, _invalidIp);

      expect(find.text('Invalid IP address'), findsOneWidget);
      expect(find.text('ErrorInvalidIPAddress'), findsNothing);
    });

    testWidgets('a refused write adds no message of its own', (tester) async {
      await failReserve(tester, _refused);

      expect(find.byType(SnackBar), findsNothing);
    });
  });
}
