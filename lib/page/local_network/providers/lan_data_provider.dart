import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';
import 'package:privacy_gui/page/_shared/models/lan_info_ui_model.dart';
import 'package:privacy_gui/page/local_network/services/usp_lan_data_service.dart';

// ── Data Model ──

class LanData extends Equatable with DiagnosticLoggable {
  final LanInfoUIModel model;

  const LanData({required this.model});

  const LanData.empty()
      : model = const LanInfoUIModel(
          ipAddress: '',
          subnetMask: '',
          dhcpEnabled: false,
          minAddress: '',
          maxAddress: '',
        );

  @override
  String get diagnosticName => 'LanData';

  @override
  Map<String, Object?> get namedProps => {'model': model};
}

// ── Provider ──

final lanDataProvider =
    AsyncNotifierProvider<LanDataNotifier, LanData>(LanDataNotifier.new);

// ── Notifier (NOT autoDispose) ──

class LanDataNotifier extends AsyncNotifier<LanData> {
  Timer? _debounce;

  /// Which push refresh is allowed to publish — see [_refreshFromPush].
  int _pushGeneration = 0;

  @override
  Future<LanData> build() async {
    // A rebuild (the Local Network save's invalidate) supersedes any push in
    // flight, as in dhcp_data_provider.
    _pushGeneration++;
    _debounce?.cancel();

    // A LAN subnet change moves the pool after the Set has returned, so the
    // post-save read can hold the old range; the router then pushes the range
    // it settled on (PrivacyGUI#1729). The LAN address itself has no domain:
    // a mask change also moves Pool.{i}.SubnetMask, which is a pool push.
    ref.listen(sseInvalidationProvider, (_, next) {
      if (next.valueOrNull?.domain == InvalidationDomain.lanDhcpPool) {
        _debouncedRefresh();
      }
    });

    ref.onDispose(() => _debounce?.cancel());
    return _fetch();
  }

  Future<LanData> _fetch() async {
    final svc = ref.read(uspLanDataServiceProvider);
    final model = await svc.fetch();

    return LanData(model: model);
  }

  /// One refresh for the burst a pool change pushes (MinAddress, MaxAddress
  /// and SubnetMask arrive together).
  void _debouncedRefresh() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _refreshFromPush());
  }

  /// Re-reads and publishes, keeping the previous value on failure. Assigns
  /// `state` rather than `invalidateSelf()`, which re-reads only when someone
  /// reads the provider (#1615); only the newest refresh publishes (#1618).
  /// Same shape as firewall_data_provider.
  Future<void> _refreshFromPush() async {
    final generation = ++_pushGeneration;
    try {
      final data = await _fetch();
      if (generation != _pushGeneration) return;
      state = AsyncData(data);
    } catch (e, st) {
      logger.w(
          '[USP][LanData] push-triggered refetch failed, keeping previous value',
          error: e,
          stackTrace: st);
    }
  }
}
