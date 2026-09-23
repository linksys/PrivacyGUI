import 'package:flutter/material.dart';
import 'package:privacy_gui/page/devices/views/components/device_icon_with_badge.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shared node content builder for topology views.
///
/// Renders leaf nodes with multi-interface badge overlay when applicable.
/// Master and slave nodes use default image/icon rendering.
class TopologyNodeContentBuilder {
  TopologyNodeContentBuilder._();

  /// Builds node content with multi-interface badge support.
  ///
  /// For leaf nodes, checks `hasMultipleInterfaces` in metadata and
  /// displays a hub badge overlay on the device icon.
  ///
  /// The leaf test reads the slot the builder **stated** ([GraphNode.styleSlot]),
  /// not a structure the kit would derive: a slave carrying no clients is a
  /// structural leaf and must not be given a client's badge treatment. See
  /// `UspTopologyBuilder`, which states the slot at each of its three origins.
  static Widget build(
    BuildContext context,
    GraphNode node,
    NodeStyle style,
    bool isOffline,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final iconColor = isOffline ? colorScheme.outline : style.iconColor;

    // For non-leaf nodes, use default rendering (image or icon)
    if (node.styleSlot != 'leaf') {
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

    // For leaf nodes, check for multi-interface badge
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
