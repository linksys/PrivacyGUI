import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/utils/topology_adapter.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Helper class for building and handling topology node menu items.
///
/// This class provides shared menu logic for both [InstantTopologyView]
/// and [InstantVerifyView] to avoid code duplication.
class TopologyMenuHelper {
  final ServiceHelper serviceHelper;

  TopologyMenuHelper(this.serviceHelper);

  /// Build menu items for a topology node.
  ///
  /// Returns null for Internet nodes or empty menu.
  /// Menu items are based on node type and device capabilities.
  /// In remote read-only mode, only Details and Blink Device Light are enabled.
  List<AppPopupMenuItem<String>>? buildNodeMenu(
    BuildContext context,
    WidgetRef ref,
    MeshNode meshNode,
  ) {
    // Don't show menu for internet nodes
    if (meshNode.isInternet) return null;

    final items = <AppPopupMenuItem<String>>[];
    final isOffline = meshNode.status == MeshNodeStatus.offline;
    final isRemoteReadOnly = ref.watch(
      remoteAccessProvider.select((state) => state.isRemoteReadOnly),
    );

    // Always add details for all online node types
    if (!meshNode.isOffline) {
      items.add(AppPopupMenuItem(
        value: 'details',
        label: 'Details',
        icon: Icons.info_outline,
      ));
    }

    // Skip action items for offline nodes (they can only view details)
    if (isOffline) {
      return items.isEmpty ? null : items;
    }

    // Add actions based on node type and capabilities
    final supportChildReboot = serviceHelper.isSupportChildReboot();
    final autoOnboarding = serviceHelper.isSupportAutoOnboarding();

    // Extender and Gateway menu items
    if (meshNode.isExtender || meshNode.isGateway) {
      // Reboot action (disabled in remote mode)
      if (supportChildReboot) {
        items.add(AppPopupMenuItem(
          value: 'reboot',
          label: loc(context).rebootUnit,
          icon: Icons.restart_alt,
          enabled: !isRemoteReadOnly,
        ));
      }

      // Blink device light (always enabled, even in remote mode)
      items.add(AppPopupMenuItem(
        value: 'blink',
        label: loc(context).blinkDeviceLight,
        icon: Icons.lightbulb_outline,
      ));

      // Pairing options for gateway (disabled in remote mode)
      if (meshNode.isGateway && autoOnboarding) {
        items.add(AppPopupMenuItem(
          value: 'pair',
          label: loc(context).instantPair,
          icon: Icons.link,
          enabled: !isRemoteReadOnly,
          children: [
            AppPopupMenuItem(
              value: 'pairWired',
              label: loc(context).pairWiredNode,
              icon: Icons.cable,
              enabled: !isRemoteReadOnly,
            ),
            AppPopupMenuItem(
              value: 'pairWireless',
              label: loc(context).pairWirelessNode,
              icon: Icons.wifi,
              enabled: !isRemoteReadOnly,
            ),
          ],
        ));
      }

      // Factory reset for extenders and gateway (disabled in remote mode)
      items.add(AppPopupMenuItem(
        value: 'reset',
        label: loc(context).resetToFactoryDefault,
        icon: Icons.restore,
        enabled: !isRemoteReadOnly,
      ));
    }

    return items.isEmpty ? null : items;
  }

  /// Handle menu action selection for a topology node.
  ///
  /// [onNavigateToDetail] - Callback to navigate to node details page
  /// [onNodeAction] - Callback to handle node actions (reboot, blink, etc.)
  void handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    String nodeId,
    String action,
    List<RouterTreeNode> originalNodes, {
    required void Function(String deviceId) onNavigateToDetail,
    required void Function(NodeInstantActions action, RouterTreeNode node)
        onNodeAction,
  }) {
    // Find the original node
    final originalNode = findOriginalNode(originalNodes, nodeId);
    if (originalNode == null) return;

    // Convert action string to NodeInstantActions enum
    NodeInstantActions? nodeAction;
    switch (action) {
      case 'reboot':
        nodeAction = NodeInstantActions.reboot;
        break;
      case 'blink':
        nodeAction = NodeInstantActions.blink;
        break;
      case 'pair':
        nodeAction = NodeInstantActions.pair;
        break;
      case 'pairWired':
        nodeAction = NodeInstantActions.pairWired;
        break;
      case 'pairWireless':
        nodeAction = NodeInstantActions.pairWireless;
        break;
      case 'reset':
        nodeAction = NodeInstantActions.reset;
        break;
      case 'details':
        // Handle details view
        onNavigateToDetail(originalNode.data.deviceId);
        return;
    }

    if (nodeAction != null) {
      onNodeAction(nodeAction, originalNode);
    }
  }

  /// Find original RouterTreeNode from MeshNode ID.
  RouterTreeNode? findOriginalNode(
    List<RouterTreeNode> rootNodes,
    String nodeId,
  ) {
    for (final rootNode in rootNodes) {
      final flatNodes = rootNode.toFlatList();
      for (final node in flatNodes) {
        if (TopologyAdapter.getNodeId(node) == nodeId) {
          return node;
        }
      }
    }
    return null;
  }
}
