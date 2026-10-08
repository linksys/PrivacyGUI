import 'package:privacy_gui/core/capability/device_capability.dart';

/// The DM path whose presence proves a [DeviceCapability] is supported.
///
/// This is the **composition root** of the capability subsystem: a `switch`
/// over [DeviceCapability] with **no `default:` and no `_ =>` arm**, so a new
/// capability is a compile error here until it is given a path. It is guarded by
/// `test/core/capability/capability_composition_root_test.dart` the same way the
/// mode roots are guarded (constitution Article XVII Rule 1).
///
/// The map is **source-agnostic**: `GetProbeCapabilitySource` uses the path as a
/// plain `Get` target today, and a future `GsdmCapabilitySource`
/// (linksys/usp_framework#69) uses it as a `GetSupportedDM` `obj_paths` entry —
/// neither owns the path, so swapping sources changes no capability definition.
///
/// A linksys-overlay path is chosen deliberately: on firmware without the
/// feature such a path is absent from the schema (cleanly resolvable as
/// unsupported), whereas a base-TR-181 leaf can be present-but-dead — see
/// #1635's design note.
String capabilityProbePath(DeviceCapability capability) {
  return switch (capability) {
    DeviceCapability.autoIPoE => 'Device.X_LINKSYS_AutoIPoE.APIVersion',
    DeviceCapability.wifiMacFilter =>
      'Device.WiFi.DataElements.Network.X_LINKSYS_MACFilterMode',
  };
}
