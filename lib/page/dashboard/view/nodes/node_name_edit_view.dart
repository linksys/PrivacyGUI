import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/topology/topology_view.dart';
import 'package:linksys_moab/route/_route.dart';

class NodeNameEditView extends ArgumentsStatefulView {
  const NodeNameEditView({Key? key, super.args, super.next}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _NodeNameEditViewState();
}

class _NodeNameEditViewState extends State<NodeNameEditView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.args['location'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return BasePageView.onDashboardSecondary(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(getAppLocalizations(context).node_detail_label_node_name,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () {
            NavigationCubit.of(context).pop();
          }),
          actions: [
            TextButton(
                onPressed: () {
                  final newLocation = _controller.text;
                  if (newLocation.isNotEmpty) {
                    context.read<NodeCubit>().updateNodeLocation(newLocation);
                  }
                },
                child: Text(getAppLocalizations(context).save,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: MoabColor.textButtonBlue))),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InputField(
              titleText:
                  getAppLocalizations(context).node_detail_label_node_name,
              controller: _controller,
              customPrimaryColor: Colors.black,
            )
          ],
        ),
      );
    });
  }
}
