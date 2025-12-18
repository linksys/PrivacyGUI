import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/topology_adapter.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';

import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';

import 'package:ui_kit_library/ui_kit.dart';

class InstantTopologyView extends ArgumentsConsumerStatefulView {
  const InstantTopologyView({super.key, super.args});

  factory InstantTopologyView.widget({Key? key}) {
    return InstantTopologyView(key: key, args: const {'widget': true});
  }

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _InstantTopologyViewState();
}

class _InstantTopologyViewState extends ConsumerState<InstantTopologyView> {
  bool _isLoading = false;
  bool _isWidget = false;

  @override
  void initState() {
    super.initState();
    _isWidget = widget.args['widget'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final topologyState = ref.watch(instantTopologyProvider);

    // Convert topology data to ui_kit format
    // Convert topology data to ui_kit format
    final meshTopology = TopologyAdapter.convert([topologyState.root]);

    return _isLoading
        ? Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          )
        : UiKitPageView(
            title: _isWidget ? null : loc(context).instantTopology,
            hideTopbar: _isWidget,
            backState: _isWidget ? UiKitBackState.none : UiKitBackState.enabled,
            useMainPadding: false,
            appBarStyle:
                _isWidget ? UiKitAppBarStyle.none : UiKitAppBarStyle.back,
            child: (context, constraints) => Column(
              children: [
                // Refresh button for non-mobile platforms
                if (!Utils.isMobilePlatform())
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedRefreshContainer(
                          builder: (controller) {
                            return AppIconButton(
                              icon: AppIcon.font(Icons.refresh),
                              onTap: () {
                                controller.repeat();
                                ref
                                    .read(pollingProvider.notifier)
                                    .forcePolling()
                                    .then((value) {
                                  controller.stop();
                                });
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                // Main topology content - use Expanded to fill available space
                if (constraints.maxHeight.isFinite)
                  Expanded(
                    child: _buildTopology(context, ref,
                        topologyState.root.children, meshTopology),
                  )
                else
                  SizedBox(
                    height: 800,
                    child: _buildTopology(context, ref,
                        topologyState.root.children, meshTopology),
                  ),
              ],
            ),
          );
  }

  Widget _buildTopology(BuildContext context, WidgetRef ref,
      List<RouterTreeNode> originalNodes, MeshTopology meshTopology) {
    return AppTopology(
      topology: meshTopology,
      viewMode: TopologyViewMode.auto, // Responsive switching
      onNodeTap: TopologyAdapter.wrapNodeTapCallback(
        originalNodes,
        (RouterTreeNode node) => onNodeTap(context, ref, node),
      ),
      nodeMenuBuilder: _buildNodeMenu,
      onNodeMenuSelected: (nodeId, action) => _handleNodeMenuAction(
        context,
        ref,
        nodeId,
        action,
        originalNodes,
      ),
      nodeContentBuilder: (context, meshNode, style, isOffline) {
        // Find original node for custom content
        final originalNode = _findOriginalNode(originalNodes, meshNode.id);
        if (originalNode == null) {
          // Return default content if original node not found
          return AppIcon.font(
            meshNode.iconData ?? Icons.devices,
            size: 20,
            color: isOffline
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.onPrimary,
          );
        }

        // Custom content based on node type
        return _buildCustomNodeContent(
          context,
          ref,
          originalNode,
          meshNode,
          isOffline,
        );
      },
      enableAnimation: true,
      clientVisibility: ClientVisibility.always,
      // Detail panel configuration
      nodeDetailConfig: NodeDetailConfig(
        trigger: NodeDetailTrigger.tap,
        mode: NodeDetailMode.floatingPanel,
        detailBuilder: (context, meshNode, metadata) => _buildDetailPanel(
          context,
          ref,
          meshNode,
          metadata,
          originalNodes,
        ),
      ),
    );
  }

  /// Build custom detail panel content for a node.
  Widget _buildDetailPanel(
    BuildContext context,
    WidgetRef ref,
    MeshNode meshNode,
    Map<String, dynamic>? metadata,
    List<RouterTreeNode> originalNodes,
  ) {
    // Find original node for more details
    final originalNode = _findOriginalNode(originalNodes, meshNode.id);

    // Disable detail panel for Internet node
    if (originalNode?.data.location == 'Internet')
      return const SizedBox.shrink();

    final isRouter = originalNode?.data.isRouter ?? false;
    final nodeType = isRouter ? 'Router' : 'Client';

    final ipAddress = metadata?['ipAddress'] as String? ?? '';
    final macAddress = metadata?['macAddress'] as String? ?? '';
    final model = metadata?['model'] as String? ?? '';
    final fwVersion = metadata?['fwVersion'] as String? ?? '';
    final signalStrength = metadata?['signalStrength'] as int? ?? 0;
    final isWired = metadata?['isWiredConnection'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (model.isNotEmpty) _detailRow(loc(context).model, model),
        if (ipAddress.isNotEmpty) _detailRow(loc(context).ipAddress, ipAddress),
        _detailRow('Node Type', nodeType),
        if (macAddress.isNotEmpty)
          _detailRow(loc(context).macAddress, macAddress),
        if (fwVersion.isNotEmpty)
          _detailRow(loc(context).firmwareVersion, fwVersion),
        if (isWired)
          _detailRow(loc(context).connectionType, loc(context).wired),
        // Force Signal Display for Debug
        if (!isWired && !meshNode.isOffline)
          _detailRow(loc(context).signalStrength, '$signalStrength dBm'),
        if (originalNode?.data.isOnline == true &&
            originalNode?.data.location != 'Internet')
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () =>
                    _navigateToNodeDetail(context, ref, meshNode.id),
                child: Text('Details'),
              ),
            ),
          ),
      ],
    );
  }

  /// Build a detail row with label and value.
  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            flex: 2,
            child: AppText.bodySmall(
              label,
              color: Colors.grey,
            ),
          ),
          Expanded(
            flex: 3,
            child: AppText.bodySmall(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Navigate to node detail page.
  void _navigateToNodeDetail(
      BuildContext context, WidgetRef ref, String nodeId) {
    ref.read(nodeDetailIdProvider.notifier).state = nodeId;
    context.pushNamed(RouteNamed.nodeDetails);
  }

  RouterTreeNode? _findOriginalNode(
      List<RouterTreeNode> rootNodes, String nodeId) {
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

  /// Build node menu using ui_kit AppPopupMenuItem
  List<AppPopupMenuItem<String>>? _buildNodeMenu(
      BuildContext context, MeshNode meshNode) {
    // Don't show menu for gateway/internet nodes or offline nodes
    if (meshNode.isGateway || meshNode.status == MeshNodeStatus.offline)
      return null;

    final items = <AppPopupMenuItem<String>>[];

    // Always add details
    items.add(AppPopupMenuItem(
      value: 'details',
      label: 'Details', // Direct text since localization key may not exist
      icon: Icons.info_outline,
    ));

    // Add actions based on node type and capabilities
    final supportChildReboot = serviceHelper.isSupportChildReboot();
    final autoOnboarding = serviceHelper.isSupportAutoOnboarding();

    if (meshNode.isExtender || meshNode.isClient) {
      // Reboot action for extenders and nodes
      if (supportChildReboot) {
        items.add(AppPopupMenuItem(
          value: 'reboot',
          label: loc(context).rebootUnit,
          icon: AppFontIcons.restartAlt,
        ));
      }

      // Blink device light
      items.add(AppPopupMenuItem(
        value: 'blink',
        label: loc(context).blinkDeviceLight,
        icon: AppFontIcons.lightBulb,
      ));

      // Pairing options for extenders
      if (meshNode.isExtender && autoOnboarding) {
        items.add(AppPopupMenuItem(
          value: 'pair',
          label: loc(context).instantPair,
          icon: Icons.link,
        ));
      }

      // Factory reset for extenders
      if (meshNode.isExtender) {
        items.add(AppPopupMenuItem(
          value: 'reset',
          label: loc(context).resetToFactoryDefault,
          icon: Icons.restore,
        ));
      }
    }

    return items.isEmpty ? null : items;
  }

  /// Handle node menu action selection
  void _handleNodeMenuAction(
    BuildContext context,
    WidgetRef ref,
    String nodeId,
    String action,
    List<RouterTreeNode> originalNodes,
  ) {
    // Find the original node
    final originalNode = _findOriginalNode(originalNodes, nodeId);
    if (originalNode == null) return;

    final supportChildReboot = serviceHelper.isSupportChildReboot();

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
      case 'reset':
        nodeAction = NodeInstantActions.reset;
        break;
      case 'details':
        // Handle details view
        onNodeTap(context, ref, originalNode);
        return;
    }

    if (nodeAction != null) {
      _handleSelectedNodeAction(nodeAction, originalNode, supportChildReboot);
    }
  }

  /// Build custom node content for ui_kit topology
  Widget _buildCustomNodeContent(
    BuildContext context,
    WidgetRef ref,
    RouterTreeNode originalNode,
    MeshNode meshNode,
    bool isOffline,
  ) {
    Widget content;

    // For gateway nodes, show additional info
    if (meshNode.isGateway && originalNode.data.isMaster) {
      final internetStatus = ref.watch(internetStatusProvider);
      final isOnline = internetStatus == InternetStatus.online;

      content = AppIcon.font(
        meshNode.iconData ?? Icons.router,
        size: 24,
        color: isOffline
            ? Theme.of(context).colorScheme.outline
            : isOnline
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.error,
      );
    } else if (meshNode.image != null) {
      // For other nodes, use device image if available
      content = Padding(
        padding: const EdgeInsets.all(8.0),
        child: Image(
          image: meshNode.image!,
          fit: BoxFit.contain,
        ),
      );
    } else {
      // For other nodes, use default rendering with custom icon
      content = AppIcon.font(
        meshNode.iconData ?? _getIconForNode(originalNode.data),
        size: 20,
        color: isOffline
            ? Theme.of(context).colorScheme.outline
            : Theme.of(context).colorScheme.onPrimary,
      );
    }

    // Use connectedDeviceCount from model
    final clientCount = originalNode.data.connectedDeviceCount;
    Widget result = content;

    if (clientCount > 0) {
      result = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          content,
          Positioned(
            top: -2,
            right: -6,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: const Color(0xFF2B3A42), // Dark Badge (Golden Style)
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
              child: Center(
                child: Text(
                  '$clientCount',
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return result;
  }

  /// Get appropriate icon for topology node
  IconData _getIconForNode(TopologyModel topology) {
    if (topology.isRouter) {
      return topology.isMaster ? Icons.router : Icons.wifi_tethering;
    }

    // Map device icons based on topology.icon string
    switch (topology.icon.toLowerCase()) {
      case 'laptop':
      case 'computer':
        return Icons.laptop;
      case 'phone':
      case 'smartphone':
        return AppFontIcons.smartPhone;
      case 'tablet':
        return Icons.tablet;
      case 'tv':
      case 'television':
        return Icons.tv;
      case 'gamedevice':
      case 'gaming':
        return AppFontIcons.stadiaController;
      case 'camera':
        return Icons.camera_alt;
      case 'printer':
        return Icons.print;
      case 'speaker':
        return AppFontIcons.musicSpeaker;
      case 'smartdevice':
      case 'iot':
        return AppFontIcons.devices;
      default:
        return AppFontIcons.devices;
    }
  }

  void onNodeTap(BuildContext context, WidgetRef ref, RouterTreeNode node) {
    // Disable interaction for Internet node
    if (node.data.location == 'Internet') return;

    ref.read(nodeDetailIdProvider.notifier).state = node.data.deviceId;
    if (node.data.isOnline) {
      // Online nodes: Handled by Detail Panel -> View Details button
      return;
    } else {
      // Handle offline nodes with modal dialog
      _showOfflineNodeModal(node).then((value) {
        if (value == 'remove') {
          _showRemoveNodeModal(node).then((shouldRemove) {
            if ((shouldRemove ?? false)) {
              // Do remove
              _doRemoveNode(node).then((result) {
                if (!context.mounted) return;
                showSimpleSnackBar(context, loc(context).nodeRemoved);
              }).onError((error, stackTrace) {
                if (!context.mounted) return;
                showSimpleSnackBar(context, loc(context).unknownError);
              });
            }
          });
        }
      });
    }
  }

  void _handleSelectedNodeAction(
    NodeInstantActions action,
    RouterTreeNode node,
    bool supportChildReboot,
  ) {
    switch (action) {
      case NodeInstantActions.reboot:
        _doReboot(supportChildReboot && !node.data.isMaster ? node : null,
            node.isLeaf());
        break;
      case NodeInstantActions.pair:
        // do nothing
        break;
      case NodeInstantActions.pairWired:
        _doInstantPairWired(ref);
        break;
      case NodeInstantActions.pairWireless:
        _doInstantPair();
        break;
      case NodeInstantActions.blink:
        _doBlinkNodeLed(ref, node.data.deviceId);
        break;
      case NodeInstantActions.reset:
        // If the target is a master, send null value to factory reset all nodes
        _doFactoryReset(supportChildReboot && !node.data.isMaster ? node : null,
            node.isLeaf());
        break;
    }
  }

  _doReboot(RouterTreeNode? node, bool isLastNode) {
    final isMaster = node?.data.isMaster ?? true;
    final targetDeviceIds =
        node?.toFlatList().map((e) => e.data.deviceId).toList() ?? [];
    showRebootModal(context, isMaster, isLastNode).then((result) {
      if (result == true) {
        final reboot =
            Future.sync(() => ref.read(pollingProvider.notifier).stopPolling())
                .then((_) => ref
                    .read(instantTopologyProvider.notifier)
                    .reboot(targetDeviceIds))
                .then((_) async {
          if (node?.data.isMaster == false) {
            // A delay to wait for child off
            // await Future.delayed(const Duration(seconds: 5));
            await ref.read(pollingProvider.notifier).forcePolling();
          }
        });
        // If the widget is not mounted, cancel reboot even though the user has agreed
        if (!mounted) return;
        doSomethingWithSpinner(context, reboot, messages: [
          '${loc(context).restarting}.',
          '${loc(context).restarting}..',
          '${loc(context).restarting}...'
        ]).then((value) {
          ref.read(pollingProvider.notifier).startPolling();
          if (!mounted) return;
          showSuccessSnackBar(context, loc(context).successExclamation);
        }).catchError((error) {
          if (!mounted) return;
          showRouterNotFoundAlert(context, ref);
        }, test: (error) => error is JNAPSideEffectError);
      }
    });
  }

  _doFactoryReset(RouterTreeNode? node, bool isLastNode) {
    final isMaster = node == null;
    final targetDeviceIds =
        node?.toFlatList().map((e) => e.data.deviceId).toList() ?? [];
    showFactoryResetModal(context, isMaster, isLastNode).then((isAgreed) {
      if (isAgreed == true) {
        // If the widget is not mounted, cancel factory reset even though the user has agreed
        if (!mounted) return;
        doSomethingWithSpinner(
          context,
          ref
              .read(instantTopologyProvider.notifier)
              .factoryReset(targetDeviceIds)
              .then(
            (_) async {
              if (!isMaster) {
                // Regardless of the result of waiting for disconnection,
                // the deletion action will be executed (from the bottom)
                await ref.read(deviceManagerProvider.notifier).deleteDevices(
                      deviceIds: targetDeviceIds.reversed.toList(),
                    );
                await ref.read(pollingProvider.notifier).forcePolling();
              }
            },
          ),
        ).then((_) {
          if (isMaster && mounted) {
            // If the master is restored to factory settings, the current session becomes invalid
            showRouterNotFoundAlert(context, ref);
          }
        });
      }
    });
  }

  _doBlinkNodeLed(WidgetRef ref, String deviceId) {
    ref.read(instantTopologyProvider.notifier).toggleBlinkNode(deviceId);
  }

  _doInstantPair() {
    context.pushNamed(RouteNamed.addNodes).then((result) {
      if (result is bool && result) {
        _showMoveChildNodesModal();
      }
    });
  }

  _doInstantPairWired(WidgetRef ref) {
    // Implementation needed - this is complex dialog logic
    // For now, use the simpler approach
    context.pushNamed(RouteNamed.addNodes).then((result) {
      if (result is bool && result) {
        _showMoveChildNodesModal();
      }
    });
  }

  _showMoveChildNodesModal() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).modalMoveChildNodesTitle),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop();
                },
                child: Text(loc(context).close),
              ),
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.bodyMedium(loc(context).modalMoveChildNodesDesc),
              ],
            ),
          );
        });
  }

  Future<String?> _showOfflineNodeModal(RouterTreeNode node) {
    return showDialog<String>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).modalOfflineNodeTitle),
            actions: [
              TextButton(
                onPressed: () {
                  context.pop('remove');
                },
                child: Text(
                  loc(context).modalOfflineRemoveNodeFromNetwork,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
              TextButton(
                onPressed: () {
                  context.pop();
                },
                child: Text(loc(context).close),
              )
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.bodyMedium(loc(context).modalOfflineNodeCheckDesc1),
              ],
            ),
          );
        });
  }

  Future<bool?> _showRemoveNodeModal(RouterTreeNode node) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).removeNode),
            actions: [
              TextButton(
                onPressed: () => context.pop(),
                child: Text(loc(context).cancel),
              ),
              TextButton(
                onPressed: () => context.pop(true),
                child: Text(
                  loc(context).removeNode,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              )
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: AppText.bodyMedium(
                      loc(context).modalRemoveNodeDesc(node.data.location)),
                ),
              ],
            ),
          );
        });
  }

  Future<void> _doRemoveNode(RouterTreeNode node) {
    setState(() {
      _isLoading = true;
    });
    final targetId = node.data.deviceId;
    return ref
        .read(deviceManagerProvider.notifier)
        .deleteDevices(deviceIds: [targetId]).then((value) {
      setState(() {
        _isLoading = false;
      });
    }).onError((error, stackTrace) {
      logger.e(error.toString());
      setState(() {
        _isLoading = false;
      });
      throw error ?? Exception('Unknown Error');
    });
  }
}
