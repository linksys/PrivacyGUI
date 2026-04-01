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

import '../models/package_widget_template.dart';
import '../providers/http_client_provider.dart';
import '../providers/package_widget_data_provider.dart';

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

  @override
  void initState() {
    super.initState();
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

  // ---------------------------------------------------------------------------
  // Action Handling
  // ---------------------------------------------------------------------------

  /// Handle widget actions triggered by user interactions.
  ///
  /// This method processes actions from UI components and routes them to
  /// appropriate handlers based on the action type.
  void _handleWidgetAction(Map<String, dynamic> actionData) {
    final actionType = actionData['action'] as String?;
    if (actionType == null) {
      logger.w('[PkgWidget] Action missing type: $actionData');
      return;
    }

    logger.d('[PkgWidget] ${widget.template.widgetId} action: $actionType');

    try {
      switch (actionType) {
        case 'pressed':
        case 'tapped':
          _handleTapAction(actionData);
          break;
        case 'changed':
        case 'toggled':
          _handleValueChangedAction(actionData);
          break;
        case 'selected':
          _handleSelectionAction(actionData);
          break;
        case 'save_settings':
          _handleSaveSettingsAction(actionData);
          break;
        case 'navigate':
          _handleNavigationAction(actionData);
          break;
        case 'refresh_data':
          _handleRefreshDataAction(actionData);
          break;
        default:
          logger.w('[PkgWidget] Unknown action type: $actionType');
          // For unknown actions, just log the data for debugging
          logger.d('[PkgWidget] Action data: $actionData');
      }
    } catch (e) {
      logger.w('[PkgWidget] Error handling action $actionType: $e');
    }
  }

  /// Handle tap/press actions from buttons and interactive elements.
  void _handleTapAction(Map<String, dynamic> actionData) {
    final elementType =
        actionData['button'] ?? actionData['title'] ?? 'unknown';
    logger.d('[PkgWidget] Tap action on: $elementType');

    // Add specific tap handling logic here
    // For example: trigger data refresh, show dialog, etc.
  }

  /// Handle value change actions from form inputs.
  void _handleValueChangedAction(Map<String, dynamic> actionData) {
    final newValue = actionData['value'];
    logger.d('[PkgWidget] Value changed to: $newValue');

    // Add value change handling logic here
    // For example: update local state, validate input, etc.
  }

  /// Handle selection actions from dropdowns, tabs, etc.
  void _handleSelectionAction(Map<String, dynamic> actionData) {
    final selectedValue = actionData['value'] ?? actionData['index'];
    logger.d('[PkgWidget] Selection changed to: $selectedValue');

    // Add selection handling logic here
    // For example: update filter settings, change view mode, etc.
  }

  /// Handle save settings action with validation and persistence.
  void _handleSaveSettingsAction(Map<String, dynamic> actionData) {
    final section = actionData['section'] as String?;
    final shouldValidate = actionData['validate'] as bool? ?? true;

    logger.d(
        '[PkgWidget] Save settings: section=$section, validate=$shouldValidate');

    // Add save settings logic here
    // For example: validate form data, call USP API, show success message, etc.
  }

  /// Handle navigation actions to other pages or dialogs.
  void _handleNavigationAction(Map<String, dynamic> actionData) {
    final destination = actionData['destination'] as String?;
    final params = actionData['params'] as Map<String, dynamic>?;

    logger.d('[PkgWidget] Navigate to: $destination with params: $params');

    // Add navigation handling logic here
    // For example: use GoRouter to navigate, show modal dialog, etc.
  }

  /// Handle data refresh action to reload widget content.
  void _handleRefreshDataAction(Map<String, dynamic> actionData) {
    logger.d('[PkgWidget] Refresh data requested');

    // Trigger data refresh based on widget's data source type
    if (widget.template.subscription != null) {
      // USP data source - trigger fresh GET request
      _refreshUspData();
    } else if (widget.template.dataSource != null) {
      // HTTP data source - trigger immediate fetch
      _fetchHttpData(widget.template.dataSource!);
    }
  }

  /// Refresh USP data by performing a fresh GET request.
  Future<void> _refreshUspData() async {
    final subscription = widget.template.subscription;
    if (subscription == null) return;

    final usp = ref.read(uspServiceProvider);
    if (usp == null) return;

    try {
      logger
          .d('[PkgWidget] Refreshing USP data for ${widget.template.widgetId}');
      final data = await usp.get(subscription.paths);
      if (!mounted) return;
      ref
          .read(packageWidgetDataProvider(widget.template.widgetId).notifier)
          .setAll(data);
    } catch (e) {
      logger.w(
          '[PkgWidget] USP refresh failed for ${widget.template.widgetId}: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Template Rendering with UI Kit
  // ---------------------------------------------------------------------------

  /// Build widget card with scrollable content using UI Kit template engine
  Widget _buildCardWithContent(
    BuildContext context,
    Map<String, dynamic> template,
    Map<String, dynamic> data,
  ) {
    try {
      // Create UI Kit template renderer
      final renderer = UiKitTemplateRenderer(
        template: template,
        data: data,
        builders: {
          ...UiKitCatalog.standardBuilders,
          ...PackageWidgetBuilders.all,
        },
        onAction: _handleWidgetAction,
      );

      // Get template root properties for card configuration
      final rootProps = template['props'] as Map<String, dynamic>? ?? template;
      final hasChildren = (rootProps['children'] as List?)?.isNotEmpty ?? false;

      // Extract card padding from template
      final padding = rootProps['padding'] != null
          ? EdgeInsets.all((rootProps['padding'] as num).toDouble())
          : null;

      if (hasChildren) {
        // Root has children → wrap in scrollable card
        return AppCard(
          padding: padding,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: renderer.build(context),
          ),
        );
      } else {
        // No children → render directly with optional card wrapper
        final renderedWidget = renderer.build(context);
        return padding != null
            ? AppCard(padding: padding, child: renderedWidget)
            : renderedWidget;
      }
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

    // Delegate rendering to UI Kit template engine with integrated card wrapper
    return _buildCardWithContent(context, widget.template.template, data);
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
