import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/capability/capability_source.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';

/// The active capability source.
///
/// This is the one seam to override when GSDM lands (linksys/usp_framework#69):
/// swap `GetProbeCapabilitySource` for a `GsdmCapabilitySource` here and nothing
/// downstream changes. Tests override it with a stub that returns a fixed
/// [DeviceCapabilities], so capability resolution needs no live router.
final capabilitySourceProvider = Provider<CapabilitySource>(
  (ref) => const GetProbeCapabilitySource(),
);

/// The capabilities the connected device supports, resolved once at login and
/// carried in `SessionState` (cleared on logout by `SessionNotifier.clear()`).
///
/// Sync — the probe already ran during session entry. Consumers gate UI with
/// `ref.watch(deviceCapabilitiesProvider).has(DeviceCapability.x)`; they never
/// read a DM path or an error code themselves. Before login (or in a session
/// that never resolved, e.g. Remote Assistance) this is
/// [DeviceCapabilities.empty], so any gated feature is hidden — fail-closed.
final deviceCapabilitiesProvider = Provider<DeviceCapabilities>(
  (ref) => ref.watch(sessionProvider.select((s) => s.capabilities)),
);
