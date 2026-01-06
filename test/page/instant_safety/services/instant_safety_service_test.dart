import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_state.dart';
import 'package:privacy_gui/page/instant_safety/services/instant_safety_service.dart';
import '../../../mocks/test_data/instant_safety_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late InstantSafetyService service;
  late MockRouterRepository mockRouterRepository;

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    service = InstantSafetyService(mockRouterRepository);
  });

  setUpAll(() {
    registerFallbackValue(JNAPAction.getLANSettings);
  });

  group('InstantSafetyService - fetchSettings', () {
    test('returns fortinet type when Fortinet DNS configured', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async => InstantSafetyTestData.createLANSettingsWithFortinet(),
      );

      // Act
      final result = await service.fetchSettings(
        deviceInfo: null,
        forceRemote: true,
      );

      // Assert
      expect(result.safeBrowsingType, InstantSafetyType.fortinet);
      verify(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: true,
            auth: true,
          )).called(1);
    });

    test('returns openDNS type when OpenDNS configured', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async => InstantSafetyTestData.createLANSettingsWithOpenDNS(),
      );

      // Act
      final result = await service.fetchSettings(
        deviceInfo: null,
        forceRemote: false,
      );

      // Assert
      expect(result.safeBrowsingType, InstantSafetyType.openDNS);
    });

    test('returns off type when no safe browsing DNS configured', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async =>
            InstantSafetyTestData.createLANSettingsWithSafeBrowsingOff(),
      );

      // Act
      final result = await service.fetchSettings(
        deviceInfo: null,
        forceRemote: false,
      );

      // Assert
      expect(result.safeBrowsingType, InstantSafetyType.off);
    });

    test('throws ServiceError on JNAP failure', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenThrow(
        InstantSafetyTestData.createJNAPError(
          result: '_ErrorUnknown',
          error: 'Network error',
        ),
      );

      // Act & Assert
      expect(
        () => service.fetchSettings(deviceInfo: null, forceRemote: false),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('returns hasFortinet false when deviceInfo is null', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async => InstantSafetyTestData.createLANSettingsSuccess(),
      );

      // Act
      final result = await service.fetchSettings(
        deviceInfo: null,
        forceRemote: false,
      );

      // Assert
      expect(result.hasFortinet, false);
    });

    test('returns hasFortinet false for incompatible device', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async => InstantSafetyTestData.createLANSettingsSuccess(),
      );

      // Act - Using a device that's not in the compatibility map
      final result = await service.fetchSettings(
        deviceInfo: InstantSafetyTestData.createDeviceInfo(
          modelNumber: 'UnsupportedModel',
        ),
        forceRemote: false,
      );

      // Assert - Since compatibility map is empty, all devices return false
      expect(result.hasFortinet, false);
    });
  });

  group('InstantSafetyService - saveSettings', () {
    test('with fortinet constructs Fortinet DNS payload', () async {
      // Arrange - First fetch to cache LAN settings
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async => InstantSafetyTestData.createLANSettingsSuccess(),
      );

      when(() => mockRouterRepository.send(
                JNAPAction.setLANSettings,
                auth: any(named: 'auth'),
                cacheLevel: any(named: 'cacheLevel'),
                data: any(named: 'data'),
              ))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      // Fetch first to cache settings
      await service.fetchSettings(deviceInfo: null, forceRemote: false);

      // Act
      await service.saveSettings(InstantSafetyType.fortinet);

      // Assert
      final captured = verify(() => mockRouterRepository.send(
            JNAPAction.setLANSettings,
            auth: true,
            cacheLevel: any(named: 'cacheLevel'),
            data: captureAny(named: 'data'),
          )).captured;

      final data = captured.first as Map<String, dynamic>;
      final dhcpSettings = data['dhcpSettings'] as Map<String, dynamic>;
      expect(dhcpSettings['dnsServer1'], '208.91.114.155');
    });

    test('with openDNS constructs OpenDNS payload', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async => InstantSafetyTestData.createLANSettingsSuccess(),
      );

      when(() => mockRouterRepository.send(
                JNAPAction.setLANSettings,
                auth: any(named: 'auth'),
                cacheLevel: any(named: 'cacheLevel'),
                data: any(named: 'data'),
              ))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      await service.fetchSettings(deviceInfo: null, forceRemote: false);

      // Act
      await service.saveSettings(InstantSafetyType.openDNS);

      // Assert
      final captured = verify(() => mockRouterRepository.send(
            JNAPAction.setLANSettings,
            auth: true,
            cacheLevel: any(named: 'cacheLevel'),
            data: captureAny(named: 'data'),
          )).captured;

      final data = captured.first as Map<String, dynamic>;
      final dhcpSettings = data['dhcpSettings'] as Map<String, dynamic>;
      expect(dhcpSettings['dnsServer1'], '208.67.222.123');
      expect(dhcpSettings['dnsServer2'], '208.67.220.123');
    });

    test('with off clears DNS servers', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async => InstantSafetyTestData.createLANSettingsWithOpenDNS(),
      );

      when(() => mockRouterRepository.send(
                JNAPAction.setLANSettings,
                auth: any(named: 'auth'),
                cacheLevel: any(named: 'cacheLevel'),
                data: any(named: 'data'),
              ))
          .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {}));

      await service.fetchSettings(deviceInfo: null, forceRemote: false);

      // Act
      await service.saveSettings(InstantSafetyType.off);

      // Assert
      final captured = verify(() => mockRouterRepository.send(
            JNAPAction.setLANSettings,
            auth: true,
            cacheLevel: any(named: 'cacheLevel'),
            data: captureAny(named: 'data'),
          )).captured;

      final data = captured.first as Map<String, dynamic>;
      final dhcpSettings = data['dhcpSettings'] as Map<String, dynamic>;
      // DNS servers should not be present when off
      expect(dhcpSettings.containsKey('dnsServer1'), false);
      expect(dhcpSettings.containsKey('dnsServer2'), false);
      expect(dhcpSettings.containsKey('dnsServer3'), false);
    });

    test('throws InvalidInputError when LAN settings not cached', () async {
      // Act & Assert - Don't call fetchSettings first
      expect(
        () => service.saveSettings(InstantSafetyType.openDNS),
        throwsA(isA<InvalidInputError>()),
      );
    });

    test('throws ServiceError on JNAP failure', () async {
      // Arrange
      when(() => mockRouterRepository.send(
            JNAPAction.getLANSettings,
            fetchRemote: any(named: 'fetchRemote'),
            auth: any(named: 'auth'),
          )).thenAnswer(
        (_) async => InstantSafetyTestData.createLANSettingsSuccess(),
      );

      when(() => mockRouterRepository.send(
            JNAPAction.setLANSettings,
            auth: any(named: 'auth'),
            cacheLevel: any(named: 'cacheLevel'),
            data: any(named: 'data'),
          )).thenThrow(
        InstantSafetyTestData.createJNAPError(
          result: '_ErrorUnknown',
          error: 'Save failed',
        ),
      );

      await service.fetchSettings(deviceInfo: null, forceRemote: false);

      // Act & Assert
      expect(
        () => service.saveSettings(InstantSafetyType.openDNS),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
