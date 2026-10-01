import 'package:privacy_gui/core/capability/capability_resolver.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Resolves which [DeviceCapability]s the connected device supports.
///
/// A swappable seam. The USP-official answer is `GetSupportedDM` (GSDM), but that
/// message has no outbound implementation in this stack yet
/// (linksys/usp_framework#69), so the app ships on [GetProbeCapabilitySource] and
/// swaps to a `GsdmCapabilitySource` when #69 lands — a one-line change at the
/// composition wiring, with no consumer or `SessionState` change, because both
/// sources read the same per-capability path map (`capabilityProbePath`).
abstract class CapabilitySource {
  /// Resolve every declared capability against [usp]. Never throws — a source
  /// that cannot answer resolves the affected capabilities as unavailable
  /// (fail-closed), because a session that cannot start is a worse failure than
  /// a feature that stays hidden.
  Future<DeviceCapabilities> resolveAll(UspClient usp);
}

/// Interim source: infers support from a plain `Get` on each capability's path.
///
/// **Fail-closed on two absence signals.** Firmware may signal "path unknown"
/// either by faulting (`Protocol error … 7026/7027/9005/9007`, which surfaces as
/// a thrown error) or by silently omitting the key from the Get response
/// (`usp_transport.dart`: "missing paths are simply absent"). So a capability is
/// supported **only** when its path comes back present with a non-empty value;
/// a throw, an absent key, or an empty string all mean unsupported. An
/// empty-string value is a real "present but unset" USP fact and must not count
/// as support — it is exactly what `X_LINKSYS_MACFilterMode` reads before any
/// filter is configured, but on that path the value is `Disabled`, not empty;
/// the empty-string guard is the conservative rule for paths that could read
/// blank.
///
/// GSDM (linksys/usp_framework#69) makes this inference unnecessary — it reports
/// support directly — which is why this source is explicitly the interim.
class GetProbeCapabilitySource implements CapabilitySource {
  const GetProbeCapabilitySource();

  static const _tag = '[Capability]';

  @override
  Future<DeviceCapabilities> resolveAll(UspClient usp) async {
    const capabilities = DeviceCapability.values;
    final paths = [for (final c in capabilities) capabilityProbePath(c)];

    final Map<String, dynamic> response;
    try {
      // One batch Get (one round-trip through the throttler) for every path.
      response = await usp.get(paths);
    } catch (e) {
      // A failed probe cannot distinguish which paths exist, so fail closed for
      // all of them — mirrors `SessionService._fetchDeviceUuid`: the absence is
      // the outcome, kept in the log rather than a thrown type.
      logger.w('$_tag probe Get failed, all capabilities unavailable: $e');
      return DeviceCapabilities.empty;
    }

    final supported = <DeviceCapability>{};
    for (final capability in capabilities) {
      final path = capabilityProbePath(capability);
      final value = response[path];
      // Present AND non-empty. `containsKey` false (silently omitted) or an
      // empty-string value both mean unsupported.
      if (value != null && value.toString().isNotEmpty) {
        supported.add(capability);
      } else {
        logger.d(
            '$_tag ${capability.name}: unsupported (path $path absent/empty)');
      }
    }
    return DeviceCapabilities(supported);
  }
}
