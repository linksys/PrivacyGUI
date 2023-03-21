import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/base/padding.dart';

class NodeDetailView extends ArgumentsStatefulView {
  const NodeDetailView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NodeDetailViewState();
}

class _NodeDetailViewState extends State<NodeDetailView> {
  var isLightEnabled = true; //TODO: Move it to state

  @override
  void initState() {
    super.initState();
    context.read<NodeCubit>().fetchNodeDetailData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return Scaffold(
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Color.fromRGBO(180, 210, 245, 1),
          systemOverlayStyle: const SystemUiOverlayStyle(
            //statusBarColor: Colors.pink, //TODO: Test for Android devices
            statusBarIconBrightness: Brightness.dark,
            statusBarBrightness: Brightness.dark,
          ),
        ),
        backgroundColor: AppTheme.of(context).colors.background,
        body: SafeArea(
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
                        _header(state),
                        _content(state),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
    });
  }

  Widget _header(NodeState state) {
    const textColor = ConstantColors.raisinBlock;
    
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.fromRGBO(231, 239, 247, 1),
            Color.fromRGBO(180, 210, 245, 1),
          ],
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: AlignmentDirectional.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Color.fromRGBO(8, 112, 234, 0.26),
                    width: 1,
                  ),
                  borderRadius: BorderRadius.circular(100),
                  color: Color.fromRGBO(8, 112, 234, 0.07),
                ),
                width: 120,
                height: 120,
              ),
              SvgPicture(
                AppTheme.of(context).images.imgRouterBlack,
                height: 120 * 0.75,
                width: 120 * 0.75,
              ),
            ],
          ),
          const LinksysGap.regular(),
          Stack(
            clipBehavior: Clip.none,
            children: [
              LinksysText.textLinkLarge(
                state.location,
                color: textColor,
              ),
              Positioned(
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
          const LinksysGap.extraBig(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Container(
                    height: AppTheme.of(context).spacing.extraBig,
                    width: AppTheme.of(context).spacing.extraBig,
                    alignment: Alignment.center,
                    child: LinksysText.mainTitle(
                      '${state.connectedDevices.length}',
                      color: textColor,
                    ),
                  ),
                  LinksysText.label(
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
                  LinksysText.label(
                    state.isWiredConnection
                        ? "Wired"
                        : Utils.getWifiSignalLevel(state.signalStrength)
                            .displayTitle,
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
                          //NavigationCubit.of(context).push(NodeSwitchLightPath());
                        });
                      },
                    ),
                  ),
                  const LinksysText.label(
                    'Light',
                    color: textColor,
                  ),
                ],
              ),
            ],
          ),
          const LinksysGap.big(),
        ],
      ),
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
    return AppPadding(
      padding:
          const LinksysEdgeInsets.symmetric(horizontal: AppGapSize.semiBig),
      child: Column(
        children: [
          _detailSection(state),
          _lanSection(state),
          if (state.isMaster) _wanSection(state),
        ],
      ),
    );
  }

  Widget _detailSection(NodeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const LinksysGap.big(),
        LinksysText.tags(
          getAppLocalizations(context).details_all_capital,
          color: ConstantColors.secondaryCyberPurple,
        ),
        const LinksysGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_serial_number,
          description: state.serialNumber,
        ),
        const LinksysGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_model_number,
          description: state.modelNumber,
        ),
        const LinksysGap.semiSmall(),
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
        const LinksysGap.semiSmall(),
        LinksysText.tags(
          getAppLocalizations(context).node_detail_label_lan,
          color: ConstantColors.secondaryCyberPurple,
        ),
        const LinksysGap.semiSmall(),
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
        const LinksysGap.semiSmall(),
        LinksysText.tags(
          getAppLocalizations(context).node_detail_label_wan,
          color: ConstantColors.secondaryCyberPurple,
        ),
        const LinksysGap.semiSmall(),
        AppSimplePanel(
          title: getAppLocalizations(context).node_detail_label_ip_address,
          description: state.wanIpAddress,
        ),
      ],
    );
  }

  /*

  Widget _nodeNameTile(NodeState state) {
    return SettingTile(
      title: Text(
        getAppLocalizations(context).node_detail_label_node_name,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        state.location,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: () {
        NavigationCubit.of(context)
            .push(NodeNameEditPath()..args = {'location': state.location});
      },
    );
  }

  Widget _connectedDeviceTile(NodeState state) {
    return SettingTile(
      title: Text(
        getAppLocalizations(context).node_detail_label_connected_devices,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        '${state.connectedDevices.length}',
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: () {
        NavigationCubit.of(context)
            .push(NodeConnectedDevicesPath()..args = widget.args);
      },
    );
  }

  Widget _upstreamNodeTile(NodeState state) {
    return SettingTile(
      title: Text(
        getAppLocalizations(context).node_detail_label_connected_to,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        state.upstreamNode == 'INTERNET'
            ? getAppLocalizations(context).internet_source
            : state.upstreamNode,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: null,
    );
  }

  Widget _signalStrengthTile(NodeState state) {
    return SettingTile(
      axis: SettingTileAxis.vertical,
      title: Text(
        getAppLocalizations(context).node_detail_label_signal_strength,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Row(
        children: [
          _getConnectionImage(state),
          Offstage(
            offstage: state.isWiredConnection,
            child: Expanded(
              child: Text(
                '${state.signalStrength} dBm ${Utils.getWifiSignalLevel(state.signalStrength).displayTitle}',
                style: Theme.of(context).textTheme.bodyText1,
              ),
            ),
          ),
          SimpleTextButton(
            text: getAppLocalizations(context).details,
            onPressed: () {
              NavigationCubit.of(context).push(SignalStrengthInfoPath());
            },
          ),
        ],
      ),
      onPress: null,
    );
  }
  */
}
