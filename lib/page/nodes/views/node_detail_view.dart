import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/styled/styled_tab_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/device_list_widget.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/buttons/popup_button.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/label/status_label.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';

import 'package:collection/collection.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';

import 'blink_node_light_widget.dart';

class NodeDetailView extends ArgumentsConsumerStatefulView {
  const NodeDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NodeDetailView> createState() => _NodeDetailViewState();
}

class _NodeDetailViewState extends ConsumerState<NodeDetailView>
    with PageSnackbarMixin {
  @override
  void initState() {
    super.initState();

    Future.doWhile(() => !mounted).then((value) {
      final state = ref.read(nodeDetailProvider);
      return ref
          .read(deviceFilterConfigProvider.notifier)
          .initFilter(preselectedNodeId: [state.deviceId]);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeDetailProvider);
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    final isOnlineFilter = ref.watch(
        deviceFilterConfigProvider.select((value) => value.connectionFilter));
    return LayoutBuilder(
      builder: (context, constraint) {
        return ResponsiveLayout(
          desktop: _desktopLayout(
              constraint, state, filteredDeviceList, isOnlineFilter),
          mobile: _mobileLayout(
              constraint, state, filteredDeviceList, isOnlineFilter),
        );
      },
    );
  }

  Widget _desktopLayout(BoxConstraints constraint, NodeDetailState state,
      List<DeviceListItem> filteredDeviceList, bool isOnlineFilter) {
    return StyledAppPageView(
      padding: const EdgeInsets.only(),
      title: state.location,
      scrollable: true,
      actions: [
        AnimatedRefreshContainer(
          builder: (controller) {
            return AppTextButton.noPadding(
              loc(context).refresh,
              icon: LinksysIcons.refresh,
              onTap: () {
                controller.repeat();
                ref.read(pollingProvider.notifier).forcePolling().then((value) {
                  controller.stop();
                });
              },
            );
          },
        ),
      ],
      child: AppBasicLayout(
        content: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 4.col,
              child: infoTab(state),
            ),
            const AppGap.gutter(),
            SizedBox(
              width: 8.col,
              child: deviceTab(
                state.deviceId,
                filteredDeviceList,
                constraint.maxHeight - kDefaultToolbarHeight,
                isOnlineFilter,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileLayout(BoxConstraints constraint, NodeDetailState state,
      List<DeviceListItem> filteredDeviceList, bool isOnlineFilter) {
    return StyledAppTabPageView(
      title: state.location,
      actions: [
        AnimatedRefreshContainer(
          builder: (controller) {
            return AppTextButton.noPadding(
              loc(context).refresh,
              icon: LinksysIcons.refresh,
              onTap: () {
                controller.repeat();
                ref.read(pollingProvider.notifier).forcePolling().then((value) {
                  controller.stop();
                });
              },
            );
          },
        ),
      ],
      tabs: [
        Tab(
          text: loc(context).info,
        ),
        Tab(
          text: loc(context).devices,
        ),
      ],
      tabContentViews: [
        StyledAppPageView(
          useMainPadding: false,
          appBarStyle: AppBarStyle.none,
          scrollable: true,
          child: infoTab(state),
        ),
        StyledAppPageView(
          useMainPadding: false,
          appBarStyle: AppBarStyle.none,
          scrollable: true,
          child: deviceTab(
            state.deviceId,
            filteredDeviceList,
            constraint.maxHeight - kDefaultToolbarHeight,
            isOnlineFilter,
          ),
        ),
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
        const AppGap.small2(),
        _avatarCard(state),
        const AppGap.small2(),
        _detailSection(state),
        const AppGap.small2(),
        _lightCard(state),
        const Spacer(),
      ],
    );
  }

  Widget deviceTab(String deviceId, List<DeviceListItem> filteredDeviceList,
      double listHeight, bool isOnlineFilter) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.small2(),
        Row(
          children: [
            Expanded(
              child: AppText.labelLarge(
                  loc(context).nDevices(filteredDeviceList.length)),
            ),
            const AppGap.medium(),
            ResponsiveLayout(
              desktop: AppPopupButton(
                button: Row(
                  children: [
                    Icon(
                      LinksysIcons.filter,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const AppGap.small2(),
                    AppText.labelLarge(
                      loc(context).filters,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                backgroundColor: Theme.of(context).colorScheme.background,
                builder: (controller) {
                  return Container(
                    constraints:
                        BoxConstraints(minWidth: 3.col, maxWidth: 7.col),
                    child: DevicesFilterWidget(
                      preselectedNodeId: [deviceId],
                    ),
                  );
                },
              ),
              mobile: AppIconButton.noPadding(
                icon: LinksysIcons.filter,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    builder: (context) => Container(
                      padding: const EdgeInsets.all(Spacing.large2),
                      width: double.infinity,
                      child: DevicesFilterWidget(
                        preselectedNodeId: [deviceId],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const AppGap.medium(),
        SizedBox(
          height: listHeight,
          child: DeviceListWidget(
            devices: filteredDeviceList,
            enableDeauth: isOnlineFilter,
            enableDelete: !isOnlineFilter,
            // physics: const NeverScrollableScrollPhysics(),
            onItemClick: (item) {
              ref.read(deviceDetailIdProvider.notifier).state = item.deviceId;
              context.pushNamed(RouteNamed.deviceDetails);
            },
            onItemDelete: (device) {
              showSimpleAppDialog(
                context,
                dismissible: false,
                title: loc(context).nDevicesDeleteDevicesTitle(1),
                content: AppText.bodyMedium(
                    loc(context).nDevicesDeleteDevicesDescription(1)),
                actions: [
                  AppTextButton(
                    loc(context).cancel,
                    color: Theme.of(context).colorScheme.onSurface,
                    onTap: () {
                      context.pop();
                    },
                  ),
                  AppTextButton(
                    loc(context).delete,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      context.pop();
                      doSomethingWithSpinner(
                        context,
                        ref
                            .read(deviceManagerProvider.notifier)
                            .deleteDevices(deviceIds: [device.deviceId]),
                      );
                    },
                  ),
                ],
              );
            },
            onItemDeauth: (device) {
              showSimpleAppDialog(
                context,
                dismissible: false,
                title: loc(context).disconnectClient,
                content: AppText.bodyLarge(''),
                actions: [
                  AppTextButton(
                    loc(context).cancel,
                    color: Theme.of(context).colorScheme.onSurface,
                    onTap: () {
                      context.pop();
                    },
                  ),
                  AppTextButton(
                    loc(context).disconnect,
                    color: Theme.of(context).colorScheme.error,
                    onTap: () {
                      context.pop();
                      doSomethingWithSpinner(
                        context,
                        ref
                            .read(deviceManagerProvider.notifier)
                            .deauthClient(macAddress: device.macAddress)
                            .then((_) {
                          showChangesSavedSnackBar();
                        }).onError((error, stackTrace) {
                          showErrorMessageSnackBar(error);
                        }),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _avatarCard(NodeDetailState state) {
    return _nodeDetailBackgroundCard(
      child: SizedBox(
        // height: 160,
        child: SelectionArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: Spacing.large4),
                child: Center(
                  child: Image(
                    semanticLabel: 'device image',
                    height: 120,
                    image: CustomTheme.of(context).images.devices.getByName(
                          routerIconTestByModel(modelNumber: state.modelNumber),
                        ),
                  ),
                ),
              ),
              _avatarInfoCard(
                title: state.location,
                trailing: AppIconButton(
                  icon: LinksysIcons.edit,
                  semanticLabel: 'edit',
                  onTap: () {
                    _showEditNodeNameDialog(state);
                  },
                ),
              ),
              _avatarInfoCard(
                title: loc(context).connectTo,
                description: _checkEmptyValue(state.upstreamDevice),
              ),
              if (state.isMLO)
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: Spacing.medium),
                  child: AppTextButton.noPadding(
                    loc(context).connectedWithMLO,
                    onTap: () {
                      showMLOCapableModal(context);
                    },
                  ),
                ),
              const AppGap.medium(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lightCard(NodeDetailState state) {
    bool isSupportNodeLight = serviceHelper.isSupportLedMode();

    bool isCognitive = isCognitiveMeshRouter(
        modelNumber: state.modelNumber, hardwareVersion: state.hardwareVersion);
    if (!isSupportNodeLight || !isCognitive) {
      return const Center();
    }
    return _nodeDetailBackgroundCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _createNodeLightTile(),
      ),
    );
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

  List<Widget> _createNodeLightTile() {
    if (!serviceHelper.isSupportLedMode()) {
      return [];
    } else {
      final nodeLightSettings = ref.watch(nodeLightSettingsProvider);
      final title = loc(context).nodeLight;
      final nodeLightStatus = NodeLightStatus.getStatus(nodeLightSettings);
      return [
        AppSettingCard(
          key: const ValueKey('nodeLightSettings'),
          title: title,
          showBorder: false,
          color: Theme.of(context).colorScheme.background,
          padding: const EdgeInsets.all(Spacing.medium),
          trailing: nodeLightStatus != NodeLightStatus.night
              ? AppStatusLabel(
                  isOff: nodeLightStatus == NodeLightStatus.off,
                  label: loc(context).on,
                  offLabel: loc(context).off,
                )
              : const Row(
                  children: [
                    Icon(
                      LinksysIcons.darkMode,
                      size: 16,
                    ),
                    AppText.bodyMedium('8PM - 8AM')
                  ],
                ),
          onTap: () {
            _showNodeLightSelectionDialog(nodeLightStatus);
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
    return _nodeDetailBackgroundCard(
      child: SelectionArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!state.isWiredConnection) _signalStrengthCard(state),
            if (state.isMaster)
              _detailInfoCard(
                title: loc(context).wanIPAddress,
                description: state.wanIpAddress,
              ),
            _detailInfoCard(
              title: loc(context).lanIPAddress,
              description: state.lanIpAddress,
            ),
            _detailInfoCard(
              title: loc(context).firmwareVersion,
              description: _checkEmptyValue(state.firmwareVersion),
              trailing: SharedWidgets.nodeFirmwareStatusWidget(
                  context, !isFwUpToDate, () {
                context.pushNamed(RouteNamed.firmwareUpdateDetail);
              }),
            ),
            _detailInfoCard(
              title: loc(context).modelNumber,
              description: _checkEmptyValue(state.modelNumber),
            ),
            _detailInfoCard(
              title: loc(context).serialNumber,
              description: _checkEmptyValue(state.serialNumber),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nodeDetailBackgroundCard({required Widget child}) {
    return AppCard(
      padding: const EdgeInsets.all(Spacing.small2),
      color: Theme.of(context).colorScheme.background,
      child: child,
    );
  }

  Widget _nodeDetailInfoCard({required Widget child}) {
    return AppCard(
      showBorder: false,
      color: Theme.of(context).colorScheme.background,
      child: child,
    );
  }

  Widget _avatarInfoCard(
      {String? title, String? description, Widget? trailing}) {
    return _nodeDetailInfoCard(
      child: Row(
        children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                AppText.labelLarge(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (description != null) AppText.bodyMedium(description),
            ],
          )),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _detailInfoCard(
      {String? title, String? description, Widget? trailing}) {
    return _nodeDetailInfoCard(
      child: Row(
        children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title != null)
                AppText.bodySmall(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              if (description != null)
                AppText.labelLarge(
                  description,
                ),
            ],
          )),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _signalStrengthCard(NodeDetailState state) {
    return AppListCard(
      showBorder: false,
      color: Theme.of(context).colorScheme.background,
      padding: const EdgeInsets.all(Spacing.medium),
      title: AppText.bodySmall(
        loc(context).signalStrength,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      description: Row(children: [
        AppText.labelLarge(
          getWifiSignalLevel(state.signalStrength).resolveLabel(context),
          color: getWifiSignalLevel(state.signalStrength).resolveColor(context),
        ),
        const AppText.labelLarge(' • '),
        AppText.labelLarge(
          state.isWiredConnection
              ? ''
              : _checkEmptyValue('${state.signalStrength} dBM'),
        ),
      ]),
      trailing: SharedWidgets.resolveSignalStrengthIcon(
          context, state.signalStrength),
    );
  }

  void _showEditNodeNameDialog(NodeDetailState state) {
    final textController = TextEditingController()..text = state.location;
    final hasBlinkFunction = serviceHelper.isSupportLedBlinking();
    final isCognitive = isCognitiveMeshRouter(
        modelNumber: state.modelNumber, hardwareVersion: state.hardwareVersion);
    bool isEmpty = false;
    bool overMaxSize = false;
    showSubmitAppDialog(context,
        title: loc(context).nodeName,
        contentBuilder: (context, setState, onSubmit) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                semanticLabel: 'node name',
                hintText: loc(context).nodeName,
                border: const OutlineInputBorder(),
                controller: textController,
                errorText: isEmpty
                    ? loc(context).theNameMustNotBeEmpty
                    : overMaxSize
                        ? loc(context).deviceNameExceedMaxSize
                        : null,
                onSubmitted: (_) {
                  if (!isEmpty && !overMaxSize) {
                    onSubmit();
                  }
                },
                onChanged: (value) {
                  setState(() {
                    isEmpty = value.isEmpty;
                    overMaxSize = utf8.encoder.convert(value).length >= 256;
                  });
                },
              ),
              if (isCognitive && hasBlinkFunction) ...[
                const AppGap.medium(),
                const BlinkNodeLightWidget(),
              ],
            ],
          );
        },
        event: () async {
          await _saveName(textController.text);
        },
        checkPositiveEnabled: () => !isEmpty && !overMaxSize);
  }

  Future _saveName(String name) {
    return ref
        .read(nodeDetailProvider.notifier)
        .updateDeviceName(name)
        .then((_) => showChangesSavedSnackBar());
  }

  void _showNodeLightSelectionDialog(NodeLightStatus nodeLightStatus) {
    showSubmitAppDialog(context, title: loc(context).nodeLight,
        contentBuilder: (context, setState, onSubmit) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSwitchTriggerTile(
            title: AppText.bodyLarge(
              loc(context).nodeDetailsLedNightMode,
            ),
            value: nodeLightStatus != NodeLightStatus.on,
            onChanged: (value) {
              setState(() {
                nodeLightStatus =
                    value ? NodeLightStatus.night : NodeLightStatus.on;
              });
            },
          ),
          const Divider(),
          AppCheckbox(
            value: nodeLightStatus == NodeLightStatus.off,
            text: loc(context).lightsOff,
            onChanged: nodeLightStatus != NodeLightStatus.on
                ? (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      nodeLightStatus =
                          value ? NodeLightStatus.off : NodeLightStatus.night;
                    });
                  }
                : null,
          ),
        ],
      );
    }, event: () async {
      ref
          .read(nodeLightSettingsProvider.notifier)
          .setSettings(NodeLightSettings.fromStatus(nodeLightStatus));
      await ref
          .read(nodeLightSettingsProvider.notifier)
          .save()
          .then((_) => showChangesSavedSnackBar());
    });
  }
}
