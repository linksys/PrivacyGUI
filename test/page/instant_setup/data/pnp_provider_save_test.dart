// What PnpNotifier.save writes to the router from what the user chose in the
// PnP steps and what PnP read from the router, and what it does when the
// router refuses or the save takes the router away (#1921, #1866 wave 6).
//
// The real notifier runs over a RouterBoundary, so these tests assert what
// reaches the router (payloadsOf, the save transaction's actions) and what
// save() throws, never the order of notifier calls: #1920 and #1921 move the
// flow around save(), and these tests keep passing when they do. The steps'
// choices are seeded through [choose], which writes the steps' maps as the
// steps write them today; a #1921 slice that types those maps changes that
// helper only.
//
// save() waits 3 s of real time for the LAN to restart, so these run on
// testWidgets' fake clock and read the outcome after pumping it.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/device_info.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_step_state.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/guest_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/night_mode_step.dart';
import 'package:privacy_gui/page/instant_setup/model/impl/personal_wifi_step.dart';
import 'package:privacy_gui/page/instant_setup/model/pnp_step.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../common/di.dart';
import '../../../common/router_boundary.dart';
import 'pnp_router_data.dart';

void main() {
  mockDependencyRegister();
  final services = getIt.get<ServiceHelper>();

  late RouterBoundary router;
  late ProviderContainer container;
  late PnpNotifier notifier;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    when(services.isSupportGuestNetwork(any)).thenReturn(true);
    when(services.isSupportLedMode(any)).thenReturn(true);
    // Two PnP writes RouterBoundary cannot tell from reads by their names.
    router = RouterBoundary()
      ..holds(JNAPAction.pnpSetAdminPassword, {})
      ..holds(JNAPAction.pnpCheckAdminPassword, {'isPasswordValid': true});
    holdPnpReads(router);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(pnpProvider.notifier) as PnpNotifier;
  });

  tearDown(() => container.dispose());

  /// PnP reached the setup page: it read the router's settings, and knows the
  /// router and whether it is unconfigured.
  Future<void> arrive({required bool unconfigured}) async {
    await notifier.fetchData();
    notifier.state = notifier.state.copyWith(
      deviceInfo: NodeDeviceInfo.fromJson(pnpDeviceInfo),
      isUnconfigured: unconfigured,
    );
  }

  /// What the user chose in the WiFi, guest WiFi and night mode steps.
  void choose({
    Map<String, dynamic>? wifi,
    Map<String, dynamic>? guest,
    Map<String, dynamic>? nightMode,
  }) {
    PnpStepState step(Map<String, dynamic> data) =>
        PnpStepState(status: StepViewStatus.data, data: data);
    notifier.state = notifier.state.copyWith(stepStateList: {
      if (wifi != null) PersonalWiFiStep.id: step(wifi),
      if (guest != null) GuestWiFiStep.id: step(guest),
      if (nightMode != null) NightModeStep.id: step(nightMode),
    });
  }

  /// Runs save() past its 3 s wait: 'saved', or what it threw.
  Future<Object?> runSave(WidgetTester tester) async {
    Object? outcome;
    notifier.save().then<void>((_) => outcome = 'saved',
        onError: (Object error) => outcome = error);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    for (var i = 0; i < 10 && outcome == null; i++) {
      await tester.pump();
    }
    return outcome;
  }

  /// The actions of the save transaction, the last transaction sent.
  List<JNAPAction> saved() => [for (final c in router.transactions.last) c.key];

  group('personal WiFi', () {
    testWidgets(
        'writes the chosen name and password to every band and keeps the '
        'rest of each band', (tester) async {
      await arrive(unconfigured: false);
      choose(wifi: {'ssid': 'MyHome', 'password': 'MyHomePass1'});

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.setRadioSettings).single, {
        'radios': [
          pnpSavedBand('RADIO_2.4GHz', '2.4GHz',
              ssid: 'MyHome', passphrase: 'MyHomePass1'),
          pnpSavedBand('RADIO_5GHz', '5GHz',
              ssid: 'MyHome', passphrase: 'MyHomePass1', channel: 149),
        ],
      });
    });

    testWidgets('writes each band its own name and password in split mode',
        (tester) async {
      await arrive(unconfigured: false);
      choose(wifi: {
        'isSplitMode': true,
        'perBandSettings': {
          '2.4GHz': {'ssid': 'Home-2G', 'password': 'Pass-2G-123'},
          '5GHz': {'ssid': 'Home-5G', 'password': 'Pass-5G-123'},
        },
      });

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.setRadioSettings).single, {
        'radios': [
          pnpSavedBand('RADIO_2.4GHz', '2.4GHz',
              ssid: 'Home-2G', passphrase: 'Pass-2G-123'),
          pnpSavedBand('RADIO_5GHz', '5GHz',
              ssid: 'Home-5G', passphrase: 'Pass-5G-123', channel: 149),
        ],
      });
    });

    testWidgets('leaves a band the split mode did not name as it was',
        (tester) async {
      await arrive(unconfigured: false);
      choose(wifi: {
        'isSplitMode': true,
        'perBandSettings': {
          '5GHz': {'ssid': 'Home-5G', 'password': 'Pass-5G-123'},
        },
      });

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.setRadioSettings).single, {
        'radios': [
          pnpSavedBand('RADIO_2.4GHz', '2.4GHz',
              ssid: 'Linksys00042', passphrase: 'RouterPass1'),
          pnpSavedBand('RADIO_5GHz', '5GHz',
              ssid: 'Home-5G', passphrase: 'Pass-5G-123', channel: 149),
        ],
      });
    });

    testWidgets('writes no radio settings when the user kept the router\'s',
        (tester) async {
      await arrive(unconfigured: false);
      choose(wifi: {'ssid': 'Linksys00042', 'password': 'RouterPass1'});

      expect(await runSave(tester), 'saved');

      expect(saved(), isNot(contains(JNAPAction.setRadioSettings)));
    });

    testWidgets('gives an open band the new name and no passphrase',
        (tester) async {
      router.holds(
          JNAPAction.getRadioInfo,
          pnpRadioInfo(radios: [
            pnpRadio('RADIO_2.4GHz', '2.4GHz'),
            pnpRadio('RADIO_5GHz', '5GHz', ssid: 'Open5G', passphrase: null),
          ]));
      await arrive(unconfigured: false);
      choose(wifi: {'ssid': 'MyHome', 'password': 'MyHomePass1'});

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.setRadioSettings).single['radios'][1],
          pnpSavedBand('RADIO_5GHz', '5GHz', ssid: 'MyHome', passphrase: null));
    });
  });

  group('guest WiFi', () {
    /// The router's guest radios, from pnp_router_data.dart, with the guest
    /// name and passphrase replaced where given.
    List<Map<String, dynamic>> guestRadios(
            {String? ssid, String? passphrase}) =>
        [
          for (final radio in pnpGuestRadioSettings['radios'] as List)
            {
              ...radio as Map<String, dynamic>,
              if (ssid != null) 'guestSSID': ssid,
              if (passphrase != null) 'guestWPAPassphrase': passphrase,
            },
        ];

    testWidgets('turns guest WiFi on with the chosen name and password',
        (tester) async {
      await arrive(unconfigured: false);
      choose(guest: {
        'isEnabled': true,
        'ssid': 'MyGuest',
        'password': 'GuestPass1'
      });

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.setGuestRadioSettings).single, {
        'isGuestNetworkEnabled': true,
        'radios': guestRadios(ssid: 'MyGuest', passphrase: 'GuestPass1'),
      });
    });

    testWidgets('keeps guest WiFi off, on the router\'s own guest settings',
        (tester) async {
      await arrive(unconfigured: false);
      choose(guest: {'isEnabled': false});

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.setGuestRadioSettings).single, {
        'isGuestNetworkEnabled': false,
        'radios': guestRadios(),
      });
    });

    testWidgets('writes no guest settings to a router without guest WiFi',
        (tester) async {
      when(services.isSupportGuestNetwork(any)).thenReturn(false);
      await arrive(unconfigured: false);
      choose(guest: {
        'isEnabled': true,
        'ssid': 'MyGuest',
        'password': 'GuestPass1'
      });

      expect(await runSave(tester), 'saved');

      expect(saved(), isNot(contains(JNAPAction.setGuestRadioSettings)));
    });
  });

  group('night mode', () {
    testWidgets('turns night mode on from 8 pm to 8 am', (tester) async {
      await arrive(unconfigured: false);
      choose(nightMode: {'isEnabled': true});

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.setLedNightModeSetting).single,
          {'Enable': true, 'StartingTime': 20, 'EndingTime': 8});
    });

    testWidgets('writes nothing when the user leaves it off', (tester) async {
      await arrive(unconfigured: false);
      choose(nightMode: {'isEnabled': false});

      expect(await runSave(tester), 'saved');

      expect(saved(), isNot(contains(JNAPAction.setLedNightModeSetting)));
    });

    testWidgets('writes nothing to a router without night mode',
        (tester) async {
      when(services.isSupportLedMode(any)).thenReturn(false);
      await arrive(unconfigured: false);
      choose(nightMode: {'isEnabled': true});

      expect(await runSave(tester), 'saved');

      expect(saved(), isNot(contains(JNAPAction.setLedNightModeSetting)));
    });
  });

  testWidgets('turns automatic firmware updates on, in the router\'s window',
      (tester) async {
    await arrive(unconfigured: false);

    expect(await runSave(tester), 'saved');

    expect(router.payloadsOf(JNAPAction.setFirmwareUpdateSettings).single, {
      'updatePolicy': 'AutomaticallyCheckAndInstall',
      'autoUpdateWindow': {'startMinute': 120, 'durationMinutes': 180},
    });
  });

  group('an unconfigured router', () {
    testWidgets(
        'is made Master, and its admin password set to its default WiFi '
        'password, the one on its label', (tester) async {
      await arrive(unconfigured: true);
      choose(wifi: {'ssid': 'MyHome', 'password': 'MyHomePass1'});

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.setDeviceMode).single,
          {'mode': 'Master'});
      expect(router.payloadsOf(JNAPAction.pnpSetAdminPassword).single,
          {'adminPassword': 'RouterPass1'});
      expect(saved(),
          isNot(contains(JNAPAction.setUserAcknowledgedAutoConfiguration)));
    });

    testWidgets('logs in with that password once the router is back',
        (tester) async {
      await arrive(unconfigured: true);

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.pnpCheckAdminPassword).single,
          {'adminPassword': 'RouterPass1'});
    });

    testWidgets(
        'keeps a password the user already set, and does not log in with the '
        'WiFi password', (tester) async {
      holdPnpReads(router, passwordSetByUser: true);
      await arrive(unconfigured: true);

      expect(await runSave(tester), 'saved');

      expect(saved(), contains(JNAPAction.setDeviceMode));
      expect(saved(), isNot(contains(JNAPAction.pnpSetAdminPassword)));
      expect(router.actions, isNot(contains(JNAPAction.pnpCheckAdminPassword)));
    });

    testWidgets(
        'sets the password when the router cannot say whether it has one',
        (tester) async {
      router.refuses(JNAPAction.isAdminPasswordDefault);
      await arrive(unconfigured: true);

      expect(await runSave(tester), 'saved');

      expect(router.payloadsOf(JNAPAction.pnpSetAdminPassword).single,
          {'adminPassword': 'RouterPass1'});
    });

    testWidgets('a password the router refuses after the save is a wrong one',
        (tester) async {
      router.refuses(JNAPAction.pnpCheckAdminPassword,
          result: errorInvalidAdminPassword);
      await arrive(unconfigured: true);

      expect(await runSave(tester), isA<ExceptionInvalidAdminPassword>());
    });

    testWidgets(
        'any other failure of that login means the router is not back yet',
        (tester) async {
      router.refuses(JNAPAction.pnpCheckAdminPassword,
          result: '_ErrorNotReady');
      await arrive(unconfigured: true);

      expect(await runSave(tester), isA<ExceptionNeedToReconnect>());
    });
  });

  testWidgets(
      'a configured router gets the acknowledgement, keeps its password and '
      'mode, and is not logged in to', (tester) async {
    await arrive(unconfigured: false);

    expect(await runSave(tester), 'saved');

    expect(
        router
            .payloadsOf(JNAPAction.setUserAcknowledgedAutoConfiguration)
            .single,
        isEmpty);
    expect(saved(), isNot(contains(JNAPAction.setDeviceMode)));
    expect(saved(), isNot(contains(JNAPAction.pnpSetAdminPassword)));
    expect(router.actions, isNot(contains(JNAPAction.pnpCheckAdminPassword)));
  });

  group('when the save does not land', () {
    testWidgets('a refused save is a saving error carrying the router\'s',
        (tester) async {
      router.refuses(JNAPAction.setFirmwareUpdateSettings,
          result: 'ErrorInvalidInput');
      await arrive(unconfigured: false);
      router.sent.clear();

      final outcome = await runSave(tester);

      expect(
          outcome,
          isA<ExceptionSavingChanges>().having(
              (e) => (e.error as JNAPError).result,
              'error',
              'ErrorInvalidInput'));
      // Nothing is checked after a save that did not land.
      expect(router.actions, isNot(contains(JNAPAction.getDeviceInfo)));
    });

    testWidgets('a dropped connection sends PnP to reconnect', (tester) async {
      await arrive(unconfigured: false);
      router.failsTransactions(ClientException('Connection reset by peer'));

      expect(await runSave(tester), isA<ExceptionNeedToReconnect>());
    });

    testWidgets('a router that does not come back sends PnP to reconnect',
        (tester) async {
      await arrive(unconfigured: false);
      router.failsTransactions(const JNAPSideEffectError());

      expect(await runSave(tester), isA<ExceptionNeedToReconnect>());
    });

    testWidgets('another router answering after the save is not this one',
        (tester) async {
      await arrive(unconfigured: false);
      router.holds(JNAPAction.getDeviceInfo,
          {...pnpDeviceInfo, 'serialNumber': 'ANOTHER-ROUTER'});

      expect(await runSave(tester), isA<ExceptionNeedToReconnect>());
    });

    testWidgets('the router\'s serial is forgotten once the save ends',
        (tester) async {
      await arrive(unconfigured: false);
      router.refuses(JNAPAction.setFirmwareUpdateSettings);

      await runSave(tester);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pPnpConfiguredSN), isNull);
    });
  });

  group('acknowledgeAutoConfigurationIfNeeded', () {
    testWidgets(
        'acknowledges once, after an unconfigured router\'s save, when the '
        'router has auto configuration to acknowledge', (tester) async {
      await arrive(unconfigured: true);
      expect(await runSave(tester), 'saved');
      router.sent.clear();

      await notifier.acknowledgeAutoConfigurationIfNeeded();
      await notifier.acknowledgeAutoConfigurationIfNeeded();

      expect(router.actions, [JNAPAction.setUserAcknowledgedAutoConfiguration]);
    });

    testWidgets(
        'a refused acknowledgement is a saving error, and is tried again',
        (tester) async {
      await arrive(unconfigured: true);
      expect(await runSave(tester), 'saved');
      router.refuses(JNAPAction.setUserAcknowledgedAutoConfiguration);
      router.sent.clear();

      await expectLater(notifier.acknowledgeAutoConfigurationIfNeeded(),
          throwsA(isA<ExceptionSavingChanges>()));

      router.holds(JNAPAction.setUserAcknowledgedAutoConfiguration, {});
      await notifier.acknowledgeAutoConfigurationIfNeeded();

      expect(router.actions, [
        JNAPAction.setUserAcknowledgedAutoConfiguration,
        JNAPAction.setUserAcknowledgedAutoConfiguration,
      ]);
    });

    testWidgets('sends nothing when the router already acknowledged it',
        (tester) async {
      holdPnpReads(router,
          autoConfiguration: pnpAutoConfiguration(acknowledged: true));
      await arrive(unconfigured: true);
      expect(await runSave(tester), 'saved');
      router.sent.clear();

      await notifier.acknowledgeAutoConfigurationIfNeeded();

      expect(router.sent, isEmpty);
    });

    testWidgets(
        'sends nothing after a configured router\'s save, which '
        'carried it', (tester) async {
      await arrive(unconfigured: false);
      expect(await runSave(tester), 'saved');
      router.sent.clear();

      await notifier.acknowledgeAutoConfigurationIfNeeded();

      expect(router.sent, isEmpty);
    });
  });
}
