import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/apps_and_gaming/ports/views/single_port_forwarding_rule_view.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/instant_topology/views/model/topology_model.dart';
import 'package:privacy_gui/page/instant_topology/views/model/tree_view_node.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';

enum NodeInstantActions {
  reboot,
  pair,
  blink,
  reset,
  ;

  String resolveLabel(BuildContext context) => switch (this) {
        reboot => loc(context).rebootUnit,
        pair => loc(context).instantPair,
        blink => loc(context).blinkDeviceLight,
        reset => loc(context).resetToFactoryDefault,
      };
}

class TreeNodeItem extends StatelessWidget {
  final RouterTreeNode node;
  final VoidCallback? onTap;
  final List<NodeInstantActions> actions;
  final void Function(NodeInstantActions)? onActionTap;

  const TreeNodeItem({
    super.key,
    required this.node,
    this.actions = NodeInstantActions.values,
    this.onTap,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      color: node.data.isOnline
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surfaceVariant,
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(
          minWidth: 180,
          maxWidth: 400,
          // minHeight: 264,
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
                          node.data.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const AppGap.medium(),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildNodeContent(
                              context,
                              node,
                            )
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Center(
                        child: SharedWidgets.resolveSignalStrengthIcon(
                          context,
                          node.data.signalStrength,
                          isOnline: node.data.isOnline,
                          isWired: node.data.isWiredConnection,
                        ),
                      ),
                      const AppGap.small3(),
                      SharedWidgets.resolveRouterImage(context, node.data.icon),
                    ],
                  ),
                ],
              ),
            ),
            if (node.data.isOnline && actions.isNotEmpty) ...[
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
                    AppText.labelLarge(loc(context).instantAction),
                    PopupMenuButton(
                      color: Theme.of(context).colorScheme.surface,
                      elevation: 10,
                      surfaceTintColor: Theme.of(context).colorScheme.surface,
                      itemBuilder: (context) {
                        return actions
                            .mapIndexed(
                                (index, e) => PopupMenuItem<NodeInstantActions>(
                                    value: e,
                                    child: AppText.labelLarge(
                                      e.resolveLabel(context),
                                      color: e == NodeInstantActions.reset
                                          ? Theme.of(context).colorScheme.error
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                    )))
                            .toList();
                      },
                      onSelected: onActionTap,
                    )
                  ],
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildNodeContent(
    BuildContext context,
    AppTreeNode<TopologyModel> node,
  ) {
    final signalLevel = getWifiSignalLevel(node.data.signalStrength);
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
              if (node.data.isOnline) ...[
                const AppGap.medium(),
                SharedWidgets.nodeFirmwareStatusWidget(
                    context, !node.data.fwUpToDate, () {
                  context.pushNamed(RouteNamed.firmwareUpdateDetail);
                }),
              ]
            ],
          ),
        ]),
        TableRow(children: [
          AppText.labelLarge('${loc(context).connection}:'),
          AppText.bodyMedium(!node.data.isOnline
              ? '--'
              : node.data.isWiredConnection
                  ? loc(context).wired
                  : loc(context).wireless),
        ]),
        if (!node.data.isMaster)
          TableRow(children: [
            AppText.labelLarge('${loc(context).meshHealth}:'),
            AppText.labelLarge(
              node.data.isOnline
                  ? signalLevel.resolveLabel(context)
                  : loc(context).offline,
              color: node.data.isOnline
                  ? signalLevel.resolveColor(context)
                  : Theme.of(context).colorScheme.outline,
            ),
          ]),
        TableRow(children: [
          AppText.labelLarge('${loc(context).ipAddress}:'),
          AppText.bodyMedium(node.data.isOnline ? node.data.ipAddress : '--'),
        ]),
      ],
    );
  }
}

class SimpleTreeNodeItem extends StatelessWidget {
  final RouterTreeNode node;
  final String? extra;
  final VoidCallback? onTap;
  final List<NodeInstantActions> actions;
  final void Function(NodeInstantActions)? onActionTap;

  const SimpleTreeNodeItem({
    super.key,
    required this.node,
    this.extra,
    this.onTap,
    this.actions = const [],
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: EdgeInsets.zero,
      padding: EdgeInsets.zero,
      color: node.data.isOnline
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surfaceVariant,
      onTap: onTap,
      child: Container(
        constraints: BoxConstraints(
            minWidth: 180,
            maxWidth: 300,
            maxHeight: actions.isEmpty ? 92 : 144),
        padding: const EdgeInsets.all(Spacing.medium),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    alignment: Alignment.centerRight,
                    children: [
                      SharedWidgets.resolveRouterImage(context, node.data.icon,
                          size: 64),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        AppText.titleMedium(
                          node.data.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        AppText.bodySmall(node.data.isOnline
                            ? loc(context)
                                .nDevices(node.data.connectedDeviceCount)
                            : loc(context).offline),
                        if (extra != null)
                          AppText.bodySmall(
                            extra!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  SharedWidgets.resolveSignalStrengthIcon(
                    context,
                    node.data.signalStrength,
                    isOnline: node.data.isOnline,
                    isWired: node.data.isWiredConnection,
                  ),
                ],
              ),
            ),
            // if (node.data.isOnline && actions.isNotEmpty) ...[
            //   const AppGap.medium(),
            //   const Divider(
            //     height: 0,
            //   ),
            //   Container(
            //     padding: const EdgeInsets.symmetric(
            //         vertical: 0, horizontal: Spacing.medium),
            //     child: Row(
            //       mainAxisAlignment: MainAxisAlignment.spaceBetween,
            //       crossAxisAlignment: CrossAxisAlignment.center,
            //       children: [
            //         AppText.labelLarge(loc(context).instantAction),
            //         PopupMenuButton(
            //           color: Theme.of(context).colorScheme.surface,
            //           elevation: 10,
            //           surfaceTintColor: Theme.of(context).colorScheme.surface,
            //           itemBuilder: (context) {
            //             return actions
            //                 .mapIndexed(
            //                     (index, e) => PopupMenuItem<NodeInstantActions>(
            //                         value: e,
            //                         child: AppText.labelLarge(
            //                           e.resolveLabel(context),
            //                           color: e == NodeInstantActions.reset
            //                               ? Theme.of(context).colorScheme.error
            //                               : Theme.of(context)
            //                                   .colorScheme
            //                                   .onSurface,
            //                         )))
            //                 .toList();
            //           },
            //           onSelected: onActionTap,
            //         )
            //       ],
            //     ),
            //   ),
            // ]
          ],
        ),
      ),
    );
  }
}

class BorderInfoCell extends StatefulWidget {
  final IconData? icon;
  final String name;
  final Color? lineColor;
  final bool showConnector;
  final double? width;

  const BorderInfoCell({
    super.key,
    this.name = "INTERNET",
    this.showConnector = true,
    this.icon,
    this.lineColor,
    this.width,
  });

  @override
  State<BorderInfoCell> createState() => _BorderInfoCellState();
}

class _BorderInfoCellState extends State<BorderInfoCell> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: widget.width,
          child: Card(
            margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            color: Theme.of(context).colorScheme.primaryContainer,
            elevation: 0,
            shape: RoundedRectangleBorder(
              side: BorderSide(
                  color: Theme.of(context).colorSchemeExt.primaryFixedDim ??
                      Theme.of(context).colorScheme.outline),
              borderRadius:
                  CustomTheme.of(context).radius.asBorderRadius().extraLarge,
            ),
            child: Padding(
              padding: const EdgeInsets.all(Spacing.medium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      semanticLabel: 'icon',
                      size: 24,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const AppGap.medium(),
                  ],
                  AppText.bodyLarge(widget.name),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
