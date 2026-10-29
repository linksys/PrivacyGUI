import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_notifier.dart';
import 'package:privacy_gui/page/add_nodes/views/components/add_nodes_phase_content.dart';
import 'package:privacy_gui/page/shell/usp_top_bar.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/route/navigation_extensions.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Adds every unconfigured node in range to the mesh over BLE (#879).
///
/// Reached from the controller's node menu on the topology. The route is named
/// [RouteNamed.addNodes], which the idle checker exempts: a full session can
/// outlast the idle window, and logging out mid-session would leave it running
/// with nobody watching.
///
/// Leaving the page stops a session it started — the notifier is page-scoped
/// and sends `Stop()` when it is disposed — so the back arrow needs no handler
/// of its own.
class AddNodesView extends ConsumerWidget {
  const AddNodesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addNodesProvider);
    final notifier = ref.read(addNodesProvider.notifier);

    return UiKitPageView(
      identifier: 'add-nodes',
      scrollable: true,
      title: loc(context).addNodes,
      topbar: const PreferredSize(
        preferredSize: Size.fromHeight(64),
        child: UspTopBar(),
      ),
      backFallback: RouteNamed.uspTopology,
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: (childContext, constraints) => AddNodesPhaseContent(
        state: state,
        onStart: notifier.start,
        onCancel: notifier.cancel,
        onRecheck: notifier.recheck,
        onDone: () => context.navigateBack(fallback: RouteNamed.uspTopology),
      ),
    );
  }
}
