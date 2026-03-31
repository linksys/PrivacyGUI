import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_notification.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/bridge_request_throttler.dart'
    show RequestPriority;
import 'package:ui_kit_library/ui_kit.dart';

import '../builders/package_widget_builders.dart';
import '../models/package_widget_template.dart';
import '../providers/http_client_provider.dart';
import '../providers/package_widget_data_provider.dart';
import '../utils/bind_resolver.dart';

/// Renders a package widget template with live data from USP or HTTP/CGI.
///
/// Lifecycle:
/// 1. On first build: fetch initial data (USP GET or HTTP POST/GET)
/// 2. Subscribe for live updates (SSE for USP, polling timer for HTTP)
/// 3. On each data change: resolve `$bind` → rebuild via [UiTreeBuilder]
/// 4. On dispose: unsubscribe SSE / cancel poll timer
class PackageWidgetRenderer extends ConsumerStatefulWidget {
  final PackageWidgetTemplate template;

  const PackageWidgetRenderer({super.key, required this.template});

  @override
  ConsumerState<PackageWidgetRenderer> createState() =>
      _PackageWidgetRendererState();
}

class _PackageWidgetRendererState extends ConsumerState<PackageWidgetRenderer> {
  Future<void> Function()? _sseCleanup;
  Timer? _pollTimer;
  bool _initialFetchDone = false;
  late final UiTreeBuilder _treeBuilder;

  @override
  void initState() {
    super.initState();
    _treeBuilder = UiTreeBuilder(
      builders: {
        ...UiKitCatalog.standardBuilders,
        ...PackageWidgetBuilders.all
      },
      normalizer: _PassthroughNormalizer(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  // ---------------------------------------------------------------------------
  // Data initialization — route to USP or HTTP based on template config
  // ---------------------------------------------------------------------------

  Future<void> _initializeData() async {
    final template = widget.template;

    if (template.subscription != null) {
      await _initializeUspData(template.subscription!);
    } else if (template.dataSource != null) {
      await _initializeHttpData(template.dataSource!);
    }

    if (mounted) setState(() => _initialFetchDone = true);
  }

  // ---------------------------------------------------------------------------
  // USP data source (existing behavior, now routed through throttler)
  // ---------------------------------------------------------------------------

  Future<void> _initializeUspData(WidgetSubscriptionConfig subscription) async {
    final usp = ref.read(uspServiceProvider);
    if (usp == null) return;

    try {
      // usp.get() is automatically throttled via UspService.throttler
      final data = await usp.get(subscription.paths);
      if (!mounted) return;
      ref
          .read(packageWidgetDataProvider(widget.template.widgetId).notifier)
          .setAll(data);
    } catch (e) {
      logger.w('[USP][PkgWidget] Initial GET failed for '
          '${widget.template.widgetId}: $e');
    }

    await _subscribeSse();
  }

  Future<void> _subscribeSse() async {
    final subscription = widget.template.subscription;
    if (subscription == null) return;

    final manager = ref.read(sseManagerProvider);
    if (manager == null) return;

    final subId = 'pkg-${widget.template.widgetId}-valuechange';

    try {
      _sseCleanup = await manager.subscribe(
        subscriptionId: subId,
        notifType: subscription.notifType,
        referenceList: subscription.paths.first,
        onNotification: _handleNotification,
      );
    } catch (e) {
      logger.w('[USP][PkgWidget] SSE subscribe failed for '
          '${widget.template.widgetId}: $e');
    }
  }

  void _handleNotification(SseNotification notification) {
    if (notification.type != 'ValueChange') return;

    final valueChange =
        notification.payload['value_change'] as Map<String, dynamic>?;
    if (valueChange == null) return;

    final path = valueChange['param_path'] as String?;
    final value = valueChange['param_value'];
    if (path == null) return;

    ref
        .read(packageWidgetDataProvider(widget.template.widgetId).notifier)
        .updatePath(path, value);
  }

  // ---------------------------------------------------------------------------
  // HTTP/CGI data source
  // ---------------------------------------------------------------------------

  Future<void> _initializeHttpData(HttpDataSourceConfig ds) async {
    await _fetchHttpData(ds);
    _startHttpPolling(ds);
  }

  Future<void> _fetchHttpData(HttpDataSourceConfig ds) async {
    try {
      // Security: only allow local CGI paths
      final uri = Uri.parse(ds.url);
      if (uri.hasAuthority || !ds.url.startsWith('/cgi-bin/')) {
        logger.w('[HTTP][PkgWidget] Blocked non-local URL: ${ds.url}');
        return;
      }

      final throttler = ref.read(bridgeRequestThrottlerProvider);
      final client = ref.read(httpClientProvider);
      final targetUrl = Uri.parse('${Uri.base.origin}${ds.url}');

      // Attach JWT so CGI endpoints can optionally verify auth.
      final token = ref.read(uspServiceProvider)?.sessionToken;
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await throttler.enqueue<http.Response>(
        cacheKey: 'http:${ds.method}:${ds.url}',
        priority: RequestPriority.low,
        action: () {
          if (ds.method.toUpperCase() == 'GET') {
            return client.get(targetUrl, headers: headers);
          }
          return client.post(
            targetUrl,
            headers: headers,
            body: ds.body != null ? jsonEncode(ds.body) : null,
          );
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final mapped = applyMapping(json, ds.mapping);
        if (!mounted) return;
        ref
            .read(packageWidgetDataProvider(widget.template.widgetId).notifier)
            .setAll(mapped);
      } else {
        logger.w('[HTTP][PkgWidget] ${ds.url} returned ${response.statusCode}');
      }
    } catch (e) {
      logger.w('[HTTP][PkgWidget] Fetch error for '
          '${widget.template.widgetId}: $e');
    }
  }

  void _startHttpPolling(HttpDataSourceConfig ds) {
    if (ds.refreshInterval <= 0) return;
    _pollTimer = Timer.periodic(
      Duration(seconds: ds.refreshInterval),
      (_) {
        if (!mounted) return;
        _fetchHttpData(ds);
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Dispose
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    _pollTimer?.cancel();
    _sseCleanup?.call();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // ---------------------------------------------------------------------------
  // Layout property extraction and building
  // ---------------------------------------------------------------------------

  /// Extract layout properties from the original template root.
  /// This preserves the designer's original layout intentions.
  Map<String, dynamic> _extractLayoutProperties(Map<String, dynamic> template) {
    final props = template['props'] as Map<String, dynamic>? ?? {};
    return {
      'mainAxisAlignment': props['mainAxisAlignment'],
      'crossAxisAlignment': props['crossAxisAlignment'],
      'alignment': props['alignment'],
      'expandChildren': props['expandChildren'],
    };
  }

  /// Parse main axis alignment from string value.
  /// Borrowed from UI Kit parsing logic for consistency.
  MainAxisAlignment _parseMainAxisAlignment(dynamic value) {
    if (value is! String) return MainAxisAlignment.start;
    switch (value.toLowerCase()) {
      case 'center':
        return MainAxisAlignment.center;
      case 'end':
        return MainAxisAlignment.end;
      case 'spacebetween':
        return MainAxisAlignment.spaceBetween;
      case 'spacearound':
        return MainAxisAlignment.spaceAround;
      case 'spaceevenly':
        return MainAxisAlignment.spaceEvenly;
      default:
        return MainAxisAlignment.start;
    }
  }

  /// Parse cross axis alignment from string value.
  /// Borrowed from UI Kit parsing logic for consistency.
  CrossAxisAlignment _parseCrossAxisAlignment(dynamic value) {
    if (value is! String) return CrossAxisAlignment.start;
    switch (value.toLowerCase()) {
      case 'center':
        return CrossAxisAlignment.center;
      case 'end':
        return CrossAxisAlignment.end;
      case 'stretch':
        return CrossAxisAlignment.stretch;
      default:
        return CrossAxisAlignment.start;
    }
  }

  /// Build layout container based on original template type and properties.
  /// This reconstructs the designer's original layout intentions.
  Widget _buildLayoutContainer({
    required String? originalType,
    required Map<String, dynamic> layoutProps,
    required List<Widget> children,
  }) {
    switch (originalType?.toLowerCase()) {
      case 'column':
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: _parseMainAxisAlignment(layoutProps['mainAxisAlignment']),
          crossAxisAlignment: _parseCrossAxisAlignment(layoutProps['crossAxisAlignment']),
          children: children,
        );

      case 'row':
        final expandChildren = layoutProps['expandChildren'] as bool? ?? false;
        final processedChildren = expandChildren
            ? children.map((child) => Expanded(child: child)).toList()
            : children;

        return Row(
          mainAxisSize: expandChildren ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: _parseMainAxisAlignment(layoutProps['mainAxisAlignment']),
          crossAxisAlignment: _parseCrossAxisAlignment(layoutProps['crossAxisAlignment']),
          children: processedChildren,
        );

      case 'center':
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        );

      case 'stack':
        // Basic stack support (can be enhanced later for Positioned)
        return Stack(
          children: children,
        );

      default:
        // Default: preserve center alignment instead of forcing start
        return Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: children,
        );
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(packageWidgetDataProvider(widget.template.widgetId));

    // Show skeleton while initial data is loading
    if (!_initialFetchDone && data.isEmpty) {
      return AppCard(
        child: Center(child: AppLoader()),
      );
    }

    // Resolve $bind expressions and normalize properties → props
    final resolvedTemplate = resolveBindings(widget.template.template, data);

    // Render via UiTreeBuilder.
    //
    // Split the root card from its children so that:
    //   - The card shell fills the grid cell (parent SizedBox.expand in view)
    //   - Only inner content scrolls on overflow (SingleChildScrollView)
    try {
      final rootProps = resolvedTemplate['props'] as Map<String, dynamic>? ??
          resolvedTemplate;
      final childrenDefs = rootProps['children'] as List?;

      // Root has children → build them individually, wrap in scrollable card
      if (childrenDefs != null && childrenDefs.isNotEmpty) {
        final childWidgets = childrenDefs
            .whereType<Map<String, dynamic>>()
            .map((c) => _treeBuilder.build(context, c))
            .toList();

        // 🎯 CORE FIX: Extract original layout properties
        final originalType = resolvedTemplate['type'] as String?;
        final layoutProps = _extractLayoutProperties(resolvedTemplate);

        // Forward common card props from the template
        final padding = rootProps['padding'] != null
            ? EdgeInsets.all(
                (rootProps['padding'] as num).toDouble(),
              )
            : null;

        return AppCard(
          padding: padding,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: _buildLayoutContainer(
              originalType: originalType,
              layoutProps: layoutProps,
              children: childWidgets,
            ),
          ),
        );
      }

      // No children — render the full tree as-is
      return _treeBuilder.build(context, resolvedTemplate);
    } catch (e) {
      logger.w('[USP][PkgWidget] Render error '
          '${widget.template.widgetId}: $e');
      return AppCard(
        child: Center(
          child: AppText.bodySmall(
            'Widget error: ${widget.template.displayName}',
          ),
        ),
      );
    }
  }
}

// =============================================================================
// Mapping helpers (package-visible for testing)
// =============================================================================

/// Transform JSON response into flat map via dot-notation mapping.
///
/// Example:
///   json = `{"data": {"query": "1.2.3.4", "city": "Taipei"}}`
///   mapping = `{"ip": "data.query", "city": "data.city"}`
///   → `{"ip": "1.2.3.4", "city": "Taipei"}`
Map<String, dynamic> applyMapping(
  Map<String, dynamic> json,
  Map<String, String> mapping,
) {
  final result = <String, dynamic>{};
  for (final entry in mapping.entries) {
    result[entry.key] = resolvePath(json, entry.value);
  }
  return result;
}

/// Resolve dot-notation path: `"data.query"` → `json["data"]["query"]`
dynamic resolvePath(Map<String, dynamic> json, String path) {
  dynamic current = json;
  for (final segment in path.split('.')) {
    if (current is Map<String, dynamic>) {
      current = current[segment];
    } else {
      return null;
    }
  }
  return current;
}

// =============================================================================
// Passthrough normalizer
// =============================================================================

/// Minimal passthrough normalizer for package widget templates.
///
/// Package widget JSON uses simple property names matching UiKitCatalog
/// builder expectations. No protocol-specific normalization needed.
class _PassthroughNormalizer implements PropNormalizer {
  @override
  String get protocolName => 'package_widget';

  @override
  Map<String, dynamic> normalize(
    String componentType,
    Map<String, dynamic> rawProps,
  ) {
    final props = Map<String, dynamic>.from(rawProps);
    // Promote child → children (standard normalization)
    if (props.containsKey('child') && !props.containsKey('children')) {
      final child = props['child'];
      if (child != null) {
        props['children'] = [child];
      }
    }
    return props;
  }
}
