import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/models/static_route_entry_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/services/static_routing_service.dart';
import '../../../../mocks/test_data/static_routing_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late StaticRoutingService service;
  late MockRouterRepository mockRepo;

  setUpAll(() {
    // Register fallback value for JNAPAction
    registerFallbackValue(JNAPAction.getRoutingSettings);
  });

  setUp(() {
    mockRepo = MockRouterRepository();
    service = StaticRoutingService(mockRepo);

    // Default fallback for unhandled JNAP calls
    when(
      () => mockRepo.send(
        any(),
        auth: any(named: 'auth'),
        fetchRemote: any(named: 'fetchRemote'),
      ),
    ).thenThrow(Exception('Unhandled JNAP call'));
  });

  group('StaticRoutingService - fetchRoutingSettings', () {
    test('returns UI model on successful response transformation', () async {
      // Arrange
      final testData = StaticRoutingTestData.createSuccessfulResponse(
        isNATEnabled: true,
        entries: [
          StaticRoutingTestData.createRouteEntry(name: 'Route 1'),
        ],
      );
      final testLANSettings = StaticRoutingTestData.createLANSettingsResponse();

      when(() => mockRepo.send(
            JNAPAction.getRoutingSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => JNAPSuccess(
            result: 'ok',
            output: testData.toMap(),
          ));

      when(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => JNAPSuccess(
            result: 'ok',
            output: testLANSettings.toMap(),
          ));

      // Act
      final (settings, status) = await service.fetchRoutingSettings(
        forceRemote: false,
      );

      // Assert
      expect(settings, isNotNull);
      expect(status, isNotNull);
      expect(settings?.isNATEnabled, true);
      expect(settings?.entries.length, 1);
      expect(status?.routerIp, '192.168.1.1');
      expect(status?.maxStaticRouteEntries, 10);
    });

    test('extracts LAN settings context correctly', () async {
      // Arrange
      final testData = StaticRoutingTestData.createSuccessfulResponse();
      final testLANSettings = StaticRoutingTestData.createLANSettingsResponse(
        ipAddress: '10.0.0.1',
        networkPrefixLength: 25,
      );

      when(() => mockRepo.send(
            JNAPAction.getRoutingSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => JNAPSuccess(
            result: 'ok',
            output: testData.toMap(),
          ));

      when(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => JNAPSuccess(
            result: 'ok',
            output: testLANSettings.toMap(),
          ));

      // Act
      final (settings, status) = await service.fetchRoutingSettings(
        forceRemote: false,
      );

      // Assert
      expect(status?.routerIp, '10.0.0.1');
      expect(status?.subnetMask, isNotNull);
    });

    test('returns (null, null) on JNAP error or malformed response', () async {
      // Arrange
      when(() => mockRepo.send(
            any(),
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenThrow(Exception('Network error'));

      // Act
      final (settings, status) = await service.fetchRoutingSettings(
        forceRemote: false,
      );

      // Assert
      expect(settings, isNull);
      expect(status, isNull);
    });

    test('handles multiple route entries in transformation', () async {
      // Arrange
      final testData = StaticRoutingTestData.createWithRoutes(3);
      final testLANSettings = StaticRoutingTestData.createLANSettingsResponse();

      when(() => mockRepo.send(
            JNAPAction.getRoutingSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => JNAPSuccess(
            result: 'ok',
            output: testData.toMap(),
          ));

      when(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => JNAPSuccess(
            result: 'ok',
            output: testLANSettings.toMap(),
          ));

      // Act
      final (settings, _) = await service.fetchRoutingSettings();

      // Assert
      expect(settings?.entries.length, 3);
    });
  });

  group('StaticRoutingService - Route Validation', () {
    test('validates correct route entry', () {
      // Arrange
      final validEntry = StaticRouteEntryUIModel(
        name: 'Valid Route',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final errors = service.validateRouteEntry(validEntry);

      // Assert
      expect(errors, isEmpty);
    });

    test('rejects empty route name', () {
      // Arrange
      final invalidEntry = StaticRouteEntryUIModel(
        name: '',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final errors = service.validateRouteEntry(invalidEntry);

      // Assert
      expect(errors.containsKey('name'), true);
      expect(errors['name'], contains('empty'));
    });

    test('rejects route name exceeding 32 characters', () {
      // Arrange
      final invalidEntry = StaticRouteEntryUIModel(
        name:
            'This is a very long route name that exceeds thirty two characters',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final errors = service.validateRouteEntry(invalidEntry);

      // Assert
      expect(errors.containsKey('name'), true);
      expect(errors['name'], contains('32'));
    });

    test('rejects invalid destination IP format', () {
      // Arrange
      final invalidEntry = StaticRouteEntryUIModel(
        name: 'Test Route',
        destinationIP: '256.256.256.256',
        subnetMask: '255.255.255.0',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final errors = service.validateRouteEntry(invalidEntry);

      // Assert
      expect(errors.containsKey('destinationIP'), true);
    });

    test('rejects invalid subnet mask format', () {
      // Arrange
      final invalidEntry = StaticRouteEntryUIModel(
        name: 'Test Route',
        destinationIP: '10.0.0.0',
        subnetMask: '999.999.999.999',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final errors = service.validateRouteEntry(invalidEntry);

      // Assert
      expect(errors.containsKey('subnetMask'), true);
    });

    test('rejects invalid gateway IP format', () {
      // Arrange
      final invalidEntry = StaticRouteEntryUIModel(
        name: 'Test Route',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '999.999.999.999',
        interface: 'LAN',
      );

      // Act
      final errors = service.validateRouteEntry(invalidEntry);

      // Assert
      expect(errors.containsKey('gateway'), true);
    });

    test('accepts empty gateway address', () {
      // Arrange
      final validEntry = StaticRouteEntryUIModel(
        name: 'Test Route',
        destinationIP: '10.0.0.0',
        subnetMask: '255.255.255.0',
        gateway: '',
        interface: 'LAN',
      );

      // Act
      final errors = service.validateRouteEntry(validEntry);

      // Assert
      expect(errors.containsKey('gateway'), false);
    });

    test('accepts CIDR prefix as subnet mask', () {
      // Arrange
      final validEntry = StaticRouteEntryUIModel(
        name: 'Test Route',
        destinationIP: '10.0.0.0',
        subnetMask: '24',
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final errors = service.validateRouteEntry(validEntry);

      // Assert
      expect(errors.containsKey('subnetMask'), false);
    });
  });

  group('StaticRoutingService - UI Model Transformation', () {
    test('transforms JNAP route entry to UI model correctly', () async {
      // Arrange
      final testData = StaticRoutingTestData.createSuccessfulResponse(
        entries: [
          StaticRoutingTestData.createRouteEntry(
            name: 'Test Route',
            destinationLAN: '10.1.0.0',
            gateway: '192.168.1.254',
            networkPrefixLength: 24,
          ),
        ],
      );
      final testLANSettings = StaticRoutingTestData.createLANSettingsResponse();

      when(() => mockRepo.send(
            JNAPAction.getRoutingSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => JNAPSuccess(
            result: 'ok',
            output: testData.toMap(),
          ));

      when(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => JNAPSuccess(
            result: 'ok',
            output: testLANSettings.toMap(),
          ));

      // Act
      final (settings, _) = await service.fetchRoutingSettings();

      // Assert
      expect(settings?.entries.length, 1);
      final entry = settings!.entries.first;
      expect(entry.name, 'Test Route');
      expect(entry.destinationIP, '10.1.0.0');
      expect(entry.gateway, '192.168.1.254');
    });
  });

  group('StaticRoutingService - Rule Transformations', () {
    test('transformJNAPRuleToUIModel converts JNAP entry to UI model', () {
      // Arrange
      final jnapEntry = StaticRoutingTestData.createRouteEntry(
        name: 'Test Route',
        destinationLAN: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final uiModel = service.transformJNAPRuleToUIModel(jnapEntry);

      // Assert
      expect(uiModel.name, 'Test Route');
      expect(uiModel.destinationIP, '10.0.0.0');
      expect(uiModel.networkPrefixLength, 24);
      expect(uiModel.gateway, '192.168.1.1');
      expect(uiModel.interface, 'LAN');
    });

    test('transformJNAPRuleToUIModel handles null gateway', () {
      // Arrange
      final jnapEntry = StaticRoutingTestData.createRouteEntry(
        name: 'Test Route',
        destinationLAN: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: null,
        interface: 'LAN',
      );

      // Act
      final uiModel = service.transformJNAPRuleToUIModel(jnapEntry);

      // Assert
      expect(uiModel.gateway, isNull);
    });

    test('transformUIModelToJNAPRule converts UI model to JNAP entry', () {
      // Arrange
      final uiModel = StaticRoutingTestData.createUIRuleModel(
        name: 'Test Route',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act
      final jnapEntry = service.transformUIModelToJNAPRule(uiModel);

      // Assert
      expect(jnapEntry.name, 'Test Route');
      expect(jnapEntry.settings.destinationLAN, '10.0.0.0');
      expect(jnapEntry.settings.networkPrefixLength, 24);
      expect(jnapEntry.settings.gateway, '192.168.1.1');
      expect(jnapEntry.settings.interface, 'LAN');
    });

    test('transformUIModelToJNAPRule handles empty gateway', () {
      // Arrange
      final uiModel = StaticRoutingTestData.createUIRuleModel(
        name: 'Test Route',
        destinationIP: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '',
        interface: 'LAN',
      );

      // Act
      final jnapEntry = service.transformUIModelToJNAPRule(uiModel);

      // Assert
      expect(jnapEntry.settings.gateway, isNull);
    });

    test('transformUIModelToJNAPRule round-trip preserves data', () {
      // Arrange
      final originalJnapEntry = StaticRoutingTestData.createRouteEntry(
        name: 'Test Route',
        destinationLAN: '10.0.0.0',
        networkPrefixLength: 24,
        gateway: '192.168.1.1',
        interface: 'LAN',
      );

      // Act - JNAP to UI
      final uiModel = service.transformJNAPRuleToUIModel(originalJnapEntry);

      // Act - UI to JNAP
      final restoredJnapEntry = service.transformUIModelToJNAPRule(uiModel);

      // Assert
      expect(restoredJnapEntry.name, originalJnapEntry.name);
      expect(restoredJnapEntry.settings.destinationLAN,
          originalJnapEntry.settings.destinationLAN);
      expect(restoredJnapEntry.settings.networkPrefixLength,
          originalJnapEntry.settings.networkPrefixLength);
      expect(restoredJnapEntry.settings.gateway,
          originalJnapEntry.settings.gateway);
      expect(restoredJnapEntry.settings.interface,
          originalJnapEntry.settings.interface);
    });
  });
}
