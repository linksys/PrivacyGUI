import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ddns/providers/ddns_state.dart';
import 'package:privacy_gui/providers/preservable.dart';

void main() {
  group('DDNSState', () {
    test('provides current settings via getter', () {
      const settings = DDNSSettingsUIModel(
        provider: DynDNSProviderUIModel(
          username: 'testuser',
          password: 'testpass',
          hostName: 'test.dyndns.org',
          isWildcardEnabled: false,
          mode: 'Dynamic',
          isMailExchangeEnabled: false,
        ),
      );
      const status = DDNSStatusUIModel(
        supportedProviders: ['', 'DynDNS'],
        status: 'Connected',
        ipAddress: '192.168.1.1',
      );

      final state = DDNSState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      expect(state.current, settings);
      expect(state.current.provider, isA<DynDNSProviderUIModel>());
    });

    test('copyWith returns new instance with updated settings', () {
      const originalSettings = DDNSSettingsUIModel(
        provider: NoDDNSProviderUIModel(),
      );
      const originalStatus = DDNSStatusUIModel(
        supportedProviders: [''],
        status: '',
        ipAddress: '',
      );

      final originalState = DDNSState(
        settings: Preservable(
          original: originalSettings,
          current: originalSettings,
        ),
        status: originalStatus,
      );

      const newSettings = DDNSSettingsUIModel(
        provider: NoIPDNSProviderUIModel(
          username: 'user',
          password: 'pass',
          hostName: 'host.com',
        ),
      );

      final updatedState = originalState.copyWith(
        settings: Preservable(original: newSettings, current: newSettings),
      );

      expect(updatedState.current.provider, isA<NoIPDNSProviderUIModel>());
      expect(updatedState.status, originalStatus); // unchanged
    });

    test('copyWith returns new instance with updated status', () {
      const originalSettings = DDNSSettingsUIModel(
        provider: NoDDNSProviderUIModel(),
      );
      const originalStatus = DDNSStatusUIModel(
        supportedProviders: [''],
        status: 'Unknown',
        ipAddress: '192.168.1.1',
      );

      final originalState = DDNSState(
        settings: Preservable(
          original: originalSettings,
          current: originalSettings,
        ),
        status: originalStatus,
      );

      const newStatus = DDNSStatusUIModel(
        supportedProviders: ['', 'DynDNS', 'No-IP'],
        status: 'Connected',
        ipAddress: '10.0.0.1',
      );

      final updatedState = originalState.copyWith(status: newStatus);

      expect(updatedState.status.status, 'Connected');
      expect(updatedState.status.ipAddress, '10.0.0.1');
      expect(updatedState.current.provider,
          isA<NoDDNSProviderUIModel>()); // unchanged
    });

    test('toMap serializes state correctly', () {
      const settings = DDNSSettingsUIModel(
        provider: DynDNSProviderUIModel(
          username: 'user1',
          password: 'pass1',
          hostName: 'host1.com',
          isWildcardEnabled: false,
          mode: 'Dynamic',
          isMailExchangeEnabled: false,
        ),
      );
      const status = DDNSStatusUIModel(
        supportedProviders: ['', 'DynDNS'],
        status: 'Successful',
        ipAddress: '203.0.113.1',
      );

      final state = DDNSState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      final map = state.toMap();

      expect(map['settings'], isNotNull);
      expect(map['status'], isNotNull);
      expect(map['status']['status'], 'Successful');
    });

    test('fromMap deserializes state correctly', () {
      final map = {
        'settings': {
          'original': {
            'provider': {
              'name': 'No-IP',
              'username': 'testuser',
              'password': 'testpass',
              'hostName': 'test.no-ip.org',
            },
          },
          'current': {
            'provider': {
              'name': 'No-IP',
              'username': 'testuser',
              'password': 'testpass',
              'hostName': 'test.no-ip.org',
            },
          },
        },
        'status': {
          'supportedProviders': ['', 'No-IP', 'DynDNS'],
          'status': 'Connected',
          'ipAddress': '192.0.2.1',
        },
      };

      final state = DDNSState.fromMap(map);

      expect(state.current.provider, isA<NoIPDNSProviderUIModel>());
      expect(state.status.status, 'Connected');
      expect(state.status.ipAddress, '192.0.2.1');
    });

    test('toJson and fromJson round-trip correctly', () {
      const settings = DDNSSettingsUIModel(
        provider: TzoDNSProviderUIModel(
          username: 'tzouser',
          password: 'tzopass',
          hostName: 'test.tzo.com',
        ),
      );
      const status = DDNSStatusUIModel(
        supportedProviders: ['', 'TZO'],
        status: 'Failed',
        ipAddress: '10.10.10.10',
      );

      final originalState = DDNSState(
        settings: Preservable(original: settings, current: settings),
        status: status,
      );

      final json = originalState.toJson();
      final restoredState = DDNSState.fromJson(json);

      expect(restoredState.current.provider, isA<TzoDNSProviderUIModel>());
      expect(restoredState.status.status, 'Failed');
      expect(restoredState.status.ipAddress, '10.10.10.10');
    });

    test('preservable tracks dirty state', () {
      const originalSettings = DDNSSettingsUIModel(
        provider: NoDDNSProviderUIModel(),
      );
      const modifiedSettings = DDNSSettingsUIModel(
        provider: DynDNSProviderUIModel(
          username: 'new',
          password: 'settings',
          hostName: 'host.com',
          isWildcardEnabled: false,
          mode: 'Dynamic',
          isMailExchangeEnabled: false,
        ),
      );

      final preservable = Preservable(
        original: originalSettings,
        current: originalSettings,
      );

      expect(preservable.isDirty, false);

      final dirtyPreservable = preservable.copyWith(current: modifiedSettings);
      expect(dirtyPreservable.isDirty, true);
    });
  });
}
