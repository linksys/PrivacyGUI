import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A PnP wizard step's Back and Next — or Save, on the plan's save step
/// (#1511 P4).
///
/// **Save placement is read from the plan, not written by the step.** A step
/// says only who it is ([stepId]) and whether the user may go on
/// ([canContinue]); which neighbour Back and Next go to, and whether the
/// primary button is Next or Save, come from `PnpFlowPlan`. So a step added to
/// the step list gets the right buttons without editing any other step, and
/// #1511 P5 moves Save by changing `PnpFlowPlan.saveStepId` alone.
class PnpStepFooter extends ConsumerWidget {
  const PnpStepFooter({
    super.key,
    required this.stepId,
    this.canContinue = true,
  });

  final String stepId;

  /// Whether the primary button is enabled — the step's own validation.
  final bool canContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(pnpProvider.select((s) => s.plan));
    if (plan == null) return const SizedBox.shrink();
    final before = plan.stepBefore(stepId);
    final after = plan.stepAfter(stepId);
    final isSaveStep = stepId == plan.saveStepId;

    final VoidCallback? primary = !canContinue
        ? null
        : isSaveStep
            ? () => ref.read(pnpProvider.notifier).saveChanges()
            : after == null
                ? null
                : () => context.goNamed(RouteNamed.pnpStep(after));

    // A `Wrap`, not a `Row`: at 320px Back beside Save overflowed in `el` by 17px
    // on Your Network (#1511 P4, the first sweep that step ever had), and the
    // honest degradation for a pair of actions is a second line rather than two
    // squeezed labels — the same call #1602 made for the completion screen. Where
    // the pair fits, this lays out exactly as the `Row` did.
    return Wrap(
      alignment:
          before == null ? WrapAlignment.end : WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: [
        if (before != null)
          AppButton.text(
            label: loc(context).back,
            identifier: 'pnp-step-back',
            onTap: () => context.goNamed(RouteNamed.pnpStep(before)),
          ),
        // One footer on screen at a time — the step pages replace each other —
        // so the two hooks are singletons.
        if (isSaveStep)
          AppButton(
            label: loc(context).save,
            identifier: 'pnp-step-save',
            onTap: primary,
          )
        else
          AppButton(
            label: loc(context).next,
            identifier: 'pnp-step-next',
            onTap: primary,
          ),
      ],
    );
  }
}
