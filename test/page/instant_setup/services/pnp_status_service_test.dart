import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_trigger_result.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
