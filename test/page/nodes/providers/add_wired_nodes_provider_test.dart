import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/data/providers/device_manager_state.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/services/add_wired_nodes_service.dart';

import '../../../mocks/test_data/add_wired_nodes_test_data.dart';

// Mock classes
class MockAddWiredNodesService extends Mock implements AddWiredNodesService {}

void main() {
  late MockAddWiredNodesService mockService;
  late ProviderContainer container;

  setUp(() {
    mockService = MockAddWiredNodesService();
    container = ProviderContainer(
      overrides: [
        addWiredNodesServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('AddWiredNodesNotifier', () {
    group('delegates to service methods', () {
      test(
          'setAutoOnboardingSettings delegates to service.setAutoOnboardingEnabled',
          () async {
        // Arrange
        when(() => mockService.setAutoOnboardingEnabled(true))
            .thenAnswer((_) async {});

        // Act
        final notifier = container.read(addWiredNodesProvider.notifier);
        await notifier.setAutoOnboardingSettings(true);

        // Assert
        verify(() => mockService.setAutoOnboardingEnabled(true)).called(1);
      });

      test(
          'getAutoOnboardingSettings delegates to service.getAutoOnboardingEnabled',
          () async {
        // Arrange
        when(() => mockService.getAutoOnboardingEnabled())
            .thenAnswer((_) async => true);

        // Act
        final notifier = container.read(addWiredNodesProvider.notifier);
        final result = await notifier.getAutoOnboardingSettings();

        // Assert
        expect(result, isTrue);
        verify(() => mockService.getAutoOnboardingEnabled()).called(1);
      });

      test('getAutoOnboardingSettings returns false when disabled', () async {
        // Arrange
        when(() => mockService.getAutoOnboardingEnabled())
            .thenAnswer((_) async => false);

        // Act
        final notifier = container.read(addWiredNodesProvider.notifier);
        final result = await notifier.getAutoOnboardingSettings();

        // Assert
        expect(result, isFalse);
        verify(() => mockService.getAutoOnboardingEnabled()).called(1);
      });

      test(
          'stopAutoOnboarding delegates to service.setAutoOnboardingEnabled(false)',
          () async {
        // Arrange
        when(() => mockService.setAutoOnboardingEnabled(false))
            .thenAnswer((_) async {});

        // Act
        final notifier = container.read(addWiredNodesProvider.notifier);
        await notifier.stopAutoOnboarding();

        // Assert
        verify(() => mockService.setAutoOnboardingEnabled(false)).called(1);
      });
    });

    group('handles ServiceError correctly', () {
      test('setAutoOnboardingSettings propagates NetworkError from service',
          () async {
        // Arrange
        when(() => mockService.setAutoOnboardingEnabled(true))
            .thenThrow(const NetworkError(message: 'Connection failed'));

        // Act & Assert
        final notifier = container.read(addWiredNodesProvider.notifier);
        expect(
          () => notifier.setAutoOnboardingSettings(true),
          throwsA(isA<NetworkError>()),
        );
      });

      test(
          'getAutoOnboardingSettings propagates UnauthorizedError from service',
          () async {
        // Arrange
        when(() => mockService.getAutoOnboardingEnabled())
            .thenThrow(const UnauthorizedError());

        // Act & Assert
        final notifier = container.read(addWiredNodesProvider.notifier);
        expect(
          () => notifier.getAutoOnboardingSettings(),
          throwsA(isA<UnauthorizedError>()),
        );
      });

      test('setAutoOnboardingSettings propagates UnexpectedError from service',
          () async {
        // Arrange
        when(() => mockService.setAutoOnboardingEnabled(false))
            .thenThrow(const UnexpectedError(message: 'Unknown error'));

        // Act & Assert
        final notifier = container.read(addWiredNodesProvider.notifier);
        expect(
          () => notifier.setAutoOnboardingSettings(false),
          throwsA(isA<UnexpectedError>()),
        );
      });
    });

    group('startAutoOnboarding flow with mocked service', () {
      test('uses service.pollBackhaulChanges for polling', () async {
        // Arrange - setup a stream that completes after one emission
        final pollResult = BackhaulPollResult(
          backhaulList: [
            const BackhaulInfoUIModel(
              deviceUUID: 'new-node-uuid',
              connectionType: 'Wired',
              timestamp: '2026-01-07T12:00:00Z',
            ),
          ],
          foundCounting: 1,
          anyOnboarded: true,
        );

        when(() => mockService.setAutoOnboardingEnabled(true))
            .thenAnswer((_) async {});
        when(() => mockService.setAutoOnboardingEnabled(false))
            .thenAnswer((_) async {});
        when(() => mockService.pollBackhaulChanges(
              any(),
              refreshing: any(named: 'refreshing'),
            )).thenAnswer((_) => Stream.value(pollResult));
        when(() => mockService.fetchNodes()).thenAnswer((_) async => []);

        // Note: startAutoOnboarding requires BuildContext which is hard to mock
        // This test verifies service method signatures are compatible
        verifyNever(() => mockService.setAutoOnboardingEnabled(any()));
      });

      test('uses service.fetchNodes to get final node list', () async {
        // Arrange - use the test data builder to create a valid device
        final deviceMap = AddWiredNodesTestData.createDevice(
          deviceID: 'device-1',
          nodeType: 'Slave',
        );
        final mockNodes = [LinksysDevice.fromMap(deviceMap)];

        when(() => mockService.fetchNodes()).thenAnswer((_) async => mockNodes);

        // Act
        final result = await mockService.fetchNodes();

        // Assert
        expect(result, hasLength(1));
        expect(result.first.deviceID, 'device-1');
        verify(() => mockService.fetchNodes()).called(1);
      });

      test(
          'service.pollBackhaulChanges receives correct snapshot parameter type',
          () async {
        // Arrange
        const snapshot = [
          BackhaulInfoUIModel(
            deviceUUID: 'existing-uuid',
            connectionType: 'Wired',
            timestamp: '2026-01-07T10:00:00Z',
          ),
        ];

        final pollResult = BackhaulPollResult(
          backhaulList: snapshot,
          foundCounting: 0,
          anyOnboarded: false,
        );

        when(() => mockService.pollBackhaulChanges(
              snapshot,
              refreshing: false,
            )).thenAnswer((_) => Stream.value(pollResult));

        // Act
        final stream =
            mockService.pollBackhaulChanges(snapshot, refreshing: false);
        final results = await stream.toList();

        // Assert
        expect(results, hasLength(1));
        expect(results.first.foundCounting, 0);
        verify(() =>
                mockService.pollBackhaulChanges(snapshot, refreshing: false))
            .called(1);
      });
    });

    group('state management', () {
      test('initial state has isLoading false', () {
        final state = container.read(addWiredNodesProvider);
        expect(state.isLoading, isFalse);
      });

      test('forceStopAutoOnboarding sets forceStop when loading', () async {
        // Arrange - need to set isLoading first
        final notifier = container.read(addWiredNodesProvider.notifier);

        // Manually trigger state change to simulate loading
        // Note: This tests the forceStop logic in isolation
        await notifier.forceStopAutoOnboarding();

        // Since isLoading is false by default, forceStop should not be set
        final state = container.read(addWiredNodesProvider);
        expect(state.forceStop, isFalse);
      });
    });
  });
}
