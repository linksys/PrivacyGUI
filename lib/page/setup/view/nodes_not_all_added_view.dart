import 'package:flutter/widgets.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';

class NodesNotAllAddedView extends ArgumentsStatelessView {
  const NodesNotAllAddedView({Key? key, super.next, super.args})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).nodes_not_all_added_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            DescriptionText(
                text: getAppLocalizations(context).nodes_not_all_added_desc_1),
            const SizedBox(height: 16),
            DescriptionText(
                text: getAppLocalizations(context).nodes_not_all_added_desc_2),
          ],
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: getAppLocalizations(context).try_again_button,
              onPress: () {
                NavigationCubit.of(context).pop();
              },
            ),
            SimpleTextButton(
              text: getAppLocalizations(context).try_later_and_proceed,
              onPressed: () {
                NavigationCubit.of(context).popToOrPush(next ?? UnknownPath());
              },
            ),
          ],
        ),
      ),
    );
  }
}
