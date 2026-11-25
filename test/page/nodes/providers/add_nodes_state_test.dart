// The Add Nodes run's state as a map and as a value.

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/page/nodes/providers/add_nodes_state.dart';

import '../../instant_device/providers/home_network_poll.dart';

void main() {
  final master = LinksysDevice.fromMap(masterDevice());
  final bedroom = LinksysDevice.fromMap(bedroomNode());

  AddNodesState found() => AddNodesState(
        onboardingProceed: true,
        anyOnboarded: true,
        nodesSnapshot: [master],
        addedNodes: [bedroom],
        childNodes: [bedroom],
        isLoading: true,
        loadingMessage: 'Searching',
      );

  test('writes only the fields it has', () {
    expect(const AddNodesState().toMap(), {'isLoading': false});
    expect(found().toMap(), {
      'onboardingProceed': true,
      'anyOnboarded': true,
      'nodesSnapshot': [master.toMap()],
      'addedNodes': [bedroom.toMap()],
      'childNodes': [bedroom.toMap()],
      'isLoading': true,
      'loadingMessage': 'Searching',
    });
  });

  // Through the map, not JSON: a device's JSON does not read back yet
  // (LinksysDevice.fromMap casts its decoded MLO list; lib/core, not here).
  test('reads back from the map it writes', () {
    final state = found();

    final read = AddNodesState.fromMap(state.toMap());

    expect(read.addedNodes?.single.deviceID, 'bedroom');
    expect(read.nodesSnapshot?.single.deviceID, 'master');
    expect(read, state);
  });

  test('without devices, reads back from the JSON it writes', () {
    const state = AddNodesState(
        onboardingProceed: false, isLoading: true, loadingMessage: 'Searching');

    expect(AddNodesState.fromJson(state.toJson()), state);
  });

  test('a state read twice is the same state; a change to any field is not',
      () {
    final state = found();

    expect(found(), state);
    for (final edited in [
      state.copyWith(onboardingProceed: false),
      state.copyWith(anyOnboarded: false),
      state.copyWith(nodesSnapshot: []),
      state.copyWith(addedNodes: []),
      state.copyWith(childNodes: []),
      state.copyWith(isLoading: false),
      state.copyWith(loadingMessage: 'Onboarding'),
      state.copyWith(onboardedMACList: [bedroomMac]),
    ]) {
      expect(edited, isNot(state));
    }
  });

  test('an edit keeps the fields it does not name', () {
    final state = found();

    final edited = state.copyWith(isLoading: false);

    expect(edited.addedNodes, same(state.addedNodes));
    expect(edited.loadingMessage, 'Searching');
    expect(edited.onboardingProceed, isTrue);
  });
}
