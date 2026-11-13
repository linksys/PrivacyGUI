import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_service.dart';

import '../../../mocks/test_data/ddns_test_data.dart';
import '../../../mocks/test_data/usp_envelope_test_data.dart';

class MockUspClient extends Mock implements UspClient {}

const _aliasPath = 'Device.IP.Interface.*.Alias';
const _client = DdnsTestData.clientPath;
const _hostname = DdnsTestData.hostnamePath;

void main() {
  late MockUspClient usp;
  late UspDdnsService service;

  setUp(() {
    usp = MockUspClient();
    service = UspDdnsService(usp);
  });

  /// Answers the DDNS read with [ddns], and the WAN alias read with the
  /// bench's interfaces (LAN 1, WAN 2).
  void stubGets(Map<String, dynamic> ddns) {
    when(() => usp.get(any())).thenAnswer((invocation) async {
      final paths = invocation.positionalArguments.first as List<String>;
      if (paths.contains(_aliasPath)) {
        return {
          'Device.IP.Interface.1.Alias': 'lan',
          'Device.IP.Interface.2.Alias': 'wan',
        };
      }
      return ddns;
    });
  }

  void stubSetSuccess() {
    when(() => usp.set(any(), allowPartial: any(named: 'allowPartial')))
        .thenAnswer((_) async => {
              'success': true,
              'result': {'data': <String, dynamic>{}},
            });
  }

  /// The params and the allow_partial flag of the one Set a save sends.
  (Map<String, dynamic>, bool) capturedSet() {
    final captured = verify(() => usp.set(captureAny(),
        allowPartial: captureAny(named: 'allowPartial'))).captured;
    expect(captured, hasLength(2), reason: 'a save is one Set');
    return (captured[0] as Map<String, dynamic>, captured[1] as bool);
  }

  Map<String, dynamic> capturedSetParams() => capturedSet().$1;

  group('UspDdnsService - fetch', () {
    test('reads the shipped rows as "Disabled" with both providers', () async {
      stubGets(DdnsTestData.response());

      final (settings, status) = await service.fetch();

      expect(settings.providers, [DdnsTestData.dynDns, DdnsTestData.noIp]);
      expect(settings.providerPath, isNull);
      expect(settings.isEnabled, isFalse);
      expect(settings.username, '');
      expect(settings.password, '');
      expect(settings.hostname, '');
      expect(settings.hasStoredAccount, isFalse);
      expect(settings.clientPath, _client);
      expect(settings.hostnamePath, _hostname);
      expect(status.isLoading, isFalse);
      expect(status.error, isNull);
    });

    test('reads an enabled client as the provider its Server names', () async {
      stubGets(DdnsTestData.configuredResponse());

      final (settings, _) = await service.fetch();

      expect(settings.providerPath, DdnsTestData.noIpPath);
      expect(settings.username, 'user@example.com');
      expect(settings.hostname, 'home.example.net');
      expect(settings.hasStoredAccount, isTrue);
    });

    test('a Server written with a trailing dot still matches its provider',
        () async {
      stubGets(DdnsTestData.response(
        clientEnable: true,
        clientServer: '${DdnsTestData.dynDnsPath}.',
      ));

      final (settings, _) = await service.fetch();

      expect(settings.providerPath, DdnsTestData.dynDnsPath);
    });

    test(
        'a disabled client with a stored account reads as "Disabled" and '
        'keeps the account', () async {
      stubGets(DdnsTestData.response(
        clientServer: DdnsTestData.noIpPath,
        username: 'user@example.com',
        hostname: 'home.example.net',
      ));

      final (settings, _) = await service.fetch();

      expect(settings.providerPath, isNull);
      expect(settings.username, 'user@example.com');
      expect(settings.hostname, 'home.example.net');
      expect(settings.hasStoredAccount, isTrue);
      expect(settings.storedUsername, 'user@example.com');
      expect(settings.storedServerPath, DdnsTestData.noIpPath,
          reason: 'choosing No-IP again keeps the stored password');
    });

    test('lists only the enabled Server rows, in instance order', () async {
      stubGets(DdnsTestData.response(
        servers: const [(true, 'DynDNS'), (false, 'No-IP'), (true, 'Other')],
      ));

      final (settings, _) = await service.fetch();

      expect(settings.providers.map((p) => p.name), ['DynDNS', 'Other']);
      expect(settings.providers.last.path, 'Device.DynamicDNS.Server.3');
    });

    test(
        'a client on a provider the router no longer offers reads as '
        '"Disabled"', () async {
      stubGets(DdnsTestData.response(
        servers: const [(true, 'DynDNS'), (false, 'No-IP')],
        clientEnable: true,
        clientServer: DdnsTestData.noIpPath,
      ));

      final (settings, _) = await service.fetch();

      expect(settings.providerPath, isNull);
      expect(settings.clientEnabled, isTrue,
          reason: 'choosing "Disabled" must still be a change to save');
    });

    test('an enabled client on no provider keeps its Enable too', () async {
      stubGets(DdnsTestData.response(clientEnable: true));

      final (settings, _) = await service.fetch();

      expect(settings.providerPath, isNull);
      expect(settings.clientEnabled, isTrue);
    });

    test('a router with no client row is ResourceNotFoundError', () async {
      stubGets({
        'Device.DynamicDNS.Server.1.Enable': true,
        'Device.DynamicDNS.Server.1.Name': 'DynDNS',
      });

      expect(service.fetch(), throwsA(isA<ResourceNotFoundError>()));
    });

    test('a client with no host name row is ResourceNotFoundError', () async {
      final response = DdnsTestData.response()
        ..removeWhere((key, _) => key.startsWith(_hostname));
      stubGets(response);

      expect(service.fetch(), throwsA(isA<ResourceNotFoundError>()));
    });

    test('a client row missing a required leaf fails the read', () async {
      final response = DdnsTestData.response()..remove('${_client}LastError');
      stubGets(response);

      expect(service.fetch(), throwsA(isA<ServiceError>()));
    });

    test('maps a thrown USP error to ServiceError', () async {
      when(() => usp.get(any())).thenThrow('Get failed: Transport error');

      expect(service.fetch(), throwsA(isA<ServiceError>()));
    });
  });

  group('UspDdnsService - save with a provider', () {
    test(
        'writes the client and its host name in one Set with '
        'allow_partial off', () async {
      stubGets(DdnsTestData.response());
      stubSetSuccess();

      await service.save(DdnsTestData.settings(
        providerPath: DdnsTestData.noIpPath,
        username: 'user@example.com',
        password: 'secret',
        hostname: 'home.example.net',
      ));

      final (params, allowPartial) = capturedSet();
      expect(allowPartial, isFalse);
      expect(params, {
        '${_client}Enable': true,
        '${_client}Server': DdnsTestData.noIpPath,
        '${_client}Interface': 'Device.IP.Interface.2',
        '${_client}Username': 'user@example.com',
        '${_client}Password': 'secret',
        '${_hostname}Enable': true,
        '${_hostname}Name': 'home.example.net',
      });
    });

    test('an untouched password is not sent, so the stored one is kept',
        () async {
      stubGets(DdnsTestData.response());
      stubSetSuccess();

      await service.save(DdnsTestData.configuredSettings());

      final params = capturedSetParams();
      expect(params.containsKey('${_client}Password'), isFalse,
          reason: 'the password reads back as "", and writing "" erases it');
      expect(params['${_client}Username'], 'user@example.com');
    });

    test('Interface is the WAN found by its Alias, without the trailing dot',
        () async {
      when(() => usp.get(any())).thenAnswer((invocation) async {
        final paths = invocation.positionalArguments.first as List<String>;
        expect(paths, [_aliasPath]);
        return {
          'Device.IP.Interface.1.Alias': 'lan',
          'Device.IP.Interface.5.Alias': 'wan',
        };
      });
      stubSetSuccess();

      await service.save(DdnsTestData.configuredSettings());

      expect(
          capturedSetParams()['${_client}Interface'], 'Device.IP.Interface.5');
    });

    test('a router with no WAN interface sends nothing', () async {
      when(() => usp.get(any()))
          .thenAnswer((_) async => {'Device.IP.Interface.1.Alias': 'lan'});

      await expectLater(service.save(DdnsTestData.configuredSettings()),
          throwsA(isA<ResourceNotFoundError>()));
      verifyNever(
          () => usp.set(any(), allowPartial: any(named: 'allowPartial')));
    });
  });

  group('UspDdnsService - save "Disabled"', () {
    test('writes the client Enable alone, keeping the account', () async {
      stubSetSuccess();

      await service.save(DdnsTestData.configuredSettings().copyWith(
        clearProviderPath: true,
      ));

      expect(capturedSetParams(), {'${_client}Enable': false});
      verifyNever(() => usp.get(any()));
    });
  });

  group('UspDdnsService - save errors', () {
    test('a refused Set is UspCompleteFailureError', () async {
      stubGets(DdnsTestData.response());
      when(() => usp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => UspEnvelopeTestData.parameterErrors(
                {'${_client}Username': (code: 7012, message: 'Value too long')},
                success: false,
              ));

      expect(service.save(DdnsTestData.configuredSettings()),
          throwsA(isA<UspCompleteFailureError>()));
    });

    // allow_partial is off, so a split answer is not expected; if one arrives
    // the save still fails, naming what landed.
    test('a partly applied Set is UspPartialFailureError', () async {
      stubGets(DdnsTestData.response());
      when(() => usp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenAnswer((_) async => UspEnvelopeTestData.parameterErrors(
                {'${_hostname}Name': (code: 7012, message: 'Value too long')},
                success: true,
                data: {'${_client}Enable': true},
              ));

      expect(service.save(DdnsTestData.configuredSettings()),
          throwsA(isA<UspPartialFailureError>()));
    });

    test('a thrown USP error maps to ServiceError', () async {
      stubGets(DdnsTestData.response());
      when(() => usp.set(any(), allowPartial: any(named: 'allowPartial')))
          .thenThrow('Set failed: Transport error');

      expect(service.save(DdnsTestData.configuredSettings()),
          throwsA(isA<ServiceError>()));
    });
  });

  group('UspDdnsService - provider', () {
    test('needs a USP client', () {
      final container = ProviderContainer(
          overrides: [uspClientProvider.overrideWithValue(null)]);
      addTearDown(container.dispose);

      expect(() => container.read(uspDdnsServiceProvider),
          throwsA(isA<ServiceNotInitializedError>()));
    });

    test('builds the service over the session client', () {
      final container = ProviderContainer(
          overrides: [uspClientProvider.overrideWithValue(usp)]);
      addTearDown(container.dispose);

      expect(container.read(uspDdnsServiceProvider), isA<UspDdnsService>());
    });
  });
}
