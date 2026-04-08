/// Keys for the JNAP capability map stored in [InstantVerifyPivotState].
///
/// Each key maps to a bool: true = field was present and non-null in the last
/// JNAP response for this device/firmware; false or absent = not supported.
///
/// This map allows VerdictEngine checks to be silently skipped when the
/// required JNAP data is not available on a specific firmware version,
/// rather than producing null-based false all-clears.
///
/// Populated in [InstantVerifyPivotNotifier._buildCapabilityMap()] after
/// Phase 1c supplementary calls complete.
class JnapCapability {
  const JnapCapability._();

  // ── Backhaul / Mesh ──────────────────────────────────────────────────────

  /// GetBackhaulInfo returned at least one backhaul entry.
  static const String backhaulDataPresent = 'backhaul.present';

  /// GetBackhaulInfo.backhaulDevices[n].speedMbps was non-null and parseable.
  /// Enables zombie-node detection (Check 18).
  static const String backhaulSpeedMbps = 'backhaul.speedMbps';

  /// GetBackhaulInfo.backhaulDevices[n].rssi was present.
  static const String backhaulRssi = 'backhaul.rssi';

  // ── System / Health ───────────────────────────────────────────────────────

  /// GetSystemStats returned a CPU load value (key varies by firmware).
  /// Enables CPU saturation check (Check 13).
  static const String cpuLoad = 'system.cpuLoad';

  /// GetSystemStats returned a memory load value.
  /// Enables memory saturation check (Check 13).
  static const String memoryLoad = 'system.memoryLoad';

  // ── Radio / WiFi ──────────────────────────────────────────────────────────

  /// GetRadioInfo3 returned at least one radio entry.
  static const String radioInfoPresent = 'radio.present';

  /// GetRadioInfo3 returned isBandSteeringSupported field.
  /// Enables band steering mis-steer check (Check 16).
  static const String bandSteeringState = 'radio.bandSteering';

  /// GetRadioInfo3 returned signalToNoiseRatio — NOTE: this field does NOT
  /// exist on Pinnacle/MX firmware. Always false on current hardware.
  /// Retained to document the known gap.
  static const String radioSnr = 'radio.snr'; // Expected: always false

  // ── Ethernet / LAN ────────────────────────────────────────────────────────

  /// GetEthernetPortConnections returned lanPortConnections list.
  /// Enables ethernet no-link check (Check 17).
  static const String ethernetPortStatus = 'ethernet.portStatus';

  /// GetLANSettings.dhcpSettings.firstClientIPAddress was present.
  /// Enables accurate DHCP pool size calculation (replacing hardcoded 150).
  static const String dhcpPoolRange = 'lan.dhcpPoolRange';

  // ── Security ──────────────────────────────────────────────────────────────

  /// GetNetworkSecuritySettings returned a value that could indicate PMF mode.
  /// Enables PMF Required detection (Check 15).
  static const String pmfModePresent = 'security.pmfMode';

  // ── Scheduler / Parental ──────────────────────────────────────────────────

  /// GetWirelessSchedulerSettings returned isEnabled field.
  /// Enables WiFi schedule blocking check (Check 12).
  static const String wifiSchedulePresent = 'scheduler.isEnabled';

  /// GetParentalControlSettings returned an enabled/disabled state.
  /// Enables Instant Pause detection (Check 12).
  static const String parentalControlsPresent = 'parental.enabled';

  // ── Device Mode ───────────────────────────────────────────────────────────

  /// GetDeviceMode returned a mode string.
  /// Enables AP mode detection (suppresses double-NAT false positive).
  static const String deviceModePresent = 'device.mode';

  // ── Clients ───────────────────────────────────────────────────────────────

  /// GetNodesWirelessNetworkConnections returned per-client txRate/rxRate.
  /// If false, rate-based checks (Check 16, signal score) use signal only.
  static const String clientTxRxRates = 'clients.txRxRates';
}
