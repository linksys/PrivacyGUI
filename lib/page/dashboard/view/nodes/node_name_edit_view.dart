import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/node/cubit.dart';
import 'package:linksys_moab/bloc/node/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class NodeNameEditView extends ArgumentsConsumerStatefulView {
  const NodeNameEditView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<NodeNameEditView> createState() => _NodeNameEditViewState();
}

class _NodeNameEditViewState extends ConsumerState<NodeNameEditView> {
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.text = widget.args['location'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NodeCubit, NodeState>(builder: (context, state) {
      return StyledAppPageView(
        title: getAppLocalizations(context).node_detail_label_node_name,
        actions: [
          AppTertiaryButton(
            getAppLocalizations(context).save,
            onTap: () {
              final newLocation = _controller.text;
              if (newLocation.isNotEmpty) {
                context.read<NodeCubit>().updateNodeLocation(newLocation);
              }
            },
          ),
        ],
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppTextField(
              headerText:
                  getAppLocalizations(context).node_detail_label_node_name,
              controller: _controller,
            )
          ],
        ),
      );
    });
  }
}
