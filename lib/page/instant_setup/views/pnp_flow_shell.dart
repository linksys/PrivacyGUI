import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/route/constants.dart';

/// Where the PnP flow sends the user.
enum PnpFlowDestination {
  /// The setup wizard, `/pnp/pnpConfig`.
  wizard,

  /// The no-internet troubleshooting flow, entered as its PnP caller.
  troubleshooting,
}

/// Where the flow goes when its phase moves from [previous] to [next], or
/// `null` to stay where it is.
///
/// **The one place a PnP phase becomes a page (#1511 P2).** It was six: the
/// entry view's listener and five in the troubleshooting views, which #1511 P1
/// moved to troubleshooting's own state and its caller's ending. What is left is
/// the entry view's two, and they are here.
///
/// The wizard opens only from the states before it, not when a failed save
/// returns to the form (`previous` is [WizardSaving]) and not on an edit
/// (`previous` is [WizardConfiguring]): re-navigating rebuilds `PnpSetupView`,
/// which resets its step to the first and would show step 1 after a failed save
/// on step 3. #1511 P4 retires that patch by putting the step in the URL.
PnpFlowDestination? pnpFlowDestination(PnpPhase? previous, PnpPhase next) {
  if (next is WizardConfiguring &&
      previous is! WizardSaving &&
      previous is! WizardConfiguring) {
    return PnpFlowDestination.wizard;
  }
  if (next is NoInternet) return PnpFlowDestination.troubleshooting;
  return null;
}

/// The `ShellRoute` body over the `/pnp` tree (#1511 P2).
///
/// It owns two things. The flow's phase→page mapping, [pnpFlowDestination]. And
/// since #1511 P3 the flow's **lifetime**: `pnpProvider` is `autoDispose`, and
/// the subscription below is what holds it, so the flow lives exactly while the
/// user is in the `/pnp` tree and a second visit starts a new one. A shell's own
/// widget is not rebuilt while the user moves between its child routes, so it is
/// the one place that sees every phase change for as long as the user is in the
/// flow. The stepper moves here in a later phase of #1511.
///
/// Not named `*_view.dart` on purpose: it is not a page, and the layout gate's
/// roster counts every `views/*_view.dart` as one.
class PnpFlowShell extends ConsumerWidget {
  const PnpFlowShell({super.key, required this.child});

  /// The page of the flow the URL names.
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This subscription is also the flow's keep-alive (#1511 P3): it is the one
    // thing holding `pnpProvider` for as long as this shell is mounted.
    ref.listen(pnpProvider, (previous, next) {
      switch (pnpFlowDestination(previous?.phase, next.phase)) {
        case PnpFlowDestination.wizard:
          context.goNamed(RouteNamed.pnpConfig);
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
    return child;
  }
}
