import 'package:equatable/equatable.dart';

/// A device feature whose availability depends on the connected firmware.
///
/// One value per feature that some firmware serves and some does not. The set is
/// closed and switched over exhaustively by [CapabilitySource] implementations
/// (see `capability_resolver.dart`) with **no `default:` / no `_` arm**, so
/// adding a value here is a compile error until every source gives it a rule —
/// the same guard `AppMode` gets in the mode-strategy subsystem (constitution
/// Article XVII).
///
/// This is deliberately an enum of *causes*, not a per-firmware flag table: the
/// mode subsystem recorded (proximity_strategy.dart) that a capability table with
/// scattered homes was rejected. Availability is resolved once per session and
/// carried in [DeviceCapabilities]; consumers ask [DeviceCapabilities.has].
enum DeviceCapability {
  /// WiFi MAC filtering via `Device.WiFi.DataElements.Network.X_LINKSYS_*`
  /// (linksys/FWDEV#194). The old `Device.WiFi.AccessPoint.*` path is dead on
  /// FLWRT 2.0, so this gates the shared MAC-filter feature (#1636).
  wifiMacFilter,
}

/// The resolved set of capabilities the connected device supports.
///
/// Immutable and compared by contents, so storing it in `SessionState` notifies
/// listeners only when the set actually changes (mirrors the const/equality
/// discipline `LocalModeProfile` uses so `appModeProfileProvider` does not
/// spuriously notify).
///
/// Resolved **at login** and cleared on logout by `SessionNotifier.clear()`, so a
/// log-out / log-in against a different router re-resolves rather than leaking a
/// stale answer across sessions.
class DeviceCapabilities extends Equatable {
  final Set<DeviceCapability> _supported;

  const DeviceCapabilities._(this._supported);

  /// Nothing supported — the pre-login default and the fail-closed answer for a
  /// session that never resolved (e.g. Remote Assistance, which does not fetch
  /// device info). A feature gated on any capability is hidden here.
  static const empty = DeviceCapabilities._(<DeviceCapability>{});

  /// Builds from a resolved set. Copies defensively so the value object cannot be
  /// mutated through the caller's reference.
  factory DeviceCapabilities(Set<DeviceCapability> supported) =>
      DeviceCapabilities._(Set.unmodifiable(supported));

  /// Whether [capability] is supported by the connected device. Sync — the probe
  /// already ran at login; consumers never await.
  bool has(DeviceCapability capability) => _supported.contains(capability);

  @override
  List<Object?> get props => [_supported];
}
