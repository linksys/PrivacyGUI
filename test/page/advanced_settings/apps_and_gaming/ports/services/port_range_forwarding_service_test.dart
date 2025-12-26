import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/port_range_forwarding_service.dart';

import '../../../../../mocks/test_data/port_range_forwarding_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late PortRangeForwardingService service;
  late MockRouterRepository mockRepo;

  setUp(() {
    mockRepo = MockRouterRepository();
    service = PortRangeForwardingService(mockRepo);
  });

  group('PortRangeForwardingService - fetchSettings', () {
    test('returns UI models and status on success', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createGetLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getPortRangeForwardingRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeForwardingTestData.createGetRulesSuccess());

      // Act
      final (rules, status) = await service.fetchSettings();

      // Assert
      expect(rules, isA<PortRangeForwardingRuleListUIModel>());
      expect(rules.rules, hasLength(2));
      expect(rules.rules[0].description, 'XBox Live');
      expect(rules.rules[0].firstExternalPort, 3074);
      expect(rules.rules[0].protocol, 'TCP');
      expect(rules.rules[1].description, 'Media Server');
      expect(rules.rules[1].firstExternalPort, 8000);
      expect(rules.rules[1].lastExternalPort, 8100);

      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
      expect(status.routerIp, '192.168.1.1');
      expect(status.subnetMask, '255.255.255.0');
    });

    test('returns empty list when no rules exist', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createGetLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getPortRangeForwardingRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createEmptyRulesSuccess());

      // Act
      final (rules, status) = await service.fetchSettings();

      // Assert
      expect(rules.rules, isEmpty);
      expect(status.maxRules, 50);
    });

    test('fetches with forceRemote flag', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: true,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createGetLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getPortRangeForwardingRules,
                fetchRemote: true,
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeForwardingTestData.createGetRulesSuccess());

      // Act
      await service.fetchSettings(forceRemote: true);

      // Assert
      verify(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: true,
          )).called(1);
      verify(() => mockRepo.send(
            JNAPAction.getPortRangeForwardingRules,
            fetchRemote: true,
            auth: true,
          )).called(1);
    });

    test('transforms JNAP models to UI models correctly', () async {
      // Arrange
      final customRules = [
        PortRangeForwardingTestData.createDefaultRule(
          isEnabled: false,
          firstExternalPort: 9000,
          protocol: 'UDP',
          internalServerIPAddress: '192.168.1.50',
          lastExternalPort: 9000,
          description: 'Custom Rule',
        ),
      ];

      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createGetLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getPortRangeForwardingRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createGetRulesSuccess(
                  rules: customRules));

      // Act
      final (rules, _) = await service.fetchSettings();

      // Assert
      expect(rules.rules, hasLength(1));
      expect(rules.rules[0].isEnabled, false);
      expect(rules.rules[0].firstExternalPort, 9000);
      expect(rules.rules[0].protocol, 'UDP');
      expect(rules.rules[0].internalServerIPAddress, '192.168.1.50');
      expect(rules.rules[0].description, 'Custom Rule');
    });

    test('throws UnauthorizedError when JNAP returns unauthorized', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createGetLANSettingsSuccess());

      when(() => mockRepo.send(
            JNAPAction.getPortRangeForwardingRules,
            fetchRemote: false,
            auth: true,
          )).thenThrow(PortRangeForwardingTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws InvalidIPAddressError when JNAP returns invalid IP', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createGetLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getPortRangeForwardingRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenThrow(PortRangeForwardingTestData.createInvalidIPAddressError());

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<InvalidIPAddressError>()),
      );
    });

    test('throws UnexpectedError for unmapped JNAP errors', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              PortRangeForwardingTestData.createGetLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getPortRangeForwardingRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenThrow(PortRangeForwardingTestData.createInvalidInputError(
              message: 'Unknown error'));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<InvalidInputError>()),
      );
    });
  });

  group('PortRangeForwardingService - saveSettings', () {
    test('transforms UI models to JNAP models and saves successfully',
        () async {
      // Arrange
      final uiModel = PortRangeForwardingRuleListUIModel(
        rules: [
          const PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 5000,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.150',
            lastExternalPort: 5000,
            description: 'Test Rule',
          ),
        ],
      );

      when(() => mockRepo.send(
                JNAPAction.setPortRangeForwardingRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeForwardingTestData.createSetRulesSuccess());

      // Act
      await service.saveSettings(uiModel);

      // Assert
      final captured = verify(() => mockRepo.send(
            JNAPAction.setPortRangeForwardingRules,
            data: captureAny(named: 'data'),
            auth: true,
          )).captured;

      expect(captured, hasLength(1));
      final data = captured[0] as Map<String, dynamic>;
      expect(data['rules'], hasLength(1));
      expect(data['rules'][0]['firstExternalPort'], 5000);
      expect(data['rules'][0]['protocol'], 'TCP');
      expect(data['rules'][0]['description'], 'Test Rule');
    });

    test('saves empty list successfully', () async {
      // Arrange
      const uiModel = PortRangeForwardingRuleListUIModel(
          rules: <PortRangeForwardingRuleUIModel>[]);

      when(() => mockRepo.send(
                JNAPAction.setPortRangeForwardingRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeForwardingTestData.createSetRulesSuccess());

      // Act
      await service.saveSettings(uiModel);

      // Assert
      final captured = verify(() => mockRepo.send(
            JNAPAction.setPortRangeForwardingRules,
            data: captureAny(named: 'data'),
            auth: true,
          )).captured;

      expect(captured, hasLength(1));
      final data = captured[0] as Map<String, dynamic>;
      expect(data['rules'], isEmpty);
    });

    test('saves multiple rules correctly', () async {
      // Arrange
      final uiModel = PortRangeForwardingRuleListUIModel(
        rules: [
          const PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3000,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3000,
            description: 'Rule 1',
          ),
          const PortRangeForwardingRuleUIModel(
            isEnabled: false,
            firstExternalPort: 4000,
            protocol: 'UDP',
            internalServerIPAddress: '192.168.1.200',
            lastExternalPort: 4100,
            description: 'Rule 2',
          ),
        ],
      );

      when(() => mockRepo.send(
                JNAPAction.setPortRangeForwardingRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeForwardingTestData.createSetRulesSuccess());

      // Act
      await service.saveSettings(uiModel);

      // Assert
      final captured = verify(() => mockRepo.send(
            JNAPAction.setPortRangeForwardingRules,
            data: captureAny(named: 'data'),
            auth: true,
          )).captured;

      final data = captured[0] as Map<String, dynamic>;
      expect(data['rules'], hasLength(2));
      expect(data['rules'][0]['description'], 'Rule 1');
      expect(data['rules'][1]['description'], 'Rule 2');
      expect(data['rules'][1]['lastExternalPort'], 4100);
    });

    test('throws RuleOverlapError when JNAP returns rule overlap error',
        () async {
      // Arrange
      const uiModel = PortRangeForwardingRuleListUIModel(
          rules: <PortRangeForwardingRuleUIModel>[]);

      when(() => mockRepo.send(
            JNAPAction.setPortRangeForwardingRules,
            data: any(named: 'data'),
            auth: true,
          )).thenThrow(PortRangeForwardingTestData.createRuleOverlapError());

      // Act & Assert
      expect(
        () => service.saveSettings(uiModel),
        throwsA(isA<RuleOverlapError>()),
      );
    });

    test(
        'throws InvalidDestinationIPAddressError when JNAP returns invalid destination IP',
        () async {
      // Arrange
      const uiModel = PortRangeForwardingRuleListUIModel(
          rules: <PortRangeForwardingRuleUIModel>[]);

      when(() => mockRepo.send(
                JNAPAction.setPortRangeForwardingRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenThrow(PortRangeForwardingTestData
              .createInvalidDestinationIPAddressError());

      // Act & Assert
      expect(
        () => service.saveSettings(uiModel),
        throwsA(isA<InvalidDestinationIPAddressError>()),
      );
    });

    test('throws UnauthorizedError when JNAP returns unauthorized', () async {
      // Arrange
      const uiModel = PortRangeForwardingRuleListUIModel(
          rules: <PortRangeForwardingRuleUIModel>[]);

      when(() => mockRepo.send(
            JNAPAction.setPortRangeForwardingRules,
            data: any(named: 'data'),
            auth: true,
          )).thenThrow(PortRangeForwardingTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.saveSettings(uiModel),
        throwsA(isA<UnauthorizedError>()),
      );
    });
  });
}
