import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/topology/providers/node_detail_provider.dart';
import 'package:privacy_gui/page/topology/views/usp_node_detail_view.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../layout_gate/surface.dart';
import '../../../mocks/provider_overrides/mock_topology.dart';
import '../../../mocks/test_data/scenes/topology_scene_data.dart';
import '../../../util/settle.dart';

/// An agent's backhaul card names its parent the way the rest of the app does
/// (#1751).
///
/// The row read "Connected to Master (M60-US)": the parent's model. After the
/// controller is renamed, the header of the controller's own page, Topology and
/// every client's parent say the new name, and this row alone kept the model.
/// No scene had a `parentNode` before #1751, so nothing rendered the row at all.
void main() {
  final state = slaveNodeUnderRenamedController;

  Future<void> pump(WidgetTester tester, UspNodeDetailState state) async {
    await setLayoutSurface(tester, const Size(1280, 1800));
    await tester.pumpWidget(pageSurfaceHost(
      view: UspNodeDetailView(deviceId: (state.node as SlaveNode).deviceId),
      locale: const Locale('en'),
      overrides: nodeDetailOverrides(state),
    ));
    // The node card's `AppImage.provider` stream never completes under the test
    // binding, so `pumpAndSettle` would time out on it.
    await settleIgnoringAnimations(tester);
  }

  late AppLocalizations loc;
  setUpAll(() async {
    loc = await AppLocalizations.delegate.load(const Locale('en'));
  });

  testWidgets('the fixture is a renamed parent whose name is not its model', (
    tester,
  ) async {
    // Asserted rather than assumed: with the name equal to the model, the row
    // would pass whichever of the two it printed.
    final parent = state.parentNode!;
    expect(parent.displayName, 'Living room');
    expect(parent.model, isNot(parent.displayName));

    await pump(tester, state);
    expect(find.bySemanticsIdentifier('node-detail-parent'), findsOneWidget);
  });

  testWidgets('the connected-to row names the parent, not its model', (
    tester,
  ) async {
    await pump(tester, state);

    expect(find.text('${loc.master} (Living room)'), findsOneWidget);
    expect(find.textContaining('M60-US'), findsNothing,
        reason: 'the model is on the parent\'s own page, not this row');
  });
}
