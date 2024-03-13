import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/models/firmware_update_status_nodes.dart';
import 'package:linksys_app/core/jnap/models/node_light_settings.dart';
import 'package:linksys_app/core/jnap/providers/firmware_update_provider.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/nodes/_nodes.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/avatars/device_avatar.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/card/device_info_card.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'package:collection/collection.dart';

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
    if (isServiceSupport(JNAPService.routerLEDs3)) {
      ref.read(nodeDetailProvider.notifier).getLEDLight();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(nodeDetailProvider);
    final actions = [
      AppIconButton.noPadding(
        icon: LinksysIcons.help,
        onTap: () {
          context.pushNamed(RouteNamed.nodeLight);
        },
      )
    ];

    return LayoutBuilder(
      builder: (context, constraint) {
        return StyledAppPageView(
          padding: const EdgeInsets.only(),
          title: loc(context).devices,
          scrollable: true,
          child: AppBasicLayout(
            content: ResponsiveLayout(
                desktop: _desktopLayout(state), mobile: _mobileLayout(state)),
          ),
        );
      },
    );
  }

  Widget _desktopLayout(NodeDetailState state) {
    return Row(
      children: [
        SizedBox(
          width: 280,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _avatarCard(state),
              const AppGap.regular(),
              _connectionCard(state),
              const AppGap.regular(),
              _lightCard(state),
              const Spacer(),
            ],
          ),
        ),
        const AppGap.regular(),
        Expanded(
            child: Column(
          children: [
            _nameCard(state),
            _detailSection(state),
            _lanSection(state),
            if (state.isMaster) _wanSection(state),
          ],
        ))
      ],
    );
  }

  Widget _mobileLayout(NodeDetailState state) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _avatarCard(state),
        _nameCard(state),
        _connectionCard(state),
        _lightCard(state),
        _detailSection(state),
        _lanSection(state),
        // if (state.isMaster) _wanSection(state),
      ],
    );
  }

  Widget _avatarCard(NodeDetailState state) {
    return AppCard(
      child: SizedBox(
        height: 160,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: AppIconButton(
                icon: LinksysIcons.edit,
                onTap: () {},
              ),
            ),
            Expanded(
              child: AppDeviceAvatar.large(
                borderColor: Colors.transparent,
                backgroundColor: Colors.transparent,
                image: CustomTheme.of(context).images.devices.getByName(
                      routerIconTestByModel(modelNumber: state.modelNumber),
                    ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _nameCard(NodeDetailState state) {
    return AppDeviceInfoCard(
      title: loc(context).name,
      description: _checkEmptyValue(state.location),
      onTap: () {
        context.pushNamed(RouteNamed.changeNodeName);
      },
    );
  }

  Widget _connectionCard(NodeDetailState state) {
    return AppCard(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppDeviceInfoCard(
          title: loc(context).connectTo,
          description: _checkEmptyValue(state.upstreamDevice),
          showBorder: false,
          padding: const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
        ),
        const Divider(
          height: 8,
          thickness: 1,
        ),
        AppDeviceInfoCard(
          title: loc(context).connectedDevice,
          description: _checkEmptyValue(
            loc(context).nDevices(state.connectedDevices.length),
          ),
          showBorder: false,
          padding: const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
        ),
        if (!state.isWiredConnection) ...[
          const Divider(
            height: 8,
            thickness: 1,
          ),
          AppDeviceInfoCard(
            title: loc(context).signalStrength,
            description: _checkEmptyValue('${state.signalStrength} dBM'),
            showBorder: false,
            padding: const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
            trailing: Icon(getWifiSignalIconData(
              context,
              state.isWiredConnection ? null : state.signalStrength,
            )),
          ),
        ]
      ],
    ));
  }

  Widget _lightCard(NodeDetailState state) {
    final hasBlinkFunction = isServiceSupport(JNAPService.setup9);
    bool isSupportNightModeOnly = isServiceSupport(JNAPService.routerLEDs3);
    bool isSupportNodeLight = isServiceSupport(JNAPService.routerLEDs4);
    if (!hasBlinkFunction && !isSupportNightModeOnly && !isSupportNodeLight) {
      return const Center();
    }
    return AppCard(
        child: Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ...hasBlinkFunction
            ? [
                const Divider(
                  height: 8,
                ),
                AppDeviceInfoCard(
                  showBorder: false,
                  padding:
                      const EdgeInsets.symmetric(vertical: Spacing.semiSmall),
                  title: 'Blink node LED',
                  description: state.blinkingStatus.value,
                ),
              ]
            : [],
        ..._createNodeLightTile(state.nodeLightSettings)
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
    bool isSupportNightModeOnly = isServiceSupport(JNAPService.routerLEDs3);
    bool isSupportNodeLight = isServiceSupport(JNAPService.routerLEDs4);
    if (!isSupportNodeLight && !isSupportNightModeOnly) {
      return [];
    } else {
      final title = isSupportNodeLight ? 'Node Light' : 'Night Mode';
      return [
        const Divider(
          height: 8,
        ),
        AppDeviceInfoCard(
          title: title,
          description: NodeLightStatus.getStatus(nodeLightSettings)
              .resolveString(context),
          onTap: () {
            context.pushNamed(RouteNamed.nodeLightSettings);
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppDeviceInfoCard(
          title: loc(context).serialNumber,
          description: _checkEmptyValue(state.serialNumber),
        ),
        AppDeviceInfoCard(
          title: loc(context).modelNumber,
          description: _checkEmptyValue(state.modelNumber),
        ),
        AppDeviceInfoCard(
          title:
              getAppLocalizations(context).node_detail_label_firmware_version,
          description: _checkEmptyValue(state.firmwareVersion),
          trailing: Visibility(
              visible: isFwUpToDate,
              replacement: AppText.bodyLarge(
                  updateInfo?.availableUpdate?.firmwareVersion ?? ''),
              child:
                  AppText.labelSmall(getAppLocalizations(context).up_to_date)),
        ),
      ],
    );
  }

  Widget _lanSection(NodeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppGap.semiSmall(),
        AppText.labelLarge(
          getAppLocalizations(context).lan,
        ),
        const AppGap.semiSmall(),
        AppDeviceInfoCard(
          title: getAppLocalizations(context).ipAddress,
          description: state.lanIpAddress,
        ),
      ],
    );
  }

  Widget _wanSection(NodeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        const AppGap.semiSmall(),
        AppText.labelLarge(
          getAppLocalizations(context).node_detail_label_wan,
        ),
        const AppGap.semiSmall(),
        AppDeviceInfoCard(
          title: getAppLocalizations(context).ipAddress,
          description: state.wanIpAddress,
        ),
      ],
    );
  }
}
