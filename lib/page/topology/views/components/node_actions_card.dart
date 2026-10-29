import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/detail_widgets.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Reboot and Factory Reset for the node a detail page shows (#876).
///
/// Offers exactly [actions], in [NodeAction] order, and builds nothing when
/// there are none: an agent offers what its `X_LINKSYS_SupportedOperations`
/// lists, and the router offers both. What a tap does is the page's, because
/// the router's two run the Administration page's flow and an agent's run a
/// node command.
class NodeActionsCard extends StatelessWidget {
  final Set<NodeAction> actions;
  final void Function(NodeAction action) onAction;

  const NodeActionsCard({
    super.key,
    required this.actions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      width: double.infinity,
      child: AppCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DetailCardHeader(
              icon: Icons.settings_power,
              title: loc(context).nodeActions,
            ),
            AppGap.md(),
            // `Wrap`, not a `Row` of two: both labels are translated, and on
            // the desktop layout this card is a third of the page wide.
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final action in NodeAction.values)
                  if (actions.contains(action))
                    switch (action) {
                      // Identifiers spelled inline: the E2E harvester reads
                      // this file as text, so a composed value never reaches
                      // the specs' selector map.
                      NodeAction.reboot => AppButton.primaryOutline(
                          identifier: 'node-detail-reboot',
                          label: loc(context).reboot,
                          onTap: () => onAction(NodeAction.reboot),
                        ),
                      NodeAction.factoryReset => AppButton.primaryOutline(
                          identifier: 'node-detail-factory-reset',
                          label: loc(context).factoryReset,
                          onTap: () => onAction(NodeAction.factoryReset),
                        ),
                    },
              ],
            ),
          ],
        ),
      ),
    );
  }
}
