import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class NodeConnectedDevicesView extends ArgumentsConsumerStatefulView {
  const NodeConnectedDevicesView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<NodeConnectedDevicesView> createState() =>
      _NodeConnectedDevicesViewState();
}

class _NodeConnectedDevicesViewState
    extends ConsumerState<NodeConnectedDevicesView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return StyledAppPageView(
        title: state.location,
        actions: [
          AppIconButton(
            icon: getCharactersIcons(context).refreshDefault,
            onTap: () => context.read<NodeCubit>().fetchNodeDetailData(),
          ),
        ],
        child: ListView.separated(
          itemCount: state.connectedDevices.length,
          separatorBuilder: (_, i) => const SizedBox(height: 24),
          itemBuilder: (context, i) {
            final device = state.connectedDevices[i];
            return AppPanelWithValueCheck(
              title: Utils.getDeviceName_(device),
              valueText: ' ',
              // icon: Icons.circle,
            );
          },
        ),
      );
    });
  }
}
