import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/nodes_path.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/utils.dart';

class NodeDetailView extends ArgumentsStatefulView {
  const NodeDetailView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NodeDetailViewState();
}

class _NodeDetailViewState extends State<NodeDetailView> {

  @override
  void initState() {
    super.initState();
    context.read<NodeCubit>().fetchNodeDetailData();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return BasePageView.onDashboardSecondary(
        scrollable: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(state.location,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading:
              BackButton(onPressed: () => NavigationCubit.of(context).pop()),
          actions: [
            IconButton(
                icon: Image.asset('assets/images/icon_refresh.png'),
                onPressed: () =>
                    context.read<NodeCubit>().fetchNodeDetailData())
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerTile(state),
            _nodeNameTile(state),
            _connectedDeviceTile(state),
            _upstreamNodeTile(state),
            if (!state.isMaster) _signalStrengthTile(state),
            _switchLightTile(state),
            _serialNumberTile(state),
            _modelNumberTile(state),
            _firmwareInfoTile(state),
            _lanTile(state),
            if (state.isMaster) _wanTile(state),
          ],
        ),
      );
    });
  }

  Widget _headerTile(NodeState state) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Column(
          children: [
            Image.asset(
              'assets/images/img_topology_node.png',
              width: 74,
              height: 74,
            ),
            const SizedBox(
              height: 8,
            ),
            Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _getConnectionImage(state),
                  box8(),
                  Text(
                    state.isOnline
                        ? getAppLocalizations(context).online
                        : getAppLocalizations(context).offline,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                        color: state.isOnline ? Colors.blue : Colors.grey),
                  )
                ]),
          ],
        ),
      ),
    );
  }

  Widget _getConnectionImage(NodeState state) {
    return Image.asset(
      state.isWiredConnection ? 'assets/images/icon_signal_wired.png' : Utils.getWifiSignalImage(state.signalStrength),
      width: 22,
      height: 22,
    );
  }

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
    return SettingTileTwoLine(
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

  Widget _switchLightTile(NodeState state) {
    return SettingTile(
      title: Text(
        'Light',
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        state.isLightTurnedOn ? 'On' : 'Off',
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: () {
        NavigationCubit.of(context).push(NodeSwitchLightPath());
      },
    );
  }

  Widget _serialNumberTile(NodeState state) {
    return SettingTileTwoLine(
      title: Text(
        getAppLocalizations(context).node_detail_label_serial_number,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        state.serialNumber,
        style: Theme.of(context).textTheme.bodyText1,
      ),
    );
  }

  Widget _modelNumberTile(NodeState state) {
    return SettingTileTwoLine(
      title: Text(
        getAppLocalizations(context).node_detail_label_model_number,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        state.modelNumber,
        style: Theme.of(context).textTheme.bodyText1,
      ),
    );
  }

  Widget _firmwareInfoTile(NodeState state) {
    return SettingTileTwoLine(
      title: Text(
        getAppLocalizations(context).node_detail_label_firmware_version,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Row(
        children: [
          Expanded(
            child: Text(
              state.firmwareVersion,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          Offstage(
            offstage: !state.isLatestFw,
            child: Text(
              getAppLocalizations(context).up_to_date,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _lanTile(NodeState state) {
    return SectionTile(
      header: Text(
        getAppLocalizations(context).node_detail_label_lan,
        style: Theme.of(context).textTheme.headline3,
      ),
      child: SettingTileTwoLine(
        title: Text(
          getAppLocalizations(context).node_detail_label_ip_address,
          style: Theme.of(context).textTheme.bodyText1,
        ),
        value: Text(
          state.lanIpAddress,
          style: Theme.of(context).textTheme.bodyText1,
        ),
      ),
    );
  }

  Widget _wanTile(NodeState state) {
    return SectionTile(
      header: Text(
        getAppLocalizations(context).node_detail_label_wan,
        style: Theme.of(context).textTheme.headline3,
      ),
      child: SettingTileTwoLine(
          title: Text(
            getAppLocalizations(context).node_detail_label_ip_address,
            style: Theme.of(context).textTheme.bodyText1,
          ),
          value: Text(
            state.wanIpAddress,
            style: Theme.of(context).textTheme.bodyText1,
          ),
          onPress: null),
    );
  }
}
