import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_ending.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:privacy_gui/route/constants.dart';

/// How PnP ends a run of the no-internet troubleshooting flow (#1511 P1).
///
/// **Recovered, or the router could not be read:** back to `/pnp`. PnP's entry
/// re-runs its own check and starts the wizard — or shows its read-failure card —
/// so troubleshooting does not need to know what PnP does next.
///
/// **Continue without internet:** acknowledge setup, then the dashboard. Only PnP
/// offers this, because only PnP has a setup to acknowledge.
final pnpTroubleshootingEndingProvider = Provider<TroubleshootingEnding>(
  (ref) => TroubleshootingEnding(
    exitLocation: RoutePath.pnp,
    continueWithoutInternet: () async {
      await _acknowledgeWithoutInternet(ref);
      return RoutePath.uspDashboard;
    },
  ),
);

/// Ports the dev-1.3.0 "Log into router" escape hatch. Unlike 1.3.0 — which
/// routed into a trimmed-down setup wizard — the USP flow goes straight to the
/// dashboard (the USP wizard is phase-driven and has no forceLogin branch, and
/// the dashboard does not depend on internet being up).
///
/// We acknowledge PnP completion here so a later redirect through `/` does not
/// bounce the user back into PnP (`router_provider._prepare` re-checks
/// `needsPnp`; without acknowledging, a full-page reload would kick them out
/// again). This mirrors 1.3.0, where a configured router's save already sends
/// `SetUserAcknowledgedAutoConfig`. Acknowledge is fire-and-forget and does not
/// need WAN, so it succeeds while the router is offline.
///
/// **The session's serial, not PnP's flow state.** It is the serial `_prepare`
/// checked PnP against, and it outlives the PnP flow, which a caller's ending has
/// to: the user has left PnP for troubleshooting by the time this runs.
///
/// This never throws: an escape hatch must always let the user through. A
/// failed acknowledge / save is logged and swallowed — at worst the router
/// stays un-acknowledged and PnP is re-offered on the next `/` redirect, which
/// is strictly better than trapping the user on the no-internet page.
Future<void> _acknowledgeWithoutInternet(Ref ref) async {
  final sn = ref.read(sessionProvider).deviceInfo?.serialNumber;
  if (sn == null || sn.isEmpty) {
    logger.w('[PnP] continue without internet: no serial number, '
        'skipping acknowledge');
    return;
  }
  try {
    // Same acknowledge + saveSelectedNetwork pair as PnpNotifier's save, but the
    // error handling is intentionally the opposite: the save lets errors
    // propagate (a failed WiFi save should keep the user on the form to retry),
    // whereas here we swallow them (an escape hatch must never block
    // navigation). Keep the two in sync when changing this pair.
    await ref.read(pnpStatusServiceProvider).acknowledge(sn);
    // Persist selected network for session management, matching the save.
    await ref.read(sessionProvider.notifier).saveSelectedNetwork(sn, '');
    logger.i('[PnP] continue without internet: acknowledged, entering '
        'dashboard');
  } catch (e) {
    // Do not block navigation — see the doc above.
    logger.w('[PnP] continue without internet: acknowledge/save failed '
        '(ignored): $e');
  }
}
