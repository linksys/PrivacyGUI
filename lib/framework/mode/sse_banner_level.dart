/// How urgently a surface wants an SSE connection state reported to the person
/// looking at it.
///
/// Cause 5's one non-`Widget` vocabulary, and it exists because the *same*
/// [SseConnectionState] means two different things to the two modes. Locally a
/// dropped stream is a fault: the router is on the other end of a LAN and should
/// not be closing anything. Under Remote Assistance, Guardian force-closes every
/// proxied stream at roughly ten minutes, so the identical `disconnected` is the
/// most routine event in a support session — reporting it in danger colours
/// trains the agent to ignore the banner, which is the one outcome worse than
/// hiding it.
///
/// An enum rather than a `bool isSevere`, per Article XVII Rule 4: the banner
/// switches on it in two places (the grace period and the colour pair), and a
/// third level is the shape the next surface will want. [hidden] is not dead —
/// `connected` maps to it, and having a level for "nothing to say" is what lets
/// the banner ask the strategy *before* deciding whether to render at all.
enum SseBannerLevel {
  /// Nothing to report — the banner does not render.
  hidden,

  /// Worth knowing, not worth alarm: shown in warning colours, and only after
  /// the banner's grace period, so a stream that comes straight back never
  /// flashes anything.
  warning,

  /// The stream is not coming back on its own. Shown immediately, in danger
  /// colours, with the Reconnect affordance.
  danger,
}
