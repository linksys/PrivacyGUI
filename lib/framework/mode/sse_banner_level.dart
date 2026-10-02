/// How urgently a surface wants an SSE connection state reported to the person
/// looking at it.
///
/// Cause 5's one non-`Widget` vocabulary, and it exists because the *same*
/// [SseConnectionState] means two different things to the two modes. Locally a
/// dropped stream is a fault: the router is on the other end of a LAN and should
/// not be closing anything.
///
/// **Under Remote Assistance the banner says nothing at all** (2026-10-01). The
/// stream runs to Guardian, which force-closes it at roughly ten minutes, so a
/// closed stream is routine there; the banner's copy is about the router, which
/// the stream does not reach; and it sat over every login, because the stream
/// opens after the first reads. An earlier version graded these as warnings
/// instead, and that was still a banner naming the wrong thing. The remote
/// stream is reported on the session chip, in words about the cloud.
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
