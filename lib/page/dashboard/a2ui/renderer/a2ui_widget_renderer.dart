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
/// Populates registry with preset widgets and watches for async loaded widgets.
final a2uiWidgetRegistryProvider = Provider<A2UIWidgetRegistry>((ref) {
  final registry = A2UIWidgetRegistry();

  // Always register preset widgets first (for tests and immediate availability)
  final presetWidgets = ref.read(presetWidgetsProvider);
  for (final widget in presetWidgets) {
    registry.register(widget);
  }

  // Watch async loaded widgets and merge them in
  final asyncWidgets = ref.watch(a2uiLoaderProvider);
  asyncWidgets.whenData((widgets) {
    for (final widget in widgets) {
      registry.register(widget);
    }
  });

  return registry;
});

/// Provider for preset widgets.
final presetWidgetsProvider = Provider<List<A2UIWidgetDefinition>>((ref) {
  // Import preset widgets here
  return [
    // Device count widget
    A2UIWidgetDefinition.fromJson(const {
      "widgetId": "a2ui_device_count",
      "displayName": "Connected Devices",
      "constraints": {
        "minColumns": 2,
        "maxColumns": 6,
        "preferredColumns": 4,
        "minRows": 1,
        "maxRows": 3,
        "preferredRows": 2
      },
      "template": {
        "type": "Column",
        "properties": {"mainAxisAlignment": "center"},
        "children": [
          {"type": "AppIcon", "properties": {"icon": "Icons.devices"}},
          {"type": "AppText", "properties": {"text": {"\$bind": "router.deviceCount"}}},
          {"type": "AppText", "properties": {"text": "Connected Devices"}}
        ]
      }
    }),
    // Node count widget
    A2UIWidgetDefinition.fromJson(const {
      "widgetId": "a2ui_node_count",
      "displayName": "Mesh Nodes",
      "constraints": {
        "minColumns": 2,
        "maxColumns": 6,
        "preferredColumns": 4,
        "minRows": 1,
        "maxRows": 3,
        "preferredRows": 2
      },
      "template": {
        "type": "Column",
        "properties": {"mainAxisAlignment": "center"},
        "children": [
          {"type": "AppIcon", "properties": {"icon": "Icons.router"}},
          {"type": "AppText", "properties": {"text": {"\$bind": "router.nodeCount"}}},
          {"type": "AppText", "properties": {"text": "Mesh Nodes"}}
        ]
      }
    }),
    // WAN status widget
    A2UIWidgetDefinition.fromJson(const {
      "widgetId": "a2ui_wan_status",
      "displayName": "WAN Status",
      "constraints": {
        "minColumns": 3,
        "maxColumns": 8,
        "preferredColumns": 6,
        "minRows": 1,
        "maxRows": 2,
        "preferredRows": 1
      },
      "template": {
        "type": "Row",
        "properties": {"mainAxisAlignment": "center"},
        "children": [
          {"type": "AppIcon", "properties": {"icon": "Icons.lan"}},
          {"type": "AppText", "properties": {"text": {"\$bind": "router.wanStatus"}}},
          {"type": "AppText", "properties": {"text": "Connected"}}
        ]
      }
    }),
  ];
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
