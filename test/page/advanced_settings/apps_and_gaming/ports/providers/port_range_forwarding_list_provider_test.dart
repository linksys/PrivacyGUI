import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/models/port_range_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_list_provider.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/providers/port_range_forwarding_list_state.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/services/port_range_forwarding_service.dart';
import 'package:privacy_gui/providers/preservable.dart';

class MockPortRangeForwardingService extends Mock
    implements PortRangeForwardingService {}

void main() {
  late MockPortRangeForwardingService mockService;
  late ProviderContainer container;

  setUpAll(() {
    // Register fallback value for mocktail
    registerFallbackValue(const PortRangeForwardingRuleListUIModel(rules: []));
  });

  setUp(() {
    mockService = MockPortRangeForwardingService();
    container = ProviderContainer(
      overrides: [
        portRangeForwardingServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('PortRangeForwardingListNotifier - Initialization', () {
    test('build returns initial state', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      final state = notifier.build();

      expect(state.settings.original.rules, isEmpty);
      expect(state.settings.current.rules, isEmpty);
      expect(state.status.maxRules, 50);
      expect(state.status.maxDescriptionLength, 32);
      expect(state.status.routerIp, '192.168.1.1');
      expect(state.status.subnetMask, '255.255.255.0');
    });
  });

  group('PortRangeForwardingListNotifier - performFetch', () {
    test('fetches settings successfully and updates state', () async {
      // Arrange
      const rules = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3074,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3074,
            description: 'XBox Live',
          ),
        ],
      );
      const status = PortRangeForwardingListStatus(
        maxRules: 50,
        maxDescriptionLength: 32,
        routerIp: '192.168.1.1',
        subnetMask: '255.255.255.0',
      );

      when(() => mockService.fetchSettings(forceRemote: false))
          .thenAnswer((_) async => (rules, status));

      final notifier = container.read(portRangeForwardingListProvider.notifier);

      // Act
      final result = await notifier.performFetch();

      // Assert
      expect(result.$1, rules);
      expect(result.$2, status);

      final state = container.read(portRangeForwardingListProvider);
      expect(state.settings.original, rules);
      expect(state.settings.current, rules);
      expect(state.status, status);

      verify(() => mockService.fetchSettings(forceRemote: false)).called(1);
    });

    test('fetches with forceRemote flag', () async {
      // Arrange
      const rules = PortRangeForwardingRuleListUIModel(rules: []);
      const status = PortRangeForwardingListStatus();

      when(() => mockService.fetchSettings(forceRemote: true))
          .thenAnswer((_) async => (rules, status));

      final notifier = container.read(portRangeForwardingListProvider.notifier);

      // Act
      await notifier.performFetch(forceRemote: true);

      // Assert
      verify(() => mockService.fetchSettings(forceRemote: true)).called(1);
    });

    test('throws ServiceError when fetch fails', () async {
      // Arrange
      when(() => mockService.fetchSettings(forceRemote: false))
          .thenThrow(const UnauthorizedError());

      final notifier = container.read(portRangeForwardingListProvider.notifier);

      // Act & Assert
      expect(
        () => notifier.performFetch(),
        throwsA(isA<UnauthorizedError>()),
      );
    });

    test('handles empty rules list', () async {
      // Arrange
      const rules = PortRangeForwardingRuleListUIModel(rules: []);
      const status = PortRangeForwardingListStatus(
        maxRules: 100,
        maxDescriptionLength: 64,
        routerIp: '10.0.0.1',
        subnetMask: '255.255.0.0',
      );

      when(() => mockService.fetchSettings(forceRemote: false))
          .thenAnswer((_) async => (rules, status));

      final notifier = container.read(portRangeForwardingListProvider.notifier);

      // Act
      await notifier.performFetch();

      // Assert
      final state = container.read(portRangeForwardingListProvider);
      expect(state.settings.original.rules, isEmpty);
      expect(state.settings.current.rules, isEmpty);
      expect(state.status.maxRules, 100);
      expect(state.status.routerIp, '10.0.0.1');
    });
  });

  group('PortRangeForwardingListNotifier - performSave', () {
    test('saves settings successfully', () async {
      // Arrange
      const rules = PortRangeForwardingRuleListUIModel(
        rules: [
          PortRangeForwardingRuleUIModel(
            isEnabled: true,
            firstExternalPort: 3074,
            protocol: 'TCP',
            internalServerIPAddress: '192.168.1.100',
            lastExternalPort: 3074,
            description: 'XBox Live',
          ),
        ],
      );

      when(() => mockService.saveSettings(any()))
          .thenAnswer((_) async => Future.value());

      final notifier = container.read(portRangeForwardingListProvider.notifier);

      // Set current state
      container.read(portRangeForwardingListProvider.notifier).state =
          const PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: rules,
        ),
        status: PortRangeForwardingListStatus(),
      );

      // Act
      await notifier.performSave();

      // Assert
      verify(() => mockService.saveSettings(rules)).called(1);
    });

    test('throws ServiceError when save fails', () async {
      // Arrange
      when(() => mockService.saveSettings(any()))
          .thenThrow(const RuleOverlapError());

      final notifier = container.read(portRangeForwardingListProvider.notifier);

      // Act & Assert
      expect(
        () => notifier.performSave(),
        throwsA(isA<RuleOverlapError>()),
      );
    });

    test('saves empty list successfully', () async {
      // Arrange
      const emptyRules = PortRangeForwardingRuleListUIModel(rules: []);

      when(() => mockService.saveSettings(any()))
          .thenAnswer((_) async => Future.value());

      final notifier = container.read(portRangeForwardingListProvider.notifier);

      // Set current state
      container.read(portRangeForwardingListProvider.notifier).state =
          const PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: []),
          current: emptyRules,
        ),
        status: PortRangeForwardingListStatus(),
      );

      // Act
      await notifier.performSave();

      // Assert
      verify(() => mockService.saveSettings(emptyRules)).called(1);
    });
  });

  group('PortRangeForwardingListNotifier - Rule Management', () {
    test('addRule adds a new rule to current settings', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      const initialRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Initial Rule',
      );
      const newRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8080,
        protocol: 'UDP',
        internalServerIPAddress: '192.168.1.200',
        lastExternalPort: 8080,
        description: 'New Rule',
      );

      // Set initial state with one rule
      notifier.state = const PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [initialRule]),
          current: PortRangeForwardingRuleListUIModel(rules: [initialRule]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      // Act
      notifier.addRule(newRule);

      // Assert
      final state = container.read(portRangeForwardingListProvider);
      expect(state.settings.current.rules, hasLength(2));
      expect(state.settings.current.rules[0], initialRule);
      expect(state.settings.current.rules[1], newRule);
      // Original should remain unchanged
      expect(state.settings.original.rules, hasLength(1));
    });

    test('addRule to empty list', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      const newRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'First Rule',
      );

      // Act
      notifier.addRule(newRule);

      // Assert
      final state = container.read(portRangeForwardingListProvider);
      expect(state.settings.current.rules, hasLength(1));
      expect(state.settings.current.rules[0], newRule);
    });

    test('editRule updates existing rule at index', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      const originalRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Original',
      );
      const updatedRule = PortRangeForwardingRuleUIModel(
        isEnabled: false,
        firstExternalPort: 8080,
        protocol: 'UDP',
        internalServerIPAddress: '192.168.1.200',
        lastExternalPort: 8080,
        description: 'Updated',
      );

      // Set initial state
      notifier.state = const PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [originalRule]),
          current: PortRangeForwardingRuleListUIModel(rules: [originalRule]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      // Act
      notifier.editRule(0, updatedRule);

      // Assert
      final state = container.read(portRangeForwardingListProvider);
      expect(state.settings.current.rules, hasLength(1));
      expect(state.settings.current.rules[0], updatedRule);
      // Original should remain unchanged
      expect(state.settings.original.rules[0], originalRule);
    });

    test('editRule updates middle rule in list', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      const rule1 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Rule 1',
      );
      const rule2 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8080,
        protocol: 'UDP',
        internalServerIPAddress: '192.168.1.200',
        lastExternalPort: 8080,
        description: 'Rule 2',
      );
      const rule3 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 9000,
        protocol: 'Both',
        internalServerIPAddress: '192.168.1.150',
        lastExternalPort: 9000,
        description: 'Rule 3',
      );
      const updatedRule2 = PortRangeForwardingRuleUIModel(
        isEnabled: false,
        firstExternalPort: 8888,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.222',
        lastExternalPort: 8888,
        description: 'Updated Rule 2',
      );

      // Set initial state with 3 rules
      notifier.state = const PortRangeForwardingListState(
        settings: Preservable(
          original:
              PortRangeForwardingRuleListUIModel(rules: [rule1, rule2, rule3]),
          current:
              PortRangeForwardingRuleListUIModel(rules: [rule1, rule2, rule3]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      // Act - edit middle rule (index 1)
      notifier.editRule(1, updatedRule2);

      // Assert
      final state = container.read(portRangeForwardingListProvider);
      expect(state.settings.current.rules, hasLength(3));
      expect(state.settings.current.rules[0], rule1);
      expect(state.settings.current.rules[1], updatedRule2);
      expect(state.settings.current.rules[2], rule3);
    });

    test('deleteRule removes rule from current settings', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      const rule1 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Rule 1',
      );
      const rule2 = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 8080,
        protocol: 'UDP',
        internalServerIPAddress: '192.168.1.200',
        lastExternalPort: 8080,
        description: 'Rule 2',
      );

      // Set initial state with 2 rules
      notifier.state = const PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [rule1, rule2]),
          current: PortRangeForwardingRuleListUIModel(rules: [rule1, rule2]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      // Act
      notifier.deleteRule(rule1);

      // Assert
      final state = container.read(portRangeForwardingListProvider);
      expect(state.settings.current.rules, hasLength(1));
      expect(state.settings.current.rules[0], rule2);
      // Original should remain unchanged
      expect(state.settings.original.rules, hasLength(2));
    });

    test('deleteRule removes last remaining rule', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      const onlyRule = PortRangeForwardingRuleUIModel(
        isEnabled: true,
        firstExternalPort: 3074,
        protocol: 'TCP',
        internalServerIPAddress: '192.168.1.100',
        lastExternalPort: 3074,
        description: 'Only Rule',
      );

      // Set initial state with 1 rule
      notifier.state = const PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: [onlyRule]),
          current: PortRangeForwardingRuleListUIModel(rules: [onlyRule]),
        ),
        status: PortRangeForwardingListStatus(),
      );

      // Act
      notifier.deleteRule(onlyRule);

      // Assert
      final state = container.read(portRangeForwardingListProvider);
      expect(state.settings.current.rules, isEmpty);
    });
  });

  group('PortRangeForwardingListNotifier - isExceedMax', () {
    test('returns true when rules count equals maxRules', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      final rules = List.generate(
        50,
        (index) => PortRangeForwardingRuleUIModel(
          isEnabled: true,
          firstExternalPort: 3000 + index,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.100',
          lastExternalPort: 3000 + index,
          description: 'Rule $index',
        ),
      );

      notifier.state = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: rules),
          current: PortRangeForwardingRuleListUIModel(rules: rules),
        ),
        status: const PortRangeForwardingListStatus(maxRules: 50),
      );

      expect(notifier.isExceedMax(), true);
    });

    test('returns false when rules count is less than maxRules', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      const rules = [
        PortRangeForwardingRuleUIModel(
          isEnabled: true,
          firstExternalPort: 3074,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.100',
          lastExternalPort: 3074,
          description: 'Rule 1',
        ),
      ];

      notifier.state = const PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: rules),
          current: PortRangeForwardingRuleListUIModel(rules: rules),
        ),
        status: PortRangeForwardingListStatus(maxRules: 50),
      );

      expect(notifier.isExceedMax(), false);
    });

    test('returns false when rules list is empty', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);

      expect(notifier.isExceedMax(), false);
    });

    test('returns true when rules count exceeds custom maxRules', () {
      final notifier = container.read(portRangeForwardingListProvider.notifier);
      final rules = List.generate(
        10,
        (index) => PortRangeForwardingRuleUIModel(
          isEnabled: true,
          firstExternalPort: 3000 + index,
          protocol: 'TCP',
          internalServerIPAddress: '192.168.1.100',
          lastExternalPort: 3000 + index,
          description: 'Rule $index',
        ),
      );

      notifier.state = PortRangeForwardingListState(
        settings: Preservable(
          original: PortRangeForwardingRuleListUIModel(rules: rules),
          current: PortRangeForwardingRuleListUIModel(rules: rules),
        ),
        status: const PortRangeForwardingListStatus(maxRules: 10),
      );

      expect(notifier.isExceedMax(), true);
    });
  });
}
