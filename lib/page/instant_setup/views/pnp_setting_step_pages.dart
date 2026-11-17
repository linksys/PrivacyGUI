import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_guest_step_view.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_wifi_step_view.dart';

/// A PnP setting step's page side: its stepper label and its view (#1511 P4).
///
/// The flow side — its inclusion condition and its draft — is
/// `kPnpSettingSteps` in `providers/pnp_setting_steps_provider.dart`; a provider may
/// not import a view, so the step is two entries, one per layer.
/// `pnp_setting_steps_provider_test.dart` keeps the two lists naming the same steps in
/// the same order. The routes under `/pnp/pnpConfig` are built from this list.
class PnpSettingStepPage {
  const PnpSettingStepPage({
    required this.id,
    required this.label,
    required this.view,
  });

  final String id;
  final String Function(BuildContext context) label;
  final Widget Function() view;
}

/// See [PnpSettingStepPage].
final pnpSettingStepPages = <PnpSettingStepPage>[
  PnpSettingStepPage(
    id: PnpWifiStepView.stepId,
    label: (context) => loc(context).pnpPersonalizeWiFiTitle,
    view: () => const PnpWifiStepView(),
  ),
  PnpSettingStepPage(
    id: PnpGuestStepView.stepId,
    label: (context) => loc(context).guestWifi,
    view: () => const PnpGuestStepView(),
  ),
];

/// The stepper's label for [stepId]: a setting step's own, or Your Network's,
/// which is the wizard's skeleton rather than a setting step.
String pnpStepLabel(BuildContext context, String stepId) =>
    stepId == PnpFlowPlan.yourNetworkStepId
        ? loc(context).pnpYourNetworkTitle
        : pnpSettingStepPages.firstWhere((p) => p.id == stepId).label(context);
