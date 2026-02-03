import '../models/a2ui_constraints.dart';
import '../models/a2ui_template.dart';
import '../models/a2ui_widget_definition.dart';

/// Preset A2UI widget definitions for initial testing and validation.
///
/// These can be loaded into [A2UIWidgetRegistry] at startup.
class PresetWidgets {
  PresetWidgets._();

  /// Device Count Widget - shows the number of connected devices.
  static final deviceCount = A2UIWidgetDefinition(
    widgetId: 'a2ui_device_count',
    displayName: 'Connected Devices',
    description: 'Shows the number of connected devices',
    constraints: const A2UIConstraints(
      minColumns: 2,
      maxColumns: 4,
      preferredColumns: 3,
      minRows: 2,
      maxRows: 3,
      preferredRows: 2,
    ),
    template: A2UIContainerNode(
      type: 'Column',
      properties: const {
        'mainAxisAlignment': 'center',
        'crossAxisAlignment': 'center',
        'mainAxisSize': 'min',
      },
      children: const [
        A2UILeafNode(
          type: 'AppIcon',
          properties: {'icon': 'devices', 'size': 32.0},
        ),
        A2UILeafNode(
          type: 'SizedBox',
          properties: {'height': 8.0},
        ),
        A2UILeafNode(
          type: 'AppText',
          properties: {
            'text': {r'$bind': 'router.deviceCount'},
            'variant': 'headline',
          },
        ),
        A2UILeafNode(
          type: 'AppText',
          properties: {
            'text': 'Connected Devices',
            'variant': 'label',
          },
        ),
      ],
    ),
  );

  /// Node Count Widget - shows the number of mesh nodes.
  static final nodeCount = A2UIWidgetDefinition(
    widgetId: 'a2ui_node_count',
    displayName: 'Mesh Nodes',
    description: 'Shows the number of mesh nodes',
    constraints: const A2UIConstraints(
      minColumns: 2,
      maxColumns: 4,
      preferredColumns: 3,
      minRows: 2,
      maxRows: 3,
      preferredRows: 2,
    ),
    template: A2UIContainerNode(
      type: 'Column',
      properties: const {
        'mainAxisAlignment': 'center',
        'crossAxisAlignment': 'center',
        'mainAxisSize': 'min',
      },
      children: const [
        A2UILeafNode(
          type: 'AppIcon',
          properties: {'icon': 'router', 'size': 32.0},
        ),
        A2UILeafNode(
          type: 'SizedBox',
          properties: {'height': 8.0},
        ),
        A2UILeafNode(
          type: 'AppText',
          properties: {
            'text': {r'$bind': 'router.nodeCount'},
            'variant': 'headline',
          },
        ),
        A2UILeafNode(
          type: 'AppText',
          properties: {
            'text': 'Mesh Nodes',
            'variant': 'label',
          },
        ),
      ],
    ),
  );

  /// WAN Status Widget - shows the WAN connection status.
  static final wanStatus = A2UIWidgetDefinition(
    widgetId: 'a2ui_wan_status',
    displayName: 'WAN Status',
    description: 'Shows the WAN connection status',
    constraints: const A2UIConstraints(
      minColumns: 2,
      maxColumns: 4,
      preferredColumns: 3,
      minRows: 1,
      maxRows: 2,
      preferredRows: 1,
    ),
    template: A2UIContainerNode(
      type: 'Row',
      properties: const {
        'mainAxisAlignment': 'center',
        'crossAxisAlignment': 'center',
        'mainAxisSize': 'min',
      },
      children: const [
        A2UILeafNode(
          type: 'AppIcon',
          properties: {'icon': 'network', 'size': 24.0},
        ),
        A2UILeafNode(
          type: 'SizedBox',
          properties: {'width': 8.0},
        ),
        A2UILeafNode(
          type: 'AppText',
          properties: {
            'text': {r'$bind': 'router.wanStatus'},
            'variant': 'body',
          },
        ),
      ],
    ),
  );

  /// All preset widgets.
  static final List<A2UIWidgetDefinition> all = [
    deviceCount,
    nodeCount,
    wanStatus,
  ];
}
