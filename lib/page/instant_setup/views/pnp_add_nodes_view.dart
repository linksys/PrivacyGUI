import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/add_nodes/providers/add_nodes_notifier.dart';
import 'package:privacy_gui/page/add_nodes/views/components/add_nodes_phase_content.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Adds nodes from the PnP wizard's Your Network step (#1734).
///
/// The topology's flow in the wizard's frame: the same [addNodesProvider] and
/// [AddNodesPhaseContent], so every phase, command and stop behaves as it does
/// there (#879). Only the shell differs: no app bar, as on every PnP page, and
/// Done pops back to the step rather than to the topology.
///
/// Pushed over [RouteNamed.pnpConfig], which stays mounted under it, so the
/// wizard keeps its step and its form. Leaving by the browser's Back pops the
/// same way, and the notifier, page-scoped, stops a session it started when it
/// is disposed. Either way the step reads the nodes again on return.
///
/// The route is [RouteNamed.pnpAddNodes], which the idle checker exempts as it
/// does [RouteNamed.addNodes]: a full session can outlast the idle window.
class PnpAddNodesView extends ConsumerWidget {
  const PnpAddNodesView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(addNodesProvider);
    final notifier = ref.read(addNodesProvider.notifier);

    return UiKitPageView(
      identifier: 'pnp-add-nodes-view',
      appBarStyle: UiKitAppBarStyle.none,
      scrollable: true,
      child: (childContext, constraints) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.lg,
        ),
        child: AddNodesPhaseContent(
          state: state,
          onStart: notifier.start,
          onCancel: notifier.cancel,
          onRecheck: notifier.recheck,
          onDone: () => context.pop(),
        ),
      ),
    );
  }
}
