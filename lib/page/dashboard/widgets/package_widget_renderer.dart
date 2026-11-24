import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:privacy_gui/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/cgi_call_result.dart';
import '../models/package_widget_template.dart';
import '../providers/package_widget_live_provider.dart';
import '../providers/package_widget_data_provider.dart';

/// Renders a package widget template with live data from USP or HTTP/CGI.
///
/// The data comes from two providers (#1837):
/// - [packageWidgetLiveProvider] — autoDispose, kept alive by this
///   widget: the initial fetch, the SSE subscription or HTTP poll, and the
///   `refresh_data` / `cgi_call` actions. Its state is whether the initial
///   fetch has finished.
/// - [packageWidgetDataProvider] — not autoDispose: the data itself, so a card
///   that comes back to the dashboard shows its last data at once.
///
/// This widget renders the template (`$bind` → [UiTreeBuilder]), dispatches
/// actions, shows their snackbars, and opens app pages for `navigate`.
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
  PackageWidgetLiveNotifier get _live =>
      ref.read(packageWidgetLiveProvider(widget.template).notifier);

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
    await _live.refresh();
    if (mounted) {
      showSuccessSnackBar(context, 'Data refreshed');
    }
  }

  /// POST to a whitelisted CGI endpoint, auto-refresh on success.
  Future<void> _handleCgiCallAction(Map<String, dynamic> actionData) async {
    final url = actionData['url'] as String?;
    if (url == null || url.isEmpty) return;

    // Resolve $bind expressions in body against current widget data
    final rawBody = actionData['body'] as Map<String, dynamic>?;
    final widgetData =
        ref.read(packageWidgetDataProvider(widget.template.widgetId));
    final body = rawBody != null ? resolveBindings(rawBody, widgetData) : null;

    final result = await _live.cgiCall(url: url, body: body);
    if (!mounted) return;

    switch (result) {
      case CgiCallSkipped():
        return;
      case CgiCallSuccess():
        showSuccessSnackBar(context, 'Action completed');
        _handleRefreshDataAction();
      case CgiCallFailure(statusCode: final statusCode?):
        showFailedSnackBar(context, 'Action failed ($statusCode)');
      case CgiCallFailure():
        showFailedSnackBar(context, 'Action failed');
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
    final initialFetchDone =
        ref.watch(packageWidgetLiveProvider(widget.template));
    final data = ref.watch(packageWidgetDataProvider(widget.template.widgetId));

    // Show skeleton while initial data is loading — not for a card that comes
    // back with data already in the cache.
    if (!initialFetchDone && data.isEmpty) {
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
