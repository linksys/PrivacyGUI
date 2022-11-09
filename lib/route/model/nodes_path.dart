import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_connected_devices_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_detail_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_name_edit_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_offline_check_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_restart_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/node_switch_light_view.dart';
import 'package:linksys_moab/page/dashboard/view/nodes/signal_strength_view.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_view.dart';
import '_model.dart';
import 'package:linksys_moab/route/_route.dart';


class NodesPath extends DashboardPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case TopologyPath:
        return TopologyView(
          args: args,
          next: next,
        );
      case NodeDetailPath:
        return NodeDetailView(
          args: args,
          next: next,
        );
      case NodeNameEditPath:
        return NodeNameEditView(
          args: args,
          next: next,
        );
      case NodeConnectedDevicesPath:
        return NodeConnectedDevicesView(
          args: args,
          next: next,
        );
      case SignalStrengthInfoPath:
        return SignalStrengthView(
          args: args,
          next: next,
        );
      case NodeOfflineCheckPath:
        return NodeOfflineCheckView(
          args: args,
          next: next,
        );
      case NodeSwitchLightPath:
        return const NodeSwitchLightView();
      case NodeRestartPath:
        return const NodeRestartView();
      default:
        return const Center();
    }
  }
}


class TopologyPath extends NodesPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class NodeNameEditPath extends NodesPath {}

class NodeConnectedDevicesPath extends NodesPath {}

class SignalStrengthInfoPath extends NodesPath {}

class NodeOfflineCheckPath extends NodesPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}

class NodeDetailPath extends NodesPath {
  @override
  PageConfig get pageConfig => super.pageConfig..isHideBottomNavBar = false;
}

class NodeSwitchLightPath extends NodesPath {}

class NodeRestartPath extends NodesPath {}