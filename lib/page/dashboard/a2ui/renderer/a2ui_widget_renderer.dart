import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../loader/json_widget_loader.dart';
import '../models/a2ui_widget_definition.dart';
import '../../models/display_mode.dart';
import '../registry/a2ui_widget_registry.dart';
import '../resolver/jnap_data_resolver.dart';
import 'template_builder_enhanced.dart';

/// Loads widget definitions from assets.
final a2uiLoaderProvider =
    FutureProvider<List<A2UIWidgetDefinition>>((ref) async {
  return JsonWidgetLoader().loadAll();
});

/// Provider for the A2UI widget registry.
///
/// Loads A2UI widgets from assets and remote sources dynamically.
/// Uses ChangeNotifierProvider for efficient rebuilds based on content hash.
final a2uiWidgetRegistryProvider = Provider<A2UIWidgetRegistry>((ref) {
  final registry = A2UIWidgetRegistry();

  // Watch async loaded widgets
  final asyncWidgets = ref.watch(a2uiLoaderProvider);

  // Fill registry when data is available
  asyncWidgets.whenData((widgets) {
    for (final widget in widgets) {
      registry.register(widget);
    }
  });

  return registry;
});

/// Renders an A2UI widget by ID.
///
/// Looks up the widget definition from the registry and builds the UI
/// using [TemplateBuilderEnhanced] with full action support.
class A2UIWidgetRenderer extends ConsumerWidget {
  /// The widget ID to render.
  final String widgetId;

  /// Optional display mode (not used by A2UI widgets, but kept for API consistency).
  final DisplayMode? displayMode;

  const A2UIWidgetRenderer({
    super.key,
    required this.widgetId,
    this.displayMode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(a2uiWidgetRegistryProvider);
    final resolver = ref.watch(jnapDataResolverProvider);

    final definition = registry.get(widgetId);
    if (definition == null) {
      return _buildErrorWidget('A2UI Widget not found: $widgetId', context);
    }

    return TemplateBuilderEnhanced.build(
      template: definition.template,
      resolver: resolver,
      ref: ref,
      widgetId: widgetId,
    );
  }

  Widget _buildErrorWidget(String message, BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      style: SurfaceStyle(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        borderColor: Theme.of(context).colorScheme.error,
        borderWidth: 1,
        borderRadius: 12,
        contentColor: Theme.of(context).colorScheme.onErrorContainer,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.error,
              size: 32,
            ),
            AppGap.sm(),
            AppText(
              message,
              variant: AppTextVariant.bodyMedium,
              color: Theme.of(context).colorScheme.error,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
