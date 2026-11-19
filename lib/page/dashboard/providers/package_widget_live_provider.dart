import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/dashboard/models/cgi_call_result.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_data_provider.dart';
import 'package:privacy_gui/page/dashboard/services/package_widget_service.dart';

/// The live side of one package widget card: its initial fetch, its SSE
/// subscription or HTTP poll, and its `refresh_data` / `cgi_call` actions.
///
/// AutoDispose, so the live updates stop when the card leaves the dashboard;
/// everything it reads lands in [packageWidgetDataProvider], which outlives it.
///
/// Keyed by the [PackageWidgetTemplate] the card already holds (it is
/// `Equatable`).
///
/// The state is whether the initial fetch has finished.
final packageWidgetLiveProvider = NotifierProvider.autoDispose
    .family<PackageWidgetLiveNotifier, bool, PackageWidgetTemplate>(
  PackageWidgetLiveNotifier.new,
);

class PackageWidgetLiveNotifier
    extends AutoDisposeFamilyNotifier<bool, PackageWidgetTemplate> {
  Future<void> Function()? _sseCleanup;
  Timer? _pollTimer;

  /// False once the card has left: a result that arrives after that is
  /// dropped, as the widget's `mounted` checks used to drop it.
  bool _active = false;

  @override
  bool build(PackageWidgetTemplate template) {
    _active = true;
    ref.onDispose(() {
      _active = false;
      _pollTimer?.cancel();
      _sseCleanup?.call();
    });
    Future.microtask(_start);
    return false;
  }

  PackageWidgetDataNotifier get _cache =>
      ref.read(packageWidgetDataProvider(arg.widgetId).notifier);

  Future<void> _start() async {
    final subscription = arg.subscription;
    final dataSource = arg.dataSource;
    try {
      if (subscription != null) {
        await _startUsp(subscription);
      } else if (dataSource != null) {
        await _fetchHttp(dataSource);
        if (_active) _startPolling(dataSource);
      }
    } catch (e, stack) {
      // Constitution 13.4.3: until this ends, the card is a loading card with
      // no way out. The service types every failure from the router, so what
      // reaches here is a bug of ours — it still ends the initial fetch, as a
      // failed fetch does.
      logger.e(
          '[PkgWidget]: Initial fetch for ${arg.widgetId} failed outside '
          'the service',
          error: e,
          stackTrace: stack);
    }
    if (_active) state = true;
  }

  /// The `refresh_data` action and the header's refresh button: reads the
  /// widget's data again. Completes once the read has finished; a failed read
  /// is logged and leaves the data as it was.
  Future<void> refresh() async {
    final subscription = arg.subscription;
    final dataSource = arg.dataSource;
    if (subscription != null) {
      await _refreshUsp(subscription);
    } else if (dataSource != null) {
      await _fetchHttp(dataSource);
    }
  }

  Future<void> _refreshUsp(WidgetSubscriptionConfig subscription) async {
    try {
      logger.d('[PkgWidget]: Refreshing USP data for ${arg.widgetId}');
      final data = await ref
          .read(packageWidgetServiceProvider)
          .fetchUspPaths(subscription.paths);
      if (data == null) return;
      if (!_active) return;
      _cache.setAll(data);
    } on ServiceError catch (e) {
      logger.w('[PkgWidget]: USP refresh failed for ${arg.widgetId}: $e');
    }
  }

  /// The `cgi_call` action: POSTs [body] to [url] and says how it went, for
  /// the card to show. A success does not refresh by itself; the card does,
  /// after telling the user.
  Future<CgiCallResult> cgiCall({
    required String url,
    Map<String, dynamic>? body,
  }) async {
    try {
      return await ref
          .read(packageWidgetServiceProvider)
          .postCgi(url: url, body: body);
    } on ServiceError catch (e) {
      logger.w('[CGI][PkgWidget]: Call error for ${arg.widgetId}: $e');
      return const CgiCallFailure();
    }
  }

  void _startPolling(HttpDataSourceConfig dataSource) {
    if (dataSource.refreshInterval <= 0) return;
    _pollTimer = Timer.periodic(
      Duration(seconds: dataSource.refreshInterval),
      (_) {
        if (!_active) return;
        _fetchHttp(dataSource);
      },
    );
  }

  Future<void> _fetchHttp(HttpDataSourceConfig dataSource) async {
    try {
      final data = await ref
          .read(packageWidgetServiceProvider)
          .fetchHttpData(dataSource);
      if (data == null) return;
      if (!_active) return;
      _cache.setAll(data);
    } on ServiceError catch (e) {
      logger.w('[HTTP][PkgWidget]: Fetch error for ${arg.widgetId}: $e');
    }
  }

  /// The initial GET, then the SSE subscription — after a failed GET too, so
  /// a value that changes later still arrives. With no USP client (no
  /// session) neither happens.
  Future<void> _startUsp(WidgetSubscriptionConfig subscription) async {
    final service = ref.read(packageWidgetServiceProvider);
    try {
      final data = await service.fetchUspPaths(subscription.paths);
      if (data == null) return;
      if (!_active) return;
      _cache.setAll(data);
    } on ServiceError catch (e) {
      logger.w('[USP][PkgWidget]: Initial GET failed for '
          '${arg.widgetId}: $e');
    }

    try {
      _sseCleanup = await service.subscribeValueChanges(
        widgetId: arg.widgetId,
        subscription: subscription,
        onValueChange: (path, value) {
          if (_active) _cache.updatePath(path, value);
        },
      );
    } on ServiceError catch (e) {
      logger.w('[USP][PkgWidget]: SSE subscribe failed for '
          '${arg.widgetId}: $e');
    }
  }
}
