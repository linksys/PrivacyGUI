import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/errors/usp_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/generated/multi_interface_traffic_stats.g.dart';
import 'package:privacy_gui/page/_shared/models/traffic_analysis_state.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Returns null when USP is not available (polling providers check before use).
final uspTrafficAnalysisServiceProvider = Provider<UspTrafficAnalysisService?>(
  (ref) {
    final usp = ref.read(uspClientProvider);
    if (usp == null) return null;
    return UspTrafficAnalysisService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless service for fetching multi-interface traffic baselines.
///
/// Owns the codegen call for [uspTrafficAnalysisProvider]. A failed read is
/// mapped to a [ServiceError] (constitution Article XIII), so the poller can
/// count it (#1212) — before, it was a raw string nothing counted.
class UspTrafficAnalysisService {
  final UspClient _usp;

  UspTrafficAnalysisService(this._usp);

  /// Fetches current WAN/LAN traffic counters and returns baselines.
  ///
  /// The provider is responsible for computing rates by comparing
  /// consecutive baselines.
  Future<Map<TrafficInterface, InterfaceBaseline>> fetchBaselines() async {
    final MultiInterfaceTrafficStats stats;
    try {
      stats = await MultiInterfaceTrafficStats.fetch(_usp);
    } catch (e) {
      throw mapUspErrorToServiceError(e);
    }
    return {
      TrafficInterface.wan: InterfaceBaseline(
        bytesSent: stats.wanBytesSent,
        bytesReceived: stats.wanBytesReceived,
        packetsSent: stats.wanPacketsSent,
        packetsReceived: stats.wanPacketsReceived,
        errorsSent: stats.wanErrorsSent,
        errorsReceived: stats.wanErrorsReceived,
        discardsSent: stats.wanDiscardPacketsSent,
        discardsReceived: stats.wanDiscardPacketsReceived,
      ),
      TrafficInterface.lan: InterfaceBaseline(
        bytesSent: stats.lanBytesSent,
        bytesReceived: stats.lanBytesReceived,
        packetsSent: stats.lanPacketsSent,
        packetsReceived: stats.lanPacketsReceived,
        errorsSent: stats.lanErrorsSent,
        errorsReceived: stats.lanErrorsReceived,
        discardsSent: stats.lanDiscardPacketsSent,
        discardsReceived: stats.lanDiscardPacketsReceived,
      ),
    };
  }
}
