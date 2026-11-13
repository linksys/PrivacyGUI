import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/composed/app_node_list_card.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/_shared/components/layout_blocks.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_step_footer.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// E2E hook for the Your Network step's "Add nodes" button (#1734). Singleton:
/// the step has one.
const String kPnpAddNodesIdentifier = 'pnp-add-nodes';

/// The PnP wizard's Your Network step: the mesh nodes, and the way in to add
/// more (#1734, #1511 P4).
///
/// Always in the plan, after the setting steps, with one node as with several:
/// it is where nodes are added, and a single router is the case that most
/// needs to (REQ-16). **After the save** since #1511 P5: the flow opens it once
/// the Wi-Fi write has landed, so a node added here joins with the Wi-Fi the
/// user has just set. Its footer — Done, and no Back — is the plan's, not this
/// page's.
class PnpYourNetworkStepView extends ConsumerWidget {
  const PnpYourNetworkStepView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nodes = ref.watch(pnpProvider.select((s) => s.meshNodes));
    // The topology's own two answers, read the same way (#1734): whether this
    // firmware has the onboarding API, and whether this mode offers a way in.
    // The button renders iff both say yes.
    final openAddNodes = ref.watch(deviceCapabilitiesProvider).has(
              DeviceCapability.bleOnboarding,
            )
        ? ref
            .watch(surfaceStrategyProvider)
            .addNodesEntry(() => _openAddNodes(context, ref))
        : null;

    return UiKitPageView.innerPage(
      scrollable: true,
      useMainPadding: false,
      child: (context, constraints) => Column(
        // In a Column so the card wraps its content: as the page's own child
        // it took the scroll view's minimum height and ran to the bottom of
        // the screen (bench, 2026-11-13).
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText.titleMedium(loc(context).pnpYourNetworkTitle),
                  AppGap.sm(),
                  AppText.bodyMedium(loc(context).pnpYourNetworkDesc),
                  AppGap.xl(),
                  // Empty only when the mesh read failed, which the service answers
                  // with no nodes rather than an error: the step still shows, so an
                  // empty block would be a frame with nothing in it.
                  if (nodes.isNotEmpty)
                    LayoutBlock(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          for (final (i, node) in nodes.indexed) ...[
                            AppNodeListCard(
                              leading: DeviceImageHelper.getRouterImage(
                                routerIconTestByModel(modelNumber: node.model),
                              ),
                              title: node.model.isNotEmpty
                                  ? node.model
                                  : node.deviceId,
                              // The node's own role, not its place in the list: the
                              // nodes keep DataElements order, which does not promise
                              // the controller first. The topology's words for the
                              // two roles.
                              description: node.isMaster
                                  ? loc(context).master
                                  : loc(context).slave,
                              trailing: AppIcon.font(
                                Icons.check_circle,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                            ),
                            if (i < nodes.length - 1)
                              const Divider(height: AppSpacing.md),
                          ],
                        ],
                      ),
                    ),
                  if (openAddNodes != null) ...[
                    AppGap.md(),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AppButton.text(
                        label: loc(context).addNodes,
                        icon: AppIcon.font(Icons.add_circle_outline),
                        identifier: kPnpAddNodesIdentifier,
                        onTap: openAddNodes,
                      ),
                    ),
                  ],
                  AppGap.xxxl(),
                  const PnpStepFooter(stepId: PnpFlowPlan.yourNetworkStepId),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// Opens the add-nodes flow over the wizard, then reads the nodes again so
  /// the step shows the ones that joined (#1734).
  ///
  /// Pushed, onto the root navigator over the whole PnP shell, so the wizard
  /// stays mounted under it with its drafts and its step. Going to `/pnp`
  /// instead would leave the wizard.
  Future<void> _openAddNodes(BuildContext context, WidgetRef ref) async {
    await context.pushNamed(RouteNamed.pnpAddNodes);
    if (!context.mounted) return;
    await ref.read(pnpProvider.notifier).refreshMeshNodes();
  }
}
