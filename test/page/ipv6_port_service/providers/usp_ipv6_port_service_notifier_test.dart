import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/ipv6_port_service/models/ipv6_port_service_ui_model.dart';
import 'package:privacy_gui/page/ipv6_port_service/providers/usp_ipv6_port_service_notifier.dart';
import 'package:privacy_gui/page/ipv6_port_service/services/usp_ipv6_port_service_service.dart';

class MockUspIpv6PortServiceService extends Mock
    implements UspIpv6PortServiceService {}

void main() {
  late MockUspIpv6PortServiceService mockService;

  final rule1 = Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.1.',
    enabled: true,
    description: 'Web Server',
    ipv6Address: '2001:db8::1',
    protocol: 'TCP',
    startPort: 80,
    endPort: 80,
  );
  final rule2 = Ipv6PortServiceRuleUIModel(
    instancePath: 'Device.Firewall.Chain.1.Rule.2.',
    enabled: false,
    description: 'DNS',
    ipv6Address: '2001:db8::2',
    protocol: 'UDP',
    startPort: 53,
    endPort: 53,
  );

  setUpAll(() {
    registerFallbackValue(<Ipv6PortServiceRuleUIModel>[]);
  });

  setUp(() {
    mockService = MockUspIpv6PortServiceService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspIpv6PortServiceServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(uspIpv6PortServiceProvider, (_, __) {});
    return container;
  }

  group('UspIpv6PortServiceNotifier', () {
    test('build returns initial loading state', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1]);
      final container = createContainer();

      final state = container.read(uspIpv6PortServiceProvider);
      expect(state.status.isLoading, isTrue);
      expect(state.settings.current.rules, isEmpty);
      await Future.delayed(Duration.zero);
      container.dispose();
    });

    test('fetch success populates rules', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1, rule2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspIpv6PortServiceProvider);
      expect(state.settings.current.rules, hasLength(2));
      expect(state.settings.current.rules[0].description, 'Web Server');
      expect(state.settings.current.rules[1].protocol, 'UDP');
      container.dispose();
    });

    test('fetch error sets error status', () async {
      when(() => mockService.fetch())
          .thenThrow(const NetworkError(detail: 'fetch failed'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspIpv6PortServiceProvider);
      expect(state.status.errorMessage, contains('fetch failed'));
      expect(state.settings.current.rules, isEmpty);
      container.dispose();
    });

    test('performSave calls saveBatch', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1]);
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async => (added: 1, updated: 0, deleted: 0));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspIpv6PortServiceProvider.notifier);
      notifier.addRule(rule2);
      await notifier.save();

      verify(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).called(1);
      container.dispose();
    });

    test('addRule appends to list', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspIpv6PortServiceProvider.notifier).addRule(rule2);

      final rules =
          container.read(uspIpv6PortServiceProvider).settings.current.rules;
      expect(rules, hasLength(2));
      expect(rules[1].description, 'DNS');
      container.dispose();
    });

    test('editRule replaces by index', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1, rule2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final updated = rule1.copyWith(description: 'HTTPS');
      container.read(uspIpv6PortServiceProvider.notifier).editRule(0, updated);

      final rules =
          container.read(uspIpv6PortServiceProvider).settings.current.rules;
      expect(rules[0].description, 'HTTPS');
      expect(rules, hasLength(2));
      container.dispose();
    });

    test('toggleRule flips enabled flag', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspIpv6PortServiceProvider.notifier).toggleRule(0, false);

      final rules =
          container.read(uspIpv6PortServiceProvider).settings.current.rules;
      expect(rules[0].enabled, isFalse);
      container.dispose();
    });

    test('deleteRule removes by index', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1, rule2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspIpv6PortServiceProvider.notifier).deleteRule(0);

      final rules =
          container.read(uspIpv6PortServiceProvider).settings.current.rules;
      expect(rules, hasLength(1));
      expect(rules[0].description, 'DNS');
      container.dispose();
    });

    test('performSave rethrows ServiceError and clears isSaving', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1]);
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenThrow(const NetworkError(detail: 'save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspIpv6PortServiceProvider.notifier);
      notifier.addRule(rule2);

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(
          container.read(uspIpv6PortServiceProvider).status.isSaving, isFalse);
      container.dispose();
    });

    test('isDirty after mutation, clean after revert', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [rule1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspIpv6PortServiceProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.addRule(rule2);
      expect(notifier.isDirty(), isTrue);

      notifier.revert();
      expect(notifier.isDirty(), isFalse);
      expect(container.read(uspIpv6PortServiceProvider).settings.current.rules,
          hasLength(1));
      container.dispose();
    });
  });
}
