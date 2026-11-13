/// How a run of the no-internet troubleshooting flow ends, supplied by whoever
/// started it (#1511 P1).
///
/// Troubleshooting never asks who its caller is. The caller is a segment of every
/// troubleshooting URL — so a reload keeps it — and the route layer turns that
/// segment into one of these and hands it to each page that can end the run.
class TroubleshootingEnding {
  const TroubleshootingEnding({
    required this.exitLocation,
    this.continueWithoutInternet,
  });

  /// Where the user goes once the run is over: the internet is back, or the
  /// router could not be read and the caller has to look again.
  final String exitLocation;

  /// The hub's "Log into router" escape: runs whatever the caller needs done
  /// first and answers where to go.
  ///
  /// `null` for a caller with nothing to continue into, and the hub then offers
  /// no such button.
  final Future<String> Function()? continueWithoutInternet;
}
