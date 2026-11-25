import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/dmz_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/dmz/providers/dmz_settings_state.dart';

import '../../../../common/router_boundary.dart';

/// `GetLANSettings` output: 10.0.1.1/16.
const _lan = <String, dynamic>{
  'minNetworkPrefixLength': 16,
  'maxNetworkPrefixLength': 30,
  'minAllowedDHCPLeaseMinutes': 1,
  'maxDHCPReservationDescriptionLength': 63,
  'hostName': 'Linksys00042',
  'ipAddress': '10.0.1.1',
  'networkPrefixLength': 16,
  'isDHCPEnabled': true,
  'dhcpSettings': {
    'firstClientIPAddress': '10.0.1.100',
    'lastClientIPAddress': '10.0.1.149',
    'leaseMinutes': 1440,
    'reservations': <Map<String, dynamic>>[],
  },
};

/// `GetDMZSettings` output, as in the legacy JNAP reference's sample: on,
/// open to a source range, to a server picked by its address. Not the
/// router-shaped test data, which has no source range.
const _dmzToAddress = <String, dynamic>{
  'isDMZEnabled': true,
  'sourceRestriction': {
    'firstIPAddress': '192.168.10.1',
    'lastIPAddress': '192.168.11.1',
  },
  'destinationIPAddress': '10.0.1.200',
};

void main() {
  late RouterBoundary router;
  late ProviderContainer container;
  late DMZSettingNotifier notifier;

  DMZSettingsState page() => container.read(dmzSettingsProvider);

  setUp(() {
    router = RouterBoundary()
      ..holds(JNAPAction.getLANSettings, _lan)
      ..holds(JNAPAction.getDMZSettings, _dmzToAddress);
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(router.repo),
    ]);
    notifier = container.read(dmzSettingsProvider.notifier);
  });

  tearDown(() => container.dispose());

  group('fetch', () {
    test('reads the LAN and the DMZ in one transaction', () async {
      await notifier.fetch();

      expect(router.transactions.single.map((command) => command.key),
          [JNAPAction.getLANSettings, JNAPAction.getDMZSettings]);
    });

    test('shows a DMZ open to a source range, to a server address', () async {
      final shown = await notifier.fetch();

      expect(shown, page());
      expect(
        page().settings,
        const DMZSettings(
          isDMZEnabled: true,
          sourceRestriction: DMZSourceRestriction(
            firstIPAddress: '192.168.10.1',
            lastIPAddress: '192.168.11.1',
          ),
          destinationIPAddress: '10.0.1.200',
        ),
      );
      expect(page().sourceType, DMZSourceType.range);
      expect(page().destinationType, DMZDestinationType.ip);
    });

    test('shows a DMZ open to any source, to a server MAC address', () async {
      router.holds(JNAPAction.getDMZSettings, {
        'isDMZEnabled': true,
        'destinationMACAddress': 'AA:BB:CC:DD:EE:01',
      });

      await notifier.fetch();

      expect(page().sourceType, DMZSourceType.auto);
      expect(page().destinationType, DMZDestinationType.mac);
      expect(page().settings.destinationMACAddress, 'AA:BB:CC:DD:EE:01');
    });

    test('takes the LAN network the server address must sit in', () async {
      await notifier.fetch();

      // 10.0.1.1/16: the page offers 10.0.x.x.
      expect(notifier.subnetMask, '255.255.0.0');
      expect(notifier.ipAddress, '10.0.0.0');
    });

    test('reports a read the router refuses, and keeps what it showed',
        () async {
      await notifier.fetch();
      router.refuses(JNAPAction.getDMZSettings);

      await expectLater(notifier.fetch(), throwsA(isA<JNAPError>()));

      expect(page().settings, DMZSettings.fromMap(_dmzToAddress));
      expect(page().sourceType, DMZSourceType.range);
    });
  });

  group('save', () {
    setUp(() async {
      await notifier.fetch();
      router
        ..sent.clear()
        ..transactions.clear();
    });

    test('writes the DMZ the page shows', () async {
      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setDMZSettings).single, {
        'isDMZEnabled': true,
        'sourceRestriction': {
          'firstIPAddress': '192.168.10.1',
          'lastIPAddress': '192.168.11.1',
        },
        'destinationIPAddress': '10.0.1.200',
      });
    });

    test('leaves out what the DMZ does not use', () async {
      notifier.setSettings(const DMZSettings(
        isDMZEnabled: true,
        destinationMACAddress: 'AA:BB:CC:DD:EE:01',
      ));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setDMZSettings).single, {
        'isDMZEnabled': true,
        'destinationMACAddress': 'AA:BB:CC:DD:EE:01',
      });
    });

    test('turns the DMZ off with nothing else', () async {
      notifier.setSettings(const DMZSettings(isDMZEnabled: false));

      await notifier.save();

      expect(router.payloadsOf(JNAPAction.setDMZSettings).single,
          {'isDMZEnabled': false});
    });

    test('reads the DMZ back from the router after the write', () async {
      router.holds(JNAPAction.getDMZSettings, {'isDMZEnabled': false});

      final saved = await notifier.save();

      expect(router.actions.first, JNAPAction.setDMZSettings);
      expect(router.transactions, hasLength(1));
      expect(saved.settings, const DMZSettings(isDMZEnabled: false));
      expect(page().settings.isDMZEnabled, isFalse);
    });

    test('reports a write the router refuses, and reads nothing back',
        () async {
      router.refuses(JNAPAction.setDMZSettings,
          result: 'ErrorInvalidDestinationIPAddress');
      notifier.setSettings(const DMZSettings(isDMZEnabled: false));

      await expectLater(
        notifier.save(),
        throwsA(isA<JNAPError>().having((error) => error.result, 'result',
            'ErrorInvalidDestinationIPAddress')),
      );

      expect(router.actions, [JNAPAction.setDMZSettings]);
      expect(page().settings.isDMZEnabled, isFalse);
    });
  });

  group('editing', () {
    setUp(() => notifier.fetch());

    test('switches the source between any and a range', () {
      notifier.setSourceType(DMZSourceType.auto);
      expect(page().sourceType, DMZSourceType.auto);

      notifier.setSourceType(DMZSourceType.range);
      expect(page().sourceType, DMZSourceType.range);
    });

    test('switches the destination between an address and a MAC', () {
      notifier.setDestinationType(DMZDestinationType.mac);

      expect(page().destinationType, DMZDestinationType.mac);
    });

    test('clears both destinations and keeps the source range', () {
      notifier.clearDestinations();

      expect(
        page().settings,
        const DMZSettings(
          isDMZEnabled: true,
          sourceRestriction: DMZSourceRestriction(
            firstIPAddress: '192.168.10.1',
            lastIPAddress: '192.168.11.1',
          ),
        ),
      );
    });
  });
}
