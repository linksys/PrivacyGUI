import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/nodes/providers/node_detail_id_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

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
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).name,
      actions: [
        AppTextButton(
          loc(context).save,
          onTap: () {
            final newLocation = _controller.text;
            if (newLocation.isNotEmpty) {
              final targetId = ref.read(nodeDetailIdProvider);

              ref.read(deviceManagerProvider.notifier).updateDeviceNameAndIcon(
                    targetId: targetId,
                    newName: newLocation,
                    isLocation: true,
                  );
            }
          },
        ),
      ],
      child: (context, constraints) => Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            headerText: loc(context).name,
            controller: _controller,
          )
        ],
      ),
    );
  }
}
