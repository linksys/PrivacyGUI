import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';

// ── Data Model ──

class WanData extends Equatable with DiagnosticLoggable {
  final WanStatusUIModel model;

  const WanData({required this.model});

  @override
  Map<String, Object?> get namedProps => {'model': model};
}

// ── Provider ──

/// Layer 1 data provider for WAN status.
///
/// SSE invalidation: listens to [InvalidationDomain.wanStatus] for
/// WAN interface status changes (Up/Down, IP address changes).
final wanDataProvider =
    AsyncNotifierProvider<WanDataNotifier, WanData>(WanDataNotifier.new);

// ── Notifier (NOT autoDispose) ──

class WanDataNotifier extends AsyncNotifier<WanData> {
  @override
  Future<WanData> build() async {
    // SSE listener: WAN status changes (link up/down, IP changes)
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.value == InvalidationDomain.wanStatus) {
        ref.invalidateSelf();
      }
    });

    return _fetch();
  }

  Future<WanData> _fetch() async {
    final svc = ref.read(uspWanDataServiceProvider);
    final model = await svc.fetch();

    return WanData(model: model);
  }
}
