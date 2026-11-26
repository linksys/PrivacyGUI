import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_topology/providers/instant_topology_state.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';

void main() {
  final internet = OnlineTopologyNode(
      data: const TopologyModel(isOnline: true, location: 'Internet'),
      children: []);

  test('an edit with no tree keeps the tree', () {
    final state = InstantTopologyState(root: internet);

    expect(state.copyWith().root, same(internet));
  });

  test('an edit with a tree replaces it', () {
    final state = InstantTopologyState(root: internet);
    final other = OnlineTopologyNode(
        data: const TopologyModel(isOnline: true, location: 'Internet'),
        children: [internet]);

    expect(state.copyWith(root: other).root, same(other));
  });
}
