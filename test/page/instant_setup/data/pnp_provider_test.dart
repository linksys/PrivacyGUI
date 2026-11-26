// PnpNotifier's reads of the router, over a RouterBoundary: the router it sets
// up, its mode, its auto configuration, its settings and its nodes (#1921,
// #1866 wave 6). The save is in pnp_provider_save_test.dart; the Auto Master
// polls are in pnp_provider_auto_master_test.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/auto_configuration_settings.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_wifi_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/di.dart';
import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';
import 'pnp_router_data.dart';

void main() {
  mockDependencyRegister();
  final services = getIt.get<ServiceHelper>();

  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;
  late PnpNotifier notifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({pCurrentSN: 'THE-LAST-ROUTER'});
    when(services.isSupportLedMode(any)).thenReturn(true);
    when(services.isSupportPnP(any)).thenReturn(true);
    router = RouterBoundary()
      ..holds(JNAPAction.getDeviceMode, {'mode': 'Unconfigured'});
    holdPnpReads(router);
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
    notifier = container.read(pnpProvider.notifier) as PnpNotifier;
  });

  tearDown(() => container.dispose());

  group('fetchDeviceInfo', () {
    test('reads the router PnP sets up and pauses polling', () async {
      await notifier.fetchDeviceInfo();

      expect(notifier.state.deviceInfo?.serialNumber, pnpSerial);
      expect(notifier.state.deviceInfo?.modelNumber, 'LN16');
      expect(polling.paused, isTrue);
    });

    test(
        'remembers the serial for the save\'s restart, and forgets the last '
        'router\'s', () async {
      await notifier.fetchDeviceInfo();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pPnpConfiguredSN), pnpSerial);
      expect(prefs.getString(pCurrentSN), isNull);
    });

    test('can keep the last router\'s serial', () async {
      await notifier.fetchDeviceInfo(false);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pCurrentSN), 'THE-LAST-ROUTER');
    });

    test('a router that does not answer is a failed read', () async {
      router.refuses(JNAPAction.getDeviceInfo);

      await expectLater(
          notifier.fetchDeviceInfo(), throwsA(isA<ExceptionFetchDeviceInfo>()));
      expect(notifier.state.deviceInfo, isNull);
    });
  });

  group('checkRouterConfigured', () {
    test('an unconfigured router is recorded, and stops the flow', () async {
      await expectLater(notifier.checkRouterConfigured(),
          throwsA(isA<ExceptionRouterUnconfigured>()));

      expect(notifier.state.isRouterUnConfigured, isTrue);
    });

    test('a Master router is configured', () async {
      router.holds(JNAPAction.getDeviceMode, {'mode': 'Master'});

      await notifier.checkRouterConfigured();

      expect(notifier.state.isRouterUnConfigured, isFalse);
    });

    test('a router that names no mode counts as unconfigured', () async {
      router.holds(JNAPAction.getDeviceMode, {});

      await expectLater(notifier.checkRouterConfigured(),
          throwsA(isA<ExceptionRouterUnconfigured>()));
    });
  });

  group('autoConfigurationCheck', () {
    test('reads how the router was configured', () async {
      router.holds(JNAPAction.getAutoConfigurationSettings,
          pnpAutoConfiguration(method: 'AutoParent', acknowledged: true));

      final settings = await notifier.autoConfigurationCheck();

      expect(settings?.isAutoConfigurationSupported, isTrue);
      expect(settings?.autoConfigurationMethod,
          AutoConfigurationMethod.autoParent);
      expect(settings?.userAcknowledgedAutoConfiguration, isTrue);
    });

    test('asks nothing of a router without PnP', () async {
      when(services.isSupportPnP(any)).thenReturn(false);

      expect(await notifier.autoConfigurationCheck(), isNull);
      expect(router.sent, isEmpty);
    });

    test('a refused read is no answer', () async {
      router.refuses(JNAPAction.getAutoConfigurationSettings);

      expect(await notifier.autoConfigurationCheck(), isNull);
    });
  });

  group('fetchData', () {
    test('reads the settings PnP shows and saves, in one transaction',
        () async {
      await notifier.fetchData();

      expect(router.transactions, hasLength(1));
      expect(
          router.transactions.single.map((command) => command.key),
          unorderedEquals([
            JNAPAction.getSimpleWiFiSettings,
            JNAPAction.getGuestRadioSettings,
            JNAPAction.getLedNightModeSetting,
            JNAPAction.getAutoConfigurationSettings,
            JNAPAction.getBluetoothAutoOnboardingSettings,
            JNAPAction.getRadioInfo,
            JNAPAction.getWANSettings,
            JNAPAction.getFirmwareUpdateSettings,
          ]));
    });

    test('does not read night mode from a router without it', () async {
      when(services.isSupportLedMode(any)).thenReturn(false);

      await notifier.fetchData();

      expect(
          router.actions, isNot(contains(JNAPAction.getLedNightModeSetting)));
    });

    test('a pre-configured router is pre-paired', () async {
      await notifier.fetchData();

      expect(notifier.state.isPrePaired, isTrue);
    });

    test('an auto-parented router is not', () async {
      router.holds(JNAPAction.getAutoConfigurationSettings,
          pnpAutoConfiguration(method: 'AutoParent'));

      await notifier.fetchData();

      expect(notifier.state.isPrePaired, isFalse);
    });

    test('offers the router\'s WiFi as the defaults, on one name', () async {
      await notifier.fetchData();

      expect(
          notifier.getDefaultWiFiSettings(),
          const PnpWiFiSettings(isSplitMode: false, radios: [
            PnpWiFiRadio(
              radioId: 'RADIO_2.4GHz',
              band: '2.4GHz',
              ssid: 'Linksys00042',
              password: 'RouterPass1',
              security: 'WPA2/WPA3-Mixed-Personal',
              isEnabled: true,
            ),
            PnpWiFiRadio(
              radioId: 'RADIO_5GHz',
              band: '5GHz',
              ssid: 'Linksys00042',
              password: 'RouterPass1',
              security: 'WPA2/WPA3-Mixed-Personal',
              isEnabled: true,
            ),
          ]));
    });

    test('offers split bands when the router\'s bands differ', () async {
      router.holds(
          JNAPAction.getRadioInfo,
          pnpRadioInfo(radios: [
            pnpRadio('RADIO_2.4GHz', '2.4GHz'),
            pnpRadio('RADIO_5GHz', '5GHz', ssid: 'Linksys00042-5G'),
          ]));

      await notifier.fetchData();

      expect(notifier.getDefaultWiFiSettings().isSplitMode, isTrue);
    });

    test('offers no WiFi before the router was read', () {
      final defaults = notifier.getDefaultWiFiSettings();

      expect(defaults.isSplitMode, isFalse);
      expect(defaults.radios, isEmpty);
    });

    test('offers the router\'s guest WiFi as the defaults', () async {
      expect(notifier.getDefaultGuestWiFiNameAndPassPhrase(),
          (name: '', password: ''));

      await notifier.fetchData();

      expect(notifier.getDefaultGuestWiFiNameAndPassPhrase(),
          (name: 'Linksys00042-guest', password: 'BeMyGuest'));
    });
  });

  group('fetchDevices', () {
    test('lists the router and its nodes, and leaves the clients out',
        () async {
      router.holds(JNAPAction.getDevices, {
        'revision': 9,
        'devices': [
          pnpDevice('router', nodeType: 'Master', location: 'Living room'),
          pnpDevice('laptop'),
          pnpDevice('node', nodeType: 'Slave', location: 'Office'),
        ],
      });

      await notifier.fetchDevices();

      expect(notifier.state.childNodes.map((node) => node.deviceID),
          ['router', 'node']);
    });
  });
}
