/// What a Dynamic DNS client's last update came to, read from the three
/// TR-181 values that carry it: `Client.Status`, `Client.LastError` and the
/// host name's `Status` (linksys/FWDEV#191 implementation doc §7.3 and §9.3).
///
/// 1.0 reported this as one enum (`GetDDNSStatus2`). TR-181 has no such enum,
/// so the firmware gives each 1.0 state a distinct combination of standard
/// values, and [DdnsUpdateStatus.fromWire] reads the combination back.
enum DdnsUpdateStatus {
  /// `Disabled`: the client sends nothing. The page shows no status.
  disabled,

  /// `Connecting` (or TR-181's `Authenticating`, which this firmware does not
  /// report): an update is on its way.
  connecting,

  /// `Updated`: the provider took the last update.
  success,

  /// `Error` + `AUTHENTICATION_ERROR`: the provider refused the user name or
  /// password.
  authenticationFailed,

  /// `Error_Misconfigured` + the host name's `Error`: the host name is badly
  /// formed, or the provider does not know it. The only combination with that
  /// pair, so a missing password never reads as this.
  invalidHostname,

  /// `Error_Misconfigured` with the host name in any other state: the
  /// provider, the account or the host name is missing.
  settingsIncomplete,

  /// `Error` + `CONNECTION_ERROR`: the provider did not answer, or the router
  /// has no WAN address, or only a private one.
  connectionFailed,

  /// `Error` with any other `LastError`: the provider refused the update.
  failed,

  /// A `Client.Status` outside the firmware's contract. Shown as unknown
  /// rather than guessed.
  unknown;

  /// Reads the combination of [clientStatus], [lastError] and
  /// [hostnameStatus] (the host name the page edits; null when the client has
  /// none).
  static DdnsUpdateStatus fromWire({
    required String clientStatus,
    required String lastError,
    required String? hostnameStatus,
  }) {
    switch (clientStatus) {
      case 'Disabled':
        return DdnsUpdateStatus.disabled;
      case 'Connecting':
      case 'Authenticating':
        return DdnsUpdateStatus.connecting;
      case 'Updated':
        return DdnsUpdateStatus.success;
      case 'Error_Misconfigured':
        return hostnameStatus == 'Error'
            ? DdnsUpdateStatus.invalidHostname
            : DdnsUpdateStatus.settingsIncomplete;
      case 'Error':
        return switch (lastError) {
          'AUTHENTICATION_ERROR' => DdnsUpdateStatus.authenticationFailed,
          'CONNECTION_ERROR' => DdnsUpdateStatus.connectionFailed,
          _ => DdnsUpdateStatus.failed,
        };
      default:
        return DdnsUpdateStatus.unknown;
    }
  }
}
