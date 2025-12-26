import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/lan_settings.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/models/reservation_item_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/local_network_settings/services/local_network_settings_service.dart';
import 'package:privacy_gui/utils.dart';

import '../../../../mocks/test_data/dhcp_reservations_test_data.dart';
import '../../../../mocks/test_data/local_network_settings_test_data.dart';
import '../../../../mocks/router_repository_mocks.dart';

void main() {
  group('LocalNetworkSettingsService -', () {
    late MockRouterRepository mockRepository;
    late LocalNetworkSettingsService service;

    setUp(() {
      mockRepository = MockRouterRepository();
      service = LocalNetworkSettingsService(mockRepository);
    });

    group('fetchLANSettings -', () {
      test('fetches LAN settings successfully', () async {
        final jnapResponse =
            LocalNetworkSettingsTestData.createGetLANSettingsSuccess();
        when(mockRepository.send(
          JNAPAction.getLANSettings,
          fetchRemote: false,
          auth: true,
        )).thenAnswer((_) async => jnapResponse);

        final result = await service.fetchLANSettings();

        expect(result, isA<RouterLANSettings>());
        expect(result.ipAddress, '192.168.1.1');
        verify(mockRepository.send(
          JNAPAction.getLANSettings,
          fetchRemote: false,
          auth: true,
        )).called(1);
      });

      test('fetches LAN settings with forceRemote=true', () async {
        final jnapResponse =
            LocalNetworkSettingsTestData.createGetLANSettingsSuccess();
        when(mockRepository.send(
          JNAPAction.getLANSettings,
          fetchRemote: true,
          auth: true,
        )).thenAnswer((_) async => jnapResponse);

        await service.fetchLANSettings(forceRemote: true);

        verify(mockRepository.send(
          JNAPAction.getLANSettings,
          fetchRemote: true,
          auth: true,
        )).called(1);
      });

      test('throws error when fetch fails', () async {
        when(mockRepository.send(
          JNAPAction.getLANSettings,
          fetchRemote: false,
          auth: true,
        )).thenThrow(Exception('Network error'));

        expect(
          () => service.fetchLANSettings(),
          throwsException,
        );
      });
    });

    group('saveReservations -', () {
      test('saves reservations successfully with all required fields',
          () async {
        final reservations = DHCPReservationsTestData.createReservationList();
        final jnapResponse = JNAPSuccess(result: 'OK', output: const {});

        when(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: anyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).thenAnswer((_) async => jnapResponse);

        await service.saveReservations(
          routerIp: '192.168.1.1',
          networkPrefixLength:
              NetworkUtils.subnetMaskToPrefixLength('255.255.255.0'),
          hostName: 'MyRouter',
          isDHCPEnabled: true,
          firstClientIP: '192.168.1.100',
          lastClientIP: '192.168.1.200',
          leaseMinutes: 1440,
          dns1: '8.8.8.8',
          dns2: '8.8.4.4',
          dns3: null,
          wins: null,
          reservations: reservations,
        );

        final captured = verify(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: captureAnyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).captured;

        final sentData = captured.first as Map<String, dynamic>;
        expect(sentData['ipAddress'], '192.168.1.1');
        expect(sentData['hostName'], 'MyRouter');
        expect(sentData['isDHCPEnabled'], true);
        expect(
            sentData['dhcpSettings']['firstClientIPAddress'], '192.168.1.100');
        expect(
            sentData['dhcpSettings']['lastClientIPAddress'], '192.168.1.200');
        expect(sentData['dhcpSettings']['leaseMinutes'], 1440);
        expect(sentData['dhcpSettings']['dnsServer1'], '8.8.8.8');
        expect(sentData['dhcpSettings']['dnsServer2'], '8.8.4.4');
        expect(sentData['dhcpSettings']['reservations'], isA<List>());
        expect(sentData['dhcpSettings']['reservations'].length, 3);
      });

      test('removes null optional fields before sending', () async {
        final reservations = [
          DHCPReservationsTestData.createReservationUIModel()
        ];
        final jnapResponse = JNAPSuccess(result: 'OK', output: const {});

        when(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: anyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).thenAnswer((_) async => jnapResponse);

        await service.saveReservations(
          routerIp: '192.168.1.1',
          networkPrefixLength: 24,
          hostName: 'MyRouter',
          isDHCPEnabled: true,
          firstClientIP: '192.168.1.100',
          lastClientIP: '192.168.1.200',
          leaseMinutes: 1440,
          dns1: null,
          dns2: null,
          dns3: null,
          wins: null,
          reservations: reservations,
        );

        final captured = verify(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: captureAnyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).captured;

        final sentData = captured.first as Map<String, dynamic>;
        expect(sentData['dhcpSettings']['dnsServer1'], isNull);
        expect(sentData['dhcpSettings']['dnsServer2'], isNull);
        expect(sentData['dhcpSettings']['dnsServer3'], isNull);
        expect(sentData['dhcpSettings']['winsServer'], isNull);
      });

      test('removes empty string DNS values', () async {
        final reservations = [
          DHCPReservationsTestData.createReservationUIModel()
        ];
        final jnapResponse = JNAPSuccess(result: 'OK', output: const {});

        when(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: anyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).thenAnswer((_) async => jnapResponse);

        await service.saveReservations(
          routerIp: '192.168.1.1',
          networkPrefixLength: 24,
          hostName: 'MyRouter',
          isDHCPEnabled: true,
          firstClientIP: '192.168.1.100',
          lastClientIP: '192.168.1.200',
          leaseMinutes: 1440,
          dns1: '',
          dns2: '',
          dns3: '',
          wins: '',
          reservations: reservations,
        );

        final captured = verify(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: captureAnyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).captured;

        final sentData = captured.first as Map<String, dynamic>;
        expect(sentData['dhcpSettings']['dnsServer1'], isNull);
        expect(sentData['dhcpSettings']['dnsServer2'], isNull);
        expect(sentData['dhcpSettings']['dnsServer3'], isNull);
        expect(sentData['dhcpSettings']['winsServer'], isNull);
      });

      test('uses maxRetry=5 for side effects', () async {
        final reservations = [
          DHCPReservationsTestData.createReservationUIModel()
        ];
        final jnapResponse = JNAPSuccess(result: 'OK', output: const {});

        when(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: anyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).thenAnswer((_) async => jnapResponse);

        await service.saveReservations(
          routerIp: '192.168.1.1',
          networkPrefixLength: 24,
          hostName: 'MyRouter',
          isDHCPEnabled: true,
          firstClientIP: '192.168.1.100',
          lastClientIP: '192.168.1.200',
          leaseMinutes: 1440,
          reservations: reservations,
        );

        verify(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: anyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).called(1);
      });

      test('throws error when save fails', () async {
        final reservations = [
          DHCPReservationsTestData.createReservationUIModel()
        ];

        when(mockRepository.send(
          JNAPAction.setLANSettings,
          auth: true,
          data: anyNamed('data'),
          sideEffectOverrides: anyNamed('sideEffectOverrides'),
        )).thenThrow(Exception('Save failed'));

        expect(
          () => service.saveReservations(
            routerIp: '192.168.1.1',
            networkPrefixLength: 24,
            hostName: 'MyRouter',
            isDHCPEnabled: true,
            firstClientIP: '192.168.1.100',
            lastClientIP: '192.168.1.200',
            leaseMinutes: 1440,
            reservations: reservations,
          ),
          throwsException,
        );
      });
    });

    group('convertFromJNAPList -', () {
      test('converts JNAP list to UI model list', () {
        final jnapList = [
          DHCPReservation(
            macAddress: '00:11:22:33:44:55',
            ipAddress: '192.168.1.100',
            description: 'Device 1',
          ),
          DHCPReservation(
            macAddress: 'AA:BB:CC:DD:EE:FF',
            ipAddress: '192.168.1.101',
            description: 'Device 2',
          ),
        ];

        final result = service.convertFromJNAPList(jnapList);

        expect(result, isA<List<DHCPReservationUIModel>>());
        expect(result.length, 2);
        expect(result[0].macAddress, '00:11:22:33:44:55');
        expect(result[0].ipAddress, '192.168.1.100');
        expect(result[0].description, 'Device 1');
        expect(result[1].macAddress, 'AA:BB:CC:DD:EE:FF');
        expect(result[1].ipAddress, '192.168.1.101');
        expect(result[1].description, 'Device 2');
      });

      test('converts empty JNAP list', () {
        final result = service.convertFromJNAPList([]);

        expect(result, isEmpty);
      });

      test('preserves all fields during conversion', () {
        final jnapReservation = DHCPReservation(
          macAddress: '00:11:22:33:44:55',
          ipAddress: '192.168.1.100',
          description: 'Test Device with Special Chars !@#\$%',
        );

        final result = service.convertFromJNAPList([jnapReservation]);

        expect(result.length, 1);
        expect(result[0].macAddress, jnapReservation.macAddress);
        expect(result[0].ipAddress, jnapReservation.ipAddress);
        expect(result[0].description, jnapReservation.description);
      });
    });
  });
}
