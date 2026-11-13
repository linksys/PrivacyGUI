import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/components/ui_kit_page_view.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_probe_draft_provider.dart';
import 'package:privacy_gui/page/instant_setup/views/components/pnp_step_footer.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// **#1511 P6's probe — test-only, never shipped.** A third setting step: one
/// switch, and the footer every step has.
class PnpProbeStepView extends ConsumerWidget {
  const PnpProbeStepView({super.key});

  /// This step's id in the plan.
  static const stepId = 'probe';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(pnpProbeDraftProvider).current;
    return UiKitPageView.innerPage(
      scrollable: true,
      useMainPadding: false,
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppText.titleMedium(loc(context).settings),
                  AppGap.xl(),
                  AppSwitch(
                    value: draft.enabled,
                    identifier: 'pnp-probe-enabled',
                    onChanged:
                        ref.read(pnpProbeDraftProvider.notifier).setEnabled,
                  ),
                  AppGap.xxxl(),
                  const PnpStepFooter(stepId: PnpProbeStepView.stepId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
