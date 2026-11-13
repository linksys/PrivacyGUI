import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/browser_history/browser_history.dart';
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
/// Pushed over the PnP shell from Your Network, which stays mounted under it,
/// so the wizard keeps its step and its drafts. Done is the browser's Back on
/// web, so it and the browser's own Back are one path; the notifier,
/// page-scoped, stops a session it started when it is disposed. Either way the
/// step reads the nodes again on return.
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
          // The browser's own Back on web, for the reason the wizard's step
          // footer gives: a `pop` is recorded as a new history entry too, so
          // Your Network's Back would then return here. This page is only ever
          // pushed from Your Network, so the previous entry is that step.
          onDone: () {
            if (!browserHistoryBack()) context.pop();
          },
        ),
      ),
    );
  }
}
