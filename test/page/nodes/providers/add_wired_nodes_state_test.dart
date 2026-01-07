import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/nodes/models/backhaul_info_ui_model.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';

void main() {
  group('AddWiredNodesState', () {
    group('uses BackhaulInfoUIModel for backhaulSnapshot', () {
      test('backhaulSnapshot field accepts List<BackhaulInfoUIModel>', () {
        const backhaul = BackhaulInfoUIModel(
          deviceUUID: 'uuid-123',
          connectionType: 'Wired',
          timestamp: '2026-01-07T10:00:00Z',
        );

        const state = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: [backhaul],
        );

        expect(state.backhaulSnapshot, isA<List<BackhaulInfoUIModel>>());
        expect(state.backhaulSnapshot, hasLength(1));
        expect(state.backhaulSnapshot!.first.deviceUUID, 'uuid-123');
      });

      test('backhaulSnapshot can be null', () {
        const state = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: null,
        );

        expect(state.backhaulSnapshot, isNull);
      });
    });

    group('copyWith', () {
      test('copies backhaulSnapshot with new BackhaulInfoUIModel list', () {
        const initialState = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: [],
        );

        const newBackhaul = BackhaulInfoUIModel(
          deviceUUID: 'new-uuid',
          connectionType: 'Wired',
          timestamp: '2026-01-07T11:00:00Z',
        );

        final newState = initialState.copyWith(
          backhaulSnapshot: [newBackhaul],
        );

        expect(newState.backhaulSnapshot, hasLength(1));
        expect(newState.backhaulSnapshot!.first.deviceUUID, 'new-uuid');
      });

      test('preserves backhaulSnapshot when not provided', () {
        const backhaul = BackhaulInfoUIModel(
          deviceUUID: 'preserved-uuid',
          connectionType: 'Wired',
          timestamp: '2026-01-07T10:00:00Z',
        );

        const initialState = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: [backhaul],
        );

        final newState = initialState.copyWith(isLoading: true);

        expect(newState.backhaulSnapshot, hasLength(1));
        expect(newState.backhaulSnapshot!.first.deviceUUID, 'preserved-uuid');
        expect(newState.isLoading, isTrue);
      });

      test('copies all fields correctly', () {
        const backhaul = BackhaulInfoUIModel(
          deviceUUID: 'uuid-123',
          connectionType: 'Wired',
          timestamp: '2026-01-07T10:00:00Z',
        );

        const state = AddWiredNodesState(
          isLoading: true,
          forceStop: true,
          loadingMessage: 'Loading...',
          onboardingProceed: true,
          anyOnboarded: true,
          backhaulSnapshot: [backhaul],
          onboardingTime: 60,
        );

        final copiedState = state.copyWith();

        expect(copiedState.isLoading, isTrue);
        expect(copiedState.forceStop, isTrue);
        expect(copiedState.loadingMessage, 'Loading...');
        expect(copiedState.onboardingProceed, isTrue);
        expect(copiedState.anyOnboarded, isTrue);
        expect(copiedState.backhaulSnapshot, hasLength(1));
        expect(copiedState.onboardingTime, 60);
      });
    });

    group('toMap/fromMap', () {
      test('serializes and deserializes backhaulSnapshot correctly', () {
        const backhaul = BackhaulInfoUIModel(
          deviceUUID: 'uuid-roundtrip',
          connectionType: 'Wired',
          timestamp: '2026-01-07T12:00:00Z',
        );

        const state = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: [backhaul],
        );

        final map = state.toMap();
        final restored = AddWiredNodesState.fromMap(map);

        expect(restored.backhaulSnapshot, isA<List<BackhaulInfoUIModel>>());
        expect(restored.backhaulSnapshot, hasLength(1));
        expect(restored.backhaulSnapshot!.first.deviceUUID, 'uuid-roundtrip');
        expect(restored.backhaulSnapshot!.first.connectionType, 'Wired');
      });

      test('handles null backhaulSnapshot in fromMap', () {
        final map = {
          'isLoading': false,
          'forceStop': false,
          'backhaulSnapshot': null,
          'onboardingTime': 0,
        };

        final state = AddWiredNodesState.fromMap(map);

        expect(state.backhaulSnapshot, isNull);
      });
    });

    group('Equatable', () {
      test('states with same backhaulSnapshot are equal', () {
        const backhaul = BackhaulInfoUIModel(
          deviceUUID: 'uuid-equal',
          connectionType: 'Wired',
          timestamp: '2026-01-07T10:00:00Z',
        );

        const state1 = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: [backhaul],
        );
        const state2 = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: [backhaul],
        );

        expect(state1, equals(state2));
      });

      test('states with different backhaulSnapshot are not equal', () {
        const backhaul1 = BackhaulInfoUIModel(
          deviceUUID: 'uuid-1',
          connectionType: 'Wired',
          timestamp: '2026-01-07T10:00:00Z',
        );
        const backhaul2 = BackhaulInfoUIModel(
          deviceUUID: 'uuid-2',
          connectionType: 'Wired',
          timestamp: '2026-01-07T10:00:00Z',
        );

        const state1 = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: [backhaul1],
        );
        const state2 = AddWiredNodesState(
          isLoading: false,
          backhaulSnapshot: [backhaul2],
        );

        expect(state1, isNot(equals(state2)));
      });
    });
  });
}
