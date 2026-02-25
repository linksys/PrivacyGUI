import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/dhcp_reservation_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_provider.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/providers/local_network_settings_state.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/services/local_network_settings_service.dart';

class MockLocalNetworkSettingsService extends Mock
    implements LocalNetworkSettingsService {}

class MockRef extends Mock implements Ref {}

void main() {
  late ProviderContainer container;
  late MockLocalNetworkSettingsService mockService;

  setUpAll(() {
    registerFallbackValue(MockRef());
    registerFallbackValue(<DHCPReservationUIModel>[]);
  });

  setUp(() {
    mockService = MockLocalNetworkSettingsService();
    container = ProviderContainer(
      overrides: [
        localNetworkSettingsServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('LocalNetworkSettingsNotifier', () {
    group('build', () {
      test('returns initial state with empty values', () {
        final state = container.read(localNetworkSettingProvider);

        // LocalNetworkSettings.init() uses empty strings and defaults
        expect(state.settings.current.ipAddress, '');
        expect(state.settings.current.subnetMask, '');
        expect(state.settings.current.isDHCPEnabled, false);
        expect(state.status.errorTextMap, isEmpty);
      });

      test('settings original equals current initially', () {
        final state = container.read(localNetworkSettingProvider);

        expect(state.settings.original, state.settings.current);
      });
    });

    group('updateSettings', () {
      test('updates current settings', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        final newSettings =
            LocalNetworkSettings.init().copyWith(ipAddress: '10.0.0.1');

        notifier.updateSettings(newSettings);
        final state = container.read(localNetworkSettingProvider);

        expect(state.settings.current.ipAddress, '10.0.0.1');
        // Original stays at init value (empty)
        expect(state.settings.original.ipAddress, '');
      });
    });

    group('updateHostName', () {
      test('updates hostName in settings', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateHostName('MyRouter');
        final state = container.read(localNetworkSettingProvider);

        expect(state.settings.current.hostName, 'MyRouter');
      });

      test('sets hostName error when empty', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateHostName('');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
            LocalNetworkErrorPrompt.hostName.name);
      });

      test('sets hostNameLengthError when exceeds 15 characters', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateHostName('ThisIsAVeryLongHostName');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
            LocalNetworkErrorPrompt.hostNameLengthError.name);
      });

      test('sets hostNameStartWithHyphen when starts with hyphen', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateHostName('-MyRouter');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
            LocalNetworkErrorPrompt.hostNameStartWithHyphen.name);
      });

      test('sets hostNameEndWithHyphen when ends with hyphen', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateHostName('MyRouter-');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
            LocalNetworkErrorPrompt.hostNameEndWithHyphen.name);
      });

      test('sets hostNameInvalidCharacters and tracks invalid chars', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateHostName('My@Router#1');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
            LocalNetworkErrorPrompt.hostNameInvalidCharacters.name);
        expect(state.status.hostNameInvalidChars, isNotNull);
        expect(state.status.hostNameInvalidChars, contains('#'));
        expect(state.status.hostNameInvalidChars, contains('@'));
      });

      test('clears error and invalidChars for valid hostName', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateHostName('My@Invalid');
        notifier.updateHostName('ValidHost');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.errorTextMap[LocalNetworkErrorPrompt.hostName.name],
            isNull);
        expect(state.status.hostNameInvalidChars, isNull);
      });
    });

    group('updateErrorPrompts', () {
      test('adds error to map', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateErrorPrompts('testKey', 'testError');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.errorTextMap['testKey'], 'testError');
      });

      test('removes error when value is null', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateErrorPrompts('testKey', 'testError');
        notifier.updateErrorPrompts('testKey', null);
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.errorTextMap.containsKey('testKey'), false);
      });
    });

    group('updateHasErrorOnTabs', () {
      test('sets hasErrorOnHostNameTab when hostName error exists', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateErrorPrompts(
            LocalNetworkErrorPrompt.hostName.name, 'error');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.hasErrorOnHostNameTab, true);
        expect(state.status.hasErrorOnIPAddressTab, false);
        expect(state.status.hasErrorOnDhcpServerTab, false);
      });

      test('sets hasErrorOnIPAddressTab when IP error exists', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateErrorPrompts(
            LocalNetworkErrorPrompt.ipAddress.name, 'error');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.hasErrorOnHostNameTab, false);
        expect(state.status.hasErrorOnIPAddressTab, true);
        expect(state.status.hasErrorOnDhcpServerTab, false);
      });

      test('sets hasErrorOnDhcpServerTab when DHCP error exists', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);

        notifier.updateErrorPrompts(LocalNetworkErrorPrompt.dns1.name, 'error');
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.hasErrorOnHostNameTab, false);
        expect(state.status.hasErrorOnIPAddressTab, false);
        expect(state.status.hasErrorOnDhcpServerTab, true);
      });
    });

    group('updateDHCPReservationList', () {
      test('adds non-overlapping reservations', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const newReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );

        notifier.updateDHCPReservationList([newReservation]);
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.dhcpReservationList, hasLength(1));
      });

      test('filters overlapping MAC addresses', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const existingReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        notifier.updateDHCPReservationList([existingReservation]);

        const duplicateReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.200',
          description: 'Device2',
        );
        notifier.updateDHCPReservationList([duplicateReservation]);
        final state = container.read(localNetworkSettingProvider);

        expect(state.status.dhcpReservationList, hasLength(1));
      });
    });

    group('updateDHCPReservationOfIndex', () {
      test('updates reservation at index', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const existingReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        notifier.updateDHCPReservationList([existingReservation]);

        const updatedReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Updated Device',
        );
        final result =
            notifier.updateDHCPReservationOfIndex(updatedReservation, 0);
        final state = container.read(localNetworkSettingProvider);

        expect(result, true);
        expect(state.status.dhcpReservationList.first.description,
            'Updated Device');
      });

      test('deletes reservation when ipAddress is DELETE', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const existingReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        notifier.updateDHCPReservationList([existingReservation]);

        const deleteReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: 'DELETE',
          description: 'Device1',
        );
        final result =
            notifier.updateDHCPReservationOfIndex(deleteReservation, 0);
        final state = container.read(localNetworkSettingProvider);

        expect(result, true);
        expect(state.status.dhcpReservationList, isEmpty);
      });

      test('returns false when update would cause overlap', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const reservation1 = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        const reservation2 = DHCPReservationUIModel(
          macAddress: '11:22:33:44:55:66',
          ipAddress: '192.168.1.101',
          description: 'Device2',
        );
        notifier.updateDHCPReservationList([reservation1, reservation2]);

        const overlapReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Overlap',
        );
        final result =
            notifier.updateDHCPReservationOfIndex(overlapReservation, 1);

        expect(result, false);
      });
    });

    group('isReservationOverlap', () {
      test('returns true for overlapping IP', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const existingReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        notifier.updateDHCPReservationList([existingReservation]);

        const checkItem = DHCPReservationUIModel(
          macAddress: '11:22:33:44:55:66',
          ipAddress: '192.168.1.100',
          description: 'New',
        );

        expect(notifier.isReservationOverlap(item: checkItem), true);
      });

      test('returns true for overlapping MAC', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const existingReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        notifier.updateDHCPReservationList([existingReservation]);

        const checkItem = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.200',
          description: 'New',
        );

        expect(notifier.isReservationOverlap(item: checkItem), true);
      });

      test('returns false when no overlap', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const existingReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        notifier.updateDHCPReservationList([existingReservation]);

        const checkItem = DHCPReservationUIModel(
          macAddress: '11:22:33:44:55:66',
          ipAddress: '192.168.1.200',
          description: 'New',
        );

        expect(notifier.isReservationOverlap(item: checkItem), false);
      });

      test('ignores self when editing with index', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        const existingReservation = DHCPReservationUIModel(
          macAddress: 'AA:BB:CC:DD:EE:FF',
          ipAddress: '192.168.1.100',
          description: 'Device1',
        );
        notifier.updateDHCPReservationList([existingReservation]);

        expect(
            notifier.isReservationOverlap(item: existingReservation, index: 0),
            false);
      });
    });

    group('preservable functionality', () {
      test('preservable contract accessor returns notifier', () {
        final preservable =
            container.read(preservableLocalNetworkSettingsProvider)
                as LocalNetworkSettingsNotifier;

        expect(preservable, isNotNull);
        expect(preservable, isA<LocalNetworkSettingsNotifier>());
      });

      test('preservable stores original values for reset', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        final newSettings =
            LocalNetworkSettings.init().copyWith(ipAddress: '10.0.0.1');

        notifier.updateSettings(newSettings);
        final state = container.read(localNetworkSettingProvider);

        expect(state.settings.current.ipAddress, '10.0.0.1');
        expect(state.settings.original.ipAddress, '');
      });
    });

    group('isDirty tracking', () {
      test('isDirty is true when current differs from original', () {
        final notifier = container.read(localNetworkSettingProvider.notifier);
        final newSettings =
            LocalNetworkSettings.init().copyWith(hostName: 'Changed');

        notifier.updateSettings(newSettings);
        final state = container.read(localNetworkSettingProvider);

        expect(state.isDirty, true);
      });

      test('isDirty is false when current equals original', () {
        final state = container.read(localNetworkSettingProvider);

        expect(state.isDirty, false);
      });
    });
  });
}
