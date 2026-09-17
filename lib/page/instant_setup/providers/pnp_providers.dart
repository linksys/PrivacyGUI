import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';

final pnpProvider = NotifierProvider<PnpNotifier, PnpState>(
  PnpNotifier.new,
);

/// How long the firmware stage waits for an answer before finishing setup
/// without one (REQ-B3).
///
/// Fifteen seconds, and it bounds the **whole** stage rather than one request:
/// reading the image table, dispatching the check, and the check's own polling all
/// sit inside it. `FirmwareRouterOtaCheckService.defaultDeadline` is 10 s, so an
/// ordinary "nothing found" concludes inside this with room for the two reads
/// around it — and a router that is merely slow still finishes PnP.
///
/// A provider so that a test can shorten it. There is no other seam: the deadline
/// is consumed inside `PnpNotifier`, which tests reach only through the container,
/// and the alternative is a suite that spends fifteen real seconds per branch.
final pnpFirmwareCheckDeadlineProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 15),
);

/// How long the firmware stage waits for the router to come back after it has
/// been flashed, before showing the WiFi credentials anyway.
///
/// Six minutes, against a measured reboot baseline of four
/// (`kFirmwareRebootBaseline`). Longer than the check's deadline by two orders of
/// magnitude because the two are waiting for different kinds of thing: the check
/// can be concluded ("nothing was found"), whereas a router that has been flashed
/// is coming back or it is not.
///
/// It expires into [WizardWifiReady] rather than into an error, for the reason
/// REQ-B3 gives about the whole stage: a user whose router is not answering needs
/// the credentials to get back onto it, which is precisely the screen this leads
/// to. The dashboard's firmware page owns *reporting* a failed update; PnP owns
/// finishing setup.
final pnpFirmwareRebootDeadlineProvider = Provider<Duration>(
  (ref) => const Duration(minutes: 6),
);
