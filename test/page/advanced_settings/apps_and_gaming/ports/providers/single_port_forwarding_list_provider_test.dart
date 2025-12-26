import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/single_port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/single_port_forwarding_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/single_port_forwarding_service.dart';

import '../../../../../mocks/test_data/single_port_forwarding_test_data.dart';

class MockSinglePortForwardingService extends Mock
    implements SinglePortForwardingService {}

void main() {
  late MockSinglePortForwardingService mockService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const SinglePortForwardingRuleListUIModel(rules: []));
  });

  setUp(() {
    mockService = MockSinglePortForwardingService();
    container = ProviderContainer(
      overrides: [
        singlePortForwardingServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('SinglePortForwardingListNotifier - performFetch', () {
    test('updates state with fetched settings', () async {
      // Arrange
      final uiRules = SinglePortForwardingTestData.createUIRuleList(count: 2);
      final settings = SinglePortForwardingRuleListUIModel(rules: uiRules);
      const status = SinglePortForwardingListStatus(maxRules: 50);

      when(() => mockService.fetchSettings(forceRemote: false))
          .thenAnswer((_) async => (settings, status));

      // Act
      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      await notifier.performFetch();

      // Assert
      final state = container.read(singlePortForwardingListProvider);
      expect(state.settings.original.rules, hasLength(2));
      expect(state.settings.current.rules, hasLength(2));
      expect(state.status.maxRules, 50);
    });

    test('handles forceRemote parameter', () async {
      // Arrange
      const settings = SinglePortForwardingRuleListUIModel(rules: []);
      const status = SinglePortForwardingListStatus();

      when(() => mockService.fetchSettings(forceRemote: true))
          .thenAnswer((_) async => (settings, status));

      // Act
      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      await notifier.performFetch(forceRemote: true);

      // Assert
      verify(() => mockService.fetchSettings(forceRemote: true)).called(1);
    });

    test('handles service errors gracefully', () async {
      // Arrange
      when(() => mockService.fetchSettings(forceRemote: false))
          .thenThrow(Exception('Network error'));

      // Act & Assert
      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      expect(
        () => notifier.performFetch(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SinglePortForwardingListNotifier - performSave', () {
    test('calls service with current settings', () async {
      // Arrange
      final uiRules = SinglePortForwardingTestData.createUIRuleList(count: 1);
      final settings = SinglePortForwardingRuleListUIModel(rules: uiRules);
      const status = SinglePortForwardingListStatus();

      when(() => mockService.fetchSettings(forceRemote: false))
          .thenAnswer((_) async => (settings, status));
      when(() => mockService.saveSettings(any())).thenAnswer((_) async => {});

      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      await notifier.performFetch();

      // Act
      await notifier.performSave();

      // Assert
      verify(() => mockService.saveSettings(any())).called(1);
    });

    test('handles service errors gracefully', () async {
      // Arrange
      when(() => mockService.saveSettings(any()))
          .thenThrow(Exception('Save failed'));

      // Act & Assert
      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      expect(
        () => notifier.performSave(),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('SinglePortForwardingListNotifier - rule management', () {
    test('addRule adds rule to current settings', () {
      // Arrange
      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      final newRule = SinglePortForwardingTestData.createUIRule(
        externalPort: 8080,
        description: 'New Rule',
      );

      // Act
      notifier.addRule(newRule);

      // Assert
      final state = container.read(singlePortForwardingListProvider);
      expect(state.settings.current.rules, hasLength(1));
      expect(state.settings.current.rules.first.externalPort, 8080);
      expect(state.settings.current.rules.first.description, 'New Rule');
    });

    test('editRule updates rule at index', () {
      // Arrange
      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      final rule1 = SinglePortForwardingTestData.createUIRule(
        externalPort: 8080,
        description: 'Original',
      );
      final rule2 = SinglePortForwardingTestData.createUIRule(
        externalPort: 9090,
        description: 'Updated',
      );

      notifier.addRule(rule1);

      // Act
      notifier.editRule(0, rule2);

      // Assert
      final state = container.read(singlePortForwardingListProvider);
      expect(state.settings.current.rules, hasLength(1));
      expect(state.settings.current.rules.first.externalPort, 9090);
      expect(state.settings.current.rules.first.description, 'Updated');
    });

    test('deleteRule removes rule from settings', () {
      // Arrange
      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      final rule1 = SinglePortForwardingTestData.createUIRule(
        externalPort: 8080,
        description: 'Rule 1',
      );
      final rule2 = SinglePortForwardingTestData.createUIRule(
        externalPort: 9090,
        description: 'Rule 2',
      );

      notifier.addRule(rule1);
      notifier.addRule(rule2);

      // Act
      notifier.deleteRule(rule1);

      // Assert
      final state = container.read(singlePortForwardingListProvider);
      expect(state.settings.current.rules, hasLength(1));
      expect(state.settings.current.rules.first.externalPort, 9090);
    });

    test('isExceedMax returns false when under limit', () {
      // Arrange
      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      final rule = SinglePortForwardingTestData.createUIRule();
      notifier.addRule(rule);

      // Act
      final result = notifier.isExceedMax();

      // Assert
      expect(result, false);
    });

    test('isExceedMax returns true when at max rules', () async {
      // Arrange
      final uiRules = List.generate(
        50,
        (index) => SinglePortForwardingTestData.createUIRule(
          externalPort: 8000 + index,
          description: 'Rule ${index + 1}',
        ),
      );
      final settings = SinglePortForwardingRuleListUIModel(rules: uiRules);
      const status = SinglePortForwardingListStatus(maxRules: 50);

      when(() => mockService.fetchSettings(forceRemote: false))
          .thenAnswer((_) async => (settings, status));

      final notifier =
          container.read(singlePortForwardingListProvider.notifier);
      await notifier.performFetch();

      // Act
      final result = notifier.isExceedMax();

      // Assert
      expect(result, true);
    });
  });

  group('SinglePortForwardingListNotifier - initial state', () {
    test('starts with empty rules', () {
      // Act
      final state = container.read(singlePortForwardingListProvider);

      // Assert
      expect(state.settings.original.rules, isEmpty);
      expect(state.settings.current.rules, isEmpty);
      expect(state.status.maxRules, 50);
      expect(state.status.maxDescriptionLength, 32);
    });
  });
}
