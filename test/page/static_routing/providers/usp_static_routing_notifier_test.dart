import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
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
    when(() => mockService.mapDisplayToInterface(any()))
        .thenAnswer((inv) => inv.positionalArguments[0] as String);
  });

  ProviderContainer createContainer({Stream<InvalidationEvent>? sse}) {
    final container = ProviderContainer(
      overrides: [
        uspStaticRoutingServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        if (sse != null) sseInvalidationProvider.overrideWith((_) => sse),
      ],
    );
    container.listen(uspStaticRoutingProvider, (_, __) {});
    return container;
  }

  group('UspStaticRoutingNotifier', () {
    test('build returns initial loading state', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final container = createContainer();

      final state = container.read(uspStaticRoutingProvider);
      expect(state.status.isLoading, isTrue);
      expect(state.settings.current.routes, isEmpty);
      await Future.delayed(Duration.zero);
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
      when(() => mockService.fetch())
          .thenThrow(const NetworkError(detail: 'connection lost'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspStaticRoutingProvider);
      expect(state.status.error, isA<NetworkError>());
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

    test('performSave rethrows ServiceError and clears isSaving', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenThrow(const NetworkError(detail: 'save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspStaticRoutingProvider.notifier);
      notifier.addRoute(route2);

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(container.read(uspStaticRoutingProvider).status.isSaving, isFalse);
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

  // -------------------------------------------------------------------------
  // SSE invalidation (#1501)
  //
  // `sseInvalidationProvider` emits `({InvalidationDomain domain, int seq})`.
  // This notifier reads `.domain` and ignores `seq`, whose only job is to keep
  // two consecutive events for the *same* domain unequal — without it,
  // riverpod 3.x's `==`-based `updateShouldNotify` collapses the second one and
  // the repeat below stops re-fetching. So the repeat is the assertion that
  // pins the tag end-to-end at the consumer, not just at the producer.
  //
  // The negative test is the other half: a listener whose comparison is
  // accidentally always-true (e.g. the domain operand dropped) re-fetches on
  // every unrelated SSE arrival and would pass the positive test alone.
  // -------------------------------------------------------------------------
  group('UspStaticRoutingNotifier SSE invalidation', () {
    test('staticRouting domain re-fetches, and a repeat re-fetches again',
        () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final sse = StreamController<InvalidationEvent>();
      final container = createContainer(sse: sse.stream);
      await Future.delayed(Duration.zero);

      // Drop the build() fetch so the counting below starts from zero.
      verify(() => mockService.fetch()).called(1);
      clearInteractions(mockService);

      sse.add((domain: InvalidationDomain.staticRouting, seq: 0));
      await Future.delayed(Duration.zero);
      verify(() => mockService.fetch()).called(1);

      // Same domain again — e.g. the user adds a second route from another
      // client. `seq` is the only thing that differs.
      sse.add((domain: InvalidationDomain.staticRouting, seq: 1));
      await Future.delayed(Duration.zero);
      verify(() => mockService.fetch()).called(1);

      await sse.close();
      container.dispose();
    });

    test('a neighbouring domain does not re-fetch', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final sse = StreamController<InvalidationEvent>();
      final container = createContainer(sse: sse.stream);
      await Future.delayed(Duration.zero);
      clearInteractions(mockService);

      // Routes carry an `interfacePath` under Device.Ethernet.Interface., so
      // ethernetInterfaces is the plausible-but-wrong neighbour here.
      sse.add((domain: InvalidationDomain.ethernetInterfaces, seq: 0));
      await Future.delayed(Duration.zero);

      verifyNever(() => mockService.fetch());

      await sse.close();
      container.dispose();
    });

    test('a matching domain does not re-fetch while dirty', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final sse = StreamController<InvalidationEvent>();
      final container = createContainer(sse: sse.stream);
      await Future.delayed(Duration.zero);
      clearInteractions(mockService);

      container.read(uspStaticRoutingProvider.notifier).addRoute(route2);
      sse.add((domain: InvalidationDomain.staticRouting, seq: 0));
      await Future.delayed(Duration.zero);

      // onSseInvalidation() skips while dirty so an external change cannot
      // clobber unsaved edits.
      verifyNever(() => mockService.fetch());
      expect(container.read(uspStaticRoutingProvider).settings.current.routes,
          hasLength(2));

      await sse.close();
      container.dispose();
    });
  });
}
