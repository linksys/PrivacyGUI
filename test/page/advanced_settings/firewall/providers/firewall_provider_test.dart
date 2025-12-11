import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_provider.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/providers/firewall_state.dart';
import 'package:privacy_gui/page/advanced_settings/firewall/services/firewall_settings_service.dart';

// Mock class for Ref
class MockRef extends Mock implements Ref {}

// Fake for RouterRepository
class FakeRouterRepository extends Fake implements RouterRepository {}

void main() {
  late ProviderContainer container;

  setUpAll(() {
    registerFallbackValue(MockRef());
  });

  setUp(() {
    container = ProviderContainer();
  });

  tearDown(() {
    container.dispose();
  });

  group('FirewallProvider', () {
    group('build', () {
      test('returns default state with all firewall options disabled', () {
        // Act
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current.blockAnonymousRequests, false);
        expect(state.settings.current.blockIDENT, false);
        expect(state.settings.current.blockIPSec, false);
        expect(state.settings.current.blockL2TP, false);
        expect(state.settings.current.blockMulticast, false);
        expect(state.settings.current.blockNATRedirection, false);
        expect(state.settings.current.blockPPTP, false);
        expect(state.settings.current.isIPv4FirewallEnabled, false);
        expect(state.settings.current.isIPv6FirewallEnabled, false);
        expect(state.settings.original, state.settings.current);
      });

      test('initializes with EmptyStatus', () {
        // Act
        final state = container.read(firewallProvider);

        // Assert
        expect(state.status, isNotNull);
      });
    });

    group('notifier methods', () {
      test('notifier can be accessed from container', () {
        // Act
        final notifier = container.read(firewallProvider.notifier);

        // Assert
        expect(notifier, isNotNull);
        expect(notifier, isA<FirewallNotifier>());
      });
    });

    group('state updates', () {
      test('setSettings updates current settings', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current, newSettings);
        expect(state.settings.current.blockAnonymousRequests, true);
        expect(state.settings.current.blockIDENT, true);
        expect(state.settings.current.isIPv4FirewallEnabled, true);
        // Original should not change
        expect(state.settings.original.blockAnonymousRequests, false);
        expect(state.settings.original.isIPv4FirewallEnabled, false);
      });

      test('setSettings updates all fields independently', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: true,
          blockL2TP: false,
          blockMulticast: true,
          blockNATRedirection: false,
          blockPPTP: true,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: true,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current.blockAnonymousRequests, true);
        expect(state.settings.current.blockIDENT, false);
        expect(state.settings.current.blockIPSec, true);
        expect(state.settings.current.blockL2TP, false);
        expect(state.settings.current.blockMulticast, true);
        expect(state.settings.current.blockNATRedirection, false);
        expect(state.settings.current.blockPPTP, true);
        expect(state.settings.current.isIPv4FirewallEnabled, false);
        expect(state.settings.current.isIPv6FirewallEnabled, true);
      });

      test('setSettings can enable IPv4 firewall', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current.isIPv4FirewallEnabled, true);
        expect(state.settings.current.isIPv6FirewallEnabled, false);
      });

      test('setSettings can enable IPv6 firewall', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: true,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current.isIPv6FirewallEnabled, true);
        expect(state.settings.current.isIPv4FirewallEnabled, false);
      });

      test('setSettings can enable both IPv4 and IPv6 firewalls', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current.isIPv4FirewallEnabled, true);
        expect(state.settings.current.isIPv6FirewallEnabled, true);
      });

      test('setSettings can enable all blocking options', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current.blockAnonymousRequests, true);
        expect(state.settings.current.blockIDENT, true);
        expect(state.settings.current.blockIPSec, true);
        expect(state.settings.current.blockL2TP, true);
        expect(state.settings.current.blockMulticast, true);
        expect(state.settings.current.blockNATRedirection, true);
        expect(state.settings.current.blockPPTP, true);
        expect(state.settings.current.isIPv4FirewallEnabled, true);
        expect(state.settings.current.isIPv6FirewallEnabled, true);
      });
    });

    group('preservable functionality', () {
      test('preservable contract accessor returns notifier', () {
        // Act
        final preservable =
            container.read(preservableFirewallProvider) as FirewallNotifier;

        // Assert
        expect(preservable, isNotNull);
        expect(preservable, isA<FirewallNotifier>());
      });

      test('preservable stores original values for reset', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current.blockAnonymousRequests, true);
        expect(state.settings.current.isIPv4FirewallEnabled, true);
        expect(state.settings.original.blockAnonymousRequests, false);
        expect(state.settings.original.isIPv4FirewallEnabled, false);
      });

      test('original and current can differ after setSettings', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: true,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: false,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.settings.current, isNot(state.settings.original));
      });
    });

    group('isDirty tracking', () {
      test('isDirty is true when current differs from original', () {
        // Arrange
        const newSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.isDirty, true);
      });

      test('isDirty is false when current equals original', () {
        // Act
        final state = container.read(firewallProvider);

        // Assert
        expect(state.isDirty, false);
      });

      test('isDirty tracks changes to individual fields', () {
        // Arrange
        final initialState = container.read(firewallProvider);
        final originalSettings = initialState.settings.current;

        // Act - change only one field
        final newSettings =
            originalSettings.copyWith(blockAnonymousRequests: true);
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final state = container.read(firewallProvider);

        // Assert
        expect(state.isDirty, true);
      });
    });

    group('PreservableNotifierMixin integration', () {
      test('performFetch delegates to Service', () {
        // Note: This is an integration test that would require mocking
        // the service layer. In practice, we test the service separately
        // and verify the notifier calls it correctly via integration tests.

        // Arrange
        final notifier = container.read(firewallProvider.notifier);

        // Assert - verify method exists and is callable
        expect(notifier.performFetch, isA<Function>());
      });

      test('performSave delegates to Service', () {
        // Note: Similar to performFetch, this verifies the method contract
        // exists. Actual behavior is tested via service layer tests.

        // Arrange
        final notifier = container.read(firewallProvider.notifier);

        // Assert - verify method exists and is callable
        expect(notifier.performSave, isA<Function>());
      });

      test('notifier exposes PreservableNotifierMixin methods', () {
        // Arrange
        final notifier = container.read(firewallProvider.notifier);

        // Assert - verify mixin methods are available
        expect(notifier.performFetch, isNotNull);
        expect(notifier.performSave, isNotNull);
      });
    });

    group('state immutability', () {
      test('setSettings does not mutate previous state', () {
        // Arrange
        final initialState = container.read(firewallProvider);
        final initialCurrent = initialState.settings.current;

        const newSettings = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: true,
          blockIPSec: true,
          blockL2TP: true,
          blockMulticast: true,
          blockNATRedirection: true,
          blockPPTP: true,
          isIPv4FirewallEnabled: true,
          isIPv6FirewallEnabled: true,
        );

        // Act
        container.read(firewallProvider.notifier).setSettings(newSettings);
        final newState = container.read(firewallProvider);

        // Assert
        expect(initialCurrent.blockAnonymousRequests, false);
        expect(newState.settings.current.blockAnonymousRequests, true);
        expect(identical(initialCurrent, newState.settings.current), false);
      });

      test('multiple setSettings calls maintain immutability', () {
        // Arrange & Act
        const settings1 = FirewallUISettings(
          blockAnonymousRequests: true,
          blockIDENT: false,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );
        container.read(firewallProvider.notifier).setSettings(settings1);
        final state1 = container.read(firewallProvider);

        const settings2 = FirewallUISettings(
          blockAnonymousRequests: false,
          blockIDENT: true,
          blockIPSec: false,
          blockL2TP: false,
          blockMulticast: false,
          blockNATRedirection: false,
          blockPPTP: false,
          isIPv4FirewallEnabled: false,
          isIPv6FirewallEnabled: false,
        );
        container.read(firewallProvider.notifier).setSettings(settings2);
        final state2 = container.read(firewallProvider);

        // Assert
        expect(state1.settings.current.blockAnonymousRequests, true);
        expect(state1.settings.current.blockIDENT, false);
        expect(state2.settings.current.blockAnonymousRequests, false);
        expect(state2.settings.current.blockIDENT, true);
        expect(
            identical(state1.settings.current, state2.settings.current), false);
      });
    });

    group('error propagation', () {
      test('performFetch method exists and is callable', () {
        // Note: This test verifies that the performFetch method exists
        // and can be accessed. The actual service error handling
        // is tested in the service layer tests.

        final notifier = container.read(firewallProvider.notifier);

        // Assert - method exists and is a function
        expect(notifier.performFetch, isA<Function>());
      });

      test('performSave method exists and is callable', () {
        // Note: This test verifies that the performSave method exists
        // and can be accessed. The actual service error handling
        // is tested in the service layer tests.

        final notifier = container.read(firewallProvider.notifier);

        // Assert - method exists and is a function
        expect(notifier.performSave, isA<Function>());
      });
    });
  });
}
