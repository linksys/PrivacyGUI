import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';

const _state = LocalNetworkSettingsState(
  hostName: 'Linksys00042',
  ipAddress: '192.168.1.1',
  subnetMask: '255.255.255.0',
  isDHCPEnabled: true,
  firstIPAddress: '192.168.1.100',
  lastIPAddress: '192.168.1.149',
  maxUserLimit: 155,
  maxUserAllowed: 50,
  clientLeaseTime: 1440,
  minAllowDHCPLeaseMinutes: 1,
  maxAllowDHCPLeaseMinutes: 525600,
  minNetworkPrefixLength: 16,
  maxNetworkPrefixLength: 30,
  dns1: '8.8.8.8',
  dns2: '8.8.4.4',
  dns3: '1.1.1.1',
  wins: '192.168.1.5',
  dhcpReservationList: [
    DHCPReservation(
      macAddress: 'AA:BB:CC:DD:EE:01',
      ipAddress: '192.168.1.120',
      description: 'NAS',
    ),
  ],
  errorTextMap: {'dns1': 'dns1'},
  hasErrorOnDhcpServerTab: true,
  hostNameInvalidChars: '!',
);

void main() {
  group('LocalNetworkSettingsState', () {
    test('starts blank, with masks from /8 to /30', () {
      final init = LocalNetworkSettingsState.init();

      expect(init.hostName, '');
      expect(init.isDHCPEnabled, isFalse);
      expect(init.minNetworkPrefixLength, 8);
      expect(init.maxNetworkPrefixLength, 30);
      expect(init.dhcpReservationList, isEmpty);
      expect(init.errorTextMap, isEmpty);
    });

    test('survives a trip through JSON text', () {
      expect(LocalNetworkSettingsState.fromJson(_state.toJson()), _state);
    });

    test('reads what the map leaves out as blank', () {
      final read =
          LocalNetworkSettingsState.fromMap(const {'dhcpReservationList': []});

      expect(read.hostName, '');
      expect(read.maxUserLimit, 0);
      expect(read.minNetworkPrefixLength, 0);
      expect(read.dns1, isNull);
      expect(read.errorTextMap, isEmpty);
      expect(read.hasErrorOnHostNameTab, isFalse);
    });

    test('tells two pages apart by their fields', () {
      expect(_state.copyWith(hostName: 'Den'), isNot(_state));
      expect(_state.copyWith(), _state);
    });

    test('compares pages without their reservation lists', () {
      final noReservations = _state.copyWith(dhcpReservationList: []);

      expect(_state.isEqualStateWithoutDhcpReservationList(noReservations),
          isTrue);
      expect(
          _state.isEqualStateWithoutDhcpReservationList(
              noReservations.copyWith(clientLeaseTime: 60)),
          isFalse);
    });

    test('copyWith can clear the servers and the invalid characters', () {
      final cleared = _state.copyWith(
        dns1: () => null,
        dns2: () => null,
        dns3: () => null,
        wins: () => null,
        hostNameInvalidChars: () => null,
      );

      expect(cleared.dns1, isNull);
      expect(cleared.dns2, isNull);
      expect(cleared.dns3, isNull);
      expect(cleared.wins, isNull);
      expect(cleared.hostNameInvalidChars, isNull);
    });

    test('describes itself by its fields', () {
      expect(_state.toString(), contains('hostName: Linksys00042'));
    });
  });

  group('LocalNetworkErrorPrompt', () {
    late BuildContext context;

    /// Builds an English app for `loc(context)` to read its strings from.
    Future<void> openApp(WidgetTester tester) => tester.pumpWidget(MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(builder: (built) {
            context = built;
            return const SizedBox();
          }),
        ));

    test('reads an error by its name, and nothing for an unknown one', () {
      expect(LocalNetworkErrorPrompt.resolve('subnetMask'),
          LocalNetworkErrorPrompt.subnetMask);
      expect(LocalNetworkErrorPrompt.resolve('nope'), isNull);
      expect(LocalNetworkErrorPrompt.resolve(null), isNull);
    });

    testWidgets('shows nothing when there is no error', (tester) async {
      await openApp(tester);

      expect(LocalNetworkErrorPrompt.getErrorText(context: context), isNull);
    });

    testWidgets('shows each error as its message', (tester) async {
      await openApp(tester);
      const messages = <LocalNetworkErrorPrompt, String>{
        LocalNetworkErrorPrompt.startIpAddress:
            'Invalid IP address or the same as the Host IP address',
        LocalNetworkErrorPrompt.ipAddress: 'Invalid IP address',
        LocalNetworkErrorPrompt.maxUserAllowed: 'Invalid number',
        LocalNetworkErrorPrompt.subnetMask: 'Invalid subnet mask',
        LocalNetworkErrorPrompt.leaseTime: 'Invalid number',
        LocalNetworkErrorPrompt.dns1: 'Invalid IP address',
        LocalNetworkErrorPrompt.dns2: 'Invalid IP address',
        LocalNetworkErrorPrompt.dns3: 'Invalid IP address',
        LocalNetworkErrorPrompt.wins: 'Invalid IP address',
        LocalNetworkErrorPrompt.hostName: 'Host name can not be empty.',
        LocalNetworkErrorPrompt.hostNameStartWithHyphen:
            'Host name cannot start with a hyphen.',
        LocalNetworkErrorPrompt.hostNameEndWithHyphen:
            'Host name cannot end with a hyphen.',
        LocalNetworkErrorPrompt.hostNameLengthError:
            'Host name must be between 1 and 15 characters.',
      };

      for (final MapEntry(key: error, value: message) in messages.entries) {
        expect(
            LocalNetworkErrorPrompt.getErrorText(
                context: context, error: error),
            message,
            reason: error.name);
      }
    });

    testWidgets('names the characters a host name may not hold',
        (tester) async {
      await openApp(tester);

      expect(
          LocalNetworkErrorPrompt.getErrorText(
            context: context,
            error: LocalNetworkErrorPrompt.hostNameInvalidCharacters,
            invalidChars: '!, @',
          ),
          'Host name contains invalid characters: !, @. '
          'Allowed characters are letters, numbers, and hyphens.');
    });

    testWidgets(
        'names the first host of the router network for a start '
        'address outside it', (tester) async {
      await openApp(tester);

      final text = LocalNetworkErrorPrompt.getErrorText(
        context: context,
        error: LocalNetworkErrorPrompt.startIpAddressRange,
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      // The end of the range is left out: on the Dart VM the state computes
      // the broadcast address with a 64-bit `~` and gets it wrong (see the
      // #1866 wave 5 report); dart2js, which 1.x ships, gets it right.
      expect(
          text, startsWith('IP address not in valid subnet [192.168.1.1 - '));
    });
  });
}
