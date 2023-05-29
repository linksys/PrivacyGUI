import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class NodeSwitchLightView extends ConsumerWidget {
  const NodeSwitchLightView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return StyledAppPageView(
        title: 'Node light',
        child: Column(
          children: [
            AppPanelWithSwitch(
              value: state.isLightTurnedOn,
              title: 'Node light',
              onChangedEvent: (bool newValue) {
                context.read<NodeCubit>().updateNodeLightSwitch(newValue);
              },
            ),
          ],
        ),
      );
    });
  }
}
