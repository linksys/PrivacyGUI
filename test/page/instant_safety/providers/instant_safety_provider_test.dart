// Instant Safety: safe browsing is the DNS servers the router's DHCP server
// hands out. The notifier reads them from the LAN settings and writes them
// back, against the router behind RouterRepository.
//
// Whether the router offers Fortinet comes from the poll's GetDeviceInfo, so
// that input is poll-shaped, through RecordingPolling (#1922 decodes the poll
// in one place; a test fed by the poll survives that). The save's error cases
// are in instant_safety_save_error_test.dart.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';

import '../../../common/recording_polling.dart';
import '../../../common/router_boundary.dart';

const _openDNS1 = '208.67.222.222';
const _openDNS2 = '208.67.220.220';
const _fortinet = '208.91.114.155';

/// `GetLANSettings`, with the DNS servers the DHCP server hands out.
Map<String, dynamic> _lanSettings({String? dns1, String? dns2}) => {
      'minNetworkPrefixLength': 16,
      'maxNetworkPrefixLength': 30,
      'minAllowedDHCPLeaseMinutes': 1,
      'maxAllowedDHCPLeaseMinutes': 525600,
      'maxDHCPReservationDescriptionLength': 63,
      'hostName': 'Linksys00042',
      'ipAddress': '192.168.1.1',
      'networkPrefixLength': 24,
      'isDHCPEnabled': true,
      'dhcpSettings': {
        'firstClientIPAddress': '192.168.1.100',
        'lastClientIPAddress': '192.168.1.149',
        'leaseMinutes': 1440,
        if (dns1 != null) 'dnsServer1': dns1,
        if (dns2 != null) 'dnsServer2': dns2,
        'reservations': [
          {
            'macAddress': 'AA:BB:CC:DD:EE:01',
            'ipAddress': '192.168.1.120',
            'description': 'NAS',
          },
        ],
      },
    };

/// The SetLANSettings payload for [_lanSettings] with these DNS servers.
Map<String, dynamic> _written({String? dns1, String? dns2}) => {
      'ipAddress': '192.168.1.1',
      'networkPrefixLength': 24,
      'hostName': 'Linksys00042',
      'isDHCPEnabled': true,
      'dhcpSettings': {
        'lastClientIPAddress': '192.168.1.149',
        'leaseMinutes': 1440,
        'reservations': [
          {
            'macAddress': 'AA:BB:CC:DD:EE:01',
            'ipAddress': '192.168.1.120',
            'description': 'NAS',
          },
        ],
        'firstClientIPAddress': '192.168.1.100',
        if (dns1 != null) 'dnsServer1': dns1,
        if (dns2 != null) 'dnsServer2': dns2,
      },
    };

/// GetDeviceInfo as the poll reports it.
JNAPSuccess _deviceInfo(String modelNumber, String firmwareVersion) =>
    JNAPSuccess(result: 'OK', output: {
      'manufacturer': 'Linksys',
      'modelNumber': modelNumber,
      'hardwareVersion': '1',
      'description': 'Velop',
      'serialNumber': '59A10M21C00042',
      'firmwareVersion': firmwareVersion,
      'firmwareDate': '2026-01-01T00:00:00Z',
      'services': const ['http://linksys.com/jnap/core/Core'],
    });

/// The notifier as the page meets it before any LAN settings were read.
class _NothingRead extends InstantSafetyNotifier {
  @override
  InstantSafetyState build() => const InstantSafetyState();
}

void main() {
  late RouterBoundary router;
  late ProviderContainer container;

  InstantSafetyNotifier notifier() =>
      container.read(instantSafetyProvider.notifier);
  InstantSafetyState page() => container.read(instantSafetyProvider);

  /// Opens the page on a router holding [lan], polled as [poll]; the
  /// notifier's own first read is let land, and the log cleared after it.
  Future<void> open(Map<String, dynamic> lan,
      {Map<JNAPAction, JNAPResult> poll = const {}}) async {
    router = RouterBoundary()..holds(JNAPAction.getLANSettings, lan);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
      pollingProvider.overrideWith(() => RecordingPolling(poll)),
    ]);
    addTearDown(container.dispose);
    container.read(instantSafetyProvider);
    await pumpEventQueue();
    router.sent.clear();
  }

  group('fetchLANSettings', () {
    test('reads OpenDNS when the first DNS server is OpenDNS', () async {
      await open(_lanSettings(dns1: _openDNS1, dns2: _openDNS2));

      await notifier().fetchLANSettings();

      expect(page().safeBrowsingType, InstantSafetyType.openDNS);
    });

    test('reads Fortinet when the first DNS server is Fortinet', () async {
      await open(_lanSettings(dns1: _fortinet));

      await notifier().fetchLANSettings();

      expect(page().safeBrowsingType, InstantSafetyType.fortinet);
    });

    test('reads it off for any other DNS server, and for none', () async {
      await open(_lanSettings(dns1: '8.8.8.8', dns2: _openDNS1));
      await notifier().fetchLANSettings();
      expect(page().safeBrowsingType, InstantSafetyType.off);

      router.holds(JNAPAction.getLANSettings, _lanSettings());
      await notifier().fetchLANSettings();
      expect(page().safeBrowsingType, InstantSafetyType.off);
    });

    test('keeps the LAN settings it read', () async {
      await open(_lanSettings(dns1: _openDNS1, dns2: _openDNS2));

      await notifier().fetchLANSettings();

      expect(page().lanSetting?.ipAddress, '192.168.1.1');
      expect(page().lanSetting?.dhcpSettings.dnsServer2, _openDNS2);
      expect(page().lanSetting?.dhcpSettings.reservations.single.description,
          'NAS');
    });

    test('offers Fortinet on no router: no model is on the list for it',
        () async {
      for (final model in ['MX62', 'MBE70', 'LN11', 'MX4200']) {
        await open(_lanSettings(), poll: {
          JNAPAction.getDeviceInfo: _deviceInfo(model, '9.9.9.999999'),
        });

        await notifier().fetchLANSettings();

        expect(page().hasFortinet, isFalse, reason: model);
      }
    });

    test('offers no Fortinet before the poll has read the router', () async {
      await open(_lanSettings());

      await notifier().fetchLANSettings();

      expect(page().hasFortinet, isFalse);
    });

    test('a refused read reaches the caller and leaves the page as it was',
        () async {
      await open(_lanSettings(dns1: _openDNS1));
      final before = page();
      router.refuses(JNAPAction.getLANSettings);

      await expectLater(
          notifier().fetchLANSettings(), throwsA(isA<JNAPError>()));

      expect(page(), same(before));
    });
  });

  group('setSafeBrowsing', () {
    test(
        "turning OpenDNS on writes OpenDNS's two servers, and the rest of the "
        'LAN as it was', () async {
      await open(_lanSettings());

      await notifier().setSafeBrowsing(InstantSafetyType.openDNS);

      expect(router.payloadsOf(JNAPAction.setLANSettings).single,
          _written(dns1: _openDNS1, dns2: _openDNS2));
    });

    test("turning Fortinet on writes Fortinet's server", () async {
      await open(_lanSettings());

      await notifier().setSafeBrowsing(InstantSafetyType.fortinet);

      expect(router.payloadsOf(JNAPAction.setLANSettings).single,
          _written(dns1: _fortinet));
    });

    test('turning it off hands out no DNS servers', () async {
      await open(_lanSettings(dns1: _openDNS1, dns2: _openDNS2));

      await notifier().setSafeBrowsing(InstantSafetyType.off);

      expect(router.payloadsOf(JNAPAction.setLANSettings).single, _written());
    });

    test('reads the LAN settings back after the save', () async {
      await open(_lanSettings());
      router.holds(JNAPAction.getLANSettings,
          _lanSettings(dns1: _openDNS1, dns2: _openDNS2));

      await notifier().setSafeBrowsing(InstantSafetyType.openDNS);

      expect(router.actions,
          [JNAPAction.setLANSettings, JNAPAction.getLANSettings]);
      expect(page().safeBrowsingType, InstantSafetyType.openDNS);
    });

    test('a refused save reads nothing back', () async {
      await open(_lanSettings());
      router.refuses(JNAPAction.setLANSettings);

      await expectLater(notifier().setSafeBrowsing(InstantSafetyType.openDNS),
          throwsA(isA<SafeBrowsingError>()));

      expect(router.actions, [JNAPAction.setLANSettings]);
      expect(page().safeBrowsingType, InstantSafetyType.off);
    });

    test('saves nothing before the LAN settings have been read', () async {
      router = RouterBoundary();
      container = ProviderContainer(overrides: [
        routerRepositoryProvider.overrideWithValue(router.repo),
        instantSafetyProvider.overrideWith(_NothingRead.new),
      ]);
      addTearDown(container.dispose);

      await expectLater(
        notifier().setSafeBrowsing(InstantSafetyType.openDNS),
        throwsA(isA<SafeBrowsingError>()
            .having((e) => e.message, 'message', 'Lan settings NULL')),
      );
      expect(router.sent, isEmpty);
    });
  });
}
