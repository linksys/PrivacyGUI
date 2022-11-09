import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/route/_route.dart';

class NodeSwitchLightView extends StatelessWidget {
  const NodeSwitchLightView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return BasePageView(
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Node light',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          leading:
              BackButton(onPressed: () => NavigationCubit.of(context).pop()),
        ),
        child: Column(
          children: [
            SettingTile(
                title: Text(
                  'Node light',
                  style: Theme.of(context).textTheme.bodyText1,
                ),
                value: Switch.adaptive(
                    value: state.isLightTurnedOn,
                    onChanged: (bool newValue) {
                      context.read<NodeCubit>().updateNodeLightSwitch(newValue);
                    })),
          ],
        ),
      );
    });
  }
}
