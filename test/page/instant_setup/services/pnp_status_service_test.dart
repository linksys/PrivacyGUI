import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_trigger_result.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockUspClient extends Mock implements UspClient {}

Map<String, dynamic> _setupResponse({
  required bool acknowledged,
  String method = 'AutoParent',
  bool configured = false,
}) =>
    {
      'Device.DeviceInfo.X_LINKSYS_Setup.AutoConfigurationMethod': method,
      'Device.DeviceInfo.X_LINKSYS_Setup.UserAcknowledgedAutoConfig':
          acknowledged ? '1' : '0',
      'Device.DeviceInfo.X_LINKSYS_Setup.Configured': configured ? '1' : '0',
    };

void main() {
  group('LocalPnpStatusService', () {
    late LocalPnpStatusService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      service = LocalPnpStatusService();
    });

    group('check', () {
      test('returns needsPnp=true when no acknowledged SN exists', () async {
        final result = await service.check('SN123');

        expect(result.needsPnp, isTrue);
        expect(result.configurationMethod, AutoConfigurationMethod.none);
      });

      test('returns needsPnp=true when acknowledged SN is empty', () async {
        SharedPreferences.setMockInitialValues({pPnpConfiguredSN: ''});
        service = LocalPnpStatusService();

        final result = await service.check('SN123');

        expect(result.needsPnp, isTrue);
      });

      test('returns needsPnp=true when SN differs from acknowledged', () async {
        SharedPreferences.setMockInitialValues({pPnpConfiguredSN: 'OLD_SN'});
        service = LocalPnpStatusService();

        final result = await service.check('NEW_SN');

        expect(result.needsPnp, isTrue);
      });

      test('returns needsPnp=false when SN matches acknowledged', () async {
        SharedPreferences.setMockInitialValues({pPnpConfiguredSN: 'SN123'});
        service = LocalPnpStatusService();

        final result = await service.check('SN123');

        expect(result.needsPnp, isFalse);
      });

      test('returns needsPnp=true when currentSerialNumber is null', () async {
        SharedPreferences.setMockInitialValues({pPnpConfiguredSN: 'SN123'});
        service = LocalPnpStatusService();

        final result = await service.check(null);

        expect(result.needsPnp, isTrue);
      });

      test('returns needsPnp=true when currentSerialNumber is empty', () async {
        SharedPreferences.setMockInitialValues({pPnpConfiguredSN: 'SN123'});
        service = LocalPnpStatusService();

        final result = await service.check('');

        expect(result.needsPnp, isTrue);
      });
    });

    group('acknowledge', () {
      test('stores serial number in SharedPreferences', () async {
        await service.acknowledge('SN456');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(pPnpConfiguredSN), 'SN456');
      });

      test('overwrites previous acknowledged SN', () async {
        SharedPreferences.setMockInitialValues({pPnpConfiguredSN: 'OLD_SN'});
        service = LocalPnpStatusService();

        await service.acknowledge('NEW_SN');

        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString(pPnpConfiguredSN), 'NEW_SN');
      });

      test('after acknowledge, check returns needsPnp=false for same SN',
          () async {
        await service.acknowledge('SN789');

        final result = await service.check('SN789');

        expect(result.needsPnp, isFalse);
      });
    });
  });

  group('Tr181PnpStatusService', () {
    late _MockUspClient mockUsp;
    late Tr181PnpStatusService service;

    setUp(() {
      mockUsp = _MockUspClient();
      service = Tr181PnpStatusService(mockUsp);
    });

    test('returns needsPnp=false when UserAcknowledgedAutoConfig=true',
        () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          _setupResponse(acknowledged: true, method: 'AutoParent'));

      final result = await service.check('SN-IGNORED');

      expect(result.needsPnp, isFalse);
    });

    test('returns needsPnp=true with autoParent method when not acknowledged',
        () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          _setupResponse(acknowledged: false, method: 'AutoParent'));

      final result = await service.check('SN-IGNORED');

      expect(result.needsPnp, isTrue);
      expect(result.configurationMethod, AutoConfigurationMethod.autoParent);
    });

    test(
        'returns needsPnp=true with preConfigured method when not acknowledged',
        () async {
      when(() => mockUsp.get(any())).thenAnswer((_) async =>
          _setupResponse(acknowledged: false, method: 'PreConfigured'));

      final result = await service.check(null);

      expect(result.needsPnp, isTrue);
      expect(result.configurationMethod, AutoConfigurationMethod.preConfigured);
    });

    test('maps unknown AutoConfigurationMethod string to none', () async {
      when(() => mockUsp.get(any())).thenAnswer(
          (_) async => _setupResponse(acknowledged: false, method: 'None'));

      final result = await service.check(null);

      expect(result.configurationMethod, AutoConfigurationMethod.none);
    });

    test('acknowledge invokes SetUserAcknowledgedAutoConfig() operate',
        () async {
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {});

      await service.acknowledge('SN-IGNORED');

      verify(() => mockUsp.operate(
              'Device.DeviceInfo.X_LINKSYS_Setup.SetUserAcknowledgedAutoConfig()'))
          .called(1);
    });

    test('check returns notNeeded when fetch throws', () async {
      when(() => mockUsp.get(any())).thenThrow(Exception('USP unreachable'));

      final result = await service.check('SN-IGNORED');

      expect(result.needsPnp, isFalse);
      expect(result.configurationMethod, AutoConfigurationMethod.none);
    });

    test('acknowledge swallows operate failures', () async {
      when(() => mockUsp.operate(any())).thenThrow(Exception('operate failed'));

      // Must not throw — acknowledge is fire-and-forget.
      await service.acknowledge('SN-IGNORED');

      verify(() => mockUsp.operate(any())).called(1);
    });
  });

  group('PnpTriggerResult', () {
    test('notNeeded factory creates correct result', () {
      final result = PnpTriggerResult.notNeeded();

      expect(result.needsPnp, isFalse);
      expect(result.configurationMethod, AutoConfigurationMethod.none);
    });

    test('needed factory creates correct result with default method', () {
      final result = PnpTriggerResult.needed();

      expect(result.needsPnp, isTrue);
      expect(result.configurationMethod, AutoConfigurationMethod.none);
    });

    test('needed factory accepts custom configuration method', () {
      final result =
          PnpTriggerResult.needed(method: AutoConfigurationMethod.autoParent);

      expect(result.needsPnp, isTrue);
      expect(result.configurationMethod, AutoConfigurationMethod.autoParent);
    });

    test('equality works correctly', () {
      final a = PnpTriggerResult.needed();
      final b = PnpTriggerResult.needed();
      final c = PnpTriggerResult.notNeeded();

      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });
}
