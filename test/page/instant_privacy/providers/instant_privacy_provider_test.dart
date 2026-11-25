// Instant Privacy: the router's MAC filter as the notifier reads and writes
// it, against the router behind RouterRepository and a device list built
// from a poll.
//
// #1834 moves who calls fetch() - polling calls it today - so these tests call
// it themselves and never assert that polling does.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

import '../../../common/di.dart';
import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../instant_device/providers/home_network_poll.dart';

/// `GetMACFilterSettings`, as the router writes the addresses: lower case.
Map<String, dynamic> _filter(String mode, List<String> macAddresses) => {
      'macFilterMode': mode,
      'maxMACAddresses': 32,
      'macAddresses': macAddresses,
    };

void main() {
  mockDependencyRegister();
  final services = serviceHelper as MockServiceHelper;

  late RouterBoundary router;
  late RecordingPolling polling;
  late ProviderContainer container;

  InstantPrivacyNotifier notifier() =>
      container.read(instantPrivacyProvider.notifier);
  InstantPrivacyState page() => container.read(instantPrivacyProvider);

  setUp(() async {
    router = RouterBoundary()
      ..holds(JNAPAction.getMACFilterSettings,
          _filter('Allow', ['a4:bb:6d:00:00:10', 'd2:60:cb:00:00:20']))
      ..holds(JNAPAction.getLocalDevice, {'deviceID': 'laptop'})
      ..holds(JNAPAction.getSTABSSIDs, {
        'staBSSIDS': ['80:69:1a:00:02:51'],
      });
    when(services.isSupportGetSTABSSID()).thenReturn(true);
    polling = RecordingPolling(homeNetworkPoll());
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
    // Building the notifier starts a fetch of its own; let it land, so each
    // test starts from the filter the router holds and an empty log.
    container.read(instantPrivacyProvider);
    await pumpEventQueue();
    router.sent.clear();
  });

  tearDown(() {
    container.dispose();
    reset(services);
  });

  group('fetch', () {
    test('reads an allow list, in capitals', () async {
      await notifier().fetch();

      expect(page().settings.mode, MacFilterMode.allow);
      expect(page().status.mode, MacFilterMode.allow);
      expect(page().settings.macAddresses, [laptopMac, phoneMac]);
      expect(page().settings.denyMacAddresses, isEmpty);
      expect(page().settings.maxMacAddresses, 32);
    });

    test('reads a deny list as the deny list', () async {
      router.holds(JNAPAction.getMACFilterSettings,
          _filter('Deny', ['3c:22:fb:00:00:30']));

      await notifier().fetch();

      expect(page().settings.mode, MacFilterMode.deny);
      expect(page().settings.denyMacAddresses, [tabletMac]);
      expect(page().settings.macAddresses, isEmpty);
    });

    test('reads a filter that is off as disabled, with no lists', () async {
      router.holds(JNAPAction.getMACFilterSettings,
          _filter('Disabled', ['3c:22:fb:00:00:30']));

      await notifier().fetch();

      expect(page().settings.mode, MacFilterMode.disabled);
      expect(page().status.mode, MacFilterMode.disabled);
      expect(page().settings.macAddresses, isEmpty);
      expect(page().settings.denyMacAddresses, isEmpty);
    });

    test("knows the MAC address of the user's own device", () async {
      await notifier().fetch();

      expect(page().settings.myMac, laptopMac);
    });

    test('has no own address when the router cannot say which device this is',
        () async {
      router.refuses(JNAPAction.getLocalDevice);

      await notifier().fetch();

      expect(page().settings.myMac, isNull);
    });

    test('has no own address when this device is not in the device list',
        () async {
      router.holds(JNAPAction.getLocalDevice, {'deviceID': 'unknown'});

      await notifier().fetch();

      expect(page().settings.myMac, isNull);
    });

    test("reads the nodes' station BSSIDs, in capitals", () async {
      await notifier().fetch();

      expect(page().settings.bssids, ['80:69:1A:00:02:51']);
    });

    test('asks for no BSSIDs on a router that cannot list them', () async {
      when(services.isSupportGetSTABSSID()).thenReturn(false);

      await notifier().fetch();

      expect(router.actions, isNot(contains(JNAPAction.getSTABSSIDs)));
      expect(page().settings.bssids, isEmpty);
    });

    test('goes on without BSSIDs when the router refuses to list them',
        () async {
      router.refuses(JNAPAction.getSTABSSIDs);

      await notifier().fetch();

      expect(page().settings.bssids, isEmpty);
      expect(page().settings.macAddresses, [laptopMac, phoneMac]);
    });

    test('a status-only fetch updates the mode and keeps the page as it is',
        () async {
      await notifier().fetch();
      notifier().setSelection(['3c:22:fb:00:00:30']);
      router.holds(JNAPAction.getMACFilterSettings, _filter('Deny', const []));
      router.sent.clear();

      await notifier().fetch(statusOnly: true);

      expect(page().status.mode, MacFilterMode.deny);
      expect(page().settings.mode, MacFilterMode.allow);
      expect(page().settings.macAddresses, [laptopMac, phoneMac, tabletMac]);
      expect(router.actions, [JNAPAction.getMACFilterSettings]);
    });

    test('returns the state it ends in', () async {
      final returned = await notifier().fetch();

      expect(returned, page());
    });

    test('a refused read reaches the caller and leaves the page as it was',
        () async {
      final before = page();
      router.refuses(JNAPAction.getMACFilterSettings);

      await expectLater(notifier().fetch(), throwsA(isA<JNAPError>()));

      expect(page(), before);
    });
  });

  group('save', () {
    setUp(() => notifier().fetch());

    test(
        'with allow on, writes the chosen devices, the nodes and the '
        "nodes' BSSIDs, each once", () async {
      router.holds(JNAPAction.getMACFilterSettings,
          _filter('Allow', ['a4:bb:6d:00:00:10', '80:69:1a:00:00:01']));
      await notifier().fetch();

      await notifier().save();

      expect(router.payloadsOf(JNAPAction.setMACFilterSettings).single, {
        'macFilterMode': 'Allow',
        'macAddresses': [
          laptopMac,
          masterMac,
          bedroomMac,
          '80:69:1A:00:02:51',
        ],
      });
    });

    test('with deny on, writes the deny list the page set', () async {
      notifier()
        ..setAccess(MacFilterMode.deny)
        ..setMacAddressList(['3c:22:fb:00:00:30']);

      await notifier().save();

      expect(router.payloadsOf(JNAPAction.setMACFilterSettings).single, {
        'macFilterMode': 'Deny',
        'macAddresses': [tabletMac],
      });
    });

    test('turned off, writes no addresses', () async {
      notifier().setEnable(false);

      await notifier().save();

      expect(router.payloadsOf(JNAPAction.setMACFilterSettings).single, {
        'macFilterMode': 'Disabled',
        'macAddresses': <String>[],
      });
    });

    test('reads the filter back fresh after the save', () async {
      notifier().setEnable(false);
      router.holds(JNAPAction.getMACFilterSettings, _filter('Disabled', []));
      router.sent.clear();
      clearInteractions(router.repo);

      final saved = await notifier().save();

      expect(router.actions.first, JNAPAction.setMACFilterSettings);
      expect(router.actions, contains(JNAPAction.getMACFilterSettings));
      expect(saved.settings.mode, MacFilterMode.disabled);
      expect(page().status.mode, MacFilterMode.disabled);
      verify(router.repo.send(JNAPAction.getMACFilterSettings,
              fetchRemote: true, auth: true))
          .called(1);
    });

    test('a refused write reaches the caller, and nothing is read back',
        () async {
      router.refuses(JNAPAction.setMACFilterSettings);
      router.sent.clear();

      await expectLater(notifier().save(), throwsA(isA<JNAPError>()));

      expect(router.actions, [JNAPAction.setMACFilterSettings]);
      expect(page().settings.mode, MacFilterMode.allow);
    });
  });

  group('the page edits', () {
    setUp(() => notifier().fetch());

    test('turning it on allows, turning it off disables', () {
      notifier().setEnable(false);
      expect(page().settings.mode, MacFilterMode.disabled);

      notifier().setEnable(true);
      expect(page().settings.mode, MacFilterMode.allow);
    });

    test('a selection adds to the allow list in capitals, once each', () {
      notifier().setSelection(['3c:22:fb:00:00:30', 'a4:bb:6d:00:00:10']);

      expect(page().settings.macAddresses, [laptopMac, phoneMac, tabletMac]);
      expect(page().settings.denyMacAddresses, isEmpty);
    });

    test('a deny selection starts the deny list and drops the allow list', () {
      notifier().setSelection(['3c:22:fb:00:00:30'], true);

      expect(page().settings.denyMacAddresses, [tabletMac]);
      expect(page().settings.macAddresses, isEmpty);
    });

    test('a removal takes the devices off the list it names', () {
      notifier().removeSelection(['d2:60:cb:00:00:20']);
      expect(page().settings.macAddresses, [laptopMac]);

      notifier()
        ..setSelection([printerMac, tabletMac], true)
        ..removeSelection([printerMac], true);
      expect(page().settings.denyMacAddresses, [tabletMac]);
    });

    test('a new list replaces the old one, in capitals', () {
      notifier().setMacAddressList(['00:1e:0b:00:00:40']);

      expect(page().settings.macAddresses, [printerMac]);
    });
  });

  test('asks polling for a poll now', () async {
    await notifier().doPolling();

    expect(polling.forced, 1);
  });
}
