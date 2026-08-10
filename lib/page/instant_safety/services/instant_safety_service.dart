import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/lan_network_info.g.dart';
import 'package:privacy_gui/page/instant_safety/models/safe_browsing_ui_model.dart';

/// Service provider — per Article VI.
final uspInstantSafetyServiceProvider = Provider<UspInstantSafetyService>(
  (ref) => UspInstantSafetyService(ref.read(uspClientProvider)!),
);

/// Transforms codegen [LanNetworkInfo] into [SafeBrowsingUIModel] and provides
/// DNS value mapping for save operations.
///
/// OpenDNS Family Shield IPs are identical to the JNAP version (NOW-713).
class UspInstantSafetyService {
  final UspClient _usp;

  UspInstantSafetyService(this._usp);

  static const _openDnsDns1 = '208.67.222.222';
  static const _openDnsDns2 = '208.67.220.220';
  static const _openDnsValue = '$_openDnsDns1,$_openDnsDns2';

  /// Returns true if the DNS servers string indicates OpenDNS is active.
  static bool isOpenDns(String dnsServers) {
    final first = dnsServers.split(',').firstOrNull?.trim() ?? '';
    return first == _openDnsDns1;
  }

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
      // Uses the default allow_partial=false (atomic). Safe here because this
      // SET touches a single USP micro-service (DHCPv4.Server.Pool DNSServers).
      // The OBUSPA broker only rejects atomic SETs that span more than one
      // service with 7005 — see _saveIpv6Settings in
      // usp_internet_settings_service.dart, which must relax this. Keep this SET
      // single-service; if it ever grows to touch another service, switch to
      // allowPartial: true.
      final result = await LanNetworkInfo.update(_usp, dnsServers: dnsValue);
      final parsed = UspResultParser.parseSetResult(result);
      switch (parsed) {
        case UspSuccess():
          break;
        case UspPartialSuccess(
            :final errorSummary,
            :final successes,
            :final failures
          ):
          throw UspPartialFailureError(
            summary: 'Safe browsing update partial failure: $errorSummary',
            successPaths: successes.map((s) => s.requestedPath).toList(),
            failures: failures,
          );
        case UspFailure(:final errorSummary, :final errors):
          throw UspCompleteFailureError(
            summary: 'Safe browsing update failed: $errorSummary',
            failures: errors,
          );
      }
    } catch (e) {
      if (e is ServiceError) rethrow;
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
    return isOpenDns(dnsServers)
        ? SafeBrowsingType.openDNS
        : SafeBrowsingType.off;
  }

  /// Returns the DNS servers value to write for the given type.
  String dnsValueForType(SafeBrowsingType type) => switch (type) {
        SafeBrowsingType.openDNS => _openDnsValue,
        SafeBrowsingType.off => '',
      };
}
