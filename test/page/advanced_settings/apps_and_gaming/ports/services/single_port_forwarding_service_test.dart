import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/single_port_forwarding_service.dart';

import '../../../../../mocks/test_data/single_port_forwarding_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late SinglePortForwardingService service;
  late MockRouterRepository mockRepo;

  setUp(() {
    mockRepo = MockRouterRepository();
    service = SinglePortForwardingService(mockRepo);
  });

  group('SinglePortForwardingService - fetchSettings', () {
    test('returns UI model and status on success', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              SinglePortForwardingTestData.createLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getSinglePortForwardingRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer(
              (_) async => SinglePortForwardingTestData.createRulesSuccess());

      // Act
      final (settings, status) = await service.fetchSettings();

      // Assert
      expect(settings, isA<SinglePortForwardingRuleListUIModel>());
      expect(settings.rules, hasLength(1));
      expect(settings.rules.first.externalPort, 8080);
      expect(settings.rules.first.protocol, 'TCP');
      expect(settings.rules.first.description, 'Test Rule');

      expect(status, isA<SinglePortForwardingListStatus>());
      expect(status.maxRules, 50);
      expect(status.maxDescriptionLength, 32);
      expect(status.routerIp, '192.168.1.1');
      expect(status.subnetMask, '255.255.255.0');
    });

    test('transforms JNAP models to UI models correctly', () async {
      // Arrange
      final customRules = [
        {
          'isEnabled': false,
          'externalPort': 3000,
          'protocol': 'UDP',
          'internalServerIPAddress': '192.168.1.50',
          'internalPort': 3001,
          'description': 'Custom Rule',
        },
      ];

      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              SinglePortForwardingTestData.createLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getSinglePortForwardingRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer((_) async =>
              SinglePortForwardingTestData.createRulesSuccess(
                  rules: customRules));

      // Act
      final (settings, _) = await service.fetchSettings();

      // Assert
      expect(settings.rules, hasLength(1));
      final rule = settings.rules.first;
      expect(rule.isEnabled, false);
      expect(rule.externalPort, 3000);
      expect(rule.protocol, 'UDP');
      expect(rule.internalServerIPAddress, '192.168.1.50');
      expect(rule.internalPort, 3001);
      expect(rule.description, 'Custom Rule');
    });

    test('handles forceRemote parameter correctly', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: true,
              ))
          .thenAnswer((_) async =>
              SinglePortForwardingTestData.createLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getSinglePortForwardingRules,
                fetchRemote: true,
                auth: true,
              ))
          .thenAnswer(
              (_) async => SinglePortForwardingTestData.createRulesSuccess());

      // Act
      await service.fetchSettings(forceRemote: true);

      // Assert
      verify(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: true,
          )).called(1);
      verify(() => mockRepo.send(
            JNAPAction.getSinglePortForwardingRules,
            fetchRemote: true,
            auth: true,
          )).called(1);
    });

    test('throws ServiceError on JNAP failure', () async {
      // Arrange
      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              SinglePortForwardingTestData.createLANSettingsSuccess());

      when(() => mockRepo.send(
            JNAPAction.getSinglePortForwardingRules,
            fetchRemote: false,
            auth: true,
          )).thenThrow(SinglePortForwardingTestData.createJNAPError(
        result: '_ErrorUnauthorized',
        error: 'Unauthorized',
      ));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('handles multiple rules correctly', () async {
      // Arrange
      final multipleRules = List.generate(
        5,
        (index) => {
          'isEnabled': true,
          'externalPort': 8000 + index,
          'protocol': index % 2 == 0 ? 'TCP' : 'UDP',
          'internalServerIPAddress': '192.168.1.${100 + index}',
          'internalPort': 8000 + index,
          'description': 'Rule ${index + 1}',
        },
      );

      when(() => mockRepo.send(
                JNAPAction.getLANSettings,
                auth: true,
                fetchRemote: false,
              ))
          .thenAnswer((_) async =>
              SinglePortForwardingTestData.createLANSettingsSuccess());

      when(() => mockRepo.send(
                JNAPAction.getSinglePortForwardingRules,
                fetchRemote: false,
                auth: true,
              ))
          .thenAnswer((_) async =>
              SinglePortForwardingTestData.createRulesSuccess(
                  rules: multipleRules));

      // Act
      final (settings, _) = await service.fetchSettings();

      // Assert
      expect(settings.rules, hasLength(5));
      for (var i = 0; i < 5; i++) {
        expect(settings.rules[i].externalPort, 8000 + i);
        expect(settings.rules[i].protocol, i % 2 == 0 ? 'TCP' : 'UDP');
        expect(settings.rules[i].description, 'Rule ${i + 1}');
      }
    });
  });

  group('SinglePortForwardingService - saveSettings', () {
    test('transforms UI models to JNAP models correctly', () async {
      // Arrange
      final uiRules = [
        SinglePortForwardingTestData.createUIRule(
          isEnabled: true,
          externalPort: 9000,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.200',
          internalPort: 9001,
          description: 'Save Test',
        ),
      ];
      final settings = SinglePortForwardingRuleListUIModel(rules: uiRules);

      when(() => mockRepo.send(
                JNAPAction.setSinglePortForwardingRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => SinglePortForwardingTestData.createRulesSuccess());

      // Act
      await service.saveSettings(settings);

      // Assert
      final captured = verify(() => mockRepo.send(
            JNAPAction.setSinglePortForwardingRules,
            data: captureAny(named: 'data'),
            auth: true,
          )).captured;

      expect(captured, hasLength(1));
      final data = captured.first as Map<String, dynamic>;
      expect(data['rules'], hasLength(1));

      final savedRule = data['rules'][0] as Map<String, dynamic>;
      expect(savedRule['isEnabled'], true);
      expect(savedRule['externalPort'], 9000);
      expect(savedRule['protocol'], 'TCP');
      expect(savedRule['internalServerIPAddress'], '192.168.1.200');
      expect(savedRule['internalPort'], 9001);
      expect(savedRule['description'], 'Save Test');
    });

    test('sends correct data to RouterRepository', () async {
      // Arrange
      final uiRules = SinglePortForwardingTestData.createUIRuleList(count: 3);
      final settings = SinglePortForwardingRuleListUIModel(rules: uiRules);

      when(() => mockRepo.send(
                JNAPAction.setSinglePortForwardingRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer(
              (_) async => SinglePortForwardingTestData.createRulesSuccess());

      // Act
      await service.saveSettings(settings);

      // Assert
      verify(() => mockRepo.send(
            JNAPAction.setSinglePortForwardingRules,
            data: any(named: 'data'),
            auth: true,
          )).called(1);
    });

    test('throws ServiceError on JNAP failure', () async {
      // Arrange
      final uiRules = SinglePortForwardingTestData.createUIRuleList(count: 1);
      final settings = SinglePortForwardingRuleListUIModel(rules: uiRules);

      when(() => mockRepo.send(
            JNAPAction.setSinglePortForwardingRules,
            data: any(named: 'data'),
            auth: true,
          )).thenThrow(SinglePortForwardingTestData.createJNAPError(
        result: 'ErrorRuleOverlap',
        error: 'Rule overlaps with existing rule',
      ));

      // Act & Assert
      expect(
        () => service.saveSettings(settings),
        throwsA(isA<RuleOverlapError>()),
      );
    });

    test('handles empty rules list', () async {
      // Arrange
      const settings = SinglePortForwardingRuleListUIModel(rules: []);

      when(() => mockRepo.send(
                JNAPAction.setSinglePortForwardingRules,
                data: any(named: 'data'),
                auth: true,
              ))
          .thenAnswer((_) async =>
              SinglePortForwardingTestData.createRulesSuccess(rules: []));

      // Act
      await service.saveSettings(settings);

      // Assert
      final captured = verify(() => mockRepo.send(
            JNAPAction.setSinglePortForwardingRules,
            data: captureAny(named: 'data'),
            auth: true,
          )).captured;

      final data = captured.first as Map<String, dynamic>;
      expect(data['rules'], isEmpty);
    });
  });

  group('SinglePortForwardingService - error mapping', () {
    test('maps UnauthorizedError correctly', () async {
      // Arrange
      when(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: false,
          )).thenThrow(SinglePortForwardingTestData.createJNAPError(
        result: '_ErrorUnauthorized',
      ));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('maps InvalidIPAddressError correctly', () async {
      // Arrange
      when(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: false,
          )).thenThrow(SinglePortForwardingTestData.createJNAPError(
        result: 'ErrorInvalidIPAddress',
      ));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<InvalidIPAddressError>()),
      );
    });

    test('maps unknown errors to UnexpectedError', () async {
      // Arrange
      when(() => mockRepo.send(
            JNAPAction.getLANSettings,
            auth: true,
            fetchRemote: false,
          )).thenThrow(SinglePortForwardingTestData.createJNAPError(
        result: 'SomeUnknownError',
        error: 'Something went wrong',
      ));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
