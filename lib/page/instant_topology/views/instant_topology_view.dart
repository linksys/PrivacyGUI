import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
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
import 'package:privacy_gui/page/instant_topology/helpers/topology_menu_helper.dart';
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

  late final TopologyMenuHelper _menuHelper;

  @override
  void initState() {
    super.initState();
    _menuHelper = TopologyMenuHelper(serviceHelper);
    _isWidget = widget.args['widget'] ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final topologyState = ref.watch(instantTopologyProvider);

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
      onNodeTap: (nodeId) {
        final originalNode =
            _menuHelper.findOriginalNode(originalNodes, nodeId);
        if (originalNode != null) {
          onNodeTap(context, ref, originalNode);
        }
      },
      nodeMenuBuilder: _menuHelper.buildNodeMenu,
      onNodeMenuSelected: (nodeId, action) => _handleNodeMenuAction(
        context,
        ref,
        nodeId,
        action,
        originalNodes,
      ),
      // Custom badge builder for client counts
      nodeContentBuilder: (context, meshNode, style, isOffline) {
        // NOTE: Data Provider Limitation
        // The `InstantTopologyProvider` currently filters out client nodes.
        // As requested, we are reverting to standard `clientVisibility` logic.
        // Since there are no client nodes in the graph, the system count will be 0,
        // and the system badge will NOT appear.

        final originalNode =
            _menuHelper.findOriginalNode(originalNodes, meshNode.id);

        // Return simple content without manual badge (System handles badge in Graph View)
        if (meshNode.image != null) {
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image(
              image: meshNode.image!,
              fit: BoxFit.contain,
            ),
          );
        }

        final iconData = meshNode.iconData ??
            (originalNode != null
                ? _getIconForNode(originalNode.data)
                : Icons.devices);

        return AppIcon.font(
          iconData,
          size: 24,
          color: isOffline
              ? Theme.of(context).colorScheme.outline
              : Theme.of(context).colorScheme.onPrimary,
        );
      },

      treeConfig: TopologyTreeConfiguration(
        preferAnimationNode: false,
        showType: true,
        showStatusText: true,
        showStatusIndicator: true,
        titleBuilder: (meshNode) => meshNode.name,
        subtitleBuilder: (meshNode) {
          final originalNode =
              _menuHelper.findOriginalNode(originalNodes, meshNode.id);
          return originalNode?.data.model ?? '';
        },
      ),
      enableAnimation: true,
      clientVisibility: ClientVisibility.onHover,
      // Use unified registry: RippleNode for Graph View, Pulse/Liquid for Tree View
      nodeRendererRegistry: NodeRendererRegistry.unified,
      // Disable interaction for Internet node
      nodeTapFilter: (node) => !node.isInternet,
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
    final originalNode =
        _menuHelper.findOriginalNode(originalNodes, meshNode.id);

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

  /// Handle node menu action selection
  void _handleNodeMenuAction(
    BuildContext context,
    WidgetRef ref,
    String nodeId,
    String action,
    List<RouterTreeNode> originalNodes,
  ) {
    _menuHelper.handleMenuAction(
      context,
      ref,
      nodeId,
      action,
      originalNodes,
      onNavigateToDetail: (deviceId) =>
          _navigateToNodeDetail(context, ref, deviceId),
      onNodeAction: (nodeAction, node) => _handleSelectedNodeAction(
          nodeAction, node, serviceHelper.isSupportChildReboot()),
    );
  }

  void onNodeTap(BuildContext context, WidgetRef ref, RouterTreeNode node) {
    // Disable interaction for Internet node
    if (node.data.location == 'Internet') return;

    ref.read(nodeDetailIdProvider.notifier).state = node.data.deviceId;
    if (node.data.isOnline) {
      // Online nodes: Handled by Detail Panel -> View Details button
      // EXCEPT in Tree View (Mobile), where we must navigate directly on tap
      if (MediaQuery.of(context).size.width < AppTopology.defaultBreakpoint) {
        _navigateToNodeDetail(context, ref, node.data.deviceId);
      }
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

  /// Get appropriate icon for topology node
  IconData _getIconForNode(TopologyModel topology) {
    if (topology.isRouter) {
      return topology.isMaster ? Icons.router : Icons.wifi_tethering;
    }
    // Simple fallback
    return Icons.devices;
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
