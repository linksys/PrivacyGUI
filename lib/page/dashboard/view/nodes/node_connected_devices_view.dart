import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';

class NodeConnectedDevicesView extends ArgumentsStatefulView {
  const NodeConnectedDevicesView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  State<StatefulWidget> createState() => _NodeConnectedDevicesViewState();
}

class _NodeConnectedDevicesViewState extends State<NodeConnectedDevicesView> {

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return BasePageView.onDashboardSecondary(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(state.location,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading: BackButton(onPressed: () => NavigationCubit.of(context).pop()),
          actions: [
            IconButton(
                icon: Image.asset('assets/images/icon_refresh.png'),
                onPressed: () =>
                    context.read<NodeCubit>().fetchNodeDetailData()
            ),
          ],
        ),
        child: ListView.separated(
          itemCount: state.connectedDevices.length,
          separatorBuilder: (_, i) => const SizedBox(height: 24),
          itemBuilder: (context, i) {
            final device = state.connectedDevices[i];
            return ListTile(
              leading: const Icon(Icons.circle, size: 60,),
              title: Text(
                context.read<NodeCubit>().getDeviceName(device),
                style: Theme.of(context).textTheme.headline4,
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
            );
          },
        ),
      );
    });
  }
}
