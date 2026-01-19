import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../loader/json_widget_loader.dart';
import '../models/a2ui_widget_definition.dart';
import '../../models/display_mode.dart';
import '../registry/a2ui_widget_registry.dart';
import '../resolver/jnap_data_resolver.dart';
import 'template_builder.dart';

/// Loads widget definitions from assets.
final a2uiLoaderProvider =
    FutureProvider<List<A2UIWidgetDefinition>>((ref) async {
  return JsonWidgetLoader().loadAll();
});

/// Provider for the A2UI widget registry.
///
/// Populates registry from [a2uiLoaderProvider].
final a2uiWidgetRegistryProvider = Provider<A2UIWidgetRegistry>((ref) {
  final registry = A2UIWidgetRegistry();

  // Load from async loader
  final asyncWidgets = ref.watch(a2uiLoaderProvider);
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
/// using [TemplateBuilder].
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
      return _buildErrorWidget('A2UI Widget not found: $widgetId');
    }

    return TemplateBuilder.build(
      template: definition.template,
      resolver: resolver,
      ref: ref,
    );
  }

  Widget _buildErrorWidget(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.withAlpha(25),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.withAlpha(75)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 32),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: Colors.red, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
