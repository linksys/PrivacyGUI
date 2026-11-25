// ConnectivityNotifier: what the app knows about the network it is on. The
// router redirect and the dashboard read whether there is internet, whether
// the cloud is up, and whether the router in front of the app is the one it
// manages (routerType), which decides where requests go (cloud_host.dart).
//
// Stood in:
// - connectivity_plus and network_info_plus, through their platform channels;
// - the router, through RouterBoundary;
// - the cloud's status page, through CloudStatusStandIn;
// - the internet check's DNS lookup of google.com, through a subclass:
//   InternetAddress.lookup has no override, so testConnection is not tested.

import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/router_boundary.dart';
import 'cloud_status_stand_in.dart';

/// The app's connectivity notifier, with the DNS lookup stood in.
class _Connectivity extends ConnectivityNotifier {
  _Connectivity(this._online);

  final bool Function() _online;
  int internetChecks = 0;

  @override
  Future<bool> testConnection() async {
    internetChecks++;
    return _online();
  }
}

/// GetDeviceInfo of the router in front of the app.
Map<String, dynamic> _deviceInfo(String serialNumber) => {
      'modelNumber': 'M63',
      'firmwareVersion': '1.2.5.26111117',
      'description': 'Linksys Router',
      'firmwareDate': '2026-11-11T17:00:00Z',
      'manufacturer': 'Linksys',
      'serialNumber': serialNumber,
      'hardwareVersion': '1',
      'services': ['http://linksys.com/jnap/core/Core'],
    };

const _connectivityChannel =
    MethodChannel('dev.fluttercommunity.plus/connectivity');
const _connectivityEvents =
    EventChannel('dev.fluttercommunity.plus/connectivity_status');
const _networkInfoChannel =
    MethodChannel('dev.fluttercommunity.plus/network_info');

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  late RouterBoundary router;
  late CloudStatusStandIn cloud;
  late ProviderContainer container;
  late _Connectivity notifier;

  /// What the phone reports: its connection, and its Wi-Fi name and gateway
  /// (null for a channel that fails).
  late String connection;
  late List<String?> wifiNames;
  late String? gateway;
  late List<String> networkInfoCalls;
  late bool online;

  setUpAll(() {
    logger.d('connectivity_provider_test');
    initBetterActions();
  });

  setUp(() async {
    connection = 'wifi';
    wifiNames = ['Linksys00042'];
    gateway = '192.168.1.1';
    networkInfoCalls = [];
    online = true;
    messenger.setMockMethodCallHandler(
        _connectivityChannel, (call) async => connection);
    messenger.setMockMethodCallHandler(_networkInfoChannel, (call) async {
      networkInfoCalls.add(call.method);
      switch (call.method) {
        case 'wifiName':
          final name =
              wifiNames.length > 1 ? wifiNames.removeAt(0) : wifiNames.first;
          if (name == null) throw PlatformException(code: 'denied');
          return name;
        case 'wifiGatewayAddress':
          if (gateway == null) throw PlatformException(code: 'denied');
          return gateway;
      }
      return null;
    });
    SharedPreferences.setMockInitialValues({pCurrentSN: '65G10M27E03027'});

    router = RouterBoundary()
      ..holds(JNAPAction.getDeviceInfo, _deviceInfo('65G10M27E03027'));
    cloud = await CloudStatusStandIn.start();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      connectivityProvider.overrideWith(() => _Connectivity(() => online)),
    ]);
    // The notifier builds its cloud client when it is made.
    notifier = cloud.run(() =>
        container.read(connectivityProvider.notifier) as _Connectivity);
  });

  tearDown(() async {
    container.dispose();
    await cloud.close();
    messenger.setMockStreamHandler(_connectivityEvents, null);
  });

  ConnectivityState state() => container.read(connectivityProvider);

  test('starts with no connection and no internet', () {
    expect(
        state(),
        const ConnectivityState(
            hasInternet: false, connectivityInfo: ConnectivityInfo()));
  });

  group('forceUpdate', () {
    test(
        'on the Wi-Fi of the router the app manages, says so, with internet '
        'and the cloud up', () async {
      final result = await notifier.forceUpdate();

      const expected = ConnectivityState(
        hasInternet: true,
        connectivityInfo: ConnectivityInfo(
          type: ConnectivityResult.wifi,
          gatewayIp: '192.168.1.1',
          ssid: 'Linksys00042',
          routerType: RouterType.behindManaged,
        ),
        cloudAvailabilityInfo: AvailabilityInfo(isCloudOk: true),
      );
      expect(result, expected);
      expect(state(), expected);
      expect(router.actions, [JNAPAction.getDeviceInfo]);
      expect(cloud.requested, [
        Uri.parse(
            'https://cloudhealth.lswf.net/cloud-availability/cloud-qa.json'),
      ]);
    });

    test('behind a Linksys router that is not the one it manages, says so',
        () async {
      router.holds(JNAPAction.getDeviceInfo, _deviceInfo('20J2060A839173'));

      await notifier.forceUpdate();

      expect(state().connectivityInfo.routerType, RouterType.behind);
    });

    test('behind a Linksys router, before managing any, says it is behind one',
        () async {
      SharedPreferences.setMockInitialValues({});

      await notifier.forceUpdate();

      expect(state().connectivityInfo.routerType, RouterType.behind);
    });

    test('behind a router that does not answer JNAP, says it is another one',
        () async {
      router.refuses(JNAPAction.getDeviceInfo);

      await notifier.forceUpdate();

      expect(state().connectivityInfo.routerType, RouterType.others);
      expect(state().hasInternet, isTrue);
    });

    test('without internet, says so and does not ask the cloud', () async {
      online = false;

      await notifier.forceUpdate();

      expect(state().hasInternet, isFalse);
      expect(state().cloudAvailabilityInfo, isNull);
      expect(state().connectivityInfo.routerType, RouterType.behindManaged);
      expect(cloud.requested, isEmpty);
    });

    test('when the cloud reports trouble, says the cloud is down', () async {
      cloud.body = '{"cloudStatus":"DEGRADED"}';

      await notifier.forceUpdate();

      expect(state().hasInternet, isTrue);
      expect(state().cloudAvailabilityInfo,
          const AvailabilityInfo(isCloudOk: false));
    });

    test('when the cloud status page fails, says the cloud is down', () async {
      cloud
        ..status = 503
        ..body = '<html>Service Unavailable</html>';
      // The client asks again after a 503, half a second later.
      await notifier.forceUpdate();

      expect(state().cloudAvailabilityInfo,
          const AvailabilityInfo(isCloudOk: false));
    });

    test('with no connection, records that and checks nothing', () async {
      connection = 'none';

      await notifier.forceUpdate();

      expect(state().connectivityInfo.type, ConnectivityResult.none);
      expect(state().hasInternet, isFalse);
      expect(notifier.internetChecks, 0);
      expect(router.actions, isEmpty);
    });

    test('on Ethernet, keeps the connection type the phone reports',
        () async {
      connection = 'ethernet';

      await notifier.forceUpdate();

      expect(state().connectivityInfo.type, ConnectivityResult.ethernet);
    });
  });

  group('the Wi-Fi it is on', () {
    test('when the phone will not tell, is unknown', () async {
      wifiNames = [null];
      gateway = null;

      await notifier.forceUpdate();

      expect(state().connectivityInfo.ssid, 'Unknown SSID');
      expect(state().connectivityInfo.gatewayIp, 'Unknown Gateway IP');
    });

    test('is asked for again when there is a gateway but no name yet',
        () async {
      wifiNames = ['', 'Linksys00042'];

      await notifier.forceUpdate();

      expect(networkInfoCalls,
          ['wifiName', 'wifiGatewayAddress', 'wifiName']);
      expect(state().connectivityInfo.ssid, 'Linksys00042');
    });

    test('is not asked for again without a gateway', () async {
      wifiNames = [''];
      gateway = '';

      await notifier.forceUpdate();

      expect(networkInfoCalls, ['wifiName', 'wifiGatewayAddress']);
      expect(state().connectivityInfo.ssid, '');
    });
  });

  group('start', () {
    test('follows the phone\'s connection as it changes, until stopped',
        () async {
      late MockStreamHandlerEventSink events;
      var listens = 0;
      var cancels = 0;
      messenger.setMockStreamHandler(
          _connectivityEvents,
          MockStreamHandler.inline(
            onListen: (_, sink) {
              listens++;
              events = sink;
            },
            onCancel: (_) => cancels++,
          ));

      final changed = Completer<ConnectivityState>();
      container.listen(connectivityProvider, (_, next) {
        if (next.hasInternet && !changed.isCompleted) changed.complete(next);
      });
      notifier
        ..start()
        ..start();
      await pumpEventQueue();
      events.success('wifi');

      final next = await changed.future.timeout(const Duration(seconds: 5));
      expect(next.connectivityInfo.type, ConnectivityResult.wifi);
      expect(next.connectivityInfo.routerType, RouterType.behindManaged);
      expect(listens, 1);

      notifier.stop();
      await pumpEventQueue();
      expect(cancels, 1);
    });
  });
}
