import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/nodes/providers/add_wired_nodes_provider.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/page/instant_topology/views/model/tree_view_node.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/tree_node_item.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
  late final TreeController<RouterTreeNode> treeController;

  @override
  void initState() {
    super.initState();
    _isWidget = widget.args['widget'] ?? false;
    treeController = TreeController<RouterTreeNode>(
      // Provide the root nodes that will be used as a starting point when
      // traversing your hierarchical data.
      roots: [
        OnlineTopologyNode(
            data: const TopologyModel(isOnline: true, location: 'Internet'),
            children: [])
      ],
      childrenProvider: (RouterTreeNode node) => node.children,
    );
  }

  @override
  void dispose() {
    super.dispose();
    treeController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topologyState = ref.watch(instantTopologyProvider);

    treeController.roots = [topologyState.root];
    treeController.expandAll();
    return LayoutBuilder(builder: (context, constraint) {
      final double treeWidth =
          (treeController.roots.first.maxLevel()) * 72 + 420;
      final double desiredTreeWidth =
          treeWidth > constraint.maxWidth ? treeWidth : constraint.maxWidth;
      return _isLoading
          ? AppFullScreenSpinner(
              text: loc(context).processing,
            )
          : StyledAppPageView(
              // scrollable: true,
              hideTopbar: _isWidget,
              useMainPadding: true,
              appBarStyle: _isWidget ? AppBarStyle.none : AppBarStyle.back,
              padding: EdgeInsets.zero,
              title: loc(context).instantTopology,
              child: (context, constraints) => Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Flexible(
                    child: _buildTopology(context, ref, desiredTreeWidth),
                  ),
                  const AppGap.large1(),
                ],
              ),
            );
    });
  }

  Widget _buildTopology(
      BuildContext context, WidgetRef ref, double largeDesiredTreeWidth) {
    return ResponsiveLayout.isMobileLayout(context)
        ? TreeView<RouterTreeNode>(
            treeController: treeController,
            physics: ScrollPhysics(),
            shrinkWrap: true,
            nodeBuilder:
                (BuildContext context, TreeEntry<RouterTreeNode> entry) {
              return TreeIndentation(
                entry: entry,
                guide: IndentGuide.connectingLines(
                  indent: 36,
                  thickness: 0.5,
                  pathModifier: (path) => TopologyNodeItem.buildPath(
                      path,
                      entry.node,
                      entry.node.data.isMaster
                          ? ref.watch(internetStatusProvider) ==
                              InternetStatus.online
                          : entry.node.data.isOnline),
                ),
                child: switch (entry.node.runtimeType) {
                  OnlineTopologyNode => Row(
                      children: [
                        SizedBox(
                            width: 200,
                            child: _buildHeader(context, ref, entry.node)),
                        const Spacer(),
                      ],
                    ),
                  RouterTopologyNode => Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: _buildNode(context, ref, entry.node),
                    ),
                  _ => const Center(),
                },
              );
            },
          )
        : SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: largeDesiredTreeWidth,
              child: TreeView<RouterTreeNode>(
                treeController: treeController,
                nodeBuilder:
                    (BuildContext context, TreeEntry<RouterTreeNode> entry) {
                  return TreeIndentation(
                    entry: entry,
                    guide: IndentGuide.connectingLines(
                      indent: 72,
                      thickness: 0.5,
                      pathModifier: (path) => TopologyNodeItem.buildPath(
                          path,
                          entry.node,
                          entry.node.data.isMaster
                              ? ref.watch(internetStatusProvider) ==
                                  InternetStatus.online
                              : entry.node.data.isOnline),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 16, 8, 0),
                      child: switch (entry.node.runtimeType) {
                        OnlineTopologyNode => Row(
                            children: [
                              SizedBox(
                                  width: 200,
                                  child:
                                      _buildHeader(context, ref, entry.node)),
                              const Spacer(),
                            ],
                          ),
                        RouterTopologyNode => Row(
                            children: [
                              _buildNode(context, ref, entry.node),
                              const Spacer(),
                            ],
                          ),
                        _ => const Center(),
                      },
                    ),
                  );
                },
              ),
            ),
          );
  }

  Widget _buildNode(BuildContext context, WidgetRef ref, RouterTreeNode node) {
    final supportChildReboot = serviceHelper.isSupportChildReboot();

    return ResponsiveLayout.isMobileLayout(context)
        ? TopologyNodeItem.simple(
            node: node,
            actions: _buildActions(node),
            onTap: () {
              onNodeTap(context, ref, node);
            },
            onActionTap: (action) {
              _handleSelectedNodeAction(action, node, supportChildReboot);
            },
          )
        : TopologyNodeItem(
            node: node,
            actions: _buildActions(node),
            onTap: () {
              onNodeTap(context, ref, node);
            },
            onActionTap: (action) {
              _handleSelectedNodeAction(action, node, supportChildReboot);
            },
          );
  }

  List<NodeInstantActions> _buildActions(RouterTreeNode node) {
    final autoOnboarding = serviceHelper.isSupportAutoOnboarding();
    final hasBlinkFunction = serviceHelper.isSupportLedBlinking();
    final supportChildReboot = serviceHelper.isSupportChildReboot();
    final supportChildFactoryReset = serviceHelper.isSupportChildFactoryReset();

    return node.data.isMaster
        ? [
            if (hasBlinkFunction &&
                isCognitiveMeshRouter(
                    modelNumber: node.data.model,
                    hardwareVersion: node.data.hardwareVersion))
              NodeInstantActions.blink,
            NodeInstantActions.reboot,
            if (autoOnboarding) NodeInstantActions.pair,
            NodeInstantActions.reset,
          ]
        : [
            if (hasBlinkFunction &&
                isCognitiveMeshRouter(
                    modelNumber: node.data.model,
                    hardwareVersion: node.data.hardwareVersion))
              NodeInstantActions.blink,
            if (supportChildReboot &&
                isCognitiveMeshRouter(
                    modelNumber: node.data.model,
                    hardwareVersion: node.data.hardwareVersion))
              NodeInstantActions.reboot,
            if (supportChildFactoryReset &&
                isCognitiveMeshRouter(
                    modelNumber: node.data.model,
                    hardwareVersion: node.data.hardwareVersion))
              NodeInstantActions.reset,
          ];
  }

  _handleSelectedNodeAction(
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
        doSomethingWithSpinner(context, reboot, messages: [
          '${loc(context).restarting}.',
          '${loc(context).restarting}..',
          '${loc(context).restarting}...'
        ]).then((value) {
          ref.read(pollingProvider.notifier).startPolling();
          showSuccessSnackBar(context, loc(context).successExclamation);
        }).catchError((error) {
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
          if (isMaster) {
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
    // context.pushNamed(RouteNamed.addWiredNodes).then((result) {
    //   if (result is bool && result) {
    //     _showMoveChildNodesModal();
    //   }
    // });
    final addWiredNodesNotifier = ref.read(addWiredNodesProvider.notifier);
    addWiredNodesNotifier.startAutoOnboarding(context);
    final addWiredNodesState = ref.watch(addWiredNodesProvider);
    showAppSpinnerDialog(
      context,
      title: loc(context).instantPair,
      messages: [addWiredNodesState.loadingMessage ?? ''],
      actions: [
        AppTextButton(
          loc(context).donePairing,
          onTap: () {
            if (!addWiredNodesState.isLoading) {
              addWiredNodesNotifier.forceStopAutoOnboarding();
            }
            context.pop();
          },
        )
      ],
    );
  }

  Widget _buildHeader(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return BorderInfoCell(
      name: node.data.location == 'Internet'
          ? loc(context).internet
          : node.data.location,
      icon: node is OnlineTopologyNode ? LinksysIcons.language : null,
      showConnector: node is OnlineTopologyNode,
      width: node.width,
    );
  }

  void onNodeTap(BuildContext context, WidgetRef ref, RouterTreeNode node) {
    ref.read(nodeDetailIdProvider.notifier).state = node.data.deviceId;
    if (node is DeviceTopologyNode) {
      context.pop();
    } else if (node.data.isOnline) {
      // Update the current target Id for node state
      context.pushNamed(RouteNamed.nodeDetails);
    } else {
      // context.pushNamed(RouteNamed.nodeOffline);
      _showOfflineNodeModal(node).then((value) {
        if (value == 'nightMode') {
        } else if (value == 'remove') {
          _showRemoveNodeModal(node).then((value) {
            if ((value ?? false)) {
              // Do remove
              _doRemoveNode(node).then((result) {
                showSimpleSnackBar(context, loc(context).nodeRemoved);
              }).onError((error, stackTrace) {
                showSimpleSnackBar(context, loc(context).unknownError);
              });
            }
          });
        }
      });
    }
  }

  Future<String?> _showOfflineNodeModal(RouterTreeNode node) {
    return showSimpleAppDialog(
      context,
      title: loc(context).modalOfflineNodeTitle,
      actions: [
        AppTextButton(
          loc(context).modalOfflineRemoveNodeFromNetwork,
          color: Theme.of(context).colorScheme.error,
          onTap: () {
            context.pop('remove');
          },
        ),
        AppTextButton(
          loc(context).close,
          onTap: () {
            context.pop();
          },
        )
      ],
      width: 400,
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: AbsorbPointer(
                child: _buildNode(context, ref, node),
              ),
            ),
            AppBulletList(
              style: AppBulletStyle.number,
              itemSpacing: 24,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelLarge(
                        loc(context).modalOfflineNodeCheckTitle1),
                    AppText.bodyMedium(loc(context).modalOfflineNodeCheckDesc1),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelLarge(
                        loc(context).modalOfflineNodeCheckTitle2),
                    AppText.bodyMedium(loc(context).modalOfflineNodeCheckDesc2),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelLarge(
                        loc(context).modalOfflineNodeCheckTitle3),
                    AppText.bodyMedium(loc(context).modalOfflineNodeCheckDesc3),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _showRemoveNodeModal(RouterTreeNode node) {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).removeNode),
            actions: [
              AppTextButton.noPadding(
                loc(context).cancel,
                onTap: () => context.pop(),
              ),
              AppTextButton.noPadding(
                loc(context).removeNode,
                color: Theme.of(context).colorScheme.error,
                onTap: () => context.pop(true),
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

  _showMoveChildNodesModal() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).modalMoveChildNodesTitle),
            actions: [
              AppTextButton(
                loc(context).close,
                onTap: () {
                  context.pop();
                },
              ),
            ],
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.bodyMedium(loc(context).modalMoveChildNodesDesc),
                const AppGap.large2(),
                SvgPicture(
                  CustomTheme.of(context).images.imgMoveNodes,
                  semanticsLabel: 'move nodes image',
                ),
              ],
            ),
          );
        });
  }
}
