import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_triggering_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/port_range_triggering_service.dart';

class MockPortRangeTriggeringService extends Mock
    implements PortRangeTriggeringService {}

void main() {
  late MockPortRangeTriggeringService mockService;
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(const PortRangeTriggeringRuleListUIModel(rules: []));
  });

  setUp(() {
    mockService = MockPortRangeTriggeringService();
    container = ProviderContainer(
      overrides: [
        portRangeTriggeringServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PortRangeTriggeringListNotifier', () {
    test('initial state has empty rules', () {
      final notifier = container.read(portRangeTriggeringListProvider.notifier);
      final state = notifier.state;

      expect(state.settings.current.rules, isEmpty);
      expect(state.settings.original.rules, isEmpty);
      expect(state.status.maxRules, 50);
      expect(state.status.maxDescriptionLength, 32);
    });

    test('performFetch calls service and updates state', () async {
      // Arrange
      const mockRules = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'XBox Live',
          ),
        ],
      );
      const mockStatus = PortRangeTriggeringListStatus(
        maxRules: 50,
        maxDescriptionLength: 32,
      );

      when(() => mockService.fetchSettings(forceRemote: false))
          .thenAnswer((_) async => (mockRules, mockStatus));

      // Act
      final notifier = container.read(portRangeTriggeringListProvider.notifier);
      await notifier.performFetch();

      // Assert
      verify(() => mockService.fetchSettings(forceRemote: false)).called(1);
      expect(notifier.state.settings.current.rules, hasLength(1));
      expect(notifier.state.settings.current.rules[0].description, 'XBox Live');
      expect(notifier.state.status.maxRules, 50);
    });

    test('performFetch with forceRemote flag', () async {
      // Arrange
      const mockRules = PortRangeTriggeringRuleListUIModel(rules: []);
      const mockStatus = PortRangeTriggeringListStatus();

      when(() => mockService.fetchSettings(forceRemote: true))
          .thenAnswer((_) async => (mockRules, mockStatus));

      // Act
      final notifier = container.read(portRangeTriggeringListProvider.notifier);
      await notifier.performFetch(forceRemote: true);

      // Assert
      verify(() => mockService.fetchSettings(forceRemote: true)).called(1);
    });

    test('performSave calls service with current settings', () async {
      // Arrange
      const mockRules = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Test Rule',
          ),
        ],
      );
      const mockStatus = PortRangeTriggeringListStatus();

      when(() => mockService.fetchSettings(forceRemote: false))
          .thenAnswer((_) async => (mockRules, mockStatus));
      when(() => mockService.saveSettings(any())).thenAnswer((_) async => {});

      // Act
      final notifier = container.read(portRangeTriggeringListProvider.notifier);
      await notifier.performFetch();
      await notifier.performSave();

      // Assert
      verify(() => mockService.saveSettings(any(
          that: isA<PortRangeTriggeringRuleListUIModel>()
              .having((m) => m.rules.length, 'rules length', 1)))).called(1);
    });

    test('addRule adds rule to current settings', () {
      // Arrange
      final notifier = container.read(portRangeTriggeringListProvider.notifier);
      const newRule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 5000,
        lastTriggerPort: 5000,
        firstForwardedPort: 5100,
        lastForwardedPort: 5100,
        description: 'New Rule',
      );

      // Act
      notifier.addRule(newRule);

      // Assert
      expect(notifier.state.settings.current.rules, hasLength(1));
      expect(notifier.state.settings.current.rules[0].description, 'New Rule');
      expect(notifier.state.settings.current.rules[0].firstTriggerPort, 5000);
    });

    test('editRule updates rule at index', () {
      // Arrange
      final notifier = container.read(portRangeTriggeringListProvider.notifier);
      const initialRule = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Initial Rule',
      );
      const updatedRule = PortRangeTriggeringRuleUIModel(
        isEnabled: false,
        firstTriggerPort: 4000,
        lastTriggerPort: 4000,
        firstForwardedPort: 4100,
        lastForwardedPort: 4100,
        description: 'Updated Rule',
      );

      notifier.addRule(initialRule);

      // Act
      notifier.editRule(0, updatedRule);

      // Assert
      expect(notifier.state.settings.current.rules, hasLength(1));
      expect(
          notifier.state.settings.current.rules[0].description, 'Updated Rule');
      expect(notifier.state.settings.current.rules[0].isEnabled, false);
      expect(notifier.state.settings.current.rules[0].firstTriggerPort, 4000);
    });

    test('deleteRule removes rule from current settings', () {
      // Arrange
      final notifier = container.read(portRangeTriggeringListProvider.notifier);
      const rule1 = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Rule 1',
      );
      const rule2 = PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 4000,
        lastTriggerPort: 4000,
        firstForwardedPort: 4100,
        lastForwardedPort: 4100,
        description: 'Rule 2',
      );

      notifier.addRule(rule1);
      notifier.addRule(rule2);

      // Act
      notifier.deleteRule(rule1);

      // Assert
      expect(notifier.state.settings.current.rules, hasLength(1));
      expect(notifier.state.settings.current.rules[0].description, 'Rule 2');
    });

    test('isExceedMax returns true when rules count equals maxRules', () {
      // Arrange
      final notifier = container.read(portRangeTriggeringListProvider.notifier);

      // Add rules up to max (default is 50)
      for (int i = 0; i < 50; i++) {
        notifier.addRule(PortRangeTriggeringRuleUIModel(
          isEnabled: true,
          firstTriggerPort: 3000 + i,
          lastTriggerPort: 3000 + i,
          firstForwardedPort: 4000 + i,
          lastForwardedPort: 4000 + i,
          description: 'Rule $i',
        ));
      }

      // Act & Assert
      expect(notifier.isExceedMax(), true);
    });

    test('isExceedMax returns false when rules count is less than maxRules',
        () {
      // Arrange
      final notifier = container.read(portRangeTriggeringListProvider.notifier);
      notifier.addRule(const PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 3074,
        lastTriggerPort: 3074,
        firstForwardedPort: 3075,
        lastForwardedPort: 3075,
        description: 'Rule',
      ));

      // Act & Assert
      expect(notifier.isExceedMax(), false);
    });

    test('state is preservable and tracks dirty status', () async {
      // Arrange
      const mockRules = PortRangeTriggeringRuleListUIModel(
        rules: [
          PortRangeTriggeringRuleUIModel(
            isEnabled: true,
            firstTriggerPort: 3074,
            lastTriggerPort: 3074,
            firstForwardedPort: 3075,
            lastForwardedPort: 3075,
            description: 'Original Rule',
          ),
        ],
      );
      const mockStatus = PortRangeTriggeringListStatus();

      when(() => mockService.fetchSettings(forceRemote: false))
          .thenAnswer((_) async => (mockRules, mockStatus));

      final notifier = container.read(portRangeTriggeringListProvider.notifier);

      // Act: Fetch initial data
      await notifier.performFetch();

      // Assert: Not dirty initially
      expect(notifier.state.settings.original,
          equals(notifier.state.settings.current));

      // Act: Add a new rule
      notifier.addRule(const PortRangeTriggeringRuleUIModel(
        isEnabled: true,
        firstTriggerPort: 4000,
        lastTriggerPort: 4000,
        firstForwardedPort: 4100,
        lastForwardedPort: 4100,
        description: 'New Rule',
      ));

      // Assert: Now dirty
      expect(notifier.state.settings.original,
          isNot(equals(notifier.state.settings.current)));
      expect(notifier.state.settings.current.rules, hasLength(2));
      expect(notifier.state.settings.original.rules, hasLength(1));
    });
  });
}
