import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/data/providers/dashboard_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/data/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/wan_external_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/core/utils/devices.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:flutter/material.dart';
import 'package:privacy_gui/page/dashboard/_dashboard.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_home_provider.dart';
import 'package:privacy_gui/page/health_check/_health_check.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_provider.dart';
import 'package:privacy_gui/page/instant_verify/views/components/ping_network_modal.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_external_widget.dart';
import 'package:privacy_gui/page/health_check/widgets/speed_test_widget.dart';
import 'package:privacy_gui/page/instant_verify/views/components/traceroute_modal.dart';
import 'package:privacy_gui/core/utils/topology_adapter.dart';
import 'package:privacy_gui/page/instant_topology/_instant_topology.dart';
import 'package:privacy_gui/page/instant_topology/helpers/topology_menu_helper.dart';
import 'package:privacy_gui/page/instant_topology/views/model/node_instant_actions.dart';
import 'package:privacy_gui/page/instant_topology/views/widgets/instant_topology_card.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacy_gui/route/constants.dart';

import 'package:ui_kit_library/ui_kit.dart';

import 'package:privacy_gui/page/instant_verify/services/instant_verify_pdf_service.dart';
import 'package:privacy_gui/core/utils/wifi.dart';

class InstantVerifyView extends ArgumentsConsumerStatefulView {
  const InstantVerifyView({super.key, super.args});

  @override
  ConsumerState<InstantVerifyView> createState() => _InstantVerifyViewState();
}

class _InstantVerifyViewState extends ConsumerState<InstantVerifyView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final TopologyMenuHelper _menuHelper;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _menuHelper = TopologyMenuHelper(serviceHelper);

    ref.read(wanExternalProvider.notifier).fetch();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    MediaQuery.of(context);
    final tabs = [loc(context).instantInfo, loc(context).instantTopology];
    final tabContents = [
      _instantInfo(context, ref),
      _buildInstantTopology(context, ref),
    ];
    return UiKitPageView.withSliver(
      onRefresh: () {
        return ref.read(pollingProvider.notifier).forcePolling();
      },
      title: loc(context).instantVerify,
      tabs: tabs.map((e) => Tab(text: e)).toList(),
      tabContentViews: tabContents,
      tabController: _tabController,
      actions: [
        AppIconButton(
          icon: AppIcon.font(AppFontIcons.print),
          onTap: () {
            doSomethingWithSpinner(
                context, InstantVerifyPdfService.generatePdf(context, ref));
          },
        ),
        if (!Utils.isMobilePlatform())
          AnimatedRefreshContainer(
            builder: (controller) {
              return Padding(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: AppIconButton(
                  icon: AppIcon.font(AppFontIcons.refresh),
                  onTap: () {
                    controller.repeat();
                    ref
                        .read(pollingProvider.notifier)
                        .forcePolling()
                        .then((value) {
                      controller.stop();
                    });
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildInstantTopology(BuildContext context, WidgetRef ref) {
    final topologyState = ref.watch(instantTopologyProvider);
    final meshTopology = TopologyAdapter.convert([topologyState.root]);
    final originalNodes = topologyState.root.children;

    return LayoutBuilder(
      builder: (context, constraints) {
        final content = AppTopology(
          topology: meshTopology,
          viewMode: TopologyViewMode.tree,
          nodeRendererRegistry: NodeRendererRegistry.unified,
          onNodeTap: (nodeId) {
            final originalNode =
                _menuHelper.findOriginalNode(originalNodes, nodeId);
            if (originalNode != null && originalNode.data.isOnline) {
              ref.read(nodeDetailIdProvider.notifier).state =
                  originalNode.data.deviceId;
              context.pushNamed(RouteNamed.nodeDetails);
            }
          },
          nodeMenuBuilder: _menuHelper.buildNodeMenu,
          nodeBuilder: (context, meshNode, isOffline) {
            // Special handling for Internet node
            if (meshNode.type == MeshNodeType.internet) {
              return Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    AppIcon.font(
                      Icons.public,
                      size: 24,
                      color: isOffline
                          ? Theme.of(context).disabledColor
                          : Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 16),
                    AppText.bodyMedium(loc(context).internet),
                  ],
                ),
              );
            }

            final originalNode =
                _menuHelper.findOriginalNode(originalNodes, meshNode.id);
            if (originalNode == null) return const SizedBox();

            return InstantTopologyCard(
              node: originalNode,
              isOffline: isOffline,
              isFocused:
                  originalNode.data.deviceId == ref.watch(nodeDetailIdProvider),
              onTap: () {
                // Handle tap via nodeBuilder manually if needed, or reply on TopologyTreeView to wrap?
                // TopologyTreeView wraps in AppCard which calls onNodeTap.
                // But if we want to ensure focus state updates or correct navigation:
                if (originalNode.data.isOnline) {
                  ref.read(nodeDetailIdProvider.notifier).state =
                      originalNode.data.deviceId;
                  context.pushNamed(RouteNamed.nodeDetails);
                } else {
                  // If offline, maybe we want specific action? Handled by menu or custom logic?
                  // InstantTopologyView logic was: check offline, show modal.
                  // Implemented in onNodeTap parameter.
                  // Since TopologyTreeView wraps this in AppCard with onNodeTap handler,
                  // we DON'T need onTap here IF TopologyTreeView handles it?
                  // BUT InstantTopologyCard might need to handle styling for touch.
                  // For now pass null to rely on parent inkwell.
                }
              },
            );
          },
          onNodeMenuSelected: (nodeId, action) => _handleNodeMenuAction(
            context,
            ref,
            nodeId,
            action,
            originalNodes,
          ),
          treeConfig: TopologyTreeConfiguration(
            expanded: true,
            preferAnimationNode: true,
            showType: false,
            showStatusText: false,
            showStatusIndicator: true,
            titleBuilder: (meshNode) => meshNode.name,
            subtitleBuilder: (meshNode) {
              final originalNode =
                  _menuHelper.findOriginalNode(originalNodes, meshNode.id);
              return originalNode?.data.model ?? '';
            },
            detailBuilder: (context, meshNode, metadata) {
              return _buildTreeDetailContent(
                  context, meshNode, metadata, originalNodes);
            },
          ),
        );

        // 處理無限高度情況
        if (constraints.maxHeight.isFinite) {
          return content;
        } else {
          return SizedBox(
            height: 800, // 增加高度以容納 expanded cards
            child: content,
          );
        }
      },
    );
  }

  /// 建構 Tree View Expanded Mode 的詳細內容
  Widget _buildTreeDetailContent(
    BuildContext context,
    MeshNode meshNode,
    Map<String, dynamic>? metadata,
    List<RouterTreeNode> originalNodes,
  ) {
    final theme = Theme.of(context);
    final originalNode =
        _menuHelper.findOriginalNode(originalNodes, meshNode.id);

    // Internet 節點不顯示詳細內容
    if (originalNode?.data.location == 'Internet') {
      return const SizedBox.shrink();
    }

    final model = metadata?['model'] as String? ?? '';
    final serialNumber = originalNode?.data.serialNumber ?? '';
    final macAddress = metadata?['macAddress'] as String? ?? '';
    final fwVersion = metadata?['fwVersion'] as String? ?? '';
    final isWired = metadata?['isWiredConnection'] as bool? ?? false;
    final isOnline = originalNode?.data.isOnline ?? false;
    String ipAddress = '';
    String meshHealth = '';

    if (isOnline) {
      ipAddress = metadata?['ipAddress'] as String? ?? '';

      final signalStrength = metadata?['signalStrength'] as int? ?? 0;
      if (signalStrength != 0) {
        meshHealth = getWifiSignalLevel(signalStrength).resolveLabel(context);
      }
    }

    Widget detailRow(String label, String value, {Color? valueColor}) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            SizedBox(
              width: 100,
              child: Text(
                '$label:',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: valueColor ?? theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (model.isNotEmpty) detailRow(loc(context).model, model),
        if (serialNumber.isNotEmpty)
          detailRow(loc(context).serialNumber, serialNumber),
        if (macAddress.isNotEmpty)
          detailRow(loc(context).macAddress, macAddress),
        if (fwVersion.isNotEmpty)
          detailRow(loc(context).firmwareVersion, fwVersion),
        if (isOnline)
          detailRow(loc(context).connectionType,
              isWired ? loc(context).wired : loc(context).wireless),
        if (meshHealth.isNotEmpty) detailRow('Mesh Health', meshHealth),
        if (ipAddress.isNotEmpty) detailRow(loc(context).ipAddress, ipAddress),
      ],
    );
  }

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
      onNavigateToDetail: (deviceId) {
        ref.read(nodeDetailIdProvider.notifier).state = deviceId;
        context.pushNamed(RouteNamed.nodeDetails);
      },
      onNodeAction: (nodeAction, node) => _handleSelectedNodeAction(
          nodeAction, node, serviceHelper.isSupportChildReboot()),
    );
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
      if (result == true && mounted) {
        doSomethingWithSpinner(
          context,
          Future.sync(() => ref.read(pollingProvider.notifier).stopPolling())
              .then((_) => ref
                  .read(instantTopologyProvider.notifier)
                  .reboot(targetDeviceIds))
              .then((_) async {
            if (node?.data.isMaster == false) {
              await ref.read(pollingProvider.notifier).forcePolling();
            }
          }),
        ).catchError((e) {
          logger.e('Reboot failed: $e');
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

  Future<void> _doFactoryReset(RouterTreeNode? node, bool isLastNode) async {
    final isMaster = node == null;
    final targetDeviceIds =
        node?.toFlatList().map((e) => e.data.deviceId).toList() ?? [];

    final isAgreed = await showFactoryResetModal(context, isMaster, isLastNode);
    if (isAgreed == true && mounted) {
      doSomethingWithSpinner(
        context,
        ref
            .read(instantTopologyProvider.notifier)
            .factoryReset(targetDeviceIds)
            .then((_) async {
          if (!isMaster) {
            await ref.read(deviceManagerProvider.notifier).deleteDevices(
                  deviceIds: targetDeviceIds.reversed.toList(),
                );
            await ref.read(pollingProvider.notifier).forcePolling();
          }
        }),
      ).catchError((error) {
        logger.e(error.toString());
        if (mounted) {
          showRouterNotFoundAlert(context, ref);
        }
      });
    }
  }

  Widget _instantInfo(BuildContext context, WidgetRef ref) {
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    final desktopCol = context.colWidth(4);
    return SingleChildScrollView(
      child: AppResponsiveLayout(
        mobile: (ctx) => _mobileLayout(context, ref),
        desktop: (ctx) =>
            _desktopLayout(context, ref, isHealthCheckSupported, desktopCol),
      ),
    );
  }

  Widget _mobileLayout(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _deviceInfoCard(context, ref),
        AppGap.lg(),
        _connectivityContentWidget(context, ref),
        AppGap.lg(),
        _speedTestContent(context),
        AppGap.lg(),
        _portsCard(context, ref),
      ],
    );
  }

  Widget _desktopLayout(BuildContext context, WidgetRef ref,
      bool isHealthCheckSupported, double desktopCol) {
    return Column(
      children: [
        isHealthCheckSupported
            ? IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _deviceInfoCard(context, ref),
                    ),
                    AppGap.gutter(),
                    Expanded(
                      child: _connectivityContentWidget(context, ref),
                    ),
                    AppGap.gutter(),
                    Expanded(
                      child: _speedTestContent(context),
                    ),
                  ],
                ),
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 2,
                    child: IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: _deviceInfoCard(context, ref),
                          ),
                          AppGap.gutter(),
                          Expanded(
                            child: _connectivityContentWidget(context, ref),
                          ),
                        ],
                      ),
                    ),
                  ),
                  AppGap.gutter(),
                  Expanded(
                    flex: 1,
                    child: _speedTestContent(context),
                  ),
                ],
              ),
        AppGap.lg(),
        _portsCard(context, ref),
      ],
    );
  }

  Widget _deviceInfoCard(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardManagerProvider);
    final devicesState = ref.watch(deviceManagerProvider);
    final uptime = DateFormatUtils.formatDuration(
        Duration(seconds: dashboardState.uptimes), context, true);
    final localTime =
        DateTime.fromMillisecondsSinceEpoch(dashboardState.localTime);
    final master = devicesState.masterDevice;
    final cpuLoad = dashboardState.cpuLoad;
    final memoryLoad = dashboardState.memoryLoad;

    return AppCard(
        key: const ValueKey('deviceInfoCard'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: _headerWidget(loc(context).deviceInfo),
            ),
            AppGap.lg(),
            _appNoBoarderCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppIcon.font(
                        AppFontIcons.calendar,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: AppText.bodySmall(
                            '${loc(context).systemTestDateFormat(localTime)} | ${loc(context).systemTestDateTime(localTime)}'),
                      ),
                    ],
                  ),
                  AppGap.lg(),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      AppIcon.font(
                        AppFontIcons.networkCheck,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm),
                        child: AppText.bodySmall(
                            '${loc(context).uptime}: $uptime'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(
              height: AppSpacing.xxxl,
              thickness: 1,
              indent: AppSpacing.xxl,
              endIndent: AppSpacing.xxl,
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).deviceName),
                  AppText.labelMedium(
                    master.getDeviceLocation(),
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).deviceModel),
                  AppText.labelMedium(
                    master.modelNumber ?? '--',
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).sku),
                  AppText.labelMedium(
                    dashboardState.skuModelNumber ?? '--',
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).serialNumber),
                  AppText.labelMedium(
                    master.unit.serialNumber ?? '--',
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Wrap(
                direction: Axis.vertical,
                children: [
                  AppText.bodySmall(loc(context).mac),
                  AppText.labelMedium(
                    master.getMacAddress(),
                    selectable: true,
                  ),
                ],
              ),
            ),
            _appNoBoarderCard(
              child: Row(
                children: [
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppText.bodySmall(
                        loc(context).firmwareVersion,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      AppText.labelMedium(
                        master.unit.firmwareVersion ?? '--',
                        selectable: true,
                      ),
                    ],
                  )),
                  SharedWidgets.nodeFirmwareStatusWidget(
                      context, hasNewFirmware(ref), () {
                    context.pushNamed(RouteNamed.firmwareUpdateDetail);
                  }),
                ],
              ),
            ),
            if (cpuLoad != null)
              _appNoBoarderCard(
                child: Wrap(
                  direction: Axis.vertical,
                  children: [
                    AppText.bodySmall(loc(context).cpuUtilization),
                    AppText.labelMedium(
                        '${((double.tryParse(cpuLoad.padLeft(2, '0')) ?? 0) * 100).toStringAsFixed(2)}%'),
                  ],
                ),
              ),
            if (memoryLoad != null)
              _appNoBoarderCard(
                child: Wrap(
                  direction: Axis.vertical,
                  children: [
                    AppText.bodySmall(loc(context).memoryUtilization),
                    AppText.labelMedium(
                        '${((double.tryParse(memoryLoad.padRight(2, '0')) ?? 0) * 100).toStringAsFixed(2)}%'),
                  ],
                ),
              ),
          ],
        ));
  }

  bool hasNewFirmware(WidgetRef ref) {
    final nodesStatus =
        ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus));
    return nodesStatus?.any((element) => element.availableUpdate != null) ??
        false;
  }

  Widget _portsCard(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardHomeProvider);
    return SizedBox(
      height: context.isMobileLayout ? 224 : 208,
      width: double.infinity,
      child: AppCard(
          key: const ValueKey('portCard'),
          padding: EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.xxl,
                ),
                child: Row(
                  // mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...state.lanPortConnections
                        .mapIndexed((index, e) => Expanded(
                              child: _portWidget(
                                  context,
                                  e == 'None' ? null : e,
                                  loc(context).indexedPort(index + 1),
                                  false),
                            ))
                        .toList(),
                    Expanded(
                      child: _portWidget(
                          context,
                          state.wanPortConnection == 'None'
                              ? null
                              : state.wanPortConnection,
                          loc(context).wan,
                          true),
                    )
                  ],
                ),
              ),
            ],
          )),
    );
  }

  Widget _portWidget(
      BuildContext context, String? connection, String label, bool isWan) {
    final isMobile = context.isMobileLayout;
    final portLabel = [
      AppIcon.font(
        connection == null
            ? AppFontIcons.circle
            : AppFontIcons.checkCircleFilled,
        color: connection == null
            ? Theme.of(context).colorScheme.surfaceContainerHighest
            : Theme.of(context).extension<AppColorScheme>()?.semanticSuccess,
      ),
      AppGap.sm(),
      AppText.labelMedium(label),
    ];
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          // mainAxisSize: MainAxisSize.min,
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            isMobile
                ? Column(
                    children: portLabel,
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: portLabel,
                  )
          ],
        ),
        Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: SizedBox(
            width: 40,
            height: 40,
            child: connection == null
                ? Assets.images.imgPortOff.svg()
                : Assets.images.imgPortOn.svg(),
          ),
        ),
        if (connection != null)
          Column(
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppIcon.font(
                    AppFontIcons.bidirectional,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  AppText.bodySmall(connection),
                ],
              ),
              SizedBox(
                width: 70,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: AppText.bodySmall(
                    loc(context).connectedSpeed,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                  ),
                ),
              )
            ],
          ),
        if (isWan) AppText.labelMedium(loc(context).internet),
      ],
    );
  }

  Widget _headerWidget(String title, [Widget? action]) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: AppText.titleSmall(title)),
        if (action != null) action,
      ],
    );
  }

  Widget _connectivityContentWidget(BuildContext context, WidgetRef ref) {
    return AppCard(
        key: const ValueKey('connectivityCard'),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: _headerWidget(loc(context).connectivity),
            ),
            AppGap.lg(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: Column(
                children: [
                  _linkStatusWidget(context, ref),
                  AppGap.lg(),
                  _wifiStatusWidget(context, ref),
                  AppGap.xxl(),
                  _wanStatusWidget(context, ref),
                ],
              ),
            ),
            AppGap.lg(),
            Divider(
              height: AppSpacing.xxxl,
              thickness: 1,
              indent: AppSpacing.xxl,
              endIndent: AppSpacing.xxl,
            ),
            AppGap.lg(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
              child: _pingTracerouteWidget(context, ref),
            ),
          ],
        ));
  }

  Widget _linkStatusWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final isOnline = systemConnectivityState.wanConnection != null;
    final theme = Theme.of(context).extension<AppDesignTheme>();

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          AppText(
            loc(context).internet,
            variant: AppTextVariant.titleSmall,
          ),
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isOnline
                  ? theme?.colorScheme.semanticSuccess
                  : theme?.colorScheme.semanticDanger,
            ),
          )
        ],
      ),
    );
  }

  Widget _wanStatusWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final wan = systemConnectivityState.wanConnection;
    final ipv4 = wan?.ipAddress ?? '';
    final dns2 = wan?.dnsServer2;

    Widget item(String label, String value) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelMedium(label),
          AppText(
            value,
            variant: AppTextVariant.titleSmall,
            fontWeight: FontWeight.bold,
          ),
          AppGap.md(),
        ],
      );
    }

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          item(loc(context).wanIPAddress, ipv4.isNotEmpty ? ipv4 : '--'),
          item(loc(context).gateway, wan?.gateway ?? '--'),
          item(loc(context).connectionType, wan?.wanType ?? '--'),
          item('${loc(context).dns} 1', wan?.dnsServer1 ?? '--'),
          if (dns2 != null && dns2.isNotEmpty)
            item('${loc(context).dns} 2', dns2),
        ],
      ),
    );
  }

  Widget _wifiStatusWidget(BuildContext context, WidgetRef ref) {
    final systemConnectivityState = ref.watch(instantVerifyProvider);
    final radios = systemConnectivityState.radioInfo.radios;
    final guestSettings = systemConnectivityState.guestRadioSettings;
    final guestWiFi = guestSettings.radios.firstOrNull;
    final theme = Theme.of(context).extension<AppDesignTheme>();

    Widget dot(bool enabled) {
      return Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled
              ? theme?.colorScheme.semanticSuccess
              : theme?.colorScheme.outline,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(AppSpacing.lg),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              AppText(
                loc(context).wifi,
                variant: AppTextVariant.titleSmall,
                fontWeight: FontWeight.bold,
              ),
              dot(true),
            ],
          ),
          Divider(height: AppSpacing.xxl),
          for (final e in radios) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(child: AppText.labelMedium('${e.band} | ${e.ssid}')),
                dot(e.isEnabled),
              ],
            ),
            AppGap.lg(),
          ],
          if (guestWiFi != null)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: AppText.labelMedium(
                      '${loc(context).guest} | ${guestWiFi.guestSSID}'),
                ),
                dot(guestSettings.isGuestNetworkEnabled),
              ],
            ),
        ],
      ),
    );
  }

  Widget _pingTracerouteWidget(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        _toolCard(
          context,
          key: const ValueKey('ping'),
          title: loc(context).ping,
          icon: Icons.radio_button_checked,
          onTap: () {
            doSomethingWithSpinner(
                context, _showPingNetworkModal(context, ref));
          },
        ),
        AppGap.lg(),
        _toolCard(
          context,
          key: const ValueKey('traceroute'),
          title: loc(context).traceroute,
          icon: Icons.route,
          onTap: () {
            doSomethingWithSpinner(context, _showTracerouteModal(context, ref));
          },
        ),
      ],
    );
  }

  Widget _toolCard(
    BuildContext context, {
    Key? key,
    required String title,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return InkWell(
      key: key,
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.lg),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(AppSpacing.lg),
        ),
        child: Row(
          children: [
            AppText(
              title,
              variant: AppTextVariant.titleSmall,
              fontWeight: FontWeight.bold,
            ),
            const Spacer(),
            Icon(icon, color: Theme.of(context).iconTheme.color),
          ],
        ),
      ),
    );
  }

  Widget _speedTestContent(BuildContext context) {
    final isHealthCheckSupported =
        ref.watch(healthCheckProvider).isSpeedTestModuleSupported;
    return AppCard(
      key: const ValueKey('speedTestCard'),
      padding: EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          _headerWidget(loc(context).speedTest),
          AppGap.xxl(),
          isHealthCheckSupported
              ? SpeedTestWidget()
              : AppCard(
                  child: Tooltip(
                    message: loc(context).featureUnavailableInRemoteMode,
                    child: Opacity(
                      opacity: BuildConfig.isRemote() ? 0.5 : 1,
                      child: AbsorbPointer(
                        absorbing: BuildConfig.isRemote(),
                        child: const SpeedTestExternalWidget(),
                      ),
                    ),
                  ),
                ),
        ],
      ),
    );
  }

  Widget _appNoBoarderCard({required Widget child, EdgeInsets? padding}) =>
      Padding(
        padding: padding ??
            const EdgeInsets.symmetric(
                horizontal: AppSpacing.xxl, vertical: AppSpacing.lg),
        child: child,
      );

  Future<void> _showPingNetworkModal(
      BuildContext context, WidgetRef ref) async {
    await showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).pingNetwork,
      content: const PingNetworkModal(),
    );
  }

  Future<void> _showTracerouteModal(BuildContext context, WidgetRef ref) async {
    await showSimpleAppDialog(
      context,
      dismissible: false,
      title: loc(context).traceroute,
      content: const TracerouteModal(),
    );
  }
}
