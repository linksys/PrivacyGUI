// The Add Wired Nodes run's state as a map and as a value.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/models/back_haul_info.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_state.dart';

import '../../instant_device/providers/home_network_poll.dart';

void main() {
  final backhaul = BackHaulInfoData.fromMap(
      (backhaulInfo()['backhaulDevices'] as List).single
          as Map<String, dynamic>);
  final bedroom = LinksysDevice.fromMap(bedroomNode());

  AddWiredNodesState running() => AddWiredNodesState(
        onboardingProceed: true,
        anyOnboarded: false,
        backhaulSnapshot: [backhaul],
        isLoading: true,
        loadingMessage: 'Onboarding',
        onboardingTime: 12,
      );

  test('writes every field, the backhaul as maps', () {
    expect(running().toMap(), {
      'onboardingProceed': true,
      'anyOnboarded': false,
      'backhaulSnapshot': [backhaul.toMap()],
      'isLoading': true,
      'forceStop': false,
      'loadingMessage': 'Onboarding',
      'onboardingTime': 12,
      'nodes': null,
    });
  });

  test('reads back from the JSON it writes', () {
    final state = running();

    final read = AddWiredNodesState.fromJson(state.toJson());

    expect(read.backhaulSnapshot?.single.deviceUUID, 'bedroom');
    expect(read, state);
  });

  // Through the map, not JSON: a device's JSON does not read back yet
  // (LinksysDevice.fromMap casts its decoded MLO list; lib/core, not here).
  test('writes the nodes it found as maps, and reads them back', () {
    final state = running().copyWith(nodes: [bedroom]);

    expect(state.toMap()['nodes'], [bedroom.toMap()]);
    final read = AddWiredNodesState.fromMap(state.toMap());
    expect(read.nodes?.single.deviceID, 'bedroom');
    expect(read, state);
  });

  test('reads a state with no loading or stop flag as neither', () {
    final state = AddWiredNodesState.fromMap(const {'onboardingTime': 0});

    expect(state.isLoading, isFalse);
    expect(state.forceStop, isFalse);
    expect(state.backhaulSnapshot, isNull);
    expect(state.nodes, isNull);
  });

  test('a state read twice is the same state; a change to any field is not',
      () {
    final state = running();

    expect(running(), state);
    for (final edited in [
      state.copyWith(onboardingProceed: false),
      state.copyWith(anyOnboarded: true),
      state.copyWith(backhaulSnapshot: []),
      state.copyWith(isLoading: false),
      state.copyWith(forceStop: true),
      state.copyWith(loadingMessage: 'Searching'),
      state.copyWith(onboardingTime: 13),
      state.copyWith(nodes: [bedroom]),
    ]) {
      expect(edited, isNot(state));
    }
  });

  test('an edit keeps the fields it does not name', () {
    final state = running();

    final stopped = state.copyWith(forceStop: true);

    expect(stopped.backhaulSnapshot, same(state.backhaulSnapshot));
    expect(stopped.onboardingTime, 12);
    expect(stopped.isLoading, isTrue);
  });
}
