import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:linksys_app/core/jnap/models/node_light_settings.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart';
import 'package:linksys_app/core/utils/extension.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/shortcuts/dialogs.dart';
import 'package:linksys_app/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/styled/styled_tab_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/nodes/_nodes.dart';
import 'package:linksys_app/page/nodes/views/connected_device_widget.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/device_info_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'package:collection/collection.dart';
import 'package:linksys_widgets/widgets/progress_bar/spinner.dart';
import 'package:linksys_widgets/widgets/radios/radio_list.dart';

import 'blink_node_light_widget.dart';

class NodeDetailView extends ArgumentsConsumerStatefulView {
  const NodeDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NodeDetailView> createState() => _NodeDetailViewState();
}

class _NodeDetailViewState extends ConsumerState<NodeDetailView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeDetailProvider);

    return LayoutBuilder(
      builder: (context, constraint) {
        return ResponsiveLayout(
          desktop: _desktopLayout(constraint, state),
          mobile: _mobileLayout(constraint, state),
        );
      },
    );
  }

  Widget _desktopLayout(BoxConstraints constraint, NodeDetailState state) {
    return StyledAppPageView(
      padding: const EdgeInsets.only(),
      title: loc(context).router,
      scrollable: true,
      child: AppBasicLayout(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 280,
              child: infoTab(state),
            ),
            const AppGap.regular(),
            Expanded(
                child: deviceTab(
                    state, constraint.maxHeight - kDefaultToolbarHeight))
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout(BoxConstraints constraint, NodeDetailState state) {
    return StyledAppTabPageView(
      title: loc(context).router,
      tabs: [
        Tab(
          text: loc(context).info,
          height: 24,
        ),
        Tab(
          text: loc(context).devices,
          height: 24,
        ),
      ],
      tabContentViews: [
        StyledAppPageView(
          appBarStyle: AppBarStyle.none,
          scrollable: true,
          child: infoTab(state),
        ),
        StyledAppPageView(
            appBarStyle: AppBarStyle.none,
            scrollable: true,
            child:
                deviceTab(state, constraint.maxHeight - kDefaultToolbarHeight))
      ],
      expandedHeight: 120,
    );
  }

  Widget infoTab(NodeDetailState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const AppGap.semiSmall(),
        _avatarCard(state),
        const AppGap.regular(),
        _detailSection(state),
        const AppGap.regular(),
        _lightCard(state),
        const Spacer(),
      ],
    );
  }

  Widget deviceTab(NodeDetailState state, double listHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.semiSmall(),
        AppText.labelLarge(
            loc(context).nDevices(state.connectedDevices.length)),
        const AppGap.semiSmall(),
        SizedBox(
          height: listHeight,
          child: ConnectedDeviceListWidget(
            devices: state.connectedDevices,
            physics: const NeverScrollableScrollPhysics(),
            onItemClick: (item) {
              ref.read(deviceDetailIdProvider.notifier).state = item.deviceID;
              context.pushNamed(RouteNamed.deviceDetails);
            },
          ),
        ),
      ],
    );
  }

  Widget _avatarCard(NodeDetailState state) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        // height: 160,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24.0),
              child: Center(
                child: Image(
                  height: 120,
                  image: CustomTheme.of(context).images.devices.getByName(
                        routerIconTestByModel(modelNumber: state.modelNumber),
                      ),
                ),
              ),
            ),
            AppCard(
              showBorder: false,
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AppText.labelLarge(state.location),
                  AppIconButton(
                    icon: LinksysIcons.edit,
                    onTap: () {
                      _showEditNodeNameDialog(state);
                    },
                  ),
                ],
              ),
            ),
            // const AppGap.regular(),
            AppDeviceInfoCard(
              title: loc(context).connectTo,
              description: _checkEmptyValue(state.upstreamDevice),
              showBorder: false,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lightCard(NodeDetailState state) {
    final hasBlinkFunction =
        ref.read(nodeDetailProvider.notifier).isSupportLedBlinking();
    bool isSupportNodeLight =
        ref.read(nodeDetailProvider.notifier).isSupportLedMode();
    if (!hasBlinkFunction && !isSupportNodeLight) {
      return const Center();
    }
    return AppCard(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ..._createNodeLightTile(state.nodeLightSettings),
        ...hasBlinkFunction
            ? [
                const AppGap.regular(),
                const BlinkNodeLightWidget(),
              ]
            : [],
      ],
    ));
  }

  String _checkEmptyValue(String? value) {
    if (value == null) {
      return '--';
    }
    if (value.isEmpty) {
      return '--';
    }
    return value;
  }

  List<Widget> _createNodeLightTile(NodeLightSettings? nodeLightSettings) {
    bool isSupportNodeLight =
        ref.read(nodeDetailProvider.notifier).isSupportLedMode();
    if (!isSupportNodeLight) {
      return [];
    } else {
      final title = loc(context).nodeLight;
      return [
        AppDeviceInfoCard(
          title: title,
          showBorder: false,
          padding: EdgeInsets.zero,
          trailing: AppText.bodySmall(
            NodeLightStatus.getStatus(nodeLightSettings).resolveString(context),
          ),
          onTap: () {
            // context.pushNamed(RouteNamed.nodeLightSettings);
            _showNodeLightSelectionDialog();
          },
        ),
      ];
    }
  }

  Widget _detailSection(NodeDetailState state) {
    final updateInfo = (ref.read(firmwareUpdateProvider).nodesStatus?.length ??
                0) >
            1
        ? ref.watch(firmwareUpdateProvider.select((value) => value.nodesStatus
            ?.firstWhereOrNull((element) => element is NodesFirmwareUpdateStatus
                ? element.deviceUUID == state.deviceId
                : false)))
        : ref.watch(firmwareUpdateProvider
            .select((value) => value.nodesStatus?.firstOrNull));
    final isFwUpToDate = updateInfo?.availableUpdate == null;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppDeviceInfoCard(
            showBorder: false,
            padding: EdgeInsets.zero,
            title: getAppLocalizations(context).ipAddress,
            description: state.lanIpAddress,
          ),
          if (state.isMaster) ...[
            const AppGap.semiSmall(),
            AppDeviceInfoCard(
              showBorder: false,
              padding: EdgeInsets.zero,
              title: getAppLocalizations(context).ipAddress,
              description: state.wanIpAddress,
            ),
          ],
          // AppDeviceInfoCard(
          //   title: loc(context).serialNumber,
          //   description: _checkEmptyValue(state.serialNumber),
          // ),
          // AppDeviceInfoCard(
          //   title: loc(context).modelNumber,
          //   description: _checkEmptyValue(state.modelNumber),
          // ),
          const AppGap.semiSmall(),

          AppDeviceInfoCard(
            showBorder: false,
            padding: EdgeInsets.zero,
            title:
                getAppLocalizations(context).node_detail_label_firmware_version,
            description: _checkEmptyValue(state.firmwareVersion),
            trailing: Visibility(
                visible: isFwUpToDate,
                replacement: AppText.bodyLarge(
                    updateInfo?.availableUpdate?.firmwareVersion ?? ''),
                child: AppText.labelSmall(
                    getAppLocalizations(context).up_to_date)),
          ),
          const AppGap.regular(),
          AppTextButton(
            loc(context).moreInfo,
            padding: const EdgeInsets.all(4),
            onTap: () {
              _showMoreRouterInfoModal(state);
            },
          )
        ],
      ),
    );
  }

  void _showEditNodeNameDialog(NodeDetailState state) {
    final textController = TextEditingController()..text = state.location;
    final hasBlinkFunction =
        ref.read(nodeDetailProvider.notifier).isSupportLedBlinking();
    showSubmitAppDialog(context, title: loc(context).nodeName,
        contentBuilder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            headerText: loc(context).nodeName,
            border: const OutlineInputBorder(),
            controller: textController,
          ),
          if (hasBlinkFunction) ...[
            const AppGap.regular(),
            const BlinkNodeLightWidget(),
          ],
        ],
      );
    }, event: () async {
      await ref
          .read(nodeDetailProvider.notifier)
          .updateDeviceName(textController.text)
          .then((_) => showSuccessSnackBar(context, loc(context).saved));
    });
  }

  void _showMoreRouterInfoModal(NodeDetailState state) {
    showSimpleAppDialog(
      context,
      title: loc(context).moreInfo.camelCapitalize(),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppText.labelLarge(loc(context).model),
          AppText.bodyMedium(state.modelNumber),
          const AppGap.regular(),
          AppText.labelLarge(loc(context).serialNumber.camelCapitalize()),
          AppText.bodyMedium(state.serialNumber),
        ],
      ),
      actions: [
        AppTextButton.noPadding(
          loc(context).close,
          onTap: () {
            context.pop();
          },
        )
      ],
    );
  }

  void _showNodeLightSelectionDialog() {
    var nodeLightStatus = NodeLightStatus.getStatus(
        ref.read(nodeDetailProvider).nodeLightSettings);
    showSubmitAppDialog(context, title: loc(context).nodeLight,
        contentBuilder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppRadioList(
            initial: nodeLightStatus,
            mainAxisSize: MainAxisSize.min,
            items: [
              AppRadioListItem(
                title: loc(context).off,
                value: NodeLightStatus.off,
              ),
              AppRadioListItem(
                title: loc(context).nodeDetailsLedNightMode,
                value: NodeLightStatus.night,
              ),
              AppRadioListItem(
                title: loc(context).on,
                value: NodeLightStatus.on,
              ),
            ],
            onChanged: (index, selectedType) {
              setState(() {
                if (selectedType != null) {
                  nodeLightStatus = selectedType;
                }
              });
            },
          ),
        ],
      );
    }, event: () async {
      NodeLightSettings settings;
      if (nodeLightStatus == NodeLightStatus.on) {
        settings = const NodeLightSettings(isNightModeEnable: false);
      } else if (nodeLightStatus == NodeLightStatus.off) {
        settings = const NodeLightSettings(
            isNightModeEnable: true, startHour: 0, endHour: 24);
      } else {
        settings = const NodeLightSettings(
            isNightModeEnable: true, startHour: 20, endHour: 8);
      }
      await ref
          .read(nodeDetailProvider.notifier)
          .setLEDLight(settings)
          .then((_) => showSuccessSnackBar(context, loc(context).saved));
    });
  }
}