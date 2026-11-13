import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/dynamic_dns.g.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';

final uspDdnsStatusDataServiceProvider =
    Provider<UspDdnsStatusDataService>((ref) {
  final usp = ref.read(uspClientProvider);
  if (usp == null) {
    throw const ServiceNotInitializedError(detail: 'USP service not available');
  }
  return UspDdnsStatusDataService(usp);
});

/// Stateless L1 Service for the update status the router reports for the
/// client the DDNS page edits.
///
/// Owns the codegen read for `ddnsStatusDataProvider`.
class UspDdnsStatusDataService {
  final UspClient _usp;

  UspDdnsStatusDataService(this._usp);

  /// Reads the status of the first client, judged with its first host name:
  /// the rows the page edits.
  ///
  /// [fresh] drops the throttler's GET cache first. The cache answers a
  /// repeated read for 5 s and only the app's own writes clear it, so a read
  /// made because the router pushed a change it made itself (an update that
  /// finished) would otherwise replay the status from before it. Same remedy
  /// as `UspMacFilterDataService.fetch` (#1755).
  Future<DdnsUpdateStatus> fetch({bool fresh = false}) async {
    if (fresh) _usp.throttler?.clearCache();
    try {
      return statusOf(await DynamicDns.fetch(_usp));
    } on ServiceError {
      rethrow;
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
  }

  /// The status of the first client of [ddns]. A router with no client row
  /// sends no update, which is what [DdnsUpdateStatus.disabled] says.
  static DdnsUpdateStatus statusOf(DynamicDns ddns) {
    if (ddns.clients.isEmpty) return DdnsUpdateStatus.disabled;
    final client = ddns.clients.first;
    return DdnsUpdateStatus.fromWire(
      clientStatus: client.status,
      lastError: client.lastError,
      hostnameStatus:
          client.hostnames.isEmpty ? null : client.hostnames.first.status,
    );
  }
}
