import 'package:flutter/material.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:ui_kit_library/ui_kit.dart';

class InstantTopologyCard extends StatelessWidget {
  final RouterTreeNode node;
  final bool isOffline;
  final bool isFocused;
  final VoidCallback? onTap;

  const InstantTopologyCard({
    required this.node,
    this.isOffline = false,
    this.isFocused = false,
    this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Logic to select icon (fallback if no image)
    final icon = node.data.isRouter
        ? (node.data.isMaster ? Icons.router : Icons.wifi_tethering)
        : Icons.devices;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Icon or Image
          AppIcon.font(
            icon,
            size: 24,
            color: isOffline
                ? Theme.of(context).disabledColor
                : Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.bodyMedium(node.data.location.isNotEmpty
                    ? node.data.location
                    : (node.data.model.isNotEmpty
                        ? node.data.model
                        : 'Unknown')),
                if (node.data.model.isNotEmpty &&
                    node.data.model != node.data.location)
                  AppText.bodySmall(node.data.model,
                      color: Theme.of(context).hintColor),
              ],
            ),
          ),
          if (isOffline)
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Icon(Icons.error_outline,
                  color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
