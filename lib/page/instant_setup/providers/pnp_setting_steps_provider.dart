import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/framework/empty_status.dart';
import 'package:privacy_gui/framework/preservable_contract.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_wifi_draft_provider.dart';

/// A setting step of the PnP wizard, as the flow sees it (#1511 P4).
///
/// The page side of the same step — its stepper label and its view — is in
/// `views/pnp_setting_step_pages.dart`, because a provider must not import a
/// view (constitution Article V §5.4). `pnp_setting_steps_provider_test.dart` keeps the
/// two lists naming the same steps in the same order.
class PnpSettingStep {
  const PnpSettingStep({
    required this.id,
    required this.includedFor,
    required this.draft,
  });

  /// The step's id: its stepper segment's identifier (the E2E suite reads
  /// `wifi` / `guest` / `network`) and its path under `/pnp/pnpConfig`.
  final String id;

  /// Whether the wizard has this step on [router] — asked once, when the plan
  /// is built, and never again (D2).
  final bool Function(PnpWizardData router) includedFor;

  /// The step's draft.
  final ProviderListenable<PnpStepDraft> draft;
}

/// **The setting steps, in the order the wizard shows them.** A plain list:
/// adding a step before Save — Night Mode is the next one — is one entry here,
/// one in `pnpSettingStepPages`, its draft and its view, and nothing in the
/// shell, the stepper, the back policy or the flow-level guard.
///
/// (The save is the one place that still names the two Wi-Fi drafts: both go
/// out in one Wi-Fi SET. Whether a step on another USP service joins that SET
/// or is written before it is #1511's open spike S5.)
final kPnpSettingSteps = <PnpSettingStep>[
  PnpSettingStep(
    id: 'wifi',
    includedFor: (_) => true,
    draft: pnpMainWifiDraftProvider.notifier,
  ),
  PnpSettingStep(
    id: 'guest',
    // No guest SSID on the router, no guest step.
    includedFor: (router) => router.guest != null,
    draft: pnpGuestWifiDraftProvider.notifier,
  ),
];

/// The plan for a wizard that read [router]: every step in [kPnpSettingSteps]
/// whose condition holds, in the list's order.
PnpFlowPlan buildPnpFlowPlan(PnpWizardData router) => PnpFlowPlan(
      settingStepIds: [
        for (final step in kPnpSettingSteps)
          if (step.includedFor(router)) step.id,
      ],
    );

/// The step [id] names in [kPnpSettingSteps].
PnpSettingStep pnpSettingStep(String id) =>
    kPnpSettingSteps.firstWhere((step) => step.id == id);

/// The flow-level guard on `/pnp/pnpConfig`: the drafts of every setting step
/// in the plan, taken together (#1511 P4).
///
/// The same idiom as the Wi-Fi page's `_WifiPageDirtyProxy`
/// (`usp_wifi_settings_provider.dart`). It is not what keeps the drafts alive
/// — the flow holds them — and the flow never reads it, which is what lets it
/// watch the flow's plan without a dependency cycle. Empty before the wizard
/// has a plan.
final pnpWizardDraftsProvider = Provider.autoDispose<PnpWizardDrafts>((ref) {
  final plan = ref.watch(pnpProvider.select((s) => s.plan));
  return PnpWizardDrafts([
    if (plan != null)
      for (final id in plan.settingStepIds) ref.watch(pnpSettingStep(id).draft),
  ]);
});

/// See [pnpWizardDraftsProvider].
class PnpWizardDrafts implements PreservableContract<EmptyStatus, EmptyStatus> {
  PnpWizardDrafts(this.drafts);

  final List<PnpStepDraft> drafts;

  @override
  bool isDirty() => drafts.any((d) => d.isDirty());

  @override
  void revert() {
    for (final d in drafts) {
      if (d.isDirty()) d.revert();
    }
  }

  @override
  Future<(EmptyStatus?, EmptyStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) =>
      throw UnsupportedError('Route guard over the PnP drafts — not callable');

  @override
  Future<void> performSave() =>
      throw UnsupportedError('Route guard over the PnP drafts — not callable');
}
