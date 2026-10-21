import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
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

  ProviderContainer createContainer({
    Stream<InvalidationEvent>? sse,
    bool offersRip = false,
  }) {
    final container = ProviderContainer(
      overrides: [
        deviceCapabilitiesProvider.overrideWithValue(DeviceCapabilities({
          if (offersRip) DeviceCapability.dynamicRouting,
        })),
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

  // ---------------------------------------------------------------------------
  // FWDEV#213 (#1100): the NAT / Dynamic routing radio and the list checks
  // ---------------------------------------------------------------------------

  group('UspStaticRoutingNotifier — NAT / Dynamic routing', () {
    void answerSave() {
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async => (added: 0, updated: 0, deleted: 0));
      when(() => mockService.saveRipEnabled(any())).thenAnswer((_) async {});
    }

    test('a router with RIP reads the switch with the routes', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      when(() => mockService.fetchRipEnabled()).thenAnswer((_) async => true);
      final container = createContainer(offersRip: true);
      await Future.delayed(Duration.zero);

      final settings = container.read(uspStaticRoutingProvider).settings;
      expect(settings.current.ripEnabled, isTrue);
      expect(settings.current.routes, [route1]);
      container.dispose();
    });

    test('a router without RIP never reads it and has no switch', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      expect(
          container.read(uspStaticRoutingProvider).settings.current.ripEnabled,
          isNull);
      verifyNever(() => mockService.fetchRipEnabled());
      container.dispose();
    });

    test('a failed RIP read is the page load error, not a missing switch',
        () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      when(() => mockService.fetchRipEnabled())
          .thenThrow(const NetworkError(detail: 'not read'));
      final container = createContainer(offersRip: true);
      await Future.delayed(Duration.zero);

      expect(container.read(uspStaticRoutingProvider).status.error,
          isA<NetworkError>());
      container.dispose();
    });

    test(
        'choosing Dynamic routing makes the page dirty; choosing NAT back '
        'makes it clean', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      when(() => mockService.fetchRipEnabled()).thenAnswer((_) async => false);
      final container = createContainer(offersRip: true);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.setRipEnabled(true);
      expect(notifier.isDirty(), isTrue);

      notifier.setRipEnabled(false);
      expect(notifier.isDirty(), isFalse);
      container.dispose();
    });

    test('a route edit keeps a pending NAT / Dynamic routing choice', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1, route2]);
      when(() => mockService.fetchRipEnabled()).thenAnswer((_) async => false);
      final container = createContainer(offersRip: true);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.setRipEnabled(true);
      notifier.addRoute(route1.copyWith(name: 'Added'));
      notifier.editRoute(0, route1.copyWith(name: 'Edited'));
      notifier.toggleRoute(1, true);
      notifier.deleteRoute(2);

      expect(
          container.read(uspStaticRoutingProvider).settings.current.ripEnabled,
          isTrue);
      container.dispose();
    });

    test('a changed switch is saved in one Set, after the routes', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      when(() => mockService.fetchRipEnabled()).thenAnswer((_) async => false);
      answerSave();
      final container = createContainer(offersRip: true);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.setRipEnabled(true);
      await notifier.save();

      verifyInOrder([
        () => mockService.saveBatch(
              original: any(named: 'original'),
              current: any(named: 'current'),
            ),
        () => mockService.saveRipEnabled(true),
      ]);
      container.dispose();
    });

    test('an unchanged switch is not written', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      when(() => mockService.fetchRipEnabled()).thenAnswer((_) async => false);
      answerSave();
      final container = createContainer(offersRip: true);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.toggleRoute(0, false);
      await notifier.save();

      verifyNever(() => mockService.saveRipEnabled(any()));
      container.dispose();
    });
  });

  group('UspStaticRoutingNotifier — list checks before the save', () {
    StaticRouteUIModel unsaved(String name) => StaticRouteUIModel(
          enabled: true,
          name: name,
          destIpAddress: '10.30.0.0',
          destSubnetMask: '255.255.0.0',
          gatewayIpAddress: '192.168.1.50',
          interfaceName: 'LAN',
        );

    test('two unsaved routes with one name send nothing', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.addRoute(unsaved('New'));
      notifier.addRoute(unsaved('New'));

      await expectLater(
        notifier.save(),
        throwsA(isA<InvalidInputError>().having(
            (e) => e.field, 'field', StaticRoutingErrorKeys.duplicateName)),
      );
      verifyNever(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          ));
      expect(notifier.isDirty(), isTrue);
      container.dispose();
    });

    test('a 21st route sends nothing', () async {
      final saved = [
        for (var i = 1; i <= 20; i++)
          route1.copyWith(
            instancePath: 'Device.Routing.Router.1.IPv4Forwarding.$i.',
            name: 'Route $i',
          ),
      ];
      when(() => mockService.fetch()).thenAnswer((_) async => saved);
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.addRoute(unsaved('Route 21'));

      await expectLater(
        notifier.save(),
        throwsA(isA<InvalidInputError>().having(
            (e) => e.field, 'field', StaticRoutingErrorKeys.tooManyRoutes)),
      );
      verifyNever(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          ));
      container.dispose();
    });
  });

  // A failed save may still have written: a refused Set keeps the leaves it
  // took (bench 2026-10-21), and steps before the failing one landed. The
  // page reads the router back and shows it only if it changed.
  group('UspStaticRoutingNotifier — a failed save', () {
    void refuseSave() {
      when(() => mockService.saveBatch(
                original: any(named: 'original'),
                current: any(named: 'current'),
              ))
          .thenThrow(const InvalidInputError(
              field: 'ErrorInvalidIPAddress', code: 7012));
    }

    test('that changed the router shows what the router now holds', () async {
      final answers = [
        [route1],
        // The refused Edit's rename landed, its destination did not.
        [route1.copyWith(name: 'Renamed')],
      ];
      when(() => mockService.fetch())
          .thenAnswer((_) async => answers.removeAt(0));
      refuseSave();
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.editRoute(
          0, route1.copyWith(name: 'Renamed', destIpAddress: '127.0.0.0'));

      await expectLater(
        notifier.save(),
        throwsA(isA<InvalidInputError>()
            .having((e) => e.field, 'field', 'ErrorInvalidIPAddress')),
      );
      final settings = container.read(uspStaticRoutingProvider).settings;
      expect(settings.current.routes.single.name, 'Renamed');
      expect(settings.current.routes.single.destIpAddress, '10.0.0.0');
      expect(notifier.isDirty(), isFalse);
      container.dispose();
    });

    test('that wrote nothing keeps the edits for a retry', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [route1]);
      refuseSave();
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.editRoute(0, route1.copyWith(destIpAddress: '10.9.0.0'));

      await expectLater(notifier.save(), throwsA(isA<InvalidInputError>()));
      verify(() => mockService.fetch()).called(2);
      expect(
          container
              .read(uspStaticRoutingProvider)
              .settings
              .current
              .routes
              .single
              .destIpAddress,
          '10.9.0.0');
      expect(notifier.isDirty(), isTrue);
      container.dispose();
    });

    test('whose read-back fails keeps the edits, with no load error', () async {
      var reads = 0;
      when(() => mockService.fetch()).thenAnswer((_) async {
        if (++reads > 1) throw const NetworkError(detail: 'offline');
        return [route1];
      });
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenThrow(const NetworkError(detail: 'offline'));
      final container = createContainer();
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.editRoute(0, route1.copyWith(destIpAddress: '10.9.0.0'));

      await expectLater(notifier.save(), throwsA(isA<NetworkError>()));
      final state = container.read(uspStaticRoutingProvider);
      expect(state.status.error, isNull);
      expect(notifier.isDirty(), isTrue);
      container.dispose();
    });

    // The routes went in before the switch was refused: shown with their
    // instance paths, so a second Save does not Add them again.
    test('of the switch after routes were added shows the added routes',
        () async {
      final added = route2.copyWith(
          instancePath: 'Device.Routing.Router.1.IPv4Forwarding.7.');
      final answers = [
        [route1],
        [route1, added],
      ];
      when(() => mockService.fetch())
          .thenAnswer((_) async => answers.removeAt(0));
      when(() => mockService.fetchRipEnabled()).thenAnswer((_) async => false);
      when(() => mockService.saveBatch(
            original: any(named: 'original'),
            current: any(named: 'current'),
          )).thenAnswer((_) async => (added: 1, updated: 0, deleted: 0));
      when(() => mockService.saveRipEnabled(any()))
          .thenThrow(const NetworkError(detail: 'refused'));
      final container = createContainer(offersRip: true);
      await Future.delayed(Duration.zero);
      final notifier = container.read(uspStaticRoutingProvider.notifier);

      notifier.addRoute(StaticRouteUIModel(
        enabled: route2.enabled,
        name: route2.name,
        destIpAddress: route2.destIpAddress,
        destSubnetMask: route2.destSubnetMask,
        gatewayIpAddress: route2.gatewayIpAddress,
        interfaceName: route2.interfaceName,
      ));
      notifier.setRipEnabled(true);

      await expectLater(notifier.save(), throwsA(isA<NetworkError>()));
      final current = container.read(uspStaticRoutingProvider).settings.current;
      expect(current.routes.last.instancePath, added.instancePath);
      expect(current.ripEnabled, isFalse);
      container.dispose();
    });
  });
}
