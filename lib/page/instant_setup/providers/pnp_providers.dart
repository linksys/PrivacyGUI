import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_notifier.dart';

final pnpProvider = NotifierProvider<PnpNotifier, PnpState>(
  PnpNotifier.new,
);

/// How long the WiFi write is waited for before the save stops waiting for its
/// answer and starts polling the router instead.
///
/// The write restarts the network the browser is on, so whether its answer
/// arrives depends on whether the router replies before the restart takes the
/// connection: on 1.2.x it did (7.7 s); on 2.0.2 a guest-only write was answered
/// in 25 s, after the restart had run (bench, 2026-10-05), and a rename never was.
/// Thirty covers the 25 s. Ending the wait early is safe either way: an
/// unanswered write is read back from the router before setup finishes.
final pnpWifiAnswerWindowProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 30),
);

/// How often the router is polled while waiting for it to be reachable again.
final pnpReconnectPollIntervalProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 3),
);

/// How long after the write the save keeps polling before it asks the user to
/// reconnect by hand.
///
/// Counted from the write, not from the end of the answer window, so it is the
/// longest a user watches the saving spinner. On 2.0.2 the renamed network went
/// on the air 40 s after the write (bench, 2026-10-05), and a browser that stays
/// on an unchanged name rejoined 23 s after the write; neither comes back faster
/// than the router, so 60 s leaves room for both. A rename still ends on the
/// reconnect step — the browser cannot join a network it does not know — whose
/// copy says the restart takes about a minute.
final pnpSaveDeadlineProvider = Provider<Duration>(
  (ref) => const Duration(seconds: 60),
);

/// The wait before reconnect attempt `n` (1-based) on the reconnect step:
/// 2, 4, 8, 16, 32 seconds.
///
/// This and the two above are providers for the same reason as the deadlines
/// below — the only seam a test has into `PnpNotifier` is the container, and the
/// real waits add up to minutes per case.
final pnpReconnectBackoffProvider = Provider<Duration Function(int attempt)>(
  (ref) => (attempt) => Duration(seconds: 1 << attempt),
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
