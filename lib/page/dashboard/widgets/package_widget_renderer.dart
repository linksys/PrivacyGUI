import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/usp/models/sse_notification.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../models/package_widget_template.dart';
import '../providers/package_widget_data_provider.dart';
import '../utils/bind_resolver.dart';

/// Renders a package widget template with live USP data.
///
/// Lifecycle:
/// 1. On first build: USP GET for initial data snapshot
/// 2. SSE subscribe for live updates
/// 3. On each data change: resolve `$bind` → rebuild via [UiTreeBuilder]
/// 4. On dispose: unsubscribe SSE
class PackageWidgetRenderer extends ConsumerStatefulWidget {
  final PackageWidgetTemplate template;

  const PackageWidgetRenderer({super.key, required this.template});

  @override
  ConsumerState<PackageWidgetRenderer> createState() =>
      _PackageWidgetRendererState();
}

class _PackageWidgetRendererState
    extends ConsumerState<PackageWidgetRenderer> {
  Future<void> Function()? _sseCleanup;
  bool _initialFetchDone = false;
  late final UiTreeBuilder _treeBuilder;

  @override
  void initState() {
    super.initState();
    _treeBuilder = UiTreeBuilder(
      builders: UiKitCatalog.standardBuilders,
      normalizer: _PassthroughNormalizer(),
    );
    // Defer data loading to after first frame to avoid provider mutations
    // during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeData();
    });
  }

  Future<void> _initializeData() async {
    final subscription = widget.template.subscription;
    if (subscription == null) {
      if (mounted) setState(() => _initialFetchDone = true);
      return;
    }

    final usp = ref.read(uspServiceProvider);
    if (usp == null) return;

    // Initial USP GET to populate data map
    try {
      final data = await usp.get(subscription.paths);
      if (!mounted) return;
      ref
          .read(packageWidgetDataProvider(widget.template.widgetId).notifier)
          .setAll(data);
      setState(() => _initialFetchDone = true);
    } catch (e) {
      logger.w('[USP][PkgWidget] Initial GET failed for '
          '${widget.template.widgetId}: $e');
      if (mounted) setState(() => _initialFetchDone = true);
    }

    // SSE subscribe for live updates
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

  @override
  void dispose() {
    _sseCleanup?.call();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data =
        ref.watch(packageWidgetDataProvider(widget.template.widgetId));

    // Show skeleton while initial data is loading
    if (!_initialFetchDone && data.isEmpty) {
      return AppCard(
        child: Center(child: AppLoader()),
      );
    }

    // Resolve $bind expressions and normalize properties → props
    final resolvedTemplate =
        resolveBindings(widget.template.template, data);

    // Render via UiTreeBuilder.
    //
    // Split the root card from its children so that:
    //   - The card shell fills the grid cell (parent SizedBox.expand in view)
    //   - Only inner content scrolls on overflow (SingleChildScrollView)
    try {
      final rootProps =
          resolvedTemplate['props'] as Map<String, dynamic>? ?? resolvedTemplate;
      final childrenDefs = rootProps['children'] as List?;

      // Root has children → build them individually, wrap in scrollable card
      if (childrenDefs != null && childrenDefs.isNotEmpty) {
        final childWidgets = childrenDefs
            .whereType<Map<String, dynamic>>()
            .map((c) => _treeBuilder.build(context, c))
            .toList();

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
