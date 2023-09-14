import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/actions/better_action.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/core/utils/nodes.dart';
import 'package:linksys_app/core/utils/wifi.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/devices/node_detail_provider.dart';
import 'package:linksys_app/provider/devices/node_detail_state.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/avatars/device_avatar.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/profile_header_layout.dart';

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
        icon: getCharactersIcons(context).infoRound,
        onTap: () {
          context.pushNamed(RouteNamed.nodeLight);
        },
      )
    ];

    return LayoutBuilder(
      builder: (context, constraint) {
        return AppProfileHeaderLayout(
          expandedHeight: constraint.maxHeight / 2,
          collaspeTitle: state.location,
          onCollaspeBackTap: () {
            context.pop();
          },
          background: Theme.of(context).colorScheme.tertiaryContainer,
          actions: actions,
          header: Column(
            children: [
              LinksysAppBar(
                leading: AppIconButton(
                  icon: getCharactersIcons(context).arrowLeft,
                  onTap: () {
                    context.pop();
                  },
                ),
                trailing: actions,
              ),
              const Spacer(),
              _header(state),
            ],
          ),
          body: Column(
            children: [
              _content(state),
            ],
          ),
        );
      },
    );
  }

  Widget _header(NodeDetailState state) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(),
      child: Column(
        children: [
          _nodeAvatar(state),
          const AppGap.regular(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppText.titleSmall(
                state.location,
              ),
              const AppGap.semiSmall(),
              AppIconButton.noPadding(
                icon: getCharactersIcons(context).editDefault,
                onTap: () {
                  context.pushNamed(RouteNamed.changeNodeName);
                },
              ),
            ],
          ),
          // const AppGap.extraBig(),
          _nodeStatus(state),
          const AppGap.semiSmall(),
        ],
      ),
    );
  }

  Widget _nodeAvatar(NodeDetailState state) {
    return AppDeviceAvatar.extraLarge(
      image: AppTheme.of(context).images.devices.getByName(
            routerIconTest(modelNumber: state.modelNumber),
          ),
    );
  }

  Widget _nodeStatus(NodeDetailState state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        GestureDetector(
          onTap: () {
            print('test');
          },
          child: Column(
            children: [
              Container(
                height: AppTheme.of(context).spacing.extraBig,
                width: AppTheme.of(context).spacing.extraBig,
                alignment: Alignment.center,
                child: AppText.titleLarge(
                  '${state.connectedDevices.length}',
                ),
              ),
              AppText.bodyLarge(
                getAppLocalizations(context).devices,
              ),
            ],
          ),
        ),
        Column(
          children: [
            Container(
              height: AppTheme.of(context).spacing.extraBig,
              width: AppTheme.of(context).spacing.extraBig,
              alignment: Alignment.center,
              child: _getConnectionImage(state),
            ),
            AppText.bodyLarge(
              state.isWiredConnection
                  ? "Wired"
                  : getWifiSignalLevel(state.signalStrength).displayTitle,
            ),
          ],
        ),
        Column(
          children: [
            Container(
              height: AppTheme.of(context).spacing.extraBig,
              width: AppTheme.of(context).spacing.extraBig,
              alignment: Alignment.center,
              child: AppSwitch(
                value: state.isLightTurnedOn,
                onChanged: (value) {
                  ref.read(nodeDetailProvider.notifier).toggleNodeLight(value);
                  //ref.read(navigationsProvider.notifier).push(NodeSwitchLightPath());
                },
              ),
            ),
            const AppText.bodyLarge(
              'Light',
            ),
          ],
        ),
      ],
    );
  }

  Widget _getConnectionImage(NodeDetailState state) {
    return AppIcon.big(
      icon: state.isWiredConnection
          ? AppTheme.of(context).icons.characters.ethernetDefault
          : getWifiSignalIconData(
              context,
              state.signalStrength,
            ),
    );
  }

  Widget _content(NodeDetailState state) {
    return Expanded(
      child: LayoutBuilder(
        builder: (context, viewportConstraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: viewportConstraints.maxHeight,
              ),
              child: IntrinsicHeight(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppPadding(
                      padding: const AppEdgeInsets.symmetric(
                        horizontal: AppGapSize.semiBig,
                      ),
                      child: Column(
                        children: [
                          _detailSection(state),
                          _lanSection(state),
                          if (state.isMaster) _wanSection(state),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _detailSection(NodeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.big(),
        AppText.titleLarge(
          getAppLocalizations(context).details_all_capital,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_serial_number,
          description: state.serialNumber,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_model_number,
          description: state.modelNumber,
        ),
        const AppGap.semiSmall(),
        Visibility(
          visible: ref.watch(deviceManagerProvider).isFirmwareUpToDate,
          replacement: AppSimplePanel(
            title:
                getAppLocalizations(context).node_detail_label_firmware_version,
            description: state.firmwareVersion,
          ),
          child: AppPanelWithInfo(
            title:
                getAppLocalizations(context).node_detail_label_firmware_version,
            description: state.firmwareVersion,
            infoText: getAppLocalizations(context).up_to_date,
          ),
        ),
      ],
    );
  }

  Widget _lanSection(NodeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.semiSmall(),
        AppText.titleLarge(
          getAppLocalizations(context).node_detail_label_lan,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_ip_address,
          description: state.lanIpAddress,
        ),
      ],
    );
  }

  Widget _wanSection(NodeDetailState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.semiSmall(),
        AppText.titleLarge(
          getAppLocalizations(context).node_detail_label_wan,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_ip_address,
          description: state.wanIpAddress,
        ),
      ],
    );
  }
}
