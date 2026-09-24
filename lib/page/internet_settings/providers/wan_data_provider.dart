import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_wan_data_service.dart';

// ── Data Model ──

class WanData extends Equatable with DiagnosticLoggable {
  final WanStatusUIModel model;

  const WanData({required this.model});

  @override
  String get diagnosticName => 'WanData';

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

/// Physical WAN link state as a plain `bool`, the single source of truth for
/// "is the WAN up?" across the dashboard, Statistics, and health scoring.
///
/// Defaults to `true` while [wanDataProvider] has never produced a value
/// (first load), so a momentarily-unavailable link state does not read as a
/// false disconnect. During an SSE-triggered `invalidateSelf()` refresh the
/// previous value is preserved (seamless refresh), so this keeps reporting the
/// last known state rather than flipping to the loading default. See #1143.
final wanIsUpProvider = Provider<bool>(
  (ref) => ref.watch(wanDataProvider).valueOrNull?.model.isUp ?? true,
);

// ── Notifier (NOT autoDispose) ──

class WanDataNotifier extends AsyncNotifier<WanData> {
  @override
  Future<WanData> build() async {
    // SSE listener: WAN status changes (link up/down, IP changes)
    // Logged on both sides of the branch. Knowing the listener RAN but did not match is
    // a different fact from it never running, and on FW 2.0 the distinction mattered:
    // this listener fires, `invalidateSelf()` is called, and `build()` is then never
    // re-entered — so nothing below this line is reached again. Without a log here that
    // is indistinguishable from the notification never arriving. See
    // linksys/PrivacyGUI-RealRouter-E2E's R20 spec header for the measurement.
    ref.listen(sseInvalidationProvider, (_, next) {
      final domain = next.valueOrNull?.domain;
      if (domain == InvalidationDomain.wanStatus) {
        logger.d('[WAN] wanStatus invalidation (seq=${next.valueOrNull?.seq}) '
            '→ invalidateSelf()');
        ref.invalidateSelf();
      } else {
        logger.t('[WAN] ignoring ${domain?.name ?? 'no-domain'} invalidation');
      }
    });

    return _fetch();
  }

  Future<WanData> _fetch() async {
    final svc = ref.read(uspWanDataServiceProvider);
    final model = await svc.fetch();
    // The counterpart to the listener log above: together they show whether an
    // invalidation actually produced a re-fetch, which is the link that was broken on
    // FW 2.0.
    logger.d('[WAN] fetched: isUp=${model.isUp} ip="${model.ipAddress}"');

    return WanData(model: model);
  }
}
