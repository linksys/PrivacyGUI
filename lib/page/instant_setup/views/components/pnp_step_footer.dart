import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/browser_history/browser_history.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A PnP wizard step's Back and Next — or Save, on the plan's save step, or
/// Done, on the last step (#1511 P4, P5).
///
/// **Save placement is read from the plan, not written by the step.** A step
/// says only who it is ([stepId]) and whether the user may go on
/// ([canContinue]); which neighbour Back and Next go to, and whether the
/// primary button is Next, Save or Done, come from `PnpFlowPlan`. So a step
/// added to the step list gets the right buttons without editing any other
/// step. Save is on the last setting step (#1511 P5); Your Network, after it,
/// has no Back — Back never crosses the save — and its Done finishes the
/// wizard, as 1.x's Your Network did.
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
    final before = plan.backFrom(stepId);
    final after = plan.nextFrom(stepId);

    // The primary button, decided once: Save on the save step, Done on Your
    // Network, Next everywhere else. One footer is on screen at a time — the
    // step pages replace each other — so the three hooks are singletons.
    final (String label, String identifier, VoidCallback? action) =
        stepId == plan.saveStepId
            ? (
                loc(context).save,
                'pnp-step-save',
                () => ref.read(pnpProvider.notifier).saveChanges(),
              )
            : stepId == PnpFlowPlan.yourNetworkStepId
                ? (
                    loc(context).done,
                    'pnp-step-done',
                    () => ref.read(pnpProvider.notifier).finishWizard(),
                  )
                : (
                    loc(context).next,
                    'pnp-step-next',
                    after == null
                        ? null
                        : () => context.goNamed(RouteNamed.pnpStep(after)),
                  );

    // A `Wrap`, not a `Row`: at 320px Back beside Save overflowed in `el` by 17px
    // on Your Network when it held Save (#1511 P4, the first sweep that step ever
    // had; the pair is on the last setting step since P5), and the honest
    // degradation for a pair of actions is a second line rather than two
    // squeezed labels — the same call #1602 made for the completion screen.
    // Where the pair fits, this lays out exactly as the `Row` did.
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
            onTap: () {
              // The browser's own Back on web, so this Back and the browser's
              // are one action and history does not grow (see
              // `browserHistoryBack`). Safe here: a step with a Back is only
              // reached by Next from the step before it, so the previous
              // history entry is that step.
              if (!browserHistoryBack()) {
                context.goNamed(RouteNamed.pnpStep(before));
              }
            },
          ),
        AppButton(
          label: label,
          identifier: identifier,
          onTap: canContinue ? action : null,
        ),
      ],
    );
  }
}
