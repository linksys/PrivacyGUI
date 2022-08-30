import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/space/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_view.dart';
import 'package:linksys_moab/route/model/dashboard_path.dart';
import 'package:linksys_moab/route/route.dart';

class NodeDetailView extends ArgumentsStatefulView {
  const NodeDetailView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NodeDetailViewState();
}

class _NodeDetailViewState extends State<NodeDetailView> {
  late final TopologyNode _node;

  @override
  void initState() {
    super.initState();
    _node = widget.args['node'] as TopologyNode;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      scrollable: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_node.friendlyName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerTile(),
          _nodeNameTile(),
          _connectedDeviceTile(),
          _connectingTile(),
          _signalStrengthTile(),
          _serialNumberTile(),
          _modelNumberTile(),
          _firmwareTile(),
          if (_node.role == DeviceRole.router) _lanTile(),
          _wanTile(),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32.0),
            child: PrimaryButton(
              text: getAppLocalizations(context).node_detail_blink_node_light_btn,
              onPress: () {},
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerTile() {
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
            _signalLabel(),
          ],
        ),
      ),
    );
  }

  Widget _signalLabel() {
    return Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Image.asset(
            'assets/images/icon_wifi_signal_excellent.png',
            width: 22,
            height: 22,
          ),
          box8(),
          Text(
            _node.isOnline ? getAppLocalizations(context).online : getAppLocalizations(context).offline,
            style: Theme.of(context)
                .textTheme
                .headline4
                ?.copyWith(color: _node.isOnline ? Colors.blue : Colors.grey),
          )
        ]);
  }

  Widget _nodeNameTile() {
    return SettingTile(
      title: Text(
        getAppLocalizations(context).node_detail_label_node_name,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        _node.friendlyName,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: () {
        NavigationCubit.of(context)
            .push(NodeNameEditPath()..args = widget.args);
      },
      space: 32,
    );
  }

  Widget _connectedDeviceTile() {
    return SettingTile(
      title: Text(
        getAppLocalizations(context).node_detail_label_connected_devices,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        '${_node.connectedDevice}',
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: () {
        NavigationCubit.of(context)
            .push(NodeConnectedDevicesPath()..args = widget.args);
      },
      space: 32,
    );
  }

  Widget _connectingTile() {
    return SettingTile(
      title: Text(
        getAppLocalizations(context).node_detail_label_connected_to,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        _node.role == DeviceRole.router ? getAppLocalizations(context).internet_source : _node.connectTo,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: null,
      space: 32,
    );
  }

  Widget _signalStrengthTile() {
    return SettingTileTwoLine(
      title: Text(
        getAppLocalizations(context).node_detail_label_signal_strength,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Row(
        children: [
          Image.asset(
            'assets/images/icon_wifi_signal_excellent.png',
            width: 22,
            height: 22,
          ),
          Expanded(
            child: Text(
              '-56dBm Excellent',
              style: Theme.of(context).textTheme.bodyText1,
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
      space: 32,
    );
  }

  Widget _serialNumberTile() {
    return SettingTileTwoLine(
      title: Text(
        getAppLocalizations(context).node_detail_label_serial_number,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        _node.serialNumber,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: null,
      space: 32,
    );
  }

  Widget _modelNumberTile() {
    return SettingTileTwoLine(
      title: Text(
        getAppLocalizations(context).node_detail_label_model_number,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Text(
        _node.modelNumber,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      onPress: null,
      space: 32,
    );
  }

  Widget _firmwareTile() {
    return SettingTileTwoLine(
      title: Text(
        getAppLocalizations(context).node_detail_label_firmware_version,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      value: Row(
        children: [
          Expanded(
            child: Text(
              _node.firmwareVersion,
              style: Theme.of(context).textTheme.bodyText1,
            ),
          ),
          Text(
          getAppLocalizations(context).up_to_date,
            style: Theme.of(context).textTheme.bodyText1,
          ),
        ],
      ),
      onPress: null,
      space: 32,
    );
  }

  Widget _lanTile() {
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
            _node.lanIp,
            style: Theme.of(context).textTheme.bodyText1,
          ),
          onPress: null),
      space: 32,
    );
  }

  Widget _wanTile() {
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
            _node.wanIp,
            style: Theme.of(context).textTheme.bodyText1,
          ),
          onPress: null),
      space: 32,
    );
  }
}
