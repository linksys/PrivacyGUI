import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';

import '../../../../common/di.dart';
import '../../../../common/router_boundary.dart';

/// LAN settings as a router reports them: 192.168.1.1/24, handing out
/// 192.168.1.100 to .149, with one reservation.
Map<String, dynamic> routerLanSettings({
  String hostName = 'Linksys00042',
  String ipAddress = '192.168.1.1',
  int networkPrefixLength = 24,
  String firstClientIPAddress = '192.168.1.100',
  String lastClientIPAddress = '192.168.1.149',
  List<Map<String, dynamic>> reservations = const [
    {
      'macAddress': 'AA:BB:CC:DD:EE:01',
      'ipAddress': '192.168.1.120',
      'description': 'NAS',
    },
  ],
}) =>
    {
      'minNetworkPrefixLength': 16,
      'maxNetworkPrefixLength': 30,
      'minAllowedDHCPLeaseMinutes': 1,
      'maxAllowedDHCPLeaseMinutes': 525600,
      'maxDHCPReservationDescriptionLength': 63,
      'hostName': hostName,
      'ipAddress': ipAddress,
      'networkPrefixLength': networkPrefixLength,
      'isDHCPEnabled': true,
      'dhcpSettings': {
        'firstClientIPAddress': firstClientIPAddress,
        'lastClientIPAddress': lastClientIPAddress,
        'leaseMinutes': 1440,
        'dnsServer1': '8.8.8.8',
        'reservations': reservations,
      },
    };

void main() {
  mockDependencyRegister();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  test('updateHostName with valid hostname', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('ValidHostname');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'ValidHostname');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name], isNull);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName with empty hostname', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, '');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostName.name);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName with too long hostname', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('HostnameTooLong1'); // 16 chars

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'HostnameTooLong1');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameLengthError.name);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName starting with hyphen', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('-InvalidStart');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, '-InvalidStart');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameStartWithHyphen.name);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName ending with hyphen', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('InvalidEnd-');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'InvalidEnd-');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameEndWithHyphen.name);
    expect(state.hostNameInvalidChars, isNull);
  });

  test('updateHostName with invalid characters', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('InvalidChar!');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'InvalidChar!');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameInvalidCharacters.name);
    expect(state.hostNameInvalidChars, '!');
  });

  test('updateHostName with multiple invalid characters', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);
    notifier.updateHostName('Invalid@#%');

    final state = container.read(localNetworkSettingProvider);
    expect(state.hostName, 'Invalid@#%');
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameInvalidCharacters.name);
    // Order is now sorted deterministically
    expect(state.hostNameInvalidChars, '#, %, @');
  });

  test('updateHostName with invalid characters clears previous errors', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);

    // First set an error
    notifier.updateHostName('InvalidEnd-');
    expect(
        container
            .read(localNetworkSettingProvider)
            .errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameEndWithHyphen.name);

    // Then set invalid chars
    notifier.updateHostName('InvalidChar!');
    final state = container.read(localNetworkSettingProvider);
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
        LocalNetworkErrorPrompt.hostNameInvalidCharacters.name);
    expect(state.hostNameInvalidChars, '!');
  });

  test('updateHostName valid input clears errors', () {
    final notifier = container.read(localNetworkSettingProvider.notifier);

    // First set an error
    notifier.updateHostName('InvalidChar!');

    // Then valid input
    notifier.updateHostName('ValidHostname');

    final state = container.read(localNetworkSettingProvider);
    expect(state.errorTextMap[LocalNetworkErrorPrompt.hostName.name], isNull);
    expect(state.hostNameInvalidChars,
        isNull); // Should be cleared, although implementing code sets it to null if no invalid chars found?
    // Wait, let's check implementation.
    // In implementation: `invalidChars` is initialized to null. If no invalid chars found, `invalidChars` remains null.
    // `state = state.copyWith(..., hostNameInvalidChars: invalidChars)`
    // So yes, it will be null.
  });

  group('with a router', () {
    late RouterBoundary router;
    late ProviderContainer routerContainer;
    late LocalNetworkSettingsNotifier notifier;

    LocalNetworkSettingsState page() =>
        routerContainer.read(localNetworkSettingProvider);

    /// The DHCP settings of the one LAN write the router received.
    Map<String, dynamic> writtenDhcp() =>
        router.payloadsOf(JNAPAction.setLANSettings).single['dhcpSettings']
            as Map<String, dynamic>;

    setUp(() async {
      router = RouterBoundary()
        ..holds(JNAPAction.getLANSettings, routerLanSettings());
      routerContainer = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router.repo),
      ]);
      notifier = routerContainer.read(localNetworkSettingProvider.notifier);
      await notifier.fetch();
    });

    tearDown(() => routerContainer.dispose());

    group('fetch', () {
      test('reads the router LAN settings into the page', () {
        final state = page();
        expect(state.hostName, 'Linksys00042');
        expect(state.ipAddress, '192.168.1.1');
        expect(state.subnetMask, '255.255.255.0');
        expect(state.isDHCPEnabled, isTrue);
        expect(state.firstIPAddress, '192.168.1.100');
        expect(state.lastIPAddress, '192.168.1.149');
        expect(state.clientLeaseTime, 1440);
        expect(state.dns1, '8.8.8.8');
        expect(state.dns2, isNull);
        expect(state.dhcpReservationList, const [
          DHCPReservation(
            macAddress: 'AA:BB:CC:DD:EE:01',
            ipAddress: '192.168.1.120',
            description: 'NAS',
          ),
        ]);
      });

      test('counts the DHCP range and how far it could grow', () {
        // .100 to .149 is 50 addresses; a /24 leaves .100 to .254, 155.
        expect(page().maxUserAllowed, 50);
        expect(page().maxUserLimit, 155);
      });
    });

    group('saveSettings', () {
      test('writes the page to the router as its LAN settings', () async {
        await notifier.saveSettings(page());

        expect(router.payloadsOf(JNAPAction.setLANSettings).single, {
          'ipAddress': '192.168.1.1',
          'networkPrefixLength': 24,
          'hostName': 'Linksys00042',
          'isDHCPEnabled': true,
          'dhcpSettings': {
            'firstClientIPAddress': '192.168.1.100',
            'lastClientIPAddress': '192.168.1.149',
            'leaseMinutes': 1440,
            'dnsServer1': '8.8.8.8',
            'reservations': [
              {
                'macAddress': 'AA:BB:CC:DD:EE:01',
                'ipAddress': '192.168.1.120',
                'description': 'NAS',
              },
            ],
          },
        });
      });

      test('sends the subnet mask as its prefix length', () async {
        await notifier.saveSettings(page().copyWith(subnetMask: '255.255.0.0'));

        expect(
          router
              .payloadsOf(JNAPAction.setLANSettings)
              .single['networkPrefixLength'],
          16,
        );
      });

      test('leaves out the DNS and WINS servers the page left empty', () async {
        await notifier.saveSettings(page().copyWith(
          dns1: () => '',
          dns2: () => '',
          dns3: () => '',
          wins: () => '',
        ));

        final dhcp = writtenDhcp();
        expect(dhcp.keys, isNot(contains('dnsServer1')));
        expect(dhcp.keys, isNot(contains('dnsServer2')));
        expect(dhcp.keys, isNot(contains('dnsServer3')));
        expect(dhcp.keys, isNot(contains('winsServer')));
      });

      test('drops the reservations when the router address changes', () async {
        await notifier.saveSettings(
          page().copyWith(ipAddress: '10.0.1.1'),
          previousIPAddress: '192.168.1.1',
        );

        final dhcp = writtenDhcp();
        expect(dhcp['reservations'], isEmpty);
      });

      test('keeps the reservations when the router address stays', () async {
        await notifier.saveSettings(page(), previousIPAddress: '192.168.1.1');

        final dhcp = writtenDhcp();
        expect(dhcp['reservations'], hasLength(1));
      });

      test('shows what the router holds after the write', () async {
        router
          ..holds(JNAPAction.getLANSettings, routerLanSettings(hostName: 'Den'))
          ..sent.clear();

        await notifier.saveSettings(page());

        expect(router.actions.first, JNAPAction.setLANSettings);
        expect(page().hostName, 'Den');
        expect(
          routerContainer.read(instantSafetyProvider).lanSetting?.hostName,
          'Den',
        );
      });

      test('reports a write the router refuses, and reads nothing back',
          () async {
        router.refuses(JNAPAction.setLANSettings);
        final before = page();

        await expectLater(
            notifier.saveSettings(before), throwsA(isA<JNAPError>()));

        expect(router.actions.last, JNAPAction.setLANSettings);
        expect(page(), before);
      });
    });

    group('saveReservations', () {
      test('writes the list and returns what the router then holds', () async {
        const added = DHCPReservation(
          macAddress: 'AA:BB:CC:DD:EE:02',
          ipAddress: '192.168.1.121',
          description: 'TV',
        );
        router.holds(
          JNAPAction.getLANSettings,
          routerLanSettings(reservations: [
            {
              'macAddress': 'AA:BB:CC:DD:EE:02',
              'ipAddress': '192.168.1.121',
              'description': 'TV',
            },
          ]),
        );

        final saved = await notifier.saveReservations(const [added]);

        final dhcp = writtenDhcp();
        expect(dhcp['reservations'], [
          {
            'macAddress': 'AA:BB:CC:DD:EE:02',
            'ipAddress': '192.168.1.121',
            'description': 'TV',
          },
        ]);
        expect(saved, const [added]);
      });

      test('reports a write the router refuses, keeping the page list',
          () async {
        router.refuses(JNAPAction.setLANSettings);

        await expectLater(
            notifier.saveReservations(const []), throwsA(isA<JNAPError>()));

        expect(page().dhcpReservationList, hasLength(1));
      });
    });

    group('editing the router address', () {
      test('moves the DHCP range onto a new network', () {
        notifier.routerIpAddressChanged(_noContext, '10.0.1.1', page());

        expect(page().ipAddress, '10.0.1.1');
        expect(page().firstIPAddress, '10.0.1.100');
        expect(page().lastIPAddress, '10.0.1.149');
        expect(page().errorTextMap, isEmpty);
      });

      test('flags a malformed address on the IP address tab', () {
        notifier.routerIpAddressChanged(_noContext, '192.168.1', page());

        expect(page().errorTextMap[LocalNetworkErrorPrompt.ipAddress.name],
            LocalNetworkErrorPrompt.ipAddress.name);
        expect(page().hasErrorOnIPAddressTab, isTrue);
      });

      test('flags a start address the new network no longer holds', () {
        // Only the first two octets of the start address follow the router.
        notifier.routerIpAddressChanged(_noContext, '192.168.2.1', page());

        expect(page().firstIPAddress, '192.168.1.100');
        expect(page().errorTextMap[LocalNetworkErrorPrompt.startIpAddress.name],
            LocalNetworkErrorPrompt.startIpAddressRange.name);
        expect(page().hasErrorOnDhcpServerTab, isTrue);
      });
    });

    group('editing the subnet mask', () {
      test('shrinks the DHCP range to fit a smaller network', () {
        // A /25 leaves .100 to .126: 27 addresses.
        notifier.subnetMaskChanged(_noContext, '255.255.255.128', page());

        expect(page().subnetMask, '255.255.255.128');
        expect(page().maxUserLimit, 27);
        expect(page().maxUserAllowed, 27);
        expect(page().lastIPAddress, '192.168.1.126');
        expect(page().errorTextMap, isEmpty);
      });

      test('flags a mask outside what the router allows', () {
        // The router allows /16 to /30.
        notifier.subnetMaskChanged(_noContext, '255.0.0.0', page());

        expect(page().errorTextMap[LocalNetworkErrorPrompt.subnetMask.name],
            LocalNetworkErrorPrompt.subnetMask.name);
        expect(page().hasErrorOnIPAddressTab, isTrue);
      });
    });

    group('editing the start address', () {
      test('keeps the range size and moves its end', () {
        notifier.startIpChanged(_noContext, '192.168.1.200', page());

        expect(page().firstIPAddress, '192.168.1.200');
        expect(page().lastIPAddress, '192.168.1.249');
        expect(page().maxUserLimit, 55);
        expect(page().maxUserAllowed, 50);
      });

      test('shrinks the range when it would run past the network', () {
        notifier.startIpChanged(_noContext, '192.168.1.220', page());

        expect(page().maxUserAllowed, 35);
        expect(page().lastIPAddress, '192.168.1.254');
      });

      test('flags the router address as a start address', () {
        notifier.startIpChanged(_noContext, '192.168.1.1', page());

        expect(page().errorTextMap[LocalNetworkErrorPrompt.startIpAddress.name],
            LocalNetworkErrorPrompt.startIpAddress.name);
      });

      test('flags a start address outside the network', () {
        notifier.startIpChanged(_noContext, '10.0.0.5', page());

        expect(page().errorTextMap[LocalNetworkErrorPrompt.startIpAddress.name],
            LocalNetworkErrorPrompt.startIpAddressRange.name);
      });
    });

    group('editing the number of addresses', () {
      test('moves the end of the range', () {
        notifier.maxUserAllowedChanged(_noContext, '20', page());

        expect(page().maxUserAllowed, 20);
        expect(page().lastIPAddress, '192.168.1.119');
        expect(page().errorTextMap, isEmpty);
      });

      test('flags more addresses than the network holds', () {
        notifier.maxUserAllowedChanged(_noContext, '200', page());

        expect(page().maxUserAllowed, 200);
        expect(page().lastIPAddress, '192.168.1.149');
        expect(page().errorTextMap[LocalNetworkErrorPrompt.maxUserAllowed.name],
            LocalNetworkErrorPrompt.maxUserAllowed.name);
        expect(page().hasErrorOnDhcpServerTab, isTrue);
      });
    });

    group('finishing an edit of a DHCP field', () {
      test('accepts a lease time the router allows', () {
        final (valid, settings) = notifier.clientLeaseFinished('60', page());

        expect(valid, isTrue);
        expect(settings.clientLeaseTime, 60);
      });

      test('turns down a lease time below the router minimum', () {
        final (valid, settings) = notifier.clientLeaseFinished('0', page());

        expect(valid, isFalse);
        expect(settings.clientLeaseTime, 1440);
      });

      // Each server field: how the page finishes an edit of it, and where the
      // result lands.
      final servers = <String,
          ({
        (bool, LocalNetworkSettingsState) Function(
            String, LocalNetworkSettingsState) finish,
        String? Function(LocalNetworkSettingsState) read,
      })>{
        'DNS 1': (
          finish: (ip, s) => notifier.staticDns1Finished(ip, s),
          read: (s) => s.dns1,
        ),
        'DNS 2': (
          finish: (ip, s) => notifier.staticDns2Finished(ip, s),
          read: (s) => s.dns2,
        ),
        'DNS 3': (
          finish: (ip, s) => notifier.staticDns3Finished(ip, s),
          read: (s) => s.dns3,
        ),
        'WINS': (
          finish: (ip, s) => notifier.winsServerFinished(ip, s),
          read: (s) => s.wins,
        ),
      };

      LocalNetworkSettingsState allServersSet() => page().copyWith(
            dns1: () => '9.9.9.9',
            dns2: () => '9.9.9.9',
            dns3: () => '9.9.9.9',
            wins: () => '9.9.9.9',
          );

      for (final MapEntry(key: name, value: (:finish, :read))
          in servers.entries) {
        test('$name: takes a valid address', () {
          final (valid, settings) = finish('1.1.1.1', allServersSet());

          expect(valid, isTrue);
          expect(read(settings), '1.1.1.1');
        });

        test('$name: clears the server when left empty', () {
          final (valid, settings) = finish('', allServersSet());

          expect(valid, isFalse);
          expect(read(settings), isNull);
        });

        test('$name: keeps the server through a malformed address', () {
          final (valid, settings) = finish('1.1.1', allServersSet());

          expect(valid, isFalse);
          expect(read(settings), '9.9.9.9');
        });
      }
    });

    group('editing the reservation list', () {
      const tv = DHCPReservation(
        macAddress: 'AA:BB:CC:DD:EE:02',
        ipAddress: '192.168.1.121',
        description: 'TV',
      );

      test('adds reservations that clash with none already listed', () {
        notifier.updateDHCPReservationList(const [
          tv,
          // The NAS's address, under another MAC.
          DHCPReservation(
            macAddress: 'AA:BB:CC:DD:EE:03',
            ipAddress: '192.168.1.120',
            description: 'Clash',
          ),
        ]);

        expect(page().dhcpReservationList.map((r) => r.description),
            ['NAS', 'TV']);
      });

      test('replaces a reservation in place', () {
        final edited = notifier.updateDHCPReservationOfIndex(tv, 0);

        expect(edited, isTrue);
        expect(page().dhcpReservationList, const [tv]);
      });

      test('turns down an edit that clashes with another reservation', () {
        notifier.updateDHCPReservationList(const [tv]);

        final edited = notifier.updateDHCPReservationOfIndex(
            tv.copyWith(description: 'Clash'), 0);

        expect(edited, isFalse);
        expect(page().dhcpReservationList.map((r) => r.description),
            ['NAS', 'TV']);
      });

      test('deletes the reservation an edit marks DELETE', () {
        final deleted = notifier.updateDHCPReservationOfIndex(
            tv.copyWith(ipAddress: 'DELETE'), 0);

        expect(deleted, isTrue);
        expect(page().dhcpReservationList, isEmpty);
      });
    });
  });
}

/// The edit handlers take a [BuildContext] they never read.
final _noContext = _NoContext();

class _NoContext extends Fake implements BuildContext {}
