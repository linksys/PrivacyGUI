import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_notification.dart';
import 'package:privacy_gui/core/usp/providers/bridge_request_throttler_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
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
  final bool showHeader;

  const PackageWidgetRenderer({
    super.key,
    required this.template,
    this.showHeader = false,
  });

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
    final usp = ref.read(uspClientProvider);
    if (usp == null) return;

    try {
      // usp.get() is automatically throttled via UspClient.throttler
      final data = await usp.get(subscription.paths);
      if (!mounted) return;
      ref
          .read(packageWidgetDataProvider(widget.template.widgetId).notifier)
          .setAll(data);
    } catch (e) {
      logger.w('[USP][PkgWidget]: Initial GET failed for '
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
      logger.w('[USP][PkgWidget]: SSE subscribe failed for '
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
        logger.w('[HTTP][PkgWidget]: Blocked non-local URL: ${ds.url}');
        return;
      }

      final throttler = ref.read(bridgeRequestThrottlerProvider);
      final client = ref.read(httpClientProvider);
      final targetUrl = Uri.parse('${Uri.base.origin}${ds.url}');

      // Attach JWT so CGI endpoints can optionally verify auth.
      final token = ref.read(uspClientProvider)?.sessionToken;
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
        logger
            .w('[HTTP][PkgWidget]: ${ds.url} returned ${response.statusCode}');
      }
    } catch (e) {
      logger.w('[HTTP][PkgWidget]: Fetch error for '
          '${widget.template.widgetId}: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Action Handling
  // ---------------------------------------------------------------------------

  /// Handle widget actions from template UI components.
  void _handleWidgetAction(Map<String, dynamic> actionData) {
    final actionType =
        (actionData[r'$action'] ?? actionData['action']) as String?;
    if (actionType == null) return;

    logger.d('[PkgWidget]: ${widget.template.widgetId} action: $actionType');

    switch (actionType) {
      case 'refresh_data':
        _handleRefreshDataAction();
      case 'navigate':
        _handleNavigationAction(actionData['destination'] as String?);
      case 'cgi_call':
        _handleCgiCallAction(actionData);
      default:
        logger.d('[PkgWidget]: Unhandled action: $actionData');
    }
  }

  Future<void> _handleNavigationAction(String? destination) async {
    if (destination == null || destination.isEmpty) return;
    if (!mounted) return;
    logger.d('[PkgWidget]: Open app page: $destination');
    try {
      final url = Uri.parse('${Uri.base.origin}/$destination/');
      logger.d('[PkgWidget]: Full URL: $url');

      final canLaunch = await canLaunchUrl(url);
      if (canLaunch) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        if (mounted) {
          showSuccessSnackBar(context, 'Opened app page');
        }
      } else {
        logger.w('[PkgWidget]: Cannot launch URL: $url');
        if (mounted) {
          showFailedSnackBar(context, 'Cannot open page');
        }
      }
    } catch (e) {
      logger.w('[PkgWidget]: Open page failed: $e');
      if (mounted) {
        showFailedSnackBar(context, 'Failed to open page');
      }
    }
  }

  Future<void> _handleRefreshDataAction() async {
    if (widget.template.subscription != null) {
      await _refreshUspData();
    } else if (widget.template.dataSource != null) {
      await _fetchHttpData(widget.template.dataSource!);
    }
    if (mounted) {
      showSuccessSnackBar(context, 'Data refreshed');
    }
  }

  /// POST to a whitelisted CGI endpoint, auto-refresh on success.
  Future<void> _handleCgiCallAction(Map<String, dynamic> actionData) async {
    final url = actionData['url'] as String?;
    if (url == null || url.isEmpty) return;

    // Security: same whitelist as _fetchHttpData
    final uri = Uri.parse(url);
    if (uri.hasAuthority || !url.startsWith('/cgi-bin/')) {
      logger.w('[CGI][PkgWidget]: Blocked non-local URL: $url');
      return;
    }

    // Resolve $bind expressions in body against current widget data
    final rawBody = actionData['body'] as Map<String, dynamic>?;
    final widgetData =
        ref.read(packageWidgetDataProvider(widget.template.widgetId));
    final body = rawBody != null ? resolveBindings(rawBody, widgetData) : null;

    try {
      final throttler = ref.read(bridgeRequestThrottlerProvider);
      final client = ref.read(httpClientProvider);
      final targetUrl = Uri.parse('${Uri.base.origin}$url');

      final token = ref.read(uspClientProvider)?.sessionToken;
      final headers = <String, String>{
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

      final response = await throttler.enqueue<http.Response>(
        cacheKey: 'cgi:$url',
        priority: RequestPriority.low,
        action: () => client.post(
          targetUrl,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        ),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        showSuccessSnackBar(context, 'Action completed');
        _handleRefreshDataAction();
      } else {
        logger.w('[CGI][PkgWidget]: $url returned ${response.statusCode}');
        showFailedSnackBar(context, 'Action failed (${response.statusCode})');
      }
    } catch (e) {
      logger.w('[CGI][PkgWidget]: Call error for '
          '${widget.template.widgetId}: $e');
      if (mounted) {
        showFailedSnackBar(context, 'Action failed');
      }
    }
  }

  /// Refresh USP data by performing a fresh GET request.
  Future<void> _refreshUspData() async {
    final subscription = widget.template.subscription;
    if (subscription == null) return;

    final usp = ref.read(uspClientProvider);
    if (usp == null) return;

    try {
      logger.d(
          '[PkgWidget]: Refreshing USP data for ${widget.template.widgetId}');
      final data = await usp.get(subscription.paths);
      if (!mounted) return;
      ref
          .read(packageWidgetDataProvider(widget.template.widgetId).notifier)
          .setAll(data);
    } catch (e) {
      logger.w(
          '[PkgWidget]: USP refresh failed for ${widget.template.widgetId}: $e');
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
      logger.w('[USP][PkgWidget]: Render error '
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

  Widget _buildContentOnly(
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
        // Root has children → wrap in scrollable container (no card)
        return Padding(
          padding: padding ?? EdgeInsets.zero,
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: renderer.build(context),
          ),
        );
      } else {
        // No children → render directly with optional padding
        final renderedWidget = renderer.build(context);
        return padding != null
            ? Padding(padding: padding, child: renderedWidget)
            : renderedWidget;
      }
    } catch (e) {
      logger.w('[USP][PkgWidget]: Render error '
          '${widget.template.widgetId}: $e');
      return Center(
        child: AppText.bodySmall(
          'Widget error: ${widget.template.displayName}',
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
  // Build with header
  // ---------------------------------------------------------------------------

  /// Extract the navigate destination — prefer top-level `navigateTo`,
  /// fall back to legacy `onTap.$action=navigate` in template root.
  String? _extractDestination() {
    if (widget.template.navigateTo != null) {
      return widget.template.navigateTo;
    }
    final rootProps =
        widget.template.template['props'] as Map<String, dynamic>?;
    if (rootProps == null) return null;
    final onTap = rootProps['onTap'] as Map<String, dynamic>?;
    if (onTap == null) return null;
    if (onTap[r'$action'] == 'navigate') {
      return onTap['destination'] as String?;
    }
    return null;
  }

  /// Resolve a field that can be `String`, `Map` ($bind/$compute), or null.
  String? _resolveStringOrBind(Object? value, Map<String, dynamic> data) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      final resolved = resolveBindings({'_': value}, data);
      return resolved['_']?.toString();
    }
    return null;
  }

  Widget _buildWidgetWithHeader(
      BuildContext context, Map<String, dynamic> data) {
    final t = widget.template;
    final hasDataSource = t.subscription != null || t.dataSource != null;
    final destination = _extractDestination();
    final badgeText = _resolveStringOrBind(t.headerBadge, data);
    final extraText = _resolveStringOrBind(t.headerExtra, data);
    final iconColor =
        t.iconColor != null ? parseColor(t.iconColor, context) : null;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: [icon] title [badge] ... buttons
          Row(
            children: [
              if (t.icon != null) ...[
                AppIcon.font(
                  parseIconData(t.icon),
                  size: 20,
                  color: iconColor,
                ),
                AppGap.xs(),
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: t.description != null
                          ? Tooltip(
                              message: t.description!,
                              child: AppText.titleMedium(t.displayName),
                            )
                          : AppText.titleMedium(t.displayName),
                    ),
                    if (badgeText != null) ...[
                      AppGap.xs(),
                      AppTag(label: badgeText),
                    ],
                  ],
                ),
              ),
              if (hasDataSource) ...[
                AppGap.xs(),
                AppIconButton(
                  icon: const Icon(Icons.refresh, size: 16),
                  size: AppButtonSize.small,
                  onTap: _handleRefreshDataAction,
                ),
              ],
              if (destination != null) ...[
                AppGap.xs(),
                AppIconButton(
                  icon: const Icon(Icons.open_in_new, size: 16),
                  size: AppButtonSize.small,
                  onTap: () => _handleNavigationAction(destination),
                ),
              ],
            ],
          ),
          // Extra subtitle
          if (extraText != null)
            AppText.bodySmall(
              extraText,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          AppGap.sm(),
          // Widget content
          Expanded(
            child: _buildContentOnly(context, t.template, data),
          ),
        ],
      ),
    );
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

    if (widget.showHeader) {
      return _buildWidgetWithHeader(context, data);
    } else {
      // Delegate rendering to UI Kit template engine with integrated card wrapper
      return _buildCardWithContent(context, widget.template.template, data);
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
