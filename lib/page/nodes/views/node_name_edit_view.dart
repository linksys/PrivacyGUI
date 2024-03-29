import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/devices/_devices.dart';
import 'package:linksys_app/page/nodes/providers/node_detail_id_provider.dart';
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
  void dispose() {
    super.dispose();

    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).name,
      actions: [
        AppTextButton(
          getAppLocalizations(context).save,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            headerText: getAppLocalizations(context).name,
            controller: _controller,
          )
        ],
      ),
    );
  }
}
