import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/provider/devices/node_detail_provider.dart';
import 'package:linksys_widgets/theme/const/spacing.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class ChangeNodeNameView extends ArgumentsConsumerStatefulView {
  const ChangeNodeNameView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<ChangeNodeNameView> createState() =>
      __ChangeNodeNameViewState();
}

class __ChangeNodeNameViewState extends ConsumerState<ChangeNodeNameView> {
  final TextEditingController nameController = TextEditingController();
  bool isChanged = false;

  @override
  void initState() {
    super.initState();
    final nodeDetail = ref.read(nodeDetailProvider);
    nameController.text = nodeDetail.location;
  }

  @override
  void dispose() {
    super.dispose();

    nameController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: getAppLocalizations(context).node_detail_label_node_name,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: Spacing.regular),
          child: AppTextButton.noPadding(
            getAppLocalizations(context).save,
            onTap: isChanged ? _checkInputData : null,
          ),
        )
      ],
      child: AppBasicLayout(
        content: Column(children: [
          AppTextField(
            headerText:
                getAppLocalizations(context).node_detail_label_node_name,
            controller: nameController,
            onChanged: _onNameChanged,
          )
        ]),
      ),
    );
  }

  void _checkInputData() {
    if (nameController.text.isNotEmpty) {
      ref
          .read(deviceManagerProvider.notifier)
          .updateDeviceName(newName: nameController.text, isLocation: true)
          .then((value) {
        context.pop();
      });
    }
  }

  void _onNameChanged(String text) {
    setState(() {
      isChanged = true;
      // nameController.text = text;
    });
  }
}
