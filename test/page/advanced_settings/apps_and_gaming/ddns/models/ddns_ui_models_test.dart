import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';

void main() {
  group('DDNSProviderUIModel', () {
    group('create factory', () {
      test('creates DynDNSProviderUIModel for DynDNS provider name', () {
        final provider = DDNSProviderUIModel.create(dynDNSProviderName);
        expect(provider, isA<DynDNSProviderUIModel>());
        expect(provider.name, dynDNSProviderName);
      });

      test('creates NoIPDNSProviderUIModel for No-IP provider name', () {
        final provider = DDNSProviderUIModel.create(noIPDNSProviderName);
        expect(provider, isA<NoIPDNSProviderUIModel>());
        expect(provider.name, noIPDNSProviderName);
      });

      test('creates TzoDNSProviderUIModel for TZO provider name', () {
        final provider = DDNSProviderUIModel.create(tzoDNSProviderName);
        expect(provider, isA<TzoDNSProviderUIModel>());
        expect(provider.name, tzoDNSProviderName);
      });

      test('creates NoDDNSProviderUIModel for empty provider name', () {
        final provider = DDNSProviderUIModel.create('');
        expect(provider, isA<NoDDNSProviderUIModel>());
        expect(provider.name, noDNSProviderName);
      });

      test('creates NoDDNSProviderUIModel for unknown provider name', () {
        final provider = DDNSProviderUIModel.create('UnknownProvider');
        expect(provider, isA<NoDDNSProviderUIModel>());
      });
    });
  });

  group('DynDNSProviderUIModel', () {
    test('has correct name constant', () {
      final provider = DynDNSProviderUIModel();
      expect(provider.name, 'DynDNS');
    });

    test('copyWith returns new instance with updated values', () {
      final original = DynDNSProviderUIModel(
        username: 'original',
        password: 'pass1',
        hostName: 'host1.com',
        isWildcardEnabled: false,
        mode: 'Dynamic',
        isMailExchangeEnabled: false,
      );

      final updated = original.copyWith(
        username: 'updated',
        isWildcardEnabled: true,
      );

      expect(updated.username, 'updated');
      expect(updated.password, 'pass1'); // unchanged
      expect(updated.hostName, 'host1.com'); // unchanged
      expect(updated.isWildcardEnabled, true);
    });

    test('copyWith with mailExchangeSettings', () {
      final original = DynDNSProviderUIModel(
        username: 'user',
        password: 'pass',
        hostName: 'host.com',
      );

      final updated = original.copyWith(
        mailExchangeSettings: () => const DynDNSMailExchangeUIModel(
          hostName: 'mail.host.com',
          isBackup: true,
        ),
      );

      expect(updated.mailExchangeSettings, isNotNull);
      expect(updated.mailExchangeSettings!.hostName, 'mail.host.com');
      expect(updated.mailExchangeSettings!.isBackup, true);
    });

    test('toMap returns correct map', () {
      final provider = DynDNSProviderUIModel(
        username: 'user1',
        password: 'pass1',
        hostName: 'host1.com',
        isWildcardEnabled: true,
        mode: 'Static',
        isMailExchangeEnabled: false,
      );

      final map = provider.toMap();

      expect(map['name'], 'DynDNS');
      expect(map['username'], 'user1');
      expect(map['password'], 'pass1');
      expect(map['hostName'], 'host1.com');
      expect(map['isWildcardEnabled'], true);
      expect(map['mode'], 'Static');
    });

    test('fromMap creates instance from map', () {
      final map = {
        'name': 'DynDNS',
        'username': 'testuser',
        'password': 'testpass',
        'hostName': 'test.dyndns.org',
        'isWildcardEnabled': true,
        'mode': 'Custom',
        'isMailExchangeEnabled': false,
        'mailExchangeSettings': null,
      };

      final provider = DynDNSProviderUIModel.fromMap(map);

      expect(provider.username, 'testuser');
      expect(provider.password, 'testpass');
      expect(provider.hostName, 'test.dyndns.org');
      expect(provider.isWildcardEnabled, true);
      expect(provider.mode, 'Custom');
    });

    test('applySettings merges settings correctly', () {
      final existing = DynDNSProviderUIModel(
        username: 'old',
        password: 'oldpass',
        hostName: 'old.com',
      );

      final newSettings = DynDNSProviderUIModel(
        username: 'new',
        password: 'newpass',
        hostName: 'new.com',
      );

      final merged = existing.applySettings(newSettings);

      expect(merged, isA<DynDNSProviderUIModel>());
      expect((merged as DynDNSProviderUIModel).username, 'new');
      expect(merged.password, 'newpass');
      expect(merged.hostName, 'new.com');
    });
  });

  group('NoIPDNSProviderUIModel', () {
    test('has correct name constant', () {
      const provider = NoIPDNSProviderUIModel();
      expect(provider.name, 'No-IP');
    });

    test('copyWith returns new instance with updated values', () {
      const original = NoIPDNSProviderUIModel(
        username: 'original',
        password: 'pass1',
        hostName: 'host1.com',
      );

      final updated = original.copyWith(username: 'updated');

      expect(updated.username, 'updated');
      expect(updated.password, 'pass1'); // unchanged
      expect(updated.hostName, 'host1.com'); // unchanged
    });

    test('toMap returns correct map', () {
      const provider = NoIPDNSProviderUIModel(
        username: 'user1',
        password: 'pass1',
        hostName: 'host1.no-ip.org',
      );

      final map = provider.toMap();

      expect(map['name'], 'No-IP');
      expect(map['username'], 'user1');
      expect(map['password'], 'pass1');
      expect(map['hostName'], 'host1.no-ip.org');
    });

    test('fromMap creates instance from map', () {
      final map = {
        'name': 'No-IP',
        'username': 'testuser',
        'password': 'testpass',
        'hostName': 'test.no-ip.org',
      };

      final provider = NoIPDNSProviderUIModel.fromMap(map);

      expect(provider.username, 'testuser');
      expect(provider.password, 'testpass');
      expect(provider.hostName, 'test.no-ip.org');
    });
  });

  group('TzoDNSProviderUIModel', () {
    test('has correct name constant', () {
      const provider = TzoDNSProviderUIModel();
      expect(provider.name, 'TZO');
    });

    test('copyWith returns new instance with updated values', () {
      const original = TzoDNSProviderUIModel(
        username: 'original',
        password: 'pass1',
        hostName: 'host1.tzo.com',
      );

      final updated = original.copyWith(password: 'newpass');

      expect(updated.username, 'original'); // unchanged
      expect(updated.password, 'newpass');
      expect(updated.hostName, 'host1.tzo.com'); // unchanged
    });

    test('toMap returns correct map', () {
      const provider = TzoDNSProviderUIModel(
        username: 'user1',
        password: 'pass1',
        hostName: 'host1.tzo.com',
      );

      final map = provider.toMap();

      expect(map['name'], 'TZO');
      expect(map['username'], 'user1');
      expect(map['password'], 'pass1');
      expect(map['hostName'], 'host1.tzo.com');
    });
  });

  group('NoDDNSProviderUIModel', () {
    test('has correct name constant', () {
      const provider = NoDDNSProviderUIModel();
      expect(provider.name, noDNSProviderName);
    });

    test('toMap returns correct map', () {
      const provider = NoDDNSProviderUIModel();
      final map = provider.toMap();
      expect(map['name'], noDNSProviderName);
    });
  });

  group('DynDNSMailExchangeUIModel', () {
    test('copyWith returns new instance with updated values', () {
      const original = DynDNSMailExchangeUIModel(
        hostName: 'mail.host.com',
        isBackup: false,
      );

      final updated = original.copyWith(isBackup: true);

      expect(updated.hostName, 'mail.host.com'); // unchanged
      expect(updated.isBackup, true);
    });

    test('toMap returns correct map', () {
      const model = DynDNSMailExchangeUIModel(
        hostName: 'mail.example.com',
        isBackup: true,
      );

      final map = model.toMap();

      expect(map['hostName'], 'mail.example.com');
      expect(map['isBackup'], true);
    });

    test('fromMap creates instance from map', () {
      final map = {
        'hostName': 'test.mail.com',
        'isBackup': true,
      };

      final model = DynDNSMailExchangeUIModel.fromMap(map);

      expect(model.hostName, 'test.mail.com');
      expect(model.isBackup, true);
    });
  });

  group('DDNSSettingsUIModel', () {
    test('copyWith returns new instance with updated provider', () {
      const original = DDNSSettingsUIModel(
        provider: NoDDNSProviderUIModel(),
      );

      final updated = original.copyWith(
        provider: const NoIPDNSProviderUIModel(
          username: 'user',
          password: 'pass',
          hostName: 'host.com',
        ),
      );

      expect(updated.provider, isA<NoIPDNSProviderUIModel>());
    });

    test('toMap returns correct map', () {
      const settings = DDNSSettingsUIModel(
        provider: NoDDNSProviderUIModel(),
      );

      final map = settings.toMap();

      expect(map['provider'], isA<Map>());
    });

    test('fromMap creates instance from map', () {
      final map = {
        'provider': {
          'name': 'DynDNS',
          'username': 'user',
          'password': 'pass',
          'hostName': 'host.com',
          'isWildcardEnabled': false,
          'mode': 'Dynamic',
          'isMailExchangeEnabled': false,
          'mailExchangeSettings': null,
        },
      };

      final settings = DDNSSettingsUIModel.fromMap(map);

      expect(settings.provider, isA<DynDNSProviderUIModel>());
    });
  });

  group('DDNSStatusUIModel', () {
    test('copyWith returns new instance with updated values', () {
      const original = DDNSStatusUIModel(
        supportedProviders: ['', 'DynDNS'],
        status: 'Unknown',
        ipAddress: '192.168.1.1',
      );

      final updated = original.copyWith(
        status: 'Connected',
        ipAddress: '10.0.0.1',
      );

      expect(updated.supportedProviders, ['', 'DynDNS']); // unchanged
      expect(updated.status, 'Connected');
      expect(updated.ipAddress, '10.0.0.1');
    });

    test('toMap returns correct map', () {
      const status = DDNSStatusUIModel(
        supportedProviders: ['', 'DynDNS', 'No-IP'],
        status: 'Successful',
        ipAddress: '203.0.113.42',
      );

      final map = status.toMap();

      expect(map['supportedProviders'], ['', 'DynDNS', 'No-IP']);
      expect(map['status'], 'Successful');
      expect(map['ipAddress'], '203.0.113.42');
    });

    test('fromMap creates instance from map', () {
      final map = {
        'supportedProviders': ['', 'DynDNS', 'TZO'],
        'status': 'Failed',
        'ipAddress': '192.0.2.1',
      };

      final status = DDNSStatusUIModel.fromMap(map);

      expect(status.supportedProviders, ['', 'DynDNS', 'TZO']);
      expect(status.status, 'Failed');
      expect(status.ipAddress, '192.0.2.1');
    });
  });
}
