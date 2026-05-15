import 'package:flutter/material.dart';
import 'package:privacy_gui/page/devices/views/components/device_icon_with_badge.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shared node content builder for topology views.
///
/// Renders client nodes with multi-interface badge overlay when applicable.
/// Gateway and extender nodes use default image/icon rendering.
class TopologyNodeContentBuilder {
  TopologyNodeContentBuilder._();

  /// Builds node content with multi-interface badge support.
  ///
  /// For client nodes, checks `hasMultipleInterfaces` in metadata and
  /// displays a hub badge overlay on the device icon.
  static Widget build(
    BuildContext context,
    MeshNode node,
    NodeStyle style,
    bool isOffline,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isOffline ? colorScheme.outline : style.iconColor;

    // For non-client nodes, use default rendering (image or icon)
    if (node.type != MeshNodeType.client) {
      if (node.image != null) {
        return Image(
          image: node.image!,
          width: style.size * 0.6,
          height: style.size * 0.6,
          fit: BoxFit.contain,
        );
      }
      return Icon(
        node.iconData ?? Icons.devices,
        size: style.size * 0.5,
        color: iconColor,
      );
    }

    // For client nodes, check for multi-interface badge
    final hasMultipleInterfaces =
        node.metadata?['hasMultipleInterfaces'] as bool? ?? false;

    return DeviceIconWithBadge.multiInterface(
      icon: node.iconData ?? Icons.devices,
      size: style.size * 0.5,
      iconColor: iconColor,
      hasMultipleInterfaces: hasMultipleInterfaces,
    );
  }
}
