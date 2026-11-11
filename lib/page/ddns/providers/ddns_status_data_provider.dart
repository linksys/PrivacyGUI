import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/ddns/models/ddns_update_status.dart';
import 'package:privacy_gui/page/ddns/services/usp_ddns_status_data_service.dart';

/// L1: the update status the router reports for the DDNS client the page
/// edits.
///
/// Read-only and changed by the router itself as an update runs, so the page
/// reads it from here rather than from its working copy (constitution Article
/// IV §4.2). `Client.Status`, `Client.LastError` and the host name's `Status`
/// change by ValueChange (`ddns-valuechange` on `Device.DynamicDNS.Client.`),
/// so the status follows an update without polling, where 1.0 polled
/// `GetDDNSStatus`.
///
/// No other surface reads it, so it is not in the dashboard orchestrator's
/// domain list: a read there would cost every session a GET for a page most
/// never open. The page's own reads re-read it instead (`UspDdnsNotifier`).
final ddnsStatusDataProvider =
    AsyncNotifierProvider<DdnsStatusDataNotifier, DdnsUpdateStatus>(
  DdnsStatusDataNotifier.new,
);

/// Reads the status through [UspDdnsStatusDataService] when first watched, and
/// again 500 ms after the last pushed [InvalidationDomain.dynamicDns], so the
/// burst one update causes (`Status`, `LastError`, the host name's `Status`
/// and `LastUpdate`) costs one read. A pushed read that fails keeps the value
/// it had.
class DdnsStatusDataNotifier extends AsyncNotifier<DdnsUpdateStatus> {
  Timer? _debounce;

  /// Bumped by every rebuild and every read this notifier publishes itself, so
  /// a read that started earlier and finishes later is discarded instead of
  /// overwriting newer data.
  int _generation = 0;

  @override
  Future<DdnsUpdateStatus> build() async {
    // A rebuild (the page's re-read) supersedes any read in flight, and a
    // timer armed before it would only re-read what the rebuild just read.
    final generation = ++_generation;
    _debounce?.cancel();

    ref.listen(sseInvalidationProvider, (prev, next) {
      if (next.valueOrNull?.domain == InvalidationDomain.dynamicDns) {
        _debouncedRefresh();
      }
    });

    ref.onDispose(() => _debounce?.cancel());

    final status = await ref.read(uspDdnsStatusDataServiceProvider).fetch();
    // The other direction: a refresh that started after this read and
    // published first holds the newer value, and assigning `state` does not
    // cancel this future, so returning the older read would overwrite it.
    if (generation != _generation && state.hasValue) return state.requireValue;
    return status;
  }

  /// Re-reads the status now, for the page's refresh icon.
  ///
  /// The value stays on screen while the read runs, and stays if it fails:
  /// the failure is thrown for the caller to report.
  Future<void> refresh() async {
    _debounce?.cancel();
    final generation = ++_generation;
    final status =
        await ref.read(uspDdnsStatusDataServiceProvider).fetch(fresh: true);
    if (generation != _generation) return;
    state = AsyncData(status);
  }

  void _debouncedRefresh() {
    _debounce?.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 500), () => _refreshFromPush());
  }

  /// Publishes by assigning [state] rather than invalidating, so the read
  /// happens whether or not anything is watching, and the listener in
  /// [build] stays registered (#1615).
  Future<void> _refreshFromPush() async {
    try {
      await refresh();
    } on ServiceError catch (e, st) {
      logger.w('[DDNS] push-triggered refetch failed, keeping previous value',
          error: e, stackTrace: st);
    }
  }
}
