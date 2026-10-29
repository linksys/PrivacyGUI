import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/administration/services/usp_administration_service.dart';

class MockUspClient extends Mock implements UspClient {}

const _upnpEnable = 'Device.UPnP.Device.Enable';
const _sipEnable = 'Device.Firewall.ConnectionTracking.SIP.Enable';
const _rulesEnable = 'Device.Firewall.Chain.*.Rule.*.Enable';

/// A `Device.Firewall.Chain.` table as the router answers it: [rules] on the
/// `Defaults Configuration` chain (Chain.3), one entry per rule,
/// `(Description, Enable)`, numbered from 11. Target is ACCEPT throughout; the
/// service reads only Description and Enable.
///
/// The UPnP chain (Chain.2) comes first and carries a `RULE_MGMT_WIFI_ACCESS`
/// of its own, enabled the other way round, so a read of the wrong chain
/// shows.
Map<String, dynamic> _chainRules(List<(String, String)> rules) {
  final defaultEnable = rules
      .where((r) => r.$1 == 'RULE_MGMT_WIFI_ACCESS')
      .map((r) => r.$2)
      .firstOrNull;
  return {
    'Device.Firewall.Chain.2.Name': 'UPnP Port Mapping (dynamic rules)',
    'Device.Firewall.Chain.2.Rule.4.Enable': defaultEnable == '1' ? '0' : '1',
    'Device.Firewall.Chain.2.Rule.4.Description': 'RULE_MGMT_WIFI_ACCESS',
    'Device.Firewall.Chain.2.Rule.4.Target': 'Accept',
    'Device.Firewall.Chain.3.Name': 'Defaults Configuration',
    for (final (i, (desc, enable)) in rules.indexed) ...{
      'Device.Firewall.Chain.3.Rule.${i + 11}.Enable': enable,
      'Device.Firewall.Chain.3.Rule.${i + 11}.Description': desc,
      'Device.Firewall.Chain.3.Rule.${i + 11}.Target': 'Accept',
    },
  };
}

/// 26101472's table, shortened: no `RULE_MGMT_WIFI_ACCESS` (31 rules there).
final _rulesWithoutManagement = _chainRules([
  ('RULE_SPI_IPV4_INPUT', '0'),
  ('RULE_PING_IPV4', '1'),
  ('RULE_NAT_REDIRECTION', '0'),
]);

/// feed_usp#52's table: the rule is appended, enabled by default. Not at a
/// fixed instance number, so it is looked up by Description.
Map<String, dynamic> _rulesWithManagement(String enable) => _chainRules([
      ('RULE_SPI_IPV4_INPUT', '0'),
      ('RULE_PING_IPV4', '1'),
      ('RULE_MGMT_WIFI_ACCESS', enable),
      ('RULE_NAT_REDIRECTION', '0'),
    ]);

Map<String, dynamic> _setSuccess() => {
      'success': true,
      'result': {'data': <String, dynamic>{}},
    };

Map<String, dynamic> _setFailure({
  String path = 'Device.UPnP.Device.Enable',
  int errorCode = 9007,
  String errorMessage = 'Invalid parameter value',
}) =>
    {
      'success': false,
      'result': {
        'data': <String, dynamic>{},
        'error': {
          path: {'errorCode': errorCode, 'errorMessage': errorMessage},
        },
      },
    };

void main() {
  late MockUspClient mockUsp;
  late UspAdministrationService svc;

  setUp(() {
    mockUsp = MockUspClient();
    svc = UspAdministrationService(mockUsp);
  });

  /// Each definition's Get, answered by its own leaves: the service reads UPnP
  /// and SIP ALG with separate Gets, so a stub keyed on the whole path list
  /// would pin the order of two calls the service is free to run in parallel.
  void answerGets({
    String upnp = '1',
    String? sip = '0',
    Map<String, dynamic>? rules,
  }) {
    final chain = rules ?? _rulesWithManagement('1');
    when(() => mockUsp.get(any())).thenAnswer((inv) async {
      final paths = inv.positionalArguments.first as List<String>;
      if (paths.contains(_upnpEnable)) {
        return {_upnpEnable: upnp, 'Device.UPnP.Device.UPnPIGD': upnp};
      }
      if (paths.contains(_sipEnable)) {
        return {if (sip != null) _sipEnable: sip};
      }
      if (paths.contains(_rulesEnable)) return chain;
      return {};
    });
  }

  group('UspAdministrationService - fetch', () {
    test('reads Device.UPnP.Device.Enable as the UPnP switch', () async {
      answerGets(upnp: '1');

      final settings = await svc.fetch();

      expect(settings.upnpEnabled, isTrue);
      verify(() => mockUsp.get([
            'Device.UPnP.Device.Enable',
            'Device.UPnP.Device.UPnPIGD',
          ])).called(1);
    });

    test('reads off as off', () async {
      answerGets(upnp: '0');

      expect((await svc.fetch()).upnpEnabled, isFalse);
    });

    test('a firmware without Device.UPnP fails the fetch, not a silent off',
        () {
      when(() => mockUsp.get(any())).thenAnswer((_) async => {});

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });

    test(
        'reads Device.Firewall.ConnectionTracking.SIP.Enable as the SIP ALG '
        'switch', () async {
      answerGets(sip: '1');

      final settings = await svc.fetch();

      expect(settings.sipAlgEnabled, isTrue);
      verify(() => mockUsp.get([_sipEnable])).called(1);
    });

    test('SIP ALG reads off on a factory-default router', () async {
      // FWDEV#217: default 0, as on 1.0. Measured `Enable => 0` on 26101472.
      answerGets(sip: '0');

      expect((await svc.fetch()).sipAlgEnabled, isFalse);
    });

    test('a firmware without the SIP leaf fails the fetch, not a silent off',
        () {
      // The leaf is required: it ships on FLWRT 2.0, and an absent one read as
      // "off" would hide a firmware that cannot honour the switch.
      answerGets(sip: null);

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });

    test(
        'reads RULE_MGMT_WIFI_ACCESS\'s Enable as the management-over-Wi-Fi '
        'switch', () async {
      answerGets(rules: _rulesWithManagement('0'));

      final settings = await svc.fetch();

      expect(settings.managementWifiEnabled, isFalse);
      verify(() => mockUsp.get([
            'Device.Firewall.Chain.*.Name',
            'Device.Firewall.Chain.*.Rule.*.Enable',
            'Device.Firewall.Chain.*.Rule.*.Description',
            'Device.Firewall.Chain.*.Rule.*.Target',
          ])).called(1);
    });

    test('the rule enabled reads on, its default', () async {
      answerGets(rules: _rulesWithManagement('1'));

      expect((await svc.fetch()).managementWifiEnabled, isTrue);
    });

    test('a firmware without the rule reads null: hide the switch only',
        () async {
      // 2.0.3.26101472, measured 2026-10-16: 31 rules, none of them this one.
      answerGets(rules: _rulesWithoutManagement, upnp: '0', sip: '1');

      final settings = await svc.fetch();

      expect(settings.managementWifiEnabled, isNull);
      expect(settings.upnpEnabled, isFalse,
          reason: 'the rest of the page still reads');
      expect(settings.sipAlgEnabled, isTrue);
    });

    test('a rule table that reads empty is a failed read, not a missing rule',
        () {
      // The WASM client resolves a failed GET with an empty data map, so a
      // chain table with no rules at all is a read that did not land: the router's
      // firewall always carries its own rules. Read as "no rule" it would hide
      // the switch without a word (FW's reference patch's `catch -> null`).
      answerGets(rules: const {});

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });

    test('a chain of only blank rules is a failed read, as before', () {
      // usp-codegen 0.18 returns rows with every value blank where 0.17 dropped
      // them (#1654); a chain holding only those read back nothing.
      answerGets(rules: {
        'Device.Firewall.Chain.3.Name': 'Defaults Configuration',
        'Device.Firewall.Chain.3.Rule.11.Enable': '',
        'Device.Firewall.Chain.3.Rule.11.Description': '',
        'Device.Firewall.Chain.3.Rule.11.Target': '',
      });

      expect(() => svc.fetch(), throwsA(isA<ServiceError>()));
    });

    test('a thrown rule-table read is a ServiceError, not a hidden switch', () {
      answerGets();
      when(() => mockUsp.get(any(that: contains(_rulesEnable))))
          .thenThrow('Get failed: Transport error: Connection refused');

      expect(() => svc.fetch(), throwsA(isA<ConnectivityError>()));
    });

    test('maps a USP error to ServiceError', () {
      when(() => mockUsp.get(any()))
          .thenThrow('Get failed: Transport error: Connection refused');

      expect(() => svc.fetch(), throwsA(isA<ConnectivityError>()));
    });
  });

  group('UspAdministrationService - setUpnpEnabled', () {
    test('writes Enable alone, in one Set', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setSuccess());

      await svc.setUpnpEnabled(false);

      // Never UPnPIGD: it is read-only and follows Enable.
      verify(() => mockUsp.set(
            {'Device.UPnP.Device.Enable': false},
            allowPartial: false,
          )).called(1);
    });

    test('a partial result is a partial failure, not a success', () {
      // A one-leaf Set should not come back partial, but the parser can say so
      // and the branch must not read as success if it ever does.
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => {
                'success': true,
                'result': {
                  'data': {'Device.UPnP.Device.UPnPIGD': '1'},
                  'error': {
                    'Device.UPnP.Device.Enable': {
                      'errorCode': 9007,
                      'errorMessage': 'Invalid parameter value',
                    },
                  },
                },
              });

      expect(() => svc.setUpnpEnabled(false),
          throwsA(isA<UspPartialFailureError>()));
    });

    test('a refused Set throws UspCompleteFailureError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setFailure());

      expect(() => svc.setUpnpEnabled(true),
          throwsA(isA<UspCompleteFailureError>()));
    });

    test('a transport error maps to ServiceError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Connection refused');

      expect(() => svc.setUpnpEnabled(true), throwsA(isA<ConnectivityError>()));
    });
  });

  group('UspAdministrationService - setSipAlgEnabled', () {
    test('writes ConnectionTracking.SIP.Enable alone, in one Set', () async {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setSuccess());

      await svc.setSipAlgEnabled(true);

      // Not Device.NAT.ALG.*: that path is invalid on FLWRT (FW, #875).
      verify(() => mockUsp.set({_sipEnable: true}, allowPartial: false))
          .called(1);
    });

    test('a refused Set throws UspCompleteFailureError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setFailure(path: _sipEnable));

      expect(() => svc.setSipAlgEnabled(true),
          throwsA(isA<UspCompleteFailureError>()));
    });

    test('a transport error maps to ServiceError', () {
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error: Connection refused');

      expect(
          () => svc.setSipAlgEnabled(false), throwsA(isA<ConnectivityError>()));
    });
  });

  group('UspAdministrationService - setManagementWifiEnabled', () {
    test('writes the Enable of the rule found by Description, alone', () async {
      answerGets(rules: _rulesWithManagement('1'));
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => _setSuccess());

      await svc.setManagementWifiEnabled(false);

      // Row 13 of the default chain: wherever the rule is, not a fixed number,
      // and never the UPnP chain's rule of the same name.
      verify(() => mockUsp.set(
            {'Device.Firewall.Chain.3.Rule.13.Enable': false},
            allowPartial: false,
          )).called(1);
    });

    test('a firmware without the rule writes nothing and says so', () async {
      answerGets(rules: _rulesWithoutManagement);

      await expectLater(svc.setManagementWifiEnabled(true),
          throwsA(isA<ResourceNotFoundError>()));
      verifyNever(
          () => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')));
    });

    test('a refused Set throws UspCompleteFailureError', () {
      answerGets(rules: _rulesWithManagement('1'));
      when(() => mockUsp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async =>
              _setFailure(path: 'Device.Firewall.Chain.3.Rule.13.Enable'));

      expect(() => svc.setManagementWifiEnabled(false),
          throwsA(isA<UspCompleteFailureError>()));
    });
  });
}
