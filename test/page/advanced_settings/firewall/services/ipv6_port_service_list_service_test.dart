import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/ipv6_port_service_list_service.dart';

import '../../../../common/unit_test_helper.dart';
import 'ipv6_port_service_list_service_test_data.dart';

// Mock class for RouterRepository
class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late MockRouterRepository mockRepository;
  late IPv6PortServiceListService service;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getIPv6FirewallRules);
    registerFallbackValue(JNAPAction.setIPv6FirewallRules);
    registerFallbackValue(CacheLevel.noCache);
  });

  setUp(() {
    mockRepository = MockRouterRepository();
    service = IPv6PortServiceListService();
    UnitTestHelper.setupMocktailFallbacks();
  });

  group('IPv6PortServiceListService', () {
    group('fetchPortServiceRules', () {
      test('fetches and transforms empty rules list successfully', () async {
        // Arrange
        final mockResponse = IPv6PortServiceTestData.createEmptyResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (rules, status) = await service.fetchPortServiceRules(
          mockRef,
        );

        // Assert
        expect(rules, isNotNull);
        expect(rules, isEmpty);
        expect(status, isNotNull);
        expect(status?.maxRules, 50);
        expect(status?.maxDescriptionLength, 32);
      });

      test('fetches and transforms single rule successfully', () async {
        // Arrange
        final mockResponse = IPv6PortServiceTestData.createSingleRuleResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (rules, status) = await service.fetchPortServiceRules(
          mockRef,
        );

        // Assert
        expect(rules, isNotNull);
        expect(rules?.rules.length, 1);
        expect(rules?.rules.first.description, 'Web Server');
        expect(rules?.rules.first.internalIPAddress, '2001:db8::1');
        expect(rules?.rules.first.enabled, true);
        expect(rules?.rules.first.protocol, 'TCP');
        expect(rules?.rules.first.externalPort, 80);
        expect(rules?.rules.first.internalPort, 80);
        expect(status?.maxRules, 50);
        expect(status?.maxDescriptionLength, 32);
      });

      test('fetches and transforms multiple rules successfully', () async {
        // Arrange
        final mockResponse =
            IPv6PortServiceTestData.createMultipleRulesResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (rules, status) = await service.fetchPortServiceRules(
          mockRef,
        );

        // Assert
        expect(rules, isNotNull);
        expect(rules?.rules.length, 3);
        // First rule
        expect(rules?.rules[0].description, 'Web Server');
        expect(rules?.rules[0].protocol, 'TCP');
        expect(rules?.rules[0].externalPort, 80);
        expect(rules?.rules[0].enabled, true);
        // Second rule
        expect(rules?.rules[1].description, 'HTTPS Server');
        expect(rules?.rules[1].protocol, 'TCP');
        expect(rules?.rules[1].externalPort, 443);
        expect(rules?.rules[1].enabled, true);
        // Third rule
        expect(rules?.rules[2].description, 'Game Server');
        expect(rules?.rules[2].protocol, 'UDP');
        expect(rules?.rules[2].externalPort, 7777);
        expect(rules?.rules[2].enabled, false);
      });

      test('fetches with port range rule successfully', () async {
        // Arrange
        final mockResponse = IPv6PortServiceTestData.createPortRangeResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (rules, status) = await service.fetchPortServiceRules(
          mockRef,
        );

        // Assert
        expect(rules, isNotNull);
        expect(rules?.rules.length, 1);
        expect(rules?.rules.first.description, 'Gaming Ports');
        expect(rules?.rules.first.protocol, 'Both');
        expect(rules?.rules.first.externalPort, 27000);
        expect(rules?.rules.first.internalPort, 27100);
      });

      test('fetches with forceRemote=true', () async {
        // Arrange
        final mockResponse = IPv6PortServiceTestData.createEmptyResponse();
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.fetchPortServiceRules(
          mockRef,
          forceRemote: true,
        );

        // Assert
        verify(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: true,
              fetchRemote: true,
            )).called(1);
      });

      test('fetches with custom maxRules and maxDescriptionLength', () async {
        // Arrange
        final mockResponse = IPv6PortServiceTestData.createCustomResponse(
          maxRules: 100,
          maxDescriptionLength: 64,
        );
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenAnswer((_) async => mockResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        final (rules, status) = await service.fetchPortServiceRules(
          mockRef,
        );

        // Assert
        expect(status?.maxRules, 100);
        expect(status?.maxDescriptionLength, 64);
      });

      test('throws exception when JNAP action fails', () async {
        // Arrange
        when(() => mockRepository.send(
              any(),
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
            )).thenThrow(Exception('Network error'));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act & Assert
        expect(
          () async => await service.fetchPortServiceRules(mockRef),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('addPortServiceRule', () {
      test('adds new rule successfully', () async {
        // Arrange
        final existingResponse = IPv6PortServiceTestData.createEmptyResponse();
        final newRule = IPv6PortServiceTestData.createUIRule();

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => existingResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.addPortServiceRule(mockRef, newRule);

        // Assert
        verify(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: true,
            )).called(1);

        verify(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: true,
              fetchRemote: true,
              cacheLevel: CacheLevel.noCache,
              data: any(named: 'data'),
            )).called(1);
      });

      test('adds rule to existing rules list', () async {
        // Arrange
        final existingResponse =
            IPv6PortServiceTestData.createSingleRuleResponse();
        final newRule = IPv6PortServiceTestData.createUIRule(
          description: 'New Rule',
          externalPort: 443,
        );

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        Map<String, dynamic>? capturedData;
        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: captureAny(named: 'data'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[#data] as Map<String, dynamic>;
          return existingResponse;
        });

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.addPortServiceRule(mockRef, newRule);

        // Assert
        expect(capturedData, isNotNull);
        final rules = capturedData!['rules'] as List;
        expect(rules.length, 2); // Original + new rule
      });

      test('throws exception when add fails', () async {
        // Arrange
        final existingResponse = IPv6PortServiceTestData.createEmptyResponse();
        final newRule = IPv6PortServiceTestData.createUIRule();

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: any(named: 'data'),
            )).thenThrow(Exception('Save failed'));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act & Assert
        expect(
          () async => await service.addPortServiceRule(mockRef, newRule),
          throwsA(isA<Exception>()),
        );
      });
    });

    group('updatePortServiceRule', () {
      test('updates existing rule successfully', () async {
        // Arrange
        final existingResponse =
            IPv6PortServiceTestData.createSingleRuleResponse();
        final oldRule = IPv6PortServiceTestData.createUIRule();
        final newRule = oldRule.copyWith(description: 'Updated Web Server');

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => existingResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.updatePortServiceRule(mockRef, oldRule, newRule);

        // Assert
        verify(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: true,
            )).called(1);

        verify(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: true,
              fetchRemote: true,
              cacheLevel: CacheLevel.noCache,
              data: any(named: 'data'),
            )).called(1);
      });

      test('throws exception when rule not found', () async {
        // Arrange
        final existingResponse =
            IPv6PortServiceTestData.createSingleRuleResponse();
        final oldRule = IPv6PortServiceTestData.createUIRule(
          description: 'Non-existent',
        );
        final newRule = oldRule.copyWith(description: 'Updated');

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act & Assert
        expect(
          () async =>
              await service.updatePortServiceRule(mockRef, oldRule, newRule),
          throwsA(isA<Exception>()),
        );
      });

      test('updates rule in multiple rules list', () async {
        // Arrange
        final existingResponse =
            IPv6PortServiceTestData.createMultipleRulesResponse();
        final oldRule = IPv6PortServiceTestData.createUIRule(
          description: 'HTTPS Server',
          externalPort: 443,
        );
        final newRule = oldRule.copyWith(enabled: false);

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        Map<String, dynamic>? capturedData;
        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: captureAny(named: 'data'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[#data] as Map<String, dynamic>;
          return existingResponse;
        });

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.updatePortServiceRule(mockRef, oldRule, newRule);

        // Assert
        expect(capturedData, isNotNull);
        final rules = capturedData!['rules'] as List;
        expect(rules.length, 3); // Same count
      });
    });

    group('deletePortServiceRule', () {
      test('deletes rule successfully', () async {
        // Arrange
        final existingResponse =
            IPv6PortServiceTestData.createSingleRuleResponse();
        final ruleToDelete = IPv6PortServiceTestData.createUIRule();

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => existingResponse);

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.deletePortServiceRule(mockRef, ruleToDelete);

        // Assert
        verify(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: true,
            )).called(1);

        verify(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: true,
              fetchRemote: true,
              cacheLevel: CacheLevel.noCache,
              data: any(named: 'data'),
            )).called(1);
      });

      test('deletes rule from multiple rules list', () async {
        // Arrange
        final existingResponse =
            IPv6PortServiceTestData.createMultipleRulesResponse();
        final ruleToDelete = IPv6PortServiceTestData.createUIRule(
          description: 'HTTPS Server',
          externalPort: 443,
        );

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        Map<String, dynamic>? capturedData;
        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: captureAny(named: 'data'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[#data] as Map<String, dynamic>;
          return existingResponse;
        });

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.deletePortServiceRule(mockRef, ruleToDelete);

        // Assert
        expect(capturedData, isNotNull);
        final rules = capturedData!['rules'] as List;
        expect(rules.length, 2); // One less than original 3
      });

      test('deletes last rule leaving empty list', () async {
        // Arrange
        final existingResponse =
            IPv6PortServiceTestData.createSingleRuleResponse();
        final ruleToDelete = IPv6PortServiceTestData.createUIRule();

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        Map<String, dynamic>? capturedData;
        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: captureAny(named: 'data'),
            )).thenAnswer((invocation) async {
          capturedData = invocation.namedArguments[#data] as Map<String, dynamic>;
          return existingResponse;
        });

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act
        await service.deletePortServiceRule(mockRef, ruleToDelete);

        // Assert
        expect(capturedData, isNotNull);
        final rules = capturedData!['rules'] as List;
        expect(rules.length, 0);
      });

      test('throws exception when delete fails', () async {
        // Arrange
        final existingResponse =
            IPv6PortServiceTestData.createSingleRuleResponse();
        final ruleToDelete = IPv6PortServiceTestData.createUIRule();

        when(() => mockRepository.send(
              JNAPAction.getIPv6FirewallRules,
              auth: any(named: 'auth'),
            )).thenAnswer((_) async => existingResponse);

        when(() => mockRepository.send(
              JNAPAction.setIPv6FirewallRules,
              auth: any(named: 'auth'),
              fetchRemote: any(named: 'fetchRemote'),
              cacheLevel: any(named: 'cacheLevel'),
              data: any(named: 'data'),
            )).thenThrow(Exception('Delete failed'));

        final mockRef = UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

        // Act & Assert
        expect(
          () async => await service.deletePortServiceRule(mockRef, ruleToDelete),
          throwsA(isA<Exception>()),
        );
      });
    });
  });
}
