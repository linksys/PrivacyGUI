import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_view.dart';

class NodeOfflineCheckView extends ArgumentsStatefulView {
  const NodeOfflineCheckView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _NodeOfflineCheckViewState();
}

class _NodeOfflineCheckViewState extends State<NodeOfflineCheckView> {
  late final TopologyNode _node;

  @override
  void initState() {
    super.initState();
    _node = widget.args['node'] as TopologyNode;
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).node_offline_check_title,
        ),
        content: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.start,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Image.asset(
                  'assets/images/img_topology_node.png',
                  width: 74,
                  height: 74,
                ),
                box16(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _node.friendlyName,
                      style: TextStyle(
                          fontSize: 15.0, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      getAppLocalizations(context).offline,
                      style: Theme.of(context).textTheme.headline4,
                    )
                  ],
                )
              ],
            ),
            box36(),
            Text(getAppLocalizations(context).node_offline_power_is_on,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
            box8(),
            Text(
                getAppLocalizations(context)
                    .node_offline_power_is_on_description,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
            box16(),
            Text(getAppLocalizations(context).node_offline_within_range,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
            box8(),
            Text(
                getAppLocalizations(context)
                    .node_offline_within_range_description,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
            box16(),
            Text(getAppLocalizations(context).node_offline_still_offline,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
            box8(),
            Text(
                getAppLocalizations(context)
                    .node_offline_still_offline_description,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w400)),
          ],
        ),
      ),
    );
  }
}
