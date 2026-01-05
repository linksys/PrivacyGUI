import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';

void main() {
  group('LocalNetworkSettings', () {
    test('creates instance with init factory', () {
      final settings = LocalNetworkSettings.init();
      expect(settings.hostName, '');
      expect(settings.ipAddress, '');
      expect(settings.isDHCPEnabled, false);
    });

    test('creates instance with custom values', () {
      const settings = LocalNetworkSettings(
        hostName: 'MyRouter',
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        isDHCPEnabled: true,
        firstIPAddress: '192.168.1.100',
        lastIPAddress: '192.168.1.200',
        maxUserAllowed: 100,
        clientLeaseTime: 1440,
        dns1: '8.8.8.8',
      );
      expect(settings.hostName, 'MyRouter');
      expect(settings.dns1, '8.8.8.8');
    });

    test('copyWith updates specified fields', () {
      const settings = LocalNetworkSettings(
        hostName: 'Router',
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        isDHCPEnabled: false,
        firstIPAddress: '',
        lastIPAddress: '',
        maxUserAllowed: 0,
        clientLeaseTime: 0,
      );
      final updated =
          settings.copyWith(hostName: 'NewName', isDHCPEnabled: true);
      expect(updated.hostName, 'NewName');
      expect(updated.isDHCPEnabled, true);
      expect(updated.ipAddress, '192.168.1.1');
    });

    test('toMap/fromMap serialization works', () {
      const original = LocalNetworkSettings(
        hostName: 'MyRouter',
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        isDHCPEnabled: true,
        firstIPAddress: '192.168.1.100',
        lastIPAddress: '192.168.1.200',
        maxUserAllowed: 100,
        clientLeaseTime: 1440,
        dns1: '8.8.8.8',
      );
      final map = original.toMap();
      final restored = LocalNetworkSettings.fromMap(map);
      expect(restored.hostName, 'MyRouter');
      expect(restored.dns1, '8.8.8.8');
    });

    test('toJson/fromJson serialization works', () {
      const original = LocalNetworkSettings(
        hostName: 'Router',
        ipAddress: '192.168.1.1',
        subnetMask: '255.255.255.0',
        isDHCPEnabled: false,
        firstIPAddress: '',
        lastIPAddress: '',
        maxUserAllowed: 0,
        clientLeaseTime: 0,
      );
      final json = original.toJson();
      final restored = LocalNetworkSettings.fromJson(json);
      expect(restored, original);
    });

    test('equality comparison works', () {
      const s1 = LocalNetworkSettings(
        hostName: 'R',
        ipAddress: '1',
        subnetMask: '2',
        isDHCPEnabled: false,
        firstIPAddress: '',
        lastIPAddress: '',
        maxUserAllowed: 0,
        clientLeaseTime: 0,
      );
      const s2 = LocalNetworkSettings(
        hostName: 'R',
        ipAddress: '1',
        subnetMask: '2',
        isDHCPEnabled: false,
        firstIPAddress: '',
        lastIPAddress: '',
        maxUserAllowed: 0,
        clientLeaseTime: 0,
      );
      expect(s1, s2);
    });
  });

  group('LocalNetworkStatus', () {
    test('creates with init factory', () {
      final status = LocalNetworkStatus.init();
      expect(status.maxUserLimit, 0);
      expect(status.minNetworkPrefixLength, 8);
      expect(status.maxNetworkPrefixLength, 30);
    });

    test('copyWith updates fields', () {
      final status = LocalNetworkStatus.init();
      final updated = status.copyWith(maxUserLimit: 254);
      expect(updated.maxUserLimit, 254);
    });

    test('toMap/fromMap serialization works', () {
      final original = LocalNetworkStatus.init().copyWith(maxUserLimit: 100);
      final map = original.toMap();
      final restored = LocalNetworkStatus.fromMap(map);
      expect(restored.maxUserLimit, 100);
    });
  });

  group('LocalNetworkSettingsState', () {
    test('creates with init factory', () {
      final state = LocalNetworkSettingsState.init();
      expect(state.settings.original.hostName, '');
      expect(state.status.maxUserLimit, 0);
    });

    test('copyWith updates fields', () {
      final state = LocalNetworkSettingsState.init();
      final newStatus = LocalNetworkStatus.init().copyWith(maxUserLimit: 200);
      final updated = state.copyWith(status: newStatus);
      expect(updated.status.maxUserLimit, 200);
    });

    test('toMap/fromMap serialization works', () {
      final original = LocalNetworkSettingsState.init();
      final map = original.toMap();
      final restored = LocalNetworkSettingsState.fromMap(map);
      expect(restored.settings.original.hostName, '');
    });

    test('toJson/fromJson serialization works', () {
      final original = LocalNetworkSettingsState.init();
      final json = original.toJson();
      final restored = LocalNetworkSettingsState.fromJson(json);
      expect(restored.status.maxUserLimit, 0);
    });
  });

  group('LocalNetworkErrorPrompt', () {
    test('resolve returns correct enum', () {
      expect(LocalNetworkErrorPrompt.resolve('hostName'),
          LocalNetworkErrorPrompt.hostName);
      expect(LocalNetworkErrorPrompt.resolve('ipAddress'),
          LocalNetworkErrorPrompt.ipAddress);
      expect(LocalNetworkErrorPrompt.resolve('unknown'), isNull);
    });
  });
}
