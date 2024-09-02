import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_fancy_tree_view/flutter_fancy_tree_view.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/snack_bar.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/page/topology/_topology.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_list.dart';
import 'package:privacygui_widgets/widgets/bullet_list/bullet_style.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:privacygui_widgets/widgets/topology/tree_item.dart';
import 'package:privacygui_widgets/widgets/topology/tree_node.dart';

class TopologyDetailedView extends ArgumentsConsumerStatefulView {
  const TopologyDetailedView({super.key, super.args});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _TopologyViewState();
}

class _TopologyViewState extends ConsumerState<TopologyDetailedView> {
  bool _isLoading = false;
  late final TreeController<RouterTreeNode> treeController;

  @override
  void initState() {
    super.initState();
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
    final topologyState = ref.watch(topologyProvider);
    final autoOnboarding =
        ref.read(topologyProvider.notifier).isSupportAutoOnboarding();
    treeController.roots = [topologyState.onlineRoot];
    treeController.expandAll();
    return LayoutBuilder(builder: (context, constraint) {
      final double treeWidth =
          (treeController.roots.first.maxLevel()) * 72 + 360;
      final double desiredTreeWidth =
          treeWidth > constraint.maxWidth ? treeWidth : constraint.maxWidth;
      return _isLoading
          ? AppFullScreenSpinner(
              text: loc(context).processing,
            )
          : StyledAppPageView(
              // scrollable: true,
              padding: EdgeInsets.zero,
              title: loc(context).instantTopology,
              actions: [
                if (autoOnboarding)
                  AppTextButton.noPadding(
                    loc(context).addNodes,
                    icon: LinksysIcons.add,
                    onTap: () {
                      context.pushNamed(RouteNamed.addNodes).then((result) {
                        if (result is bool && result) {
                          _showMoveChildNodesModal();
                        }
                      });
                    },
                  )
              ],
              child: AppBasicLayout(
                content: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SizedBox(
                          width: desiredTreeWidth,
                          child: TreeView<RouterTreeNode>(
                            treeController: treeController,
                            nodeBuilder: (BuildContext context,
                                TreeEntry<RouterTreeNode> entry) {
                              return TreeIndentation(
                                entry: entry,
                                guide: const IndentGuide.connectingLines(
                                  indent: 72,
                                  thickness: 0.5,
                                ),
                                child: Padding(
                                  padding:
                                      const EdgeInsets.fromLTRB(0, 16, 8, 0),
                                  child: switch (entry.node.runtimeType) {
                                    OnlineTopologyNode => Row(
                                        children: [
                                          SizedBox(
                                              width: 200,
                                              child: _buildHeader(
                                                  context, ref, entry.node)),
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
                      ),
                    ),
                    const AppGap.large1(),
                  ],
                ),
              ),
            );
    });
  }

  Widget _buildNode(
      BuildContext context, WidgetRef ref, AppTreeNode<TopologyModel> node) {
    return AppTreeNodeDetailedItem(
      name: node.data.location,
      image: CustomTheme.of(context).images.devices.getByName(node.data.icon),
      details: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildNodeContent(context, ref, node, node.data.isMaster)],
      ),
      // details: _buildNodeContent(context, ref, node, node.data.isMaster),
      tail: node.data.isOnline
          ? Icon(
              node.data.isWiredConnection
                  ? WiFiUtils.getWifiSignalIconData(context, null)
                  : WiFiUtils.getWifiSignalIconData(context, node.data.signalStrength),
              color: Theme.of(context).colorSchemeExt.green, semanticLabel: 'signal strength icon',
            )
          : const Icon(
              LinksysIcons.signalWifiNone,
              semanticLabel: 'signal Strength icon',
            ),
      background: node.data.isOnline
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surfaceVariant,
      onTap: () {
        onNodeTap(context, ref, node);
      },
      actions: node.data.isMaster
          ? [
              AppText.bodyLarge(loc(context).blinkDeviceLight),
              AppText.bodyLarge(loc(context).rebootUnit),
              AppText.bodyLarge(loc(context).instantPair),
              AppText.bodyLarge(
                loc(context).resetToFactoryDefault,
                color: Theme.of(context).colorScheme.error,
              )
            ]
          : [AppText.bodyLarge(loc(context).blinkDeviceLight)],
    );
  }

  Widget _buildNodeContent(BuildContext context, WidgetRef ref,
      AppTreeNode<TopologyModel> node, bool isMaster) {
    return Table(
      border: const TableBorder(),
      columnWidths: const {
        0: FlexColumnWidth(1),
        1: FlexColumnWidth(2),
      },
      children: [
        TableRow(children: [
          AppText.labelLarge('${loc(context).model}:'),
          AppText.bodyMedium(node.data.model),
        ]),
        TableRow(children: [
          AppText.labelLarge('${loc(context).serialNo}:'),
          AppText.bodyMedium(node.data.serialNumber),
        ]),
        TableRow(children: [
          AppText.labelLarge('${loc(context).fwVersion}:'),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              AppText.bodyMedium(node.data.fwVersion),
              Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 4, 0),
                child: Icon(
                  node.data.fwUpToDate
                      ? LinksysIcons.check
                      : LinksysIcons.cloudDownload,
                  color: node.data.fwUpToDate
                      ? Theme.of(context).colorSchemeExt.green
                      : Theme.of(context).colorScheme.error,
                  size: 16,
                ),
              ),
              AppText.labelMedium(
                node.data.fwUpToDate
                    ? loc(context).updated
                    : loc(context).available,
                color: node.data.fwUpToDate
                    ? Theme.of(context).colorSchemeExt.green
                    : Theme.of(context).colorScheme.error,
              ),
            ],
          ),
        ]),
        TableRow(children: [
          AppText.labelLarge('${loc(context).connection}:'),
          AppText.bodyMedium(node.data.isWiredConnection
              ? loc(context).wired
              : loc(context).wireless),
        ]),
        TableRow(children: [
          AppText.labelLarge('${loc(context).meshHealth}:'),
          AppText.bodyMedium('Excellent'),
        ]),
        TableRow(children: [
          AppText.labelLarge('${loc(context).ipAddress}:'),
          AppText.bodyMedium(node.data.ipAddress),
        ]),
      ],
    );
  }

  // List<Widget> _buildNodeDetails(BuildContext context, WidgetRef ref,
  //     AppTreeNode<TopologyModel> node, bool isMaster) {
  //   if (isMaster) {
  //     return [
  //       AppStyledText.bold('<a>Model:</a> ${node.data.model}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //       AppStyledText.bold('<a>Serial#:</a> ${node.data.serialNumber}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //       AppStyledText.bold('<a>FW Version:</a> ${node.data.fwVersion}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //       AppStyledText.bold(
  //           '<a>Connection:</a> ${node.data.isWiredConnection ? 'Wired' : 'Wireless'}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //       AppStyledText.bold('<a>Mesh Health:</a> Excellent',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //       AppStyledText.bold('<a>IP Address:</a> ${node.data.ipAddress}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //     ];
  //   }
  //   if (node.tag == 'offline') {
  //     return [
  //       AppStyledText.bold('<a>Model:</a> ${node.data.model}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //       AppStyledText.bold('<a>Serial#:</a> ${node.data.serialNumber}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //       AppStyledText.bold('<a>FW Version:</a> ${node.data.fwVersion}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //       AppStyledText.bold('<a>Connection:</a> ${loc(context).offline}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //     ];
  //   }

  //   return [
  //     AppStyledText.bold('<a>Model:</a> ${node.data.model}',
  //         defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //         tags: const ['a']),
  //     AppStyledText.bold('<a>Serial#:</a> ${node.data.serialNumber}',
  //         defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //         tags: const ['a']),
  //     AppStyledText.bold('<a>FW Version:</a> ${node.data.fwVersion}',
  //         defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //         tags: const ['a']),
  //     AppStyledText.bold(
  //         '<a>Connection:</a> ${node.data.isWiredConnection ? loc(context).wired : loc(context).wireless}',
  //         defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //         tags: const ['a']),
  //     if (!node.data.isWiredConnection)
  //       AppStyledText.bold('<a>Signal:</a> ${node.data.signalStrength}',
  //           defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //           tags: const ['a']),
  //     AppStyledText.bold('<a>IP Address:</a> ${node.data.ipAddress}',
  //         defaultTextStyle: Theme.of(context).textTheme.bodyMedium!,
  //         tags: const ['a']),
  //   ];
  // }

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
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.headlineSmall(loc(context).modalOfflineNodeTitle),
            content: Column(
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
                        AppText.bodyMedium(
                            loc(context).modalOfflineNodeCheckDesc1),
                        const AppGap.medium(),
                        AppTextButton.noPadding(
                          loc(context).modalOfflineNodeGoToNightMode,
                          onTap: () {
                            context.pop('nightMode');
                          },
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                            loc(context).modalOfflineNodeCheckTitle2),
                        AppText.bodyMedium(
                            loc(context).modalOfflineNodeCheckDesc2),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AppText.labelLarge(
                            loc(context).modalOfflineNodeCheckTitle3),
                        AppText.bodyMedium(
                            loc(context).modalOfflineNodeCheckDesc3),
                      ],
                    ),
                  ],
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: AppTextButton(
                    loc(context).modalOfflineRemoveNodeFromNetwork,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      context.pop('remove');
                    },
                  ),
                ),
                const AppGap.medium(),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppTextButton(
                    loc(context).close,
                    onTap: () {
                      context.pop();
                    },
                  ),
                ),
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
            title: AppText.headlineSmall(loc(context).modalOfflineNodeTitle),
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
        context.goNamed(RouteNamed.menuInstantTopology);
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

class AppTreeNodeDetailedItem extends StatelessWidget {
  final ImageProvider? image;
  final Widget? tail;
  final String name;
  final Widget? details;
  final VoidCallback? onTap;
  final Color? background;
  final List<Widget> actions;
  final void Function(int)? onActionTap;

  const AppTreeNodeDetailedItem({
    super.key,
    this.tail,
    required this.name,
    this.details,
    this.image,
    this.onTap,
    this.background,
    this.actions = const [],
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: background ?? Theme.of(context).colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        borderRadius: CustomTheme.of(context).radius.asBorderRadius().large,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: CustomTheme.of(context).radius.asBorderRadius().large,
        child: Container(
          constraints: const BoxConstraints(
            minWidth: 180,
            maxWidth: 400,
            minHeight: 264,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.medium),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AppText.labelLarge(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const AppGap.medium(),
                          if (details != null) details!,
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        if (tail != null) Center(child: tail!),
                        const AppGap.small3(),
                        Image(
                          image: image ??
                              CustomTheme.of(context).images.devices.routerLn11,
                          semanticLabel: 'router image',
                          width: 40,
                          height: 40,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const AppGap.medium(),
              const Divider(
                height: 0,
              ),
              Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: Spacing.large1, horizontal: Spacing.medium),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AppText.labelLarge('Instant-Actions'),
                      PopupMenuButton(
                        color: Theme.of(context).colorScheme.surface,
                        elevation: 10,
                        surfaceTintColor: Theme.of(context).colorScheme.surface,
                        itemBuilder: (context) {
                          return actions
                              .mapIndexed((index, e) =>
                                  PopupMenuItem<int>(value: index, child: e))
                              .toList();
                        },
                        onSelected: onActionTap,
                      )
                      // AppPopupButton(
                      //   parent: context,
                      //   borderRadius: CustomTheme.of(context)
                      //       .radius
                      //       .asBorderRadius()
                      //       .medium,
                      //   builder: (context) {
                      //     return Container(
                      //         constraints: const BoxConstraints(
                      //             minWidth: 200, maxWidth: 240),
                      //         padding: const EdgeInsets.all(8.0),
                      //         child: Column(
                      //           mainAxisSize: MainAxisSize.min,
                      //         ));
                      //     ;
                      //   },
                      //   button: const Icon(LinksysIcons.moreHoriz),
                      // ),
                    ],
                  )),
            ],
          ),
        ),
      ),
    );
  }
}
