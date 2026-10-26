/// Provider overrides for `add_nodes_view` (#879).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_notifier.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_state.dart';

/// Holds [state] and does nothing else: no read of the router on entry, and no
/// action reaches one.
class FixedAddNodesNotifier extends AddNodesNotifier {
  final AddNodesState _fixedState;

  FixedAddNodesNotifier(this._fixedState);

  @override
  AddNodesState build() => _fixedState;

  @override
  Future<void> start() async {}

  @override
  Future<void> cancel() async {}

  @override
  Future<void> recheck() async {}
}

List<Override> addNodesOverrides(AddNodesState state) => [
      addNodesProvider.overrideWith(() => FixedAddNodesNotifier(state)),
    ];
