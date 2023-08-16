import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/core/utils/icon_rules.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/constants.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/avatars/device_avatar.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';
import 'package:linksys_widgets/widgets/page/layout/profile_header_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

class NodeDetailView extends ArgumentsConsumerStatefulView {
  const NodeDetailView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NodeDetailView> createState() => _NodeDetailViewState();
}

class _NodeDetailViewState extends ConsumerState<NodeDetailView> {
  var isLightEnabled = true; //TODO: Move it to state

  @override
  void initState() {
    super.initState();
    context.read<NodeCubit>().fetchNodeDetailData();
  }

  @override
  Widget build(BuildContext context) {
    final actions = [
      AppIconButton.noPadding(
        icon: getCharactersIcons(context).infoRound,
        onTap: () {
          context.pushNamed(RouteNamed.nodeLight);
        },
      )
    ];
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return state.isLoading
          ? const AppFullScreenSpinner()
          : LayoutBuilder(builder: (context, constraint) {
              return AppProfileHeaderLayout(
                expandedHeight: constraint.maxHeight / 2,
                collaspeTitle: state.location,
                onCollaspeBackTap: () {
                  context.pop();
                },
                actions: actions,
                header: Column(
                  children: [
                    LinksysAppBar(
                      backgroundColor:
                          AppTheme.of(context).colors.headerBackgroundEnd,
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
            });
    });
  }

  Widget _header(NodeState state) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            AppTheme.of(context).colors.headerBackgroundStart,
            AppTheme.of(context).colors.headerBackgroundEnd,
          ],
        ),
      ),
      child: Column(
        children: [
          _nodeAvatar(state),
          const AppGap.regular(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              AppText.textLinkLarge(
                state.location,
                color: AppTheme.of(context).colors.textBoxText,
              ),
              Positioned(
                top: -2.5,
                right: -(AppTheme.of(context).spacing.big),
                child: AppIconButton.noPadding(
                  icon: getCharactersIcons(context).editDefault,
                  onTap: () {
                    //TODO: Go to edit page
                  },
                ),
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

  Widget _nodeAvatar(NodeState state) {
    return AppDeviceAvatar.extraLarge(
      image: AppTheme.of(context).images.devices.getByName(
            routerIconTest(modelNumber: state.modelNumber),
          ),
    );
  }

  Widget _nodeStatus(NodeState state) {
    final textColor = AppTheme.of(context).colors.textBoxText;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        Column(
          children: [
            Container(
              height: AppTheme.of(context).spacing.extraBig,
              width: AppTheme.of(context).spacing.extraBig,
              alignment: Alignment.center,
              child: AppText.mainTitle(
                '${state.connectedDevices.length}',
                color: textColor,
              ),
            ),
            AppText.label(
              getAppLocalizations(context).devices,
              color: textColor,
            ),
          ],
        ),
        Column(
          children: [
            Container(
              height: AppTheme.of(context).spacing.extraBig,
              width: AppTheme.of(context).spacing.extraBig,
              alignment: Alignment.center,
              child: _getConnectionImage(state),
            ),
            AppText.label(
              state.isWiredConnection
                  ? "Wired"
                  : Utils.getWifiSignalLevel(state.signalStrength).displayTitle,
              color: textColor,
            ),
          ],
        ),
        Column(
          children: [
            Container(
              height: AppTheme.of(context).spacing.extraBig,
              width: AppTheme.of(context).spacing.extraBig,
              alignment: Alignment.center,
              child: AppSwitch.full(
                value: isLightEnabled,
                onChanged: (value) {
                  setState(() {
                    isLightEnabled = value;
                    //ref.read(navigationsProvider.notifier).push(NodeSwitchLightPath());
                  });
                },
              ),
            ),
            AppText.label(
              'Light',
              color: textColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _getConnectionImage(NodeState state) {
    return AppIcon.big(
      icon: state.isWiredConnection
          ? AppTheme.of(context).icons.characters.ethernetDefault
          : Utils.getWifiSignalIconData(
              context,
              state.signalStrength,
            ),
    );
  }

  Widget _content(NodeState state) {
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

  Widget _detailSection(NodeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.big(),
        AppText.tags(
          getAppLocalizations(context).details_all_capital,
          color: ConstantColors.secondaryCyberPurple,
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
          visible: state.isLatestFw,
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
            infoTextColor: AppTheme.of(context).colors.ctaPrimaryDisable,
          ),
        ),
      ],
    );
  }

  Widget _lanSection(NodeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.semiSmall(),
        AppText.tags(
          getAppLocalizations(context).node_detail_label_lan,
          color: ConstantColors.secondaryCyberPurple,
        ),
        const AppGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_ip_address,
          description: state.lanIpAddress,
        ),
      ],
    );
  }

  Widget _wanSection(NodeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppGap.semiSmall(),
        AppText.tags(
          getAppLocalizations(context).node_detail_label_wan,
          color: ConstantColors.secondaryCyberPurple,
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
