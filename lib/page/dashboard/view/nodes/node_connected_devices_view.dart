import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_view.dart';
import 'package:linksys_moab/route/_route.dart';


class NodeConnectedDevicesView extends ArgumentsStatefulView {
  const NodeConnectedDevicesView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _NodeConnectedDevicesViewState();
}

class _NodeConnectedDevicesViewState extends State<NodeConnectedDevicesView> {
  late final TopologyNode _node;

  @override
  void initState() {
    super.initState();
    _node = widget.args['node'] as TopologyNode;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.onDashboardSecondary(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(_node.friendlyName,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        leading: BackButton(onPressed: () {
          NavigationCubit.of(context).pop();
        }),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.refresh)),
        ],
      ),
      child: ListView.separated(
        itemCount: _node.connectedDevice,
        separatorBuilder: (_, i) => SizedBox(height: 24),
        itemBuilder: (context, i) {
          return ListTile(
            leading: Icon(Icons.circle, size: 60,),
            title: Text(
              'Device name',
              style: Theme.of(context).textTheme.headline4,
            ),
            trailing: Icon(Icons.arrow_forward_ios),
          );
        },
      ),
    );
  }
}
