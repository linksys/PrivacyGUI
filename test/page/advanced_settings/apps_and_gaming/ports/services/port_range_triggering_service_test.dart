import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/port_range_triggering_service.dart';

import '../../../../../mocks/test_data/port_range_triggering_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late PortRangeTriggeringService service;
  late MockRouterRepository mockRepo;

  setUp(() {
    mockRepo = MockRouterRepository();
    service = PortRangeTriggeringService(mockRepo);
  });

  group('PortRangeTriggeringService - fetchSettings', () {
    test('returns UI models and status on success', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getPortRangeTriggeringRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeTriggeringTestData.createGetRulesSuccess());

      // Act
      final (rules, status) = await service.fetchSettings();

      // Assert
      expect(rules, isA<PortRangeTriggeringRuleListUIModel>());
      expect(rules.rules, hasLength(2));
      expect(rules.rules[0].description, 'XBox Live');
      expect(rules.rules[0].firstTriggerPort, 3074);
      expect(rules.rules[0].lastTriggerPort, 3074);
      expect(rules.rules[0].firstForwardedPort, 3074);
      expect(rules.rules[0].lastForwardedPort, 3074);
      expect(rules.rules[1].description, 'Game Server');
      expect(rules.rules[1].firstTriggerPort, 6000);
      expect(rules.rules[1].lastTriggerPort, 6100);
      expect(rules.rules[1].firstForwardedPort, 7000);
      expect(rules.rules[1].lastForwardedPort, 7100);

      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
    });

    test('returns empty list when no rules exist', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getPortRangeTriggeringRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer((_) async =>
              PortRangeTriggeringTestData.createEmptyRulesSuccess());

      // Act
      final (rules, status) = await service.fetchSettings();

      // Assert
      expect(rules.rules, isEmpty);
      expect(status.maxRules, 50);
    });

    test('fetches with forceRemote flag', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getPortRangeTriggeringRules,
                fetchRemote: true,
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeTriggeringTestData.createGetRulesSuccess());

      // Act
      await service.fetchSettings(forceRemote: true);

      // Assert
      verify(() => mockRepo.send(
            JNAPAction.getPortRangeTriggeringRules,
            fetchRemote: true,
            auth: true,
          )).called(1);
    });

    test('transforms JNAP models to UI models correctly', () async {
      // Arrange
      final customRules = [
        PortRangeTriggeringTestData.createDefaultRule(
          isEnabled: false,
          firstTriggerPort: 9000,
          lastTriggerPort: 9000,
          firstForwardedPort: 9100,
          lastForwardedPort: 9100,
          description: 'Custom Rule',
        ),
      ];

      when(() => mockRepo.send(
                JNAPAction.getPortRangeTriggeringRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer((_) async =>
              PortRangeTriggeringTestData.createGetRulesSuccess(
                  rules: customRules));

      // Act
      final (rules, _) = await service.fetchSettings();

      // Assert
      expect(rules.rules, hasLength(1));
      expect(rules.rules[0].isEnabled, false);
      expect(rules.rules[0].firstTriggerPort, 9000);
      expect(rules.rules[0].lastTriggerPort, 9000);
      expect(rules.rules[0].firstForwardedPort, 9100);
      expect(rules.rules[0].lastForwardedPort, 9100);
      expect(rules.rules[0].description, 'Custom Rule');
    });

    test('throws UnauthorizedError when JNAP returns unauthorized', () async {
      // Arrange
      when(() => mockRepo.send(
            JNAPAction.getPortRangeTriggeringRules,
            fetchRemote: false,
            auth: true,
          )).thenThrow(PortRangeTriggeringTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws InvalidInputError when JNAP returns invalid input', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getPortRangeTriggeringRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenThrow(PortRangeTriggeringTestData.createInvalidInputError(
              message: 'Invalid port range'));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<InvalidInputError>()),
      );
    });

    test('throws UnexpectedError for unmapped JNAP errors', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getPortRangeTriggeringRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenThrow(PortRangeTriggeringTestData.createInvalidInputError(
              message: 'Unknown error'));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<InvalidInputError>()),
      );
    });
  });

  group('PortRangeTriggeringService - saveSettings', () {
    test('transforms UI models to JNAP models and saves successfully',
        () async {
      // Arrange
      final uiModel = PortRangeTriggeringRuleListUIModel(
        rules: const [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 5000,
            lastTriggerPort: 5000,
            firstForwardedPort: 5100,
            lastForwardedPort: 5100,
            description: 'Test Rule',
          ),
        ],
      );

      when(() => mockRepo.send(
                JNAPAction.setPortRangeTriggeringRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeTriggeringTestData.createSetRulesSuccess());

      // Act
      await service.saveSettings(uiModel);

      // Assert
      final captured = verify(() => mockRepo.send(
            JNAPAction.setPortRangeTriggeringRules,
            data: captureAny(named: 'data'),
            auth: true,
          )).captured;

      expect(captured, hasLength(1));
      final data = captured[0] as Map<String, dynamic>;
      expect(data['rules'], hasLength(1));
      expect(data['rules'][0]['firstTriggerPort'], 5000);
      expect(data['rules'][0]['lastTriggerPort'], 5000);
      expect(data['rules'][0]['firstForwardedPort'], 5100);
      expect(data['rules'][0]['lastForwardedPort'], 5100);
      expect(data['rules'][0]['description'], 'Test Rule');
    });

    test('saves empty list successfully', () async {
      // Arrange
      const uiModel = PortRangeTriggeringRuleListUIModel(
          rules: <PortRangeTriggeringRuleUIModel>[]);

      when(() => mockRepo.send(
                JNAPAction.setPortRangeTriggeringRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeTriggeringTestData.createSetRulesSuccess());

      // Act
      await service.saveSettings(uiModel);

      // Assert
      final captured = verify(() => mockRepo.send(
            JNAPAction.setPortRangeTriggeringRules,
            data: captureAny(named: 'data'),
            auth: true,
          )).captured;

      expect(captured, hasLength(1));
      final data = captured[0] as Map<String, dynamic>;
      expect(data['rules'], isEmpty);
    });

    test('saves multiple rules correctly', () async {
      // Arrange
      final uiModel = PortRangeTriggeringRuleListUIModel(
        rules: const [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3000,
            lastTriggerPort: 3000,
            firstForwardedPort: 3100,
            lastForwardedPort: 3100,
            description: 'Rule 1',
          ),
          PortRangeTriggeringRuleUIModel(
            isEnabled: false,
            firstTriggerPort: 4000,
            lastTriggerPort: 4100,
            firstForwardedPort: 5000,
            lastForwardedPort: 5100,
            description: 'Rule 2',
          ),
        ],
      );

      when(() => mockRepo.send(
                JNAPAction.setPortRangeTriggeringRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => PortRangeTriggeringTestData.createSetRulesSuccess());

      // Act
      await service.saveSettings(uiModel);

      // Assert
      final captured = verify(() => mockRepo.send(
            JNAPAction.setPortRangeTriggeringRules,
            data: captureAny(named: 'data'),
            auth: true,
          )).captured;

      final data = captured[0] as Map<String, dynamic>;
      expect(data['rules'], hasLength(2));
      expect(data['rules'][0]['description'], 'Rule 1');
      expect(data['rules'][1]['description'], 'Rule 2');
      expect(data['rules'][1]['lastTriggerPort'], 4100);
      expect(data['rules'][1]['lastForwardedPort'], 5100);
    });

    test('throws RuleOverlapError when JNAP returns rule overlap error',
        () async {
      // Arrange
      const uiModel = PortRangeTriggeringRuleListUIModel(
          rules: <PortRangeTriggeringRuleUIModel>[]);

      when(() => mockRepo.send(
            JNAPAction.setPortRangeTriggeringRules,
            data: any(named: 'data'),
            auth: true,
          )).thenThrow(PortRangeTriggeringTestData.createRuleOverlapError());

      // Act & Assert
      expect(
        () => service.saveSettings(uiModel),
        throwsA(isA<RuleOverlapError>()),
      );
    });

    test('throws UnauthorizedError when JNAP returns unauthorized', () async {
      // Arrange
      const uiModel = PortRangeTriggeringRuleListUIModel(
          rules: <PortRangeTriggeringRuleUIModel>[]);

      when(() => mockRepo.send(
            JNAPAction.setPortRangeTriggeringRules,
            data: any(named: 'data'),
            auth: true,
          )).thenThrow(PortRangeTriggeringTestData.createUnauthorizedError());

      // Act & Assert
      expect(
        () => service.saveSettings(uiModel),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('throws InvalidInputError when JNAP returns invalid input', () async {
      // Arrange
      const uiModel = PortRangeTriggeringRuleListUIModel(
          rules: <PortRangeTriggeringRuleUIModel>[]);

      when(() => mockRepo.send(
            JNAPAction.setPortRangeTriggeringRules,
            data: any(named: 'data'),
            auth: true,
          )).thenThrow(PortRangeTriggeringTestData.createInvalidInputError());

      // Act & Assert
      expect(
        () => service.saveSettings(uiModel),
        throwsA(isA<InvalidInputError>()),
      );
    });
  });
}
