import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';

/// Service provider — per Article VI.
final uspInstantSafetyServiceProvider = Provider<UspInstantSafetyService>(
  (ref) => UspInstantSafetyService(ref.read(uspServiceProvider)!),
);

/// Transforms codegen [LanNetworkInfo] into [SafeBrowsingUIModel] and provides
/// DNS value mapping for save operations.
///
/// OpenDNS Family Shield IPs are identical to the JNAP version (NOW-713).
class UspInstantSafetyService {
  final UspService _usp;

  UspInstantSafetyService(this._usp);

  static const _openDnsDns1 = '208.67.222.222';
  static const _openDnsDns2 = '208.67.220.220';
  static const _openDnsValue = '$_openDnsDns1,$_openDnsDns2';

  // ─── CRUD ──────────────────────────────────────────────────

  /// Fetch LAN network info and transform to safe browsing UI model.
  Future<SafeBrowsingUIModel> fetch() async {
    try {
      final data = await LanNetworkInfo.fetch(_usp);
      return buildUIModel(data);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// Save safe browsing DNS setting.
  Future<void> save(SafeBrowsingType type) async {
    try {
      final dnsValue = dnsValueForType(type);
      await LanNetworkInfo.save(_usp, dnsServers: dnsValue);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  // ─── Transform ─────────────────────────────────────────────

  /// Codegen LanNetworkInfo → SafeBrowsingUIModel.
  SafeBrowsingUIModel buildUIModel(LanNetworkInfo data) {
    final type = _detectType(data.dnsServers);
    return SafeBrowsingUIModel(
      type: type,
      currentDnsServers: data.dnsServers,
    );
  }

  /// Detect safe browsing type from the raw DNS servers string.
  SafeBrowsingType _detectType(String dnsServers) {
    final first = dnsServers.split(',').firstOrNull?.trim() ?? '';
    return first == _openDnsDns1
        ? SafeBrowsingType.openDNS
        : SafeBrowsingType.off;
  }

  /// Returns the DNS servers value to write for the given type.
  String dnsValueForType(SafeBrowsingType type) => switch (type) {
        SafeBrowsingType.openDNS => _openDnsValue,
        SafeBrowsingType.off => '',
      };
}
