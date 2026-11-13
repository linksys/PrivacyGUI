import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/components/localizations/service_error_localizations.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/views/pnp_flow_frame_view.dart';
import 'package:privacy_gui/route/constants.dart';

/// Where the PnP flow sends the user.
enum PnpFlowDestination {
  /// The setup wizard's first step, `/pnp/pnpConfig/<first step>`.
  wizard,

  /// Your Network, `/pnp/pnpConfig/network`, once the save has landed
  /// (#1511 P5).
  yourNetwork,

  /// The no-internet troubleshooting flow, entered as its PnP caller.
  troubleshooting,
}

/// Where the flow goes when it moves from [previous] to [next], or `null` to
/// stay where it is.
///
/// **The one place a PnP phase becomes a page (#1511 P2).** It was six: the
/// entry view's listener and five in the troubleshooting views, which #1511 P1
/// moved to troubleshooting's own state and its caller's ending.
///
/// The wizard opens when the flow gets its plan — once per flow, because the
/// plan is built once (#1511 P4). That is the whole rule: a failed save that
/// returns to the form, a reconnect that sends the user back, an edit, do not
/// re-navigate, because the step the user is on is in the URL. The rule before
/// P4 had to name the save (`previous is! WizardSaving`), because re-navigating
/// rebuilt the one wizard page and reset its step to the first.
///
/// The one other step the flow opens itself is Your Network, when the save has
/// landed (#1511 P5): it is after the commit, so no Next reaches it — the save
/// step's button saves, and the user is moved on when the save is done.
PnpFlowDestination? pnpFlowDestination(PnpState? previous, PnpState next) {
  if (next.plan != null && previous?.plan == null) {
    return PnpFlowDestination.wizard;
  }
  if (next.phase is WizardYourNetwork &&
      previous?.phase is! WizardYourNetwork) {
    return PnpFlowDestination.yourNetwork;
  }
  if (next.phase is NoInternet && previous?.phase is! NoInternet) {
    return PnpFlowDestination.troubleshooting;
  }
  return null;
}

/// The location of the wizard step [stepId]: `/pnp/pnpConfig/<stepId>`.
String pnpStepLocation(String stepId) =>
    '${RoutePath.pnp}/${RoutePath.pnpConfig}/$stepId';

/// The wizard step [location] names — `wifi` in `/pnp/pnpConfig/wifi`,
/// `network` in `/pnp/pnpConfig/network/pnpAddNodes` — or `null` off the
/// steps.
String? pnpStepIdOf(Uri location) {
  final segments = location.pathSegments;
  return _inPnpTree(location) &&
          segments.length > 2 &&
          segments[1] == RoutePath.pnpConfig
      ? segments[2]
      : null;
}

/// By path segment, not by prefix: `/pnpNoInternetConnection` is not `/pnp`.
bool _inPnpTree(Uri location) =>
    location.pathSegments.isNotEmpty &&
    '/${location.pathSegments.first}' == RoutePath.pnp;

/// Where a navigation inside the PnP shell to [target] lands instead, or
/// `null` to let it through (#1511 P4).
///
/// **The back policy, and the only one.** The shell's `redirect` calls it for
/// every navigation into the `/pnp` tree — browser Back, a typed URL, a reload,
/// a `go` — because `redirect` sees the destination and `onExit` does not. It
/// reads the flow's phase and its plan, never a setting step by name, so the
/// table below holds for whatever setting steps the plan has:
///
/// | flow | open | everything else in the tree goes to |
/// |---|---|---|
/// | no plan yet | the entry | the entry |
/// | editing | the entry (`/pnp/pnpConfig`'s exit asks to log out), the setting steps | the first step |
/// | saving | the save step | the save step |
/// | on Your Network | Your Network, adding nodes | Your Network |
/// | after Your Network | Your Network | Your Network |
///
/// The save step is the last setting step, and Your Network comes after it
/// (#1511 P5, D3) — so Your Network is not open while editing, and once the
/// user is on it Back cannot reach a setting step again: the save is behind
/// them (D7). "Saving" is the write and what it may need before Your Network
/// (the reconnect step, its polling, the moment after the acknowledge); "after
/// Your Network" is the firmware stage and the completion screen, drawn over
/// it. A refused Back costs one extra browser-history entry — go_router
/// re-reports the current URL (spike S2).
///
/// Exhaustive over the phase on purpose: a phase added later must be placed
/// in this table, not let through by a default.
String? pnpBackPolicy(PnpState flow, Uri target) {
  if (!_inPnpTree(target)) return null;
  final atEntry = target.pathSegments.length == 1;
  final stepId = pnpStepIdOf(target);
  // The step itself, and nothing under it — adding nodes is under Your Network.
  final atStepItself = target.pathSegments.length == 3;

  final plan = flow.plan;
  if (plan == null) return atEntry ? null : RoutePath.pnp;
  const yourNetwork = PnpFlowPlan.yourNetworkStepId;

  switch (flow.phase) {
    case WizardConfiguring():
      if (atEntry) return null;
      return plan.settingStepIds.contains(stepId)
          ? null
          : pnpStepLocation(plan.firstStepId);
    case WizardSaving() ||
          WizardSaved() ||
          WizardNeedsReconnect() ||
          WizardTestingReconnect():
      return stepId == plan.saveStepId && atStepItself
          ? null
          : pnpStepLocation(plan.saveStepId);
    case WizardYourNetwork():
      return stepId == yourNetwork ? null : pnpStepLocation(yourNetwork);
    case WizardCheckingFirmware() ||
          WizardUpdatingFirmware() ||
          WizardWifiReady():
      return stepId == yourNetwork && atStepItself
          ? null
          : pnpStepLocation(yourNetwork);
    case AdminCheckingInternet() ||
          AdminInternetConnected() ||
          AdminReadFailure() ||
          NoInternet() ||
          WizardInitializing() ||
          WizardError():
      // The entry's phases. A flow with a plan is past them; only a demo pins
      // one on it, and then the entry is where it is drawn.
      return atEntry ? null : RoutePath.pnp;
  }
}

/// The `ShellRoute` body over the `/pnp` tree (#1511 P2).
///
/// It owns three things:
/// - the flow's phase→page mapping, [pnpFlowDestination];
/// - since #1511 P3 the flow's **lifetime**: `pnpProvider` is `autoDispose`,
///   and the subscription below is what holds it, so the flow lives exactly
///   while the user is in the `/pnp` tree and a second visit starts a new one;
/// - since #1511 P4 what is drawn around the page — the top bar, the stepper
///   and the status screens, [PnpFlowFrameView] — and telling the user why a
///   save came back to the form.
///
/// The back policy, [pnpBackPolicy], is the shell route's `redirect`
/// (`route_pnp.dart`), because a redirect sees the destination.
///
/// Not named `*_view.dart` on purpose: it is not a page, and the layout gate's
/// roster counts every `views/*_view.dart` as one.
class PnpFlowShell extends ConsumerWidget {
  const PnpFlowShell({super.key, required this.location, required this.child});

  /// Where the router is — which step, if any, the stepper marks.
  final Uri location;

  /// The page of the flow the URL names.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This subscription is also the flow's keep-alive (#1511 P3): it is the one
    // thing holding `pnpProvider` for as long as this shell is mounted.
    ref.listen(pnpProvider, (previous, next) {
      switch (pnpFlowDestination(previous, next)) {
        case PnpFlowDestination.wizard:
          context.goNamed(RouteNamed.pnpStep(next.plan!.firstStepId));
        case PnpFlowDestination.yourNetwork:
          context.goNamed(RouteNamed.pnpStep(PnpFlowPlan.yourNetworkStepId));
        case PnpFlowDestination.troubleshooting:
          // Troubleshooting's ending for this caller brings the user back to
          // `/pnp` once the internet is (#1511 P1).
          context.goNamed(
            RouteNamed.pnpNoInternetConnection,
            pathParameters: {
              TroubleshootingCaller.param: TroubleshootingCaller.pnp,
            },
          );
        case null:
          break;
      }
    });
    // A save that sent the user back to the form says why (#1000). A listener
    // rather than a read in `build`, so it fires once per failure: the error
    // stays on the phase until the next save, and rebuilds must not repeat it.
    ref.listen(pnpProvider.select((s) => s.phase), (_, next) {
      if (next is WizardConfiguring && next.saveError != null) {
        showFailedSnackBar(
            context, localizeServiceError(context, next.saveError!));
      }
    });
    return PnpFlowFrameView(stepId: pnpStepIdOf(location), child: child);
  }
}
