/// How the router took a reboot or factory reset request (#1777).
enum RouterRestartStart {
  /// `Device.Reboot()` / `Device.FactoryReset()`: the router goes down soon
  /// after it replies. The router has no whole-network commands — older
  /// firmware, or a unit with the mesh off, which has no DataElements
  /// `Network` object.
  router,

  /// `X_LINKSYS_RebootAll()` / `X_LINKSYS_FactoryResetAll()` started
  /// (Architecture#195). The controller commands its agents one hop level at a
  /// time, farthest first, and goes down last, so the reply says nothing about
  /// when it goes.
  network,

  /// The whole-network command was refused because one is already running
  /// (7002, Status `Busy`). Nothing new was started.
  alreadyRunning,
}

/// `Device.WiFi.DataElements.Network.X_LINKSYS_NetworkActionStatus`
/// (Architecture#195): where the controller is in a whole-network reboot or
/// factory reset.
enum NetworkActionStatus {
  /// `""`: no whole-network action since the controller booted, or one that
  /// has not reported yet.
  idle,

  /// The controller is commanding its agents.
  running,

  /// The controller's own `Device.Reboot()` / `Device.FactoryReset()` was
  /// accepted, so it goes down next.
  completed,

  /// The controller's own command failed or did not answer within 30 s. The
  /// agents may have acted; the controller stays up.
  failed,

  /// A value the definition does not name. A waiter keeps waiting on it, and
  /// a press sends the command anyway: if one is in fact running, the command
  /// is refused as busy, and a value left behind by a finished action does not
  /// lock the buttons until the router restarts.
  unknown;

  /// Reads the leaf's value.
  static NetworkActionStatus fromValue(String value) => switch (value) {
        '' => idle,
        'Running' => running,
        'Completed' => completed,
        'Failed' => failed,
        _ => unknown,
      };
}

/// How waiting for a whole-network action ended
/// (`UspAdminNotifier.awaitNetworkAction`).
enum NetworkActionOutcome {
  /// Read [NetworkActionStatus.completed]: the controller is going down now.
  controllerGoingDown,

  /// Read [NetworkActionStatus.failed]: the controller did not go down.
  failed,

  /// The status could not be read: the controller went down, or the node this
  /// app reaches it through did.
  unreachable,

  /// The limit came with no answer that settles it: the controller is still
  /// up, and has not said it is going down.
  timedOut,

  /// The app stopped waiting for the router, so the reads stopped too.
  abandoned,
}
