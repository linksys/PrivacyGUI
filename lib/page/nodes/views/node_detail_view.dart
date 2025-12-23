import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/models/node_light_settings.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_light_settings_provider.dart';
import 'package:privacy_gui/core/jnap/providers/node_wan_status_provider.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/nodes.dart';
import 'package:privacy_gui/core/utils/wifi.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/customs/animated_refresh_container.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shared_widgets.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/views/device_list_widget.dart';
import 'package:privacy_gui/page/instant_device/views/devices_filter_widget.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/nodes/views/blink_node_light_widget.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/utils.dart';

import 'package:privacy_gui/page/components/composed/app_switch_trigger_tile.dart';
import 'package:ui_kit_library/ui_kit.dart';

class NodeDetailView extends ArgumentsConsumerStatefulView {
  const NodeDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NodeDetailView> createState() => _NodeDetailViewState();
}

class _NodeDetailViewState extends ConsumerState<NodeDetailView>
    with PageSnackbarMixin, SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 2, vsync: this);

    Future.doWhile(() => !mounted).then((value) {
      final state = ref.read(nodeDetailProvider);
      return ref
          .read(deviceFilterConfigProvider.notifier)
          .initFilter(preselectedNodeId: [state.deviceId]);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeDetailProvider);
    final filteredDeviceList = ref.watch(filteredDeviceListProvider);
    final isOnlineFilter = ref.watch(
        deviceFilterConfigProvider.select((value) => value.connectionFilter));
    return AppResponsiveLayout(
      desktop: (ctx) =>
          _desktopLayout(state, filteredDeviceList, isOnlineFilter),
      mobile: (ctx) => _mobileLayout(state, filteredDeviceList, isOnlineFilter),
    );
  }

  Widget _desktopLayout(NodeDetailState state,
      List<DeviceListItem> filteredDeviceList, bool isOnlineFilter) {
    return UiKitPageView.withSliver(
      title: state.location,
      actions: [
        AnimatedRefreshContainer(
          builder: (controller) {
            return AppButton.text(
              label: loc(context).refresh,
              icon: AppIcon.font(AppFontIcons.refresh),
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
      child: (context, constraints) => PageLayoutScope(
        overrideMaxColumns: 12,
        useContentPadding:
            PageLayoutScope.of(context)?.useContentPadding ?? true,
        contentWidth: constraints.maxWidth,
        child: Builder(
          builder: (ctx) {
            return Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: ctx.colWidth(4),
                      child: infoTab(state),
                    ),
                    AppGap.gutter(),
                    SizedBox(
                      width: ctx.colWidth(8),
                      child: deviceTab(
                        state.deviceId,
                        filteredDeviceList,
                        isOnlineFilter,
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _mobileLayout(NodeDetailState state,
      List<DeviceListItem> filteredDeviceList, bool isOnlineFilter) {
    return UiKitPageView.withSliver(
      title: state.location,
      tabController: _tabController,
      actions: [
        AnimatedRefreshContainer(
          builder: (controller) {
            return AppButton.text(
              label: loc(context).refresh,
              icon: AppIcon.font(AppFontIcons.refresh),
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
        SingleChildScrollView(
          child: infoTab(state),
        ),
        SingleChildScrollView(
          child: deviceTab(
            state.deviceId,
            filteredDeviceList,
            isOnlineFilter,
          ),
        ),
      ],
    );
  }

  Widget infoTab(NodeDetailState state) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppGap.sm(),
        _avatarCard(state),
        AppGap.sm(),
        _detailSection(state),
        AppGap.sm(),
        _lightCard(state),
      ],
    );
  }

  Widget deviceTab(String deviceId, List<DeviceListItem> filteredDeviceList,
      bool isOnlineFilter) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppGap.sm(),
        Row(
          children: [
            Expanded(
              child: AppText.labelLarge(
                  loc(context).nDevices(filteredDeviceList.length)),
            ),
            AppGap.lg(),
            AppResponsiveLayout(
              desktop: (ctx) => AppPopupButton(
                button: Row(
                  children: [
                    AppIcon.font(
                      AppFontIcons.filter,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    AppGap.sm(),
                    AppText.labelLarge(
                      loc(context).filters,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(10)),
                backgroundColor: Theme.of(context).colorScheme.surface,
                builder: (controller) {
                  return Container(
                    constraints: BoxConstraints(
                        minWidth: context.colWidth(3),
                        maxWidth: context.colWidth(7)),
                    child: DevicesFilterWidget(
                      preselectedNodeId: [deviceId],
                    ),
                  );
                },
              ),
              mobile: (ctx) => AppIconButton(
                icon: AppIcon.font(AppFontIcons.filter,
                    color: Theme.of(context).colorScheme.primary),
                onTap: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    useRootNavigator: true,
                    showDragHandle: true,
                    builder: (context) => Container(
                      padding: EdgeInsets.all(AppSpacing.xxl),
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
        AppGap.lg(),
        _deviceList(filteredDeviceList, isOnlineFilter)
      ],
    );
  }

  Widget _deviceList(
      List<DeviceListItem> filteredDeviceList, bool isOnlineFilter) {
    return DeviceListWidget(
      devices: filteredDeviceList,
      enableDeauth: isOnlineFilter,
      enableDelete: !isOnlineFilter,
      physics: const NeverScrollableScrollPhysics(),
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
            AppButton.text(
              label: loc(context).cancel,
              onTap: () {
                context.pop();
              },
            ),
            AppButton.text(
              label: loc(context).delete,
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
            AppButton.text(
              label: loc(context).cancel,
              onTap: () {
                context.pop();
              },
            ),
            AppButton.text(
              label: loc(context).disconnect,
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
    );
  }

  Widget _avatarCard(NodeDetailState state) {
    final isOnline = ref.watch(internetStatusProvider) == InternetStatus.online;
    return _nodeDetailBackgroundCard(
      child: SizedBox(
        // height: 160,
        child: SelectionArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xxxl),
                child: Center(
                  child: Image(
                    semanticLabel: 'device image',
                    height: 120,
                    image: DeviceImageHelper.getRouterImage(
                      routerIconTestByModel(modelNumber: state.modelNumber),
                    ),
                  ),
                ),
              ),
              _avatarInfoCard(
                title: state.location,
                trailing: AppIconButton(
                  icon: AppIcon.font(AppFontIcons.edit),
                  onTap: () {
                    _showEditNodeNameDialog(state);
                  },
                ),
              ),
              _avatarInfoCard(
                  title: loc(context).connectTo,
                  description: switch (state.isMaster) {
                    true =>
                      isOnline ? _checkEmptyValue(state.upstreamDevice) : '--',
                    false => _checkEmptyValue(state.upstreamDevice),
                  }),
              if (state.isMLO)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: AppButton.text(
                    label: loc(context).connectedWithMLO,
                    onTap: () {
                      showMLOCapableModal(context);
                    },
                  ),
                ),
              AppGap.lg(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _lightCard(NodeDetailState state) {
    bool isSupportNodeLight = serviceHelper.isSupportLedMode();

    bool isCognitive = isCognitiveMeshRouter(
      modelNumber: state.modelNumber,
      hardwareVersion: state.hardwareVersion,
    );
    if (!isSupportNodeLight || !isCognitive || !state.isMaster) {
      return Container();
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
      final statusText = nodeLightStatus == NodeLightStatus.off
          ? loc(context).off
          : loc(context).on;

      return [
        GestureDetector(
          key: const ValueKey('nodeLightSettings'),
          onTap: () {
            _showNodeLightSelectionDialog(nodeLightStatus);
          },
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              children: [
                Expanded(child: AppText.labelLarge(title)),
                if (nodeLightStatus != NodeLightStatus.night)
                  AppBadge(
                    label: statusText,
                    color: nodeLightStatus == NodeLightStatus.off
                        ? Theme.of(context).colorScheme.surfaceContainerHighest
                        : Theme.of(context).colorScheme.primary,
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppIcon.font(
                        AppFontIcons.darkMode,
                        size: 16,
                      ),
                      AppGap.sm(),
                      AppText.bodyMedium('8PM - 8AM'),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ];
    }
  }

  Widget _detailSection(NodeDetailState state) {
    final updateInfo = ref.watch(firmwareUpdateProvider.select((value) => value
        .nodesStatus
        ?.firstWhereOrNull((element) => element.deviceId == state.deviceId)));
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
                description: _checkEmptyValue(state.wanIpAddress),
              ),
            _detailInfoCard(
              title: loc(context).lanIPAddress,
              description: _checkEmptyValue(state.lanIpAddress),
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
            _detailInfoCard(
              title: loc(context).macAddress,
              description: _checkEmptyValue(state.macAddress),
            ),
          ],
        ),
      ),
    );
  }

  Widget _nodeDetailBackgroundCard({required Widget child}) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }

  Widget _nodeDetailInfoCard({required Widget child}) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
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
                  selectable: true,
                ),
            ],
          )),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _signalStrengthCard(NodeDetailState state) {
    return AppCard(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.bodySmall(
                  loc(context).signalStrength,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Row(children: [
                  AppText.labelLarge(
                    getWifiSignalLevel(state.signalStrength)
                        .resolveLabel(context),
                    color: getWifiSignalLevel(state.signalStrength)
                        .resolveColor(context),
                  ),
                  AppText.labelLarge(' • '),
                  AppText.labelLarge(
                    state.isWiredConnection
                        ? ''
                        : _checkEmptyValue('${state.signalStrength} dBm'),
                  ),
                ]),
              ],
            ),
          ),
          SharedWidgets.resolveSignalStrengthIcon(
              context, state.signalStrength),
        ],
      ),
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
              AppTextFormField(
                key: const Key('nodeNameTextField'),
                hintText: loc(context).nodeName,
                controller: textController,
                onChanged: (value) {
                  setState(() {
                    isEmpty = value.isEmpty;
                    overMaxSize = utf8.encoder.convert(value).length >= 256;
                  });
                },
              ),
              if (isEmpty)
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: AppText.bodySmall(
                    loc(context).theNameMustNotBeEmpty,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (overMaxSize)
                Padding(
                  padding: EdgeInsets.only(top: AppSpacing.xs),
                  child: AppText.bodySmall(
                    loc(context).deviceNameExceedMaxSize,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              if (isCognitive && hasBlinkFunction) ...[
                AppGap.lg(),
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
            label: loc(context).lightsOff,
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
