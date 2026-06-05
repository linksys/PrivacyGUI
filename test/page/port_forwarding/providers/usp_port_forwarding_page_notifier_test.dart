import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/_shared/models/port_forwarding_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/models/port_triggering_rule_ui_model.dart';
import 'package:privacy_gui/page/port_forwarding/providers/usp_port_forwarding_page_notifier.dart';
import 'package:privacy_gui/page/port_forwarding/services/usp_port_forwarding_service.dart';

class MockUspPortForwardingService extends Mock
    implements UspPortForwardingService {}

void main() {
  late MockUspPortForwardingService mockService;

  final pf1 = PortForwardingRuleUIModel(
    instancePath: 'Device.NAT.PortMapping.1.',
    description: 'HTTP',
    externalPort: 80,
    internalPort: 80,
    internalClient: '192.168.1.100',
    protocol: 'TCP',
    enabled: true,
  );
  final pf2 = PortForwardingRuleUIModel(
    instancePath: 'Device.NAT.PortMapping.2.',
    description: 'HTTPS',
    externalPort: 443,
    internalPort: 443,
    internalClient: '192.168.1.100',
    protocol: 'TCP',
    enabled: true,
  );
  final pt1 = PortTriggeringRuleUIModel(
    instancePath: 'Device.NAT.PortTrigger.1.',
    enabled: true,
    description: 'Game',
    triggerPort: 3000,
    triggerProtocol: 'TCP',
  );

  setUpAll(() {
    registerFallbackValue(<PortForwardingRuleUIModel>[]);
    registerFallbackValue(<PortTriggeringRuleUIModel>[]);
  });

  setUp(() {
    mockService = MockUspPortForwardingService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspPortForwardingServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(uspPortForwardingPageProvider, (_, __) {});
    return container;
  }

  void stubFetch({
    List<PortForwardingRuleUIModel>? forwarding,
    List<PortTriggeringRuleUIModel>? triggering,
  }) {
    when(() => mockService.fetchForwardingRules())
        .thenAnswer((_) async => forwarding ?? [pf1]);
    when(() => mockService.fetchTriggeringRules())
        .thenAnswer((_) async => triggering ?? [pt1]);
  }

  group('UspPortForwardingPageNotifier', () {
    test('build returns initial loading state', () async {
      stubFetch();
      final container = createContainer();

      final state = container.read(uspPortForwardingPageProvider);
      expect(state.status.isLoading, isTrue);
      expect(state.settings.current.forwardingRules, isEmpty);
      expect(state.settings.current.triggeringRules, isEmpty);
      await Future.delayed(Duration.zero);
      container.dispose();
    });

    test('fetch success populates both rule types', () async {
      stubFetch(forwarding: [pf1, pf2], triggering: [pt1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspPortForwardingPageProvider);
      expect(state.settings.current.forwardingRules, hasLength(2));
      expect(state.settings.current.triggeringRules, hasLength(1));
      expect(state.settings.current.forwardingRules[0].description, 'HTTP');
      expect(state.settings.current.triggeringRules[0].description, 'Game');
      container.dispose();
    });

    test('fetch error sets error status', () async {
      when(() => mockService.fetchForwardingRules())
          .thenThrow(const NetworkError(message: 'timeout'));
      when(() => mockService.fetchTriggeringRules())
          .thenAnswer((_) async => [pt1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspPortForwardingPageProvider);
      expect(state.status.error, isA<NetworkError>());
      container.dispose();
    });

    test('performSave calls both batch saves', () async {
      stubFetch();
      when(() => mockService.saveForwardingBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async => (added: 1, updated: 0, deleted: 0));
      when(() => mockService.saveTriggeringBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async => (added: 0, updated: 0, deleted: 0));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspPortForwardingPageProvider.notifier);
      notifier.addForwardingRule(pf2);
      await notifier.save();

      verify(() => mockService.saveForwardingBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).called(1);
      verify(() => mockService.saveTriggeringBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).called(1);
      container.dispose();
    });

    // --- Port Forwarding Mutations ---

    test('addForwardingRule appends, preserves triggering', () async {
      stubFetch();
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container
          .read(uspPortForwardingPageProvider.notifier)
          .addForwardingRule(pf2);

      final state = container.read(uspPortForwardingPageProvider);
      expect(state.settings.current.forwardingRules, hasLength(2));
      expect(state.settings.current.triggeringRules, hasLength(1));
      container.dispose();
    });

    test('editForwardingRule replaces by value match', () async {
      stubFetch(forwarding: [pf1, pf2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final updated = pf1.copyWith(description: 'HTTP-Updated');
      container
          .read(uspPortForwardingPageProvider.notifier)
          .editForwardingRule(pf1, updated);

      final rules = container
          .read(uspPortForwardingPageProvider)
          .settings
          .current
          .forwardingRules;
      expect(rules[0].description, 'HTTP-Updated');
      expect(rules, hasLength(2));
      container.dispose();
    });

    test('toggleForwardingRule flips enabled flag', () async {
      stubFetch();
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container
          .read(uspPortForwardingPageProvider.notifier)
          .toggleForwardingRule(pf1, false);

      final rules = container
          .read(uspPortForwardingPageProvider)
          .settings
          .current
          .forwardingRules;
      expect(rules[0].enabled, isFalse);
      container.dispose();
    });

    test('deleteForwardingRule removes from list', () async {
      stubFetch(forwarding: [pf1, pf2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container
          .read(uspPortForwardingPageProvider.notifier)
          .deleteForwardingRule(pf1);

      final rules = container
          .read(uspPortForwardingPageProvider)
          .settings
          .current
          .forwardingRules;
      expect(rules, hasLength(1));
      expect(rules[0].description, 'HTTPS');
      container.dispose();
    });

    // --- Port Triggering Mutations ---

    test('addTriggeringRule appends, preserves forwarding', () async {
      stubFetch(triggering: []);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container
          .read(uspPortForwardingPageProvider.notifier)
          .addTriggeringRule(pt1);

      final state = container.read(uspPortForwardingPageProvider);
      expect(state.settings.current.triggeringRules, hasLength(1));
      expect(state.settings.current.forwardingRules, hasLength(1));
      container.dispose();
    });

    test('deleteTriggeringRule removes from list', () async {
      stubFetch();
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container
          .read(uspPortForwardingPageProvider.notifier)
          .deleteTriggeringRule(pt1);

      final state = container.read(uspPortForwardingPageProvider);
      expect(state.settings.current.triggeringRules, isEmpty);
      expect(state.settings.current.forwardingRules, hasLength(1));
      container.dispose();
    });

    test('editTriggeringRule replaces by value match', () async {
      stubFetch();
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final updated = pt1.copyWith(description: 'Game-Updated');
      container
          .read(uspPortForwardingPageProvider.notifier)
          .editTriggeringRule(pt1, updated);

      final rules = container
          .read(uspPortForwardingPageProvider)
          .settings
          .current
          .triggeringRules;
      expect(rules[0].description, 'Game-Updated');
      expect(rules, hasLength(1));
      container.dispose();
    });

    test('toggleTriggeringRule flips enabled flag', () async {
      stubFetch();
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container
          .read(uspPortForwardingPageProvider.notifier)
          .toggleTriggeringRule(pt1, false);

      final rules = container
          .read(uspPortForwardingPageProvider)
          .settings
          .current
          .triggeringRules;
      expect(rules[0].enabled, isFalse);
      container.dispose();
    });

    test('performSave rethrows ServiceError and clears isSaving', () async {
      stubFetch();
      when(() => mockService.saveForwardingBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenThrow(const NetworkError(message: 'save failed'));
      when(() => mockService.saveTriggeringBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async => (added: 0, updated: 0, deleted: 0));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspPortForwardingPageProvider.notifier);
      notifier.addForwardingRule(pf2);

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(container.read(uspPortForwardingPageProvider).status.isSaving,
          isFalse);
      container.dispose();
    });

    test('isDirty after adding, clean after revert', () async {
      stubFetch();
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspPortForwardingPageProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.addForwardingRule(pf2);
      expect(notifier.isDirty(), isTrue);

      notifier.revert();
      expect(notifier.isDirty(), isFalse);
      container.dispose();
    });
  });
}
