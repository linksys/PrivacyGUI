import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/internet_settings_state.dart';
import 'package:privacy_gui/providers/redirection/redirection_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../common/recording_polling.dart';
import '../../../../common/router_boundary.dart';

const _wanStatus = <String, dynamic>{
  'macAddress': '00:11:22:33:44:55',
  'detectedWANType': 'DHCP',
  'wanStatus': 'Connected',
  'wanIPv6Status': 'Connected',
  'supportedWANTypes': [
    'DHCP',
    ' dhcp',
    'Static',
    'pppoe',
    'PPPoE',
    '',
    'Telstra-NBN',
  ],
  'supportedIPv6WANTypes': ['Automatic', 'Pass-through'],
  'supportedWANCombinations': [
    {'wanType': 'DHCP', 'wanIPv6Type': 'Automatic'},
  ],
};

const _ipv6Manual6rd = <String, dynamic>{
  'wanType': 'Automatic',
  'duid': '00:02:03:09:05:05:00:11:22:33:44:55',
  'ipv6AutomaticSettings': {
    'isIPv6AutomaticEnabled': false,
    'ipv6rdTunnelMode': 'Manual',
    'ipv6rdTunnelSettings': {
      'prefix': '2001:db8::',
      'prefixLength': 32,
      'borderRelay': '192.0.2.1',
      'borderRelayPrefixLength': 0,
    },
  },
};

const _lan = <String, dynamic>{
  'minNetworkPrefixLength': 16,
  'maxNetworkPrefixLength': 30,
  'minAllowedDHCPLeaseMinutes': 1,
  'maxDHCPReservationDescriptionLength': 63,
  'hostName': 'Linksys00042',
  'ipAddress': '192.168.1.1',
  'networkPrefixLength': 24,
  'isDHCPEnabled': true,
  'dhcpSettings': {
    'firstClientIPAddress': '192.168.1.100',
    'lastClientIPAddress': '192.168.1.149',
    'leaseMinutes': 1440,
    'reservations': <Map<String, dynamic>>[],
  },
};

const _staticAddress = <String, dynamic>{
  'ipAddress': '203.0.113.10',
  'networkPrefixLength': 24,
  'gateway': '203.0.113.1',
  'dnsServer1': '203.0.113.53',
  'dnsServer2': '198.51.100.53',
  'domainName': 'isp.example',
};

/// A page whose IPv4 connection is [ipv4], with IPv6 automatic and MAC clone
/// off unless named.
InternetSettingsState _page(
  Ipv4Setting ipv4, {
  Ipv6Setting? ipv6,
  bool macClone = false,
  String? macCloneAddress,
}) =>
    InternetSettingsState(
      ipv4Setting: ipv4,
      ipv6Setting: ipv6 ?? _ipv6('Automatic', automatic: true),
      macClone: macClone,
      macCloneAddress: macCloneAddress,
    );

Ipv6Setting _ipv6(
  String type, {
  bool automatic = false,
  IPv6rdTunnelMode? tunnelMode,
  String? prefix,
  int? prefixLength,
  String? borderRelay,
  int? borderRelayPrefixLength,
}) =>
    Ipv6Setting(
      ipv6ConnectionType: type,
      supportedIPv6ConnectionType: const [],
      duid: '',
      isIPv6AutomaticEnabled: automatic,
      ipv6rdTunnelMode: tunnelMode,
      ipv6Prefix: prefix,
      ipv6PrefixLength: prefixLength,
      ipv6BorderRelay: borderRelay,
      ipv6BorderRelayPrefixLength: borderRelayPrefixLength,
    );

Ipv4Setting _ipv4(
  String type, {
  int mtu = 0,
  PPPConnectionBehavior? behavior,
  int? maxIdleMinutes,
  int? reconnectAfterSeconds,
  String? username,
  String? password,
  String? serviceName,
  String? serverIp,
  bool? useStaticSettings,
  String? staticIpAddress,
  String? staticGateway,
  String? staticDns1,
  int? networkPrefixLength,
  int? vlanId,
  String? redirection,
}) =>
    Ipv4Setting(
      ipv4ConnectionType: type,
      supportedIPv4ConnectionType: const [],
      supportedWANCombinations: const [],
      mtu: mtu,
      behavior: behavior,
      maxIdleMinutes: maxIdleMinutes,
      reconnectAfterSeconds: reconnectAfterSeconds,
      username: username,
      password: password,
      serviceName: serviceName,
      serverIp: serverIp,
      useStaticSettings: useStaticSettings,
      staticIpAddress: staticIpAddress,
      staticGateway: staticGateway,
      staticDns1: staticDns1,
      networkPrefixLength: networkPrefixLength,
      vlanId: vlanId,
      redirection: redirection,
    );

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late InternetSettingsNotifier notifier;
  late RecordingPolling polling;

  InternetSettingsState page() => container.read(internetSettingsProvider);

  /// The router's WAN settings are [wan]; everything else is fixed.
  void routerWan(Map<String, dynamic> wan) =>
      router.holds(JNAPAction.getWANSettings, wan);

  Map<String, dynamic> written(JNAPAction action) =>
      router.payloadsOf(action).single;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    router = RouterBoundary()
      ..holds(JNAPAction.getWANStatus, _wanStatus)
      ..holds(JNAPAction.getIPv6Settings, _ipv6Manual6rd)
      ..holds(JNAPAction.getMACAddressCloneSettings, {
        'isMACAddressCloneEnabled': true,
        'macAddress': 'AA:BB:CC:DD:EE:FF',
      })
      ..holds(JNAPAction.getLANSettings, _lan);
    routerWan({
      'wanType': 'DHCP',
      'mtu': 0,
      'wanTaggingSettings': {'isEnabled': false},
    });
    polling = RecordingPolling();
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => polling),
    ]);
    notifier = container.read(internetSettingsProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('reads a DHCP connection', () async {
      await notifier.fetch();

      expect(page().ipv4Setting.ipv4ConnectionType, 'DHCP');
      expect(page().ipv4Setting.mtu, 0);
      expect(page().ipv4Setting.username, isNull);
    });

    test('names a connection type the way the page does', () async {
      routerWan({'wanType': 'pppoe', 'mtu': 0});

      await notifier.fetch();

      expect(page().ipv4Setting.ipv4ConnectionType, 'PPPoE');
    });

    test('lists each supported connection type once, by its page name',
        () async {
      await notifier.fetch();

      expect(page().ipv4Setting.supportedIPv4ConnectionType,
          ['DHCP', 'Static', 'PPPoE', 'Telstra-NBN']);
      expect(page().ipv4Setting.supportedWANCombinations.single.wanIPv6Type,
          'Automatic');
    });

    test('reads a PPPoE account and its VLAN', () async {
      routerWan({
        'wanType': 'PPPoE',
        'mtu': 1492,
        'pppoeSettings': {
          'username': 'isp-user',
          'password': 'isp-pass',
          'serviceName': 'svc',
          'behavior': 'ConnectOnDemand',
          'maxIdleMinutes': 10,
        },
        'wanTaggingSettings': {
          'isEnabled': true,
          'vlanTaggingSettings': {'vlanID': 100, 'vlanStatus': 'Tagged'},
        },
      });

      await notifier.fetch();

      final ipv4 = page().ipv4Setting;
      expect(ipv4.username, 'isp-user');
      expect(ipv4.password, 'isp-pass');
      expect(ipv4.serviceName, 'svc');
      expect(ipv4.behavior, PPPConnectionBehavior.connectOnDemand);
      expect(ipv4.maxIdleMinutes, 10);
      expect(ipv4.wanTaggingSettingsEnable, isTrue);
      expect(ipv4.vlanId, 100);
      expect(ipv4.mtu, 1492);
    });

    test('fills in the PPP defaults the router leaves out', () async {
      routerWan({
        'wanType': 'PPPoE',
        'mtu': 0,
        'pppoeSettings': {
          'username': 'u',
          'password': 'p',
          'serviceName': '',
          'behavior': 'SomethingNewer',
        },
      });

      await notifier.fetch();

      expect(page().ipv4Setting.behavior, PPPConnectionBehavior.keepAlive);
      expect(page().ipv4Setting.maxIdleMinutes, 15);
      expect(page().ipv4Setting.reconnectAfterSeconds, 30);
    });

    test('reads a PPTP account with a static address', () async {
      routerWan({
        'wanType': 'PPTP',
        'mtu': 0,
        'tpSettings': {
          'useStaticSettings': true,
          'staticSettings': _staticAddress,
          'server': '10.0.0.1',
          'username': 'vpn-user',
          'password': 'vpn-pass',
          'behavior': 'KeepAlive',
          'reconnectAfterSeconds': 45,
        },
      });

      await notifier.fetch();

      final ipv4 = page().ipv4Setting;
      expect(ipv4.serverIp, '10.0.0.1');
      expect(ipv4.useStaticSettings, isTrue);
      expect(ipv4.staticIpAddress, '203.0.113.10');
      expect(ipv4.staticGateway, '203.0.113.1');
      expect(ipv4.staticDns2, '198.51.100.53');
      expect(ipv4.domainName, 'isp.example');
      expect(ipv4.reconnectAfterSeconds, 45);
    });

    test('reads an L2TP account as never using a static address', () async {
      routerWan({
        'wanType': 'L2TP',
        'mtu': 0,
        'tpSettings': {
          'useStaticSettings': true,
          'staticSettings': _staticAddress,
          'server': '10.0.0.2',
          'username': 'l2tp-user',
          'password': 'l2tp-pass',
          'behavior': 'KeepAlive',
        },
      });

      await notifier.fetch();

      expect(page().ipv4Setting.serverIp, '10.0.0.2');
      expect(page().ipv4Setting.useStaticSettings, isFalse);
      expect(page().ipv4Setting.staticIpAddress, isNull);
    });

    test('reads a static address', () async {
      routerWan({
        'wanType': 'Static',
        'mtu': 1500,
        'staticSettings': _staticAddress,
      });

      await notifier.fetch();

      expect(page().ipv4Setting.staticIpAddress, '203.0.113.10');
      expect(page().ipv4Setting.networkPrefixLength, 24);
      expect(page().ipv4Setting.staticDns1, '203.0.113.53');
    });

    test('reads IPv6, MAC clone and the router host name', () async {
      await notifier.fetch();

      final ipv6 = page().ipv6Setting;
      expect(ipv6.ipv6ConnectionType, 'Automatic');
      expect(ipv6.supportedIPv6ConnectionType, ['Automatic', 'Pass-through']);
      expect(ipv6.isIPv6AutomaticEnabled, isFalse);
      expect(ipv6.ipv6rdTunnelMode, IPv6rdTunnelMode.manual);
      expect(ipv6.ipv6Prefix, '2001:db8::');
      expect(ipv6.ipv6PrefixLength, 32);
      expect(ipv6.ipv6BorderRelay, '192.0.2.1');
      expect(page().macClone, isTrue);
      expect(page().macCloneAddress, 'AA:BB:CC:DD:EE:FF');
      expect(notifier.hostname, 'Linksys00042');
    });

    test('forgets a bridge redirection once the router has left bridge mode',
        () async {
      SharedPreferences.setMockInitialValues(
          {pRedirection: 'https://www.myrouter.info'});

      await notifier.fetch();

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString(pRedirection), isNull);
    });
  });

  group('saveInternetSettings', () {
    Future<void> save(InternetSettingsState state,
            [InternetSettingsState? original]) =>
        notifier.saveInternetSettings(state, original);

    test('writes MAC clone, IPv4 and IPv6 in one transaction', () async {
      await save(_page(_ipv4('DHCP')));

      expect(router.transactions.first.map((command) => command.key), [
        JNAPAction.setMACAddressCloneSettings,
        JNAPAction.setWANSettings,
        JNAPAction.setIPv6Settings,
      ]);
    });

    test('writes a DHCP connection with VLAN tagging off', () async {
      await save(_page(_ipv4('DHCP', mtu: 1400)));

      expect(written(JNAPAction.setWANSettings), {
        'wanType': 'DHCP',
        'mtu': 1400,
        'wanTaggingSettings': {'isEnabled': false},
      });
    });

    test('writes an MTU the connection type cannot carry as automatic',
        () async {
      // A DHCP connection carries 576 to 1500.
      await save(_page(_ipv4('DHCP', mtu: 9000)));

      expect(written(JNAPAction.setWANSettings)['mtu'], 0);
    });

    test('writes a PPPoE account that keeps the line up', () async {
      await save(_page(_ipv4('PPPoE',
          mtu: 1492, username: 'isp-user', password: 'isp-pass')));

      expect(written(JNAPAction.setWANSettings), {
        'wanType': 'PPPoE',
        'mtu': 1492,
        'pppoeSettings': {
          'username': 'isp-user',
          'password': 'isp-pass',
          'serviceName': '',
          'behavior': 'KeepAlive',
          'reconnectAfterSeconds': 30,
        },
        'wanTaggingSettings': {'isEnabled': false},
      });
    });

    test('writes a PPPoE account that connects on demand', () async {
      await save(_page(_ipv4('PPPoE',
          username: 'u',
          password: 'p',
          behavior: PPPConnectionBehavior.connectOnDemand)));

      final pppoe = written(JNAPAction.setWANSettings)['pppoeSettings'] as Map;
      expect(pppoe['behavior'], 'ConnectOnDemand');
      expect(pppoe['maxIdleMinutes'], 15);
      expect(pppoe.keys, isNot(contains('reconnectAfterSeconds')));
    });

    test('tags PPPoE with a VLAN between 5 and 4094', () async {
      await save(
          _page(_ipv4('PPPoE', username: 'u', password: 'p', vlanId: 100)));

      expect(written(JNAPAction.setWANSettings)['wanTaggingSettings'], {
        'isEnabled': true,
        'vlanTaggingSettings': {'vlanID': 100, 'vlanStatus': 'Tagged'},
      });
    });

    test('leaves PPPoE untagged for a VLAN outside 5 to 4094', () async {
      await save(
          _page(_ipv4('PPPoE', username: 'u', password: 'p', vlanId: 4)));

      expect(written(JNAPAction.setWANSettings)['wanTaggingSettings'],
          {'isEnabled': false});
    });

    test('writes a PPTP account with its static address', () async {
      await save(_page(_ipv4(
        'PPTP',
        serverIp: '10.0.0.1',
        username: 'vpn-user',
        password: 'vpn-pass',
        useStaticSettings: true,
        staticIpAddress: '203.0.113.10',
        staticGateway: '203.0.113.1',
        staticDns1: '203.0.113.53',
      )));

      expect(written(JNAPAction.setWANSettings)['tpSettings'], {
        'useStaticSettings': true,
        'staticSettings': {
          'ipAddress': '203.0.113.10',
          'networkPrefixLength': 24,
          'gateway': '203.0.113.1',
          'dnsServer1': '203.0.113.53',
        },
        'server': '10.0.0.1',
        'username': 'vpn-user',
        'password': 'vpn-pass',
        'behavior': 'KeepAlive',
        'reconnectAfterSeconds': 30,
      });
    });

    test('writes an L2TP account without a static address', () async {
      await save(_page(_ipv4('L2TP',
          serverIp: '10.0.0.2',
          username: 'u',
          password: 'p',
          useStaticSettings: true,
          staticIpAddress: '203.0.113.10')));

      final wan = written(JNAPAction.setWANSettings);
      expect(wan['wanType'], 'L2TP');
      expect(wan['tpSettings'], {
        'useStaticSettings': false,
        'server': '10.0.0.2',
        'username': 'u',
        'password': 'p',
        'behavior': 'KeepAlive',
        'reconnectAfterSeconds': 30,
      });
    });

    test('writes a static address', () async {
      await save(_page(_ipv4('Static',
          mtu: 1500,
          staticIpAddress: '203.0.113.10',
          staticGateway: '203.0.113.1',
          staticDns1: '203.0.113.53',
          networkPrefixLength: 28)));

      expect(written(JNAPAction.setWANSettings), {
        'wanType': 'Static',
        'mtu': 1500,
        'staticSettings': {
          'ipAddress': '203.0.113.10',
          'networkPrefixLength': 28,
          'gateway': '203.0.113.1',
          'dnsServer1': '203.0.113.53',
        },
        'wanTaggingSettings': {'isEnabled': false},
      });
    });

    test('turns remote management off with bridge mode', () async {
      await save(_page(_ipv4('Bridge')));

      expect(written(JNAPAction.setWANSettings), {
        'wanType': 'Bridge',
        'mtu': 0,
        'bridgeSettings': {'useStaticSettings': false},
        'wanTaggingSettings': {'isEnabled': false},
      });
      expect(written(JNAPAction.setRemoteSetting), {'isEnabled': false});
    });

    test('writes a connection type it has no settings for by name alone',
        () async {
      await save(_page(_ipv4('Telstra', mtu: 1400)));

      expect(written(JNAPAction.setWANSettings), {
        'wanType': 'Telstra',
        'mtu': 1400,
        'wanTaggingSettings': {'isEnabled': false},
      });
    });

    test('writes automatic IPv6', () async {
      await save(_page(_ipv4('DHCP')));

      expect(written(JNAPAction.setIPv6Settings), {
        'wanType': 'Automatic',
        'ipv6AutomaticSettings': {'isIPv6AutomaticEnabled': true},
      });
    });

    test('writes a manual 6rd tunnel', () async {
      await save(_page(
        _ipv4('DHCP'),
        ipv6: _ipv6(
          'Automatic',
          tunnelMode: IPv6rdTunnelMode.manual,
          prefix: '2001:db8::',
          prefixLength: 32,
          borderRelay: '192.0.2.1',
          borderRelayPrefixLength: 0,
        ),
      ));

      expect(written(JNAPAction.setIPv6Settings), {
        'wanType': 'Automatic',
        'ipv6AutomaticSettings': {
          'isIPv6AutomaticEnabled': false,
          'ipv6rdTunnelMode': 'Manual',
          'ipv6rdTunnelSettings': {
            'prefix': '2001:db8::',
            'prefixLength': 32,
            'borderRelay': '192.0.2.1',
            'borderRelayPrefixLength': 0,
          },
        },
      });
    });

    test('writes another IPv6 type by name alone', () async {
      await save(_page(_ipv4('DHCP'), ipv6: _ipv6('Pass-through')));

      expect(written(JNAPAction.setIPv6Settings), {'wanType': 'Pass-through'});
    });

    test('writes the cloned MAC only while cloning is on', () async {
      await save(_page(_ipv4('DHCP'),
          macClone: true, macCloneAddress: 'AA:BB:CC:DD:EE:FF'));
      await save(_page(_ipv4('DHCP'),
          macClone: false, macCloneAddress: 'AA:BB:CC:DD:EE:FF'));

      expect(router.payloadsOf(JNAPAction.setMACAddressCloneSettings), [
        {'isMACAddressCloneEnabled': true, 'macAddress': 'AA:BB:CC:DD:EE:FF'},
        {'isMACAddressCloneEnabled': false},
      ]);
    });

    test('turns down a page with no IPv4 connection type, sending nothing', () {
      expect(() => save(_page(_ipv4(''))), throwsA(isA<JNAPError>()));
      expect(router.sent, isEmpty);
    });

    test('turns down a page with no IPv6 connection type, sending nothing', () {
      expect(
        () => save(_page(_ipv4('DHCP'), ipv6: _ipv6(''))),
        throwsA(isA<JNAPError>()),
      );
      expect(router.sent, isEmpty);
    });

    test('shows what the router holds after the write', () async {
      routerWan({
        'wanType': 'Static',
        'mtu': 1500,
        'staticSettings': _staticAddress,
      });

      await save(_page(_ipv4('Static', staticIpAddress: '203.0.113.10')));

      expect(router.actions.indexOf(JNAPAction.getWANSettings),
          greaterThan(router.actions.indexOf(JNAPAction.setWANSettings)));
      expect(page().ipv4Setting.ipv4ConnectionType, 'Static');
      expect(page().ipv4Setting.staticGateway, '203.0.113.1');
    });

    test('leaves no redirection outside the web app', () async {
      container.read(redirectionProvider.notifier).state = 'https://old';

      await save(_page(_ipv4('DHCP')));

      expect(container.read(redirectionProvider), isNull);
    });

    test('treats a write the router took but never confirmed as done',
        () async {
      // The router applied the change and dropped off before its follow-up
      // checks came back; the side-effect error carries the write's answer.
      router.failsTransactions(JNAPSideEffectError(
          const JNAPTransactionSuccessWrap(result: 'OK', data: [])));

      await expectLater(save(_page(_ipv4('DHCP'))), completes);
    });

    test('reports a side-effect error that carries no answer', () async {
      router.failsTransactions(const JNAPSideEffectError());

      await expectLater(
          save(_page(_ipv4('DHCP'))), throwsA(isA<JNAPSideEffectError>()));
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.failsTransactions(
          const JNAPError(result: 'ErrorInvalidInput', error: 'mtu'));

      await expectLater(save(_page(_ipv4('DHCP'))), throwsA(isA<JNAPError>()));
      expect(router.actions, isNot(contains(JNAPAction.getWANSettings)));
    });
  });

  group('savePnpIpv4', () {
    test('writes the IPv4 connection alone', () async {
      await notifier.savePnpIpv4(
          _page(_ipv4('PPPoE', username: 'isp-user', password: 'isp-pass')));

      expect(router.transactions.first.map((command) => command.key),
          [JNAPAction.setWANSettings]);
      expect(written(JNAPAction.setWANSettings), {
        'wanType': 'PPPoE',
        'mtu': 0,
        'pppoeSettings': {
          'username': 'isp-user',
          'password': 'isp-pass',
          'serviceName': '',
          'behavior': 'KeepAlive',
          'reconnectAfterSeconds': 30,
        },
        'wanTaggingSettings': {'isEnabled': false},
      });
    });

    test('returns the write results and shows what the router then holds',
        () async {
      routerWan({
        'wanType': 'PPPoE',
        'mtu': 0,
        'pppoeSettings': {
          'username': 'isp-user',
          'password': 'isp-pass',
          'serviceName': '',
          'behavior': 'KeepAlive',
        },
      });

      final results = await notifier.savePnpIpv4(
          _page(_ipv4('PPPoE', username: 'isp-user', password: 'isp-pass')));

      expect(results.map((result) => result.key), [JNAPAction.setWANSettings]);
      expect(page().ipv4Setting.ipv4ConnectionType, 'PPPoE');
      expect(page().ipv4Setting.username, 'isp-user');
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.failsTransactions(
          const JNAPError(result: 'ErrorInvalidInput', error: 'username'));

      await expectLater(
          notifier
              .savePnpIpv4(_page(_ipv4('PPPoE', username: '', password: ''))),
          throwsA(isA<JNAPError>()));
      expect(router.actions, isNot(contains(JNAPAction.getWANSettings)));
    });
  });

  group('renewing a lease', () {
    test('renews the IPv4 lease and refreshes the poll', () async {
      await notifier.renewDHCPWANLease();

      expect(router.actions, [JNAPAction.renewDHCPWANLease]);
      expect(polling.forced, 1);
    });

    test('renews the IPv6 lease and refreshes the poll', () async {
      await notifier.renewDHCPIPv6WANLease();

      expect(router.actions, [JNAPAction.renewDHCPIPv6WANLease]);
      expect(polling.forced, 1);
    });

    test('reports a renewal the router refuses, without a poll', () async {
      router
        ..refuses(JNAPAction.renewDHCPWANLease)
        ..refuses(JNAPAction.renewDHCPIPv6WANLease);

      await expectLater(
          notifier.renewDHCPWANLease(), throwsA(isA<JNAPError>()));
      await expectLater(
          notifier.renewDHCPIPv6WANLease(), throwsA(isA<JNAPError>()));
      expect(polling.forced, 0);
    });
  });

  test('getMyMACAddress finds nothing for a device it does not know', () async {
    router.holds(JNAPAction.getLocalDevice, {'deviceID': 'unknown'});

    expect(await notifier.getMyMACAddress(), isNull);
  });

  group('updateIpv4Settings', () {
    test('keeps a PPPoE account and fills in the PPP defaults', () {
      notifier.updateIpv4Settings(_ipv4('PPPoE',
          username: 'u',
          password: 'p',
          vlanId: 100,
          staticIpAddress: '203.0.113.10'));

      final ipv4 = page().ipv4Setting;
      expect(ipv4.username, 'u');
      expect(ipv4.vlanId, 100);
      expect(ipv4.behavior, PPPConnectionBehavior.keepAlive);
      expect(ipv4.maxIdleMinutes, 15);
      expect(ipv4.reconnectAfterSeconds, 30);
      expect(ipv4.staticIpAddress, isNull);
    });

    test('keeps a PPTP account and its static address', () {
      notifier.updateIpv4Settings(_ipv4('PPTP',
          serverIp: '10.0.0.1',
          username: 'u',
          useStaticSettings: true,
          staticIpAddress: '203.0.113.10'));

      final ipv4 = page().ipv4Setting;
      expect(ipv4.serverIp, '10.0.0.1');
      expect(ipv4.useStaticSettings, isTrue);
      expect(ipv4.staticIpAddress, '203.0.113.10');
    });

    test('keeps a static address and nothing of an account', () {
      notifier.updateIpv4Settings(
          _ipv4('Static', username: 'stale', staticIpAddress: '203.0.113.10'));

      expect(page().ipv4Setting.staticIpAddress, '203.0.113.10');
      expect(page().ipv4Setting.username, isNull);
    });

    test('keeps the bridge redirection', () {
      notifier.updateIpv4Settings(
          _ipv4('Bridge', redirection: 'https://www.myrouter.info'));

      expect(page().ipv4Setting.redirection, 'https://www.myrouter.info');
    });

    test('keeps only the connection type and MTU for DHCP', () {
      notifier.updateIpv4Settings(
          _ipv4('DHCP', mtu: 1400, username: 'stale', serverIp: 'stale'));

      expect(page().ipv4Setting.mtu, 1400);
      expect(page().ipv4Setting.username, isNull);
      expect(page().ipv4Setting.serverIp, isNull);
    });
  });

  group('updateIpv6Settings', () {
    test('keeps the 6rd tunnel of automatic IPv6, disabled by default', () {
      notifier.updateIpv6Settings(_ipv6('Automatic', prefix: '2001:db8::'));

      expect(page().ipv6Setting.ipv6rdTunnelMode, IPv6rdTunnelMode.disabled);
      expect(page().ipv6Setting.ipv6Prefix, '2001:db8::');
    });

    test('drops the 6rd tunnel for any other type', () {
      notifier.updateIpv6Settings(_ipv6('Pass-through',
          tunnelMode: IPv6rdTunnelMode.manual, prefix: '2001:db8::'));

      expect(page().ipv6Setting.ipv6rdTunnelMode, isNull);
      expect(page().ipv6Setting.ipv6Prefix, isNull);
    });
  });

  test('the field setters change only what they name', () {
    notifier
      ..updateMtu(1400)
      ..updateMacAddressCloneEnable(true)
      ..updateMacAddressClone('AA:BB:CC:DD:EE:FF');

    expect(page().ipv4Setting.mtu, 1400);
    expect(page().macClone, isTrue);
    expect(page().macCloneAddress, 'AA:BB:CC:DD:EE:FF');

    notifier.updateState(_page(_ipv4('PPPoE')));
    expect(page().ipv4Setting.ipv4ConnectionType, 'PPPoE');
  });
}
