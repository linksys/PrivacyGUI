import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/generated/system_info.g.dart';
import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';

// ---------------------------------------------------------------------------
// Provider
// ---------------------------------------------------------------------------

/// Returns null when USP is not available (polling providers check before use).
final uspSystemMonitorServiceProvider = Provider<UspSystemMonitorService?>(
  (ref) {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) return null;
    return UspSystemMonitorService(usp);
  },
);

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

/// Stateless service for fetching a single system monitor snapshot.
///
/// Owns the codegen call for [uspSystemMonitorProvider].
/// No error mapping — polling providers silently catch errors.
class UspSystemMonitorService {
  final UspService _usp;

  UspSystemMonitorService(this._usp);

  bool get isAuthenticated => _usp.isAuthenticated;

  /// Fetches current CPU/memory stats and returns a [SystemSnapshot].
  Future<SystemSnapshot> fetchSnapshot() async {
    final info = await SystemInfo.fetch(_usp);
    final cpuPercent = info.cpuUsage.clamp(0, 100);
    final memPercent = info.totalMemory > 0
        ? ((info.totalMemory - info.freeMemory) / info.totalMemory * 100)
            .round()
            .clamp(0, 100)
        : 0;

    return SystemSnapshot(
      timestamp: DateTime.now(),
      cpuPercent: cpuPercent,
      memoryPercent: memPercent,
      totalMemoryKb: info.totalMemory,
      freeMemoryKb: info.freeMemory,
    );
  }
}
