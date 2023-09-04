import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
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
    // TODO: Use device manager to get the location
    //_controller.text = widget.args['location'] as String;
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).node_detail_label_node_name,
      actions: [
        AppTertiaryButton(
          getAppLocalizations(context).save,
          onTap: () {
            final newLocation = _controller.text;
            if (newLocation.isNotEmpty) {
              ref
                  .read(deviceManagerProvider.notifier)
                  .updateDeviceName(newName: newLocation, isLocation: true);
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
  }
}
