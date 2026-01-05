import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/jnap/services/wan_external_service.dart';

import '../../../mocks/test_data/wan_external_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late WanExternalService service;
  late MockRouterRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getWANExternal);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = WanExternalService(mockRepository);
  });

  group('WanExternalService - fetchWanExternal', () {
    test('returns WanExternalUIModel from JNAP response', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenAnswer(
              (_) async => WanExternalTestData.createWanExternalResponse());

      // Act
      final result = await service.fetchWanExternal();

      // Assert
      expect(result, isA<WanExternalUIModel>());
      expect(result.publicWanIPv4, '203.0.113.1');
      expect(result.publicWanIPv6, '2001:db8::1');
      expect(result.privateWanIPv4, '192.168.1.1');
      expect(result.privateWanIPv6, 'fe80::1');
    });

    test('passes force=false by default', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenAnswer(
              (_) async => WanExternalTestData.createWanExternalResponse());

      // Act
      await service.fetchWanExternal();

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.getWANExternal,
            fetchRemote: false,
            timeoutMs: 30000,
          )).called(1);
    });

    test('passes force=true when specified', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenAnswer(
              (_) async => WanExternalTestData.createWanExternalResponse());

      // Act
      await service.fetchWanExternal(force: true);

      // Assert
      verify(() => mockRepository.send(
            JNAPAction.getWANExternal,
            fetchRemote: true,
            timeoutMs: 30000,
          )).called(1);
    });

    test('handles IPv4 only response', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenAnswer(
              (_) async => WanExternalTestData.createIpv4OnlyResponse());

      // Act
      final result = await service.fetchWanExternal();

      // Assert
      expect(result.publicWanIPv4, '203.0.113.1');
      expect(result.publicWanIPv6, isNull);
      expect(result.privateWanIPv4, '192.168.1.1');
      expect(result.privateWanIPv6, isNull);
    });

    test('handles empty response', () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            timeoutMs: any(named: 'timeoutMs'),
          )).thenAnswer((_) async => WanExternalTestData.createEmptyResponse());

      // Act
      final result = await service.fetchWanExternal();

      // Assert
      expect(result.publicWanIPv4, isNull);
      expect(result.publicWanIPv6, isNull);
      expect(result.privateWanIPv4, isNull);
      expect(result.privateWanIPv6, isNull);
    });

    test('throws UnauthorizedError on auth failure', () async {
      // Arrange
      when(() => mockRepository.send(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            timeoutMs: any(named: 'timeoutMs'),
          )).thenThrow(WanExternalTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.fetchWanExternal(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws UnexpectedError on generic JNAP error', () async {
      // Arrange
      when(() => mockRepository.send(
                any(),
                fetchRemote: any(named: 'fetchRemote'),
                timeoutMs: any(named: 'timeoutMs'),
              ))
          .thenThrow(WanExternalTestData.createUnexpectedError('ErrorUnknown'));

      // Act & Assert
      expect(
        () => service.fetchWanExternal(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
