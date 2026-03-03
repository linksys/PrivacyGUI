import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';

/// Features that can be served by USP protocol.
///
/// Each enum value maps to a set of JNAP actions that can be replaced
/// by USP TR-181 paths. Add new values as more features are validated.
enum ProtocolFeature {
  deviceInfo,
  wifiRadio,
  wifiAP,
  connectedDevices,
  dhcpReservation,
  portForwarding,
  timeSettings,
  networkDiagnostics,
}

/// Resolves which protocol (JNAP or USP) to use for a given feature.
///
/// Decision logic:
/// 1. If UspService is null (non-Web platform) → JNAP
/// 2. If USP is not authenticated → JNAP
/// 3. If preference is jnapOnly → JNAP
/// 4. If preference is uspOnly → USP
/// 5. If feature is in supported set and preference is auto/uspFirst → USP
/// 6. Otherwise → JNAP
class ProtocolResolver {
  final UspService? _usp;
  final ProtocolPreference _preference;

  ProtocolResolver(this._usp, this._preference);

  /// Returns true when USP is authenticated and JNAP is not forced.
  /// Used to route to the standalone USP Dashboard instead of the
  /// JNAP-polling-dependent main Dashboard.
  bool get isUspOnlyMode =>
      _usp != null &&
      _usp.isAuthenticated &&
      _preference != ProtocolPreference.jnapOnly;

  /// Returns true if USP should be used for the given feature.
  bool useUsp(ProtocolFeature feature) {
    if (_usp == null) return false;
    if (!_usp.isAuthenticated) return false;
    if (_preference == ProtocolPreference.jnapOnly) return false;
    if (_preference == ProtocolPreference.uspOnly) return true;
    // auto or uspFirst: use USP if feature is supported
    return _uspSupportedFeatures.contains(feature);
  }

  /// Features validated with USP support (from Phase 1 validation report).
  static const _uspSupportedFeatures = {
    ProtocolFeature.deviceInfo,
    ProtocolFeature.wifiRadio,
    ProtocolFeature.wifiAP,
    ProtocolFeature.connectedDevices,
    ProtocolFeature.dhcpReservation,
    ProtocolFeature.portForwarding,
    ProtocolFeature.timeSettings,
    ProtocolFeature.networkDiagnostics,
  };
}

final protocolResolverProvider = Provider<ProtocolResolver>((ref) {
  return ProtocolResolver(
    ref.watch(uspServiceProvider),
    BuildConfig.protocolPreference,
  );
});
