import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/static_routing/models/static_routing_ui_model.dart';
import 'package:privacy_gui/page/static_routing/providers/usp_static_routing_notifier.dart';
import 'package:privacy_gui/page/static_routing/services/usp_static_routing_service.dart';

class MockUspStaticRoutingService extends Mock
    implements UspStaticRoutingService {}

void main() {
  late MockUspStaticRoutingService mockService;

  final route1 = StaticRouteUIModel(
    instancePath: 'Device.Routing.Router.1.IPv4Forwarding.1.',
    enabled: true,
    name: 'Office',
    destIpAddress: '10.0.0.0',
    destSubnetMask: '255.255.255.0',
    gatewayIpAddress: '192.168.1.1',
    interfaceName: 'eth0',
    interfacePath: 'Device.Ethernet.Interface.2.',
  );
  final route2 = StaticRouteUIModel(
    instancePath: 'Device.Routing.Router.1.IPv4Forwarding.2.',
    enabled: false,
    name: 'VPN',
    destIpAddress: '172.16.0.0',
    destSubnetMask: '255.255.0.0',
    gatewayIpAddress: '192.168.1.254',
    interfaceName: 'eth0',
    interfacePath: 'Device.Ethernet.Interface.2.',
  );

  setUpAll(() {
    registerFallbackValue(<StaticRouteUIModel>[]);
  });

  setUp(() {
    mockService = MockUspStaticRoutingService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspStaticRoutingServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(uspStaticRoutingProvider, (_, __) {});
    return container;
  }

  group('UspStaticRoutingNotifier', () {
    test('build returns initial loading state', () {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final container = createContainer();

      final state = container.read(uspStaticRoutingProvider);
      expect(state.status.isLoading, isTrue);
      expect(state.settings.current.routes, isEmpty);
      container.dispose();
    });

    test('fetch success populates routes', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1, route2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspStaticRoutingProvider);
      expect(state.settings.current.routes, hasLength(2));
      expect(state.settings.current.routes[0].name, 'Office');
      expect(state.settings.current.routes[1].enabled, isFalse);
      container.dispose();
    });

    test('fetch error sets error status', () async {
      when(() => mockService.fetch()).thenThrow(Exception('connection lost'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspStaticRoutingProvider);
      expect(state.status.errorMessage, contains('connection lost'));
      expect(state.settings.current.routes, isEmpty);
      container.dispose();
    });

    test('performSave calls saveBatch', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async => (added: 1, updated: 0, deleted: 0));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspStaticRoutingProvider.notifier);
      notifier.addRoute(route2);
      await notifier.save();

      verify(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).called(1);
      container.dispose();
    });

    test('addRoute appends to list', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspStaticRoutingProvider.notifier).addRoute(route2);

      final routes =
          container.read(uspStaticRoutingProvider).settings.current.routes;
      expect(routes, hasLength(2));
      expect(routes[1].name, 'VPN');
      container.dispose();
    });

    test('editRoute replaces by index', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1, route2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final updated = route1.copyWith(name: 'Updated');
      container.read(uspStaticRoutingProvider.notifier).editRoute(0, updated);

      final routes =
          container.read(uspStaticRoutingProvider).settings.current.routes;
      expect(routes[0].name, 'Updated');
      expect(routes, hasLength(2));
      container.dispose();
    });

    test('toggleRoute flips enabled flag', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspStaticRoutingProvider.notifier).toggleRoute(0, false);

      final routes =
          container.read(uspStaticRoutingProvider).settings.current.routes;
      expect(routes[0].enabled, isFalse);
      container.dispose();
    });

    test('deleteRoute removes by index', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1, route2]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container.read(uspStaticRoutingProvider.notifier).deleteRoute(0);

      final routes =
          container.read(uspStaticRoutingProvider).settings.current.routes;
      expect(routes, hasLength(1));
      expect(routes[0].name, 'VPN');
      container.dispose();
    });

    test('isDirty after mutation, clean after revert', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspStaticRoutingProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.addRoute(route2);
      expect(notifier.isDirty(), isTrue);

      notifier.revert();
      expect(notifier.isDirty(), isFalse);
      expect(container.read(uspStaticRoutingProvider).settings.current.routes,
          hasLength(1));
      container.dispose();
    });
  });
}
