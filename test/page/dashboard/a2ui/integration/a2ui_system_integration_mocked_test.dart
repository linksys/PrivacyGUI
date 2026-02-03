import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/models/device.dart';
import 'package:privacy_gui/page/dashboard/a2ui/loader/json_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_constraints.dart';
import 'package:privacy_gui/page/dashboard/a2ui/models/a2ui_widget_definition.dart';
import 'package:privacy_gui/page/dashboard/a2ui/registry/a2ui_widget_registry.dart';
import 'package:privacy_gui/page/dashboard/a2ui/renderer/a2ui_widget_renderer.dart';
import 'package:privacy_gui/page/dashboard/a2ui/resolver/jnap_data_resolver.dart';
import 'package:privacy_gui/page/dashboard/a2ui/validator/a2ui_constraint_validator.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_state.dart';
import 'package:ui_kit_library/ui_kit.dart';

// Import mocks
import '../../../../mocks/dashboard_home_notifier_mocks.dart';
import '../../../../mocks/device_manager_notifier_mocks.dart';

/// Enhanced A2UI System Integration Tests using proper mocks for better test isolation.
/// This version uses the established mock notifiers from test/mocks/ directory
/// to ensure predictable, fast, and isolated testing.
void main() {
  group('A2UI System Integration Tests (Mocked)', () {
    late ProviderContainer container;
    late MockDashboardHomeNotifier mockDashboardHomeNotifier;
    late MockDeviceManagerNotifier mockDeviceManagerNotifier;

    setUp(() {
      // Initialize mocks
      mockDashboardHomeNotifier = MockDashboardHomeNotifier();
      mockDeviceManagerNotifier = MockDeviceManagerNotifier();

      // Set up mock behavior
      _setupMockBehavior(mockDashboardHomeNotifier, mockDeviceManagerNotifier);

      // Create container with mocked providers
      container = ProviderContainer(
        overrides: [
          dashboardHomeProvider.overrideWith(() => mockDashboardHomeNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('Mocked Data Resolution Integration', () {
      testWidgets(
          'resolver integrates with mocked providers for predictable data',
          (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: const Scaffold(
                body: A2UIWidgetRenderer(
                  widgetId: 'test-data-binding-widget',
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Should render without crashing using mocked data
        expect(find.byType(Scaffold), findsOneWidget);
        // Note: Error icon may appear for unregistered widget - that's expected test behavior
      });

      test('resolver returns mocked data consistently', () {
        final resolver =
            container.read(jnapDataResolverProvider) as JnapDataResolver;

        final deviceCount = resolver.resolve('router.deviceCount');
        final nodeCount = resolver.resolve('router.nodeCount');
        final wanStatus = resolver.resolve('router.wanStatus');
        final uptime = resolver.resolve('router.uptime');
        final ssid = resolver.resolve('wifi.ssid');

        // Verify types and that mocked data is returned
        expect(deviceCount, isA<String>()); // String
        expect(nodeCount, isA<String>()); // String
        expect(wanStatus, isA<String>());
        expect(uptime, isA<String>());
        expect(ssid, isA<String>());

        // Verify consistent mocked values (with empty device list)
        expect(
            deviceCount, equals('0')); // From empty mock device list (String)
        expect(nodeCount, equals('0')); // From empty mock device list (String)
        expect(wanStatus, isA<String>()); // Should be a valid string
      });

      test('mocked providers handle watch() correctly', () {
        final resolver =
            container.read(jnapDataResolverProvider) as JnapDataResolver;

        final deviceCountWatch = resolver.watch('router.deviceCount');
        final wanStatusWatch = resolver.watch('router.wanStatus');

        if (deviceCountWatch != null) {
          final currentValue = container.read(deviceCountWatch);
          expect(currentValue, isA<String>()); // String
          expect(currentValue,
              equals('0')); // From empty mock device list (String)
        }

        if (wanStatusWatch != null) {
          final currentValue = container.read(wanStatusWatch);
          expect(currentValue, isA<String>());
          expect(currentValue, isA<String>()); // Should be a valid string
        }
      });
    });

    group('Widget Registry with Mocked Environment', () {
      test('registry operates independently of mocked providers', () {
        final registry = container.read(a2uiWidgetRegistryProvider);

        // Registry should work normally regardless of mocked environment
        final testWidget = A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'mocked_test_widget',
          'displayName': 'Mocked Test Widget',
          'constraints': {
            'minColumns': 2,
            'maxColumns': 4,
            'preferredColumns': 3,
            'minRows': 1,
            'maxRows': 2,
            'preferredRows': 1,
          },
          'template': {
            'type': 'Container',
            'children': [],
          },
        });

        registry.register(testWidget);
        final retrieved = registry.get('mocked_test_widget');

        expect(retrieved, isNotNull);
        expect(retrieved!.widgetId, 'mocked_test_widget');
        expect(retrieved.displayName, 'Mocked Test Widget');
      });

      test('validator works correctly with mocked environment', () {
        final registry = container.read(a2uiWidgetRegistryProvider);
        final validator = A2UIConstraintValidator(registry);

        final testWidget = A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'mocked_validator_test',
          'displayName': 'Mocked Validator Test',
          'constraints': {
            'minColumns': 2,
            'maxColumns': 6,
            'preferredColumns': 4,
            'minRows': 1,
            'maxRows': 3,
            'preferredRows': 2,
          },
          'template': {'type': 'Container', 'children': []},
        });

        registry.register(testWidget);

        // Test validation in mocked environment
        final validResult = validator.validateResize(
          widgetId: 'mocked_validator_test',
          newColumns: 3,
          newRows: 2,
        );

        expect(validResult.isValid, isTrue);

        final invalidResult = validator.validateResize(
          widgetId: 'mocked_validator_test',
          newColumns: 1, // Below minimum
          newRows: 2,
        );

        expect(invalidResult.isValid, isFalse);
        expect(invalidResult.messages, isNotEmpty);
      });
    });

    group('Mock Behavior Verification', () {
      test('dashboard home notifier mock is properly configured', () {
        // Trigger mock usage by reading from resolver
        final resolver =
            container.read(jnapDataResolverProvider) as JnapDataResolver;
        resolver.resolve(
            'router.wanStatus'); // This should trigger dashboard home provider

        final state = mockDashboardHomeNotifier.state;
        expect(state, isA<DashboardHomeState>());
        expect(state.wanType, equals('ethernet')); // From our mock setup
      });

      test('device manager notifier mock is properly configured', () {
        // Trigger mock usage by reading from resolver
        final resolver =
            container.read(jnapDataResolverProvider) as JnapDataResolver;
        resolver.resolve(
            'router.deviceCount'); // This should trigger device manager provider

        final state = mockDeviceManagerNotifier.state;
        expect(state, isA<DeviceManagerState>());
        expect(state.deviceList, isEmpty); // From our mock setup (empty list)
      });

      test('mocked data provides stable test environment', () {
        final resolver =
            container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Multiple calls should return consistent mocked values
        for (int i = 0; i < 5; i++) {
          expect(resolver.resolve('router.deviceCount'), equals('0'));
          expect(resolver.resolve('router.nodeCount'), equals('0'));
          expect(resolver.resolve('router.wanStatus'), isA<String>());
        }
      });
    });

    group('End-to-End with Mocked Providers', () {
      testWidgets('complete widget rendering flow with mocked data',
          (tester) async {
        // Register a test widget that uses data binding
        final registry = container.read(a2uiWidgetRegistryProvider);
        final dataWidget = A2UIWidgetDefinition.fromJson(const {
          'widgetId': 'mocked_data_widget',
          'displayName': 'Mocked Data Widget',
          'constraints': {
            'minColumns': 2,
            'maxColumns': 4,
            'preferredColumns': 3,
            'minRows': 1,
            'maxRows': 2,
            'preferredRows': 1,
          },
          'template': {
            'type': 'Column',
            'children': [
              {
                'type': 'AppText',
                'properties': {
                  'text': {r'$bind': 'router.deviceCount'},
                },
              },
            ],
          },
        });

        registry.register(dataWidget);

        await tester.pumpWidget(
          ProviderScope(
            parent: container,
            child: MaterialApp(
              theme: _createTestThemeData(),
              home: const Scaffold(
                body: A2UIWidgetRenderer(
                  widgetId: 'mocked_data_widget',
                ),
              ),
            ),
          ),
        );

        await tester.pump(const Duration(milliseconds: 100));

        // Give time for widget rendering
        for (int i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Should render successfully with mocked data
        expect(find.byType(Column), findsOneWidget);
        expect(find.byIcon(Icons.error_outline), findsNothing);
      });
    });

    group('Performance with Mocked Environment', () {
      test('mocked providers enable fast test execution', () {
        final stopwatch = Stopwatch()..start();

        final resolver =
            container.read(jnapDataResolverProvider) as JnapDataResolver;

        // Perform multiple operations
        for (int i = 0; i < 100; i++) {
          resolver.resolve('router.deviceCount');
          resolver.resolve('router.wanStatus');
        }

        stopwatch.stop();

        // Mocked operations should be very fast (under 100ms for 200 operations)
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}

/// Sets up mock behavior for predictable testing.
void _setupMockBehavior(
  MockDashboardHomeNotifier mockDashboardHome,
  MockDeviceManagerNotifier mockDeviceManager,
) {
  // Setup Dashboard Home mock behavior
  final mockDashboardState = const DashboardHomeState(
    wanType: 'ethernet',
    uptime: 442230, // 5 days, 12 hours, 30 minutes in seconds
  );

  when(mockDashboardHome.build()).thenReturn(mockDashboardState);
  when(mockDashboardHome.state).thenReturn(mockDashboardState);

  // Setup Device Manager mock behavior with simple empty device list
  // This demonstrates mocking without complex nested object creation
  final mockDeviceState = const DeviceManagerState(
    deviceList: [], // Empty list for simplicity - focus is on testing mocking patterns
  );

  when(mockDeviceManager.build()).thenReturn(mockDeviceState);
  when(mockDeviceManager.state).thenReturn(mockDeviceState);
}

/// Helper function to create proper theme data for A2UI integration tests.
/// This ensures AppTheme is properly configured to avoid "AppDesignTheme extension not found" errors.
ThemeData _createTestThemeData() {
  return AppTheme.create(
    brightness: Brightness.light,
    seedColor: AppPalette.brandPrimary,
    designThemeBuilder: (_) => CustomDesignTheme.fromJson(const {
      'style': 'flat',
      'brightness': 'light',
      'visualEffects': 0,
    }),
  );
}
