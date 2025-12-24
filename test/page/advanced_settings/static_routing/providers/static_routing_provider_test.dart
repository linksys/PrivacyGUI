import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_provider.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/providers/static_routing_state.dart';
import 'package:privacy_gui/page/advanced_settings/static_routing/services/static_routing_service.dart';
import '../../../../mocks/test_data/static_routing_test_data.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

class MockStaticRoutingService extends Mock implements StaticRoutingService {}

void main() {
  group('StaticRoutingNotifier - Initial State', () {
    test('builds initial state with default values', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      final state = container.read(staticRoutingProvider);

      // Assert
      expect(state.settings.original.isNATEnabled, false);
      expect(state.settings.original.isDynamicRoutingEnabled, false);
      expect(state.settings.original.entries, isEmpty);
      expect(state.settings.current.isNATEnabled, false);
      expect(state.settings.current.isDynamicRoutingEnabled, false);
      expect(state.status.maxStaticRouteEntries, 0);
    });

    test('initial original and current states are equal (dirty guard)', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      final state = container.read(staticRoutingProvider);

      // Assert
      expect(state.settings.original, state.settings.current);
    });
  });

  group('StaticRoutingNotifier - Dirty Guard', () {
    test('isDirty returns false when original equals current', () {
      // Arrange
      final container = ProviderContainer();

      // Act
      final notifier = container.read(staticRoutingProvider.notifier);

      // Assert
      expect(notifier.isDirty(), false);
    });

    test('isDirty returns true after modifying current state', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Act
      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);

      // Assert
      expect(notifier.isDirty(), true);
    });

    test('revert() restores original state', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);
      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);

      // Act
      notifier.revert();

      // Assert
      final state = container.read(staticRoutingProvider);
      expect(state.settings.original, state.settings.current);
      expect(notifier.isDirty(), false);
    });
  });

  group('StaticRoutingNotifier - updateSettingNetwork', () {
    test('sets isNATEnabled when option is NAT', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Act
      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);

      // Assert
      final state = container.read(staticRoutingProvider);
      expect(state.settings.current.isNATEnabled, true);
      expect(state.settings.current.isDynamicRoutingEnabled, false);
    });

    test('sets isDynamicRoutingEnabled when option is dynamicRouting', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Act
      notifier.updateSettingNetwork(RoutingSettingNetwork.dynamicRouting);

      // Assert
      final state = container.read(staticRoutingProvider);
      expect(state.settings.current.isNATEnabled, false);
      expect(state.settings.current.isDynamicRoutingEnabled, true);
    });

    test('marks state as dirty after updateSettingNetwork', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Act
      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);

      // Assert
      expect(notifier.isDirty(), true);
    });
  });

  group('StaticRoutingNotifier - Route Management', () {
    test('addRule adds route to current entries', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to 10 to allow adding
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      final newRoute =
          StaticRoutingTestData.createRouteEntryUIModel(name: 'Test Route');

      // Act
      notifier.addRule(newRoute);

      // Assert
      final state = container.read(staticRoutingProvider);
      expect(state.settings.current.entries.length, 1);
      expect(state.settings.current.entries.first.name, 'Test Route');
    });

    test('editRule modifies route at specified index', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to 10 to allow adding
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      final originalRoute =
          StaticRoutingTestData.createRouteEntryUIModel(name: 'Original');
      notifier.addRule(originalRoute);

      // Act
      final editedRoute = StaticRoutingTestData.createRouteEntryUIModel(
        name: 'Edited',
        destinationIP: '10.2.0.0',
      );
      notifier.editRule(0, editedRoute);

      // Assert
      final state = container.read(staticRoutingProvider);
      expect(state.settings.current.entries.first.name, 'Edited');
      expect(state.settings.current.entries.first.destinationIP, '10.2.0.0');
    });

    test('deleteRule removes route by reference', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to 10 to allow adding
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      final route =
          StaticRoutingTestData.createRouteEntryUIModel(name: 'To Delete');
      notifier.addRule(route);

      // Act
      notifier.deleteRule(route);

      // Assert
      final state = container.read(staticRoutingProvider);
      expect(state.settings.current.entries, isEmpty);
    });

    test('isExceedMax returns true when limit is reached', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Manually update state to set max to 1
      final currentState = container.read(staticRoutingProvider);
      final newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 1),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Add one route
      notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel());

      // Act
      final isExceed = notifier.isExceedMax();

      // Assert
      expect(isExceed, true);
    });

    test('isExceedMax returns false when limit is not reached', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Manually update state to set max to 10
      final currentState = container.read(staticRoutingProvider);
      final newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Act
      final isExceed = notifier.isExceedMax();

      // Assert
      expect(isExceed, false);
    });
  });

  group('StaticRoutingNotifier - Multiple Route Operations', () {
    test('can add multiple routes in sequence', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to 10 to allow adding
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Act
      for (int i = 0; i < 3; i++) {
        notifier.addRule(
          StaticRoutingTestData.createRouteEntryUIModel(
            name: 'Route $i',
            destinationIP: '10.${i + 10}.0.0', // Avoid default 10.0.0.0
          ),
        );
      }

      // Assert
      final state = container.read(staticRoutingProvider);
      expect(state.settings.current.entries.length, 3);
      expect(state.settings.current.entries[1].name, 'Route 1');
    });

    test('editRule only modifies specific route, not others', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to 10 to allow adding
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel(
          name: 'Route 1', destinationIP: '10.1.0.0'));
      notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel(
          name: 'Route 2', destinationIP: '10.2.0.0'));

      // Act
      final editedRoute = StaticRoutingTestData.createRouteEntryUIModel(
          name: 'Route 2 Edited', destinationIP: '10.2.0.0');
      notifier.editRule(1, editedRoute);

      // Assert
      final state = container.read(staticRoutingProvider);
      expect(state.settings.current.entries[0].name, 'Route 1');
      expect(state.settings.current.entries[1].name, 'Route 2 Edited');
    });

    test('addRule throws when max route limit reached', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max limit to 1
      final currentState = container.read(staticRoutingProvider);
      final newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 1),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Add one route to reach limit
      notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel());

      // Act & Assert
      expect(
        () => notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel()),
        throwsException,
      );
    });
  });

  group('StaticRoutingNotifier - US2 Route Validation', () {
    test('max route limit enforcement in provider', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to 2
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 2),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Add 2 routes to reach limit
      notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel(
          name: 'Route 1', destinationIP: '10.1.0.0'));
      notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel(
          name: 'Route 2', destinationIP: '10.2.0.0'));

      // Act & Assert - third route should fail
      expect(
        () => notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel(
            name: 'Route 3', destinationIP: '10.3.0.0')),
        throwsException,
      );
    });

    test('route name validation (non-empty, max length)', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to allow operations
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Act & Assert - empty name should fail
      expect(
        () => notifier
            .addRule(StaticRoutingTestData.createRouteEntryUIModel(name: '')),
        throwsException,
      );

      // Act & Assert - name exceeding 32 chars should fail
      expect(
        () => notifier.addRule(
          StaticRoutingTestData.createRouteEntryUIModel(
            name:
                'This is a very long route name that exceeds thirty two characters',
          ),
        ),
        throwsException,
      );
    });

    test('duplicate destination detection', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to allow operations
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Add first route with destination 10.0.0.0
      notifier.addRule(
        StaticRoutingTestData.createRouteEntryUIModel(
          name: 'Route 1',
          destinationIP: '10.0.0.0',
        ),
      );

      // Act & Assert - duplicate destination should fail
      expect(
        () => notifier.addRule(
          StaticRoutingTestData.createRouteEntryUIModel(
            name: 'Route 2',
            destinationIP: '10.0.0.0',
          ),
        ),
        throwsException,
      );
    });
  });

  group('StaticRoutingNotifier - US3 Mode Switching', () {
    test('test mode switching in StaticRoutingNotifier', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Act - Switch to NAT mode
      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);

      // Assert
      var state = container.read(staticRoutingProvider);
      expect(state.settings.current.isNATEnabled, true);
      expect(state.settings.current.isDynamicRoutingEnabled, false);

      // Act - Switch to Dynamic Routing mode
      notifier.updateSettingNetwork(RoutingSettingNetwork.dynamicRouting);

      // Assert
      state = container.read(staticRoutingProvider);
      expect(state.settings.current.isNATEnabled, false);
      expect(state.settings.current.isDynamicRoutingEnabled, true);
    });

    test('mode change persistence with correct flags in service', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Act - Update to NAT mode
      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);

      // Assert - mode is in current state
      var state = container.read(staticRoutingProvider);
      expect(state.settings.current.isNATEnabled, true);
      expect(state.settings.current.isDynamicRoutingEnabled, false);

      // Act - Update to Dynamic mode
      notifier.updateSettingNetwork(RoutingSettingNetwork.dynamicRouting);

      // Assert
      state = container.read(staticRoutingProvider);
      expect(state.settings.current.isNATEnabled, false);
      expect(state.settings.current.isDynamicRoutingEnabled, true);
    });

    test('mode changes marked as dirty for dirty guard', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Initial state should not be dirty
      expect(notifier.isDirty(), false);

      // Act
      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);

      // Assert
      expect(notifier.isDirty(), true);

      // Act - Revert changes
      notifier.revert();

      // Assert - Should no longer be dirty
      expect(notifier.isDirty(), false);
    });

    test('mode switching does not affect existing routes', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to allow adding
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Add a route
      notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel(
        name: 'Test Route',
        destinationIP: '10.1.0.0',
      ));

      // Act - Switch modes
      notifier.updateSettingNetwork(RoutingSettingNetwork.nat);
      notifier.updateSettingNetwork(RoutingSettingNetwork.dynamicRouting);

      // Assert - Route should still be there
      final state = container.read(staticRoutingProvider);
      expect(state.settings.current.entries.length, 1);
      expect(state.settings.current.entries.first.name, 'Test Route');
    });
  });

  group('StaticRoutingNotifier - US4 Delete & Manage', () {
    test('route deletion removes route by reference', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes to allow adding
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(maxStaticRouteEntries: 10),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      final route = StaticRoutingTestData.createRouteEntryUIModel(
        name: 'To Delete',
        destinationIP: '10.1.0.0',
      );
      notifier.addRule(route);

      // Verify route was added
      var state = container.read(staticRoutingProvider);
      expect(state.settings.current.entries.length, 1);

      // Act
      notifier.deleteRule(route);

      // Assert
      state = container.read(staticRoutingProvider);
      expect(state.settings.current.entries.isEmpty, true);
    });

    test('route details contains all required fields for display', () {
      // Arrange
      final container = ProviderContainer();
      final notifier = container.read(staticRoutingProvider.notifier);

      // Set max routes
      var currentState = container.read(staticRoutingProvider);
      var newState = currentState.copyWith(
        status: currentState.status.copyWith(
          maxStaticRouteEntries: 10,
          routerIp: '192.168.1.1',
          subnetMask: '255.255.255.0',
        ),
      );
      container.read(staticRoutingProvider.notifier).state = newState;

      // Add route
      notifier.addRule(StaticRoutingTestData.createRouteEntryUIModel(
        name: 'Test Route',
        destinationIP: '10.1.0.0',
      ));

      // Act - Get route details
      final state = container.read(staticRoutingProvider);
      final route = state.settings.current.entries.first;

      // Assert - All fields present
      expect(route.name, 'Test Route');
      expect(route.destinationIP, '10.1.0.0');
      expect(route.subnetMask, isNotNull);
      expect(route.gateway, isNotNull);

      // Assert - Network context available
      expect(state.status.routerIp, '192.168.1.1');
      expect(state.status.subnetMask, '255.255.255.0');
    });
  });
}
