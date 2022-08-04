import 'package:flutter/widgets.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';

class NodesDoesntFindView extends StatelessWidget {
  const NodesDoesntFindView({Key? key}) : super(key: key);


  @override
  Widget build(BuildContext context) {
      return BasePageView(
        child: BasicLayout(
          alignment: CrossAxisAlignment.start,
          header: BasicHeader(
            title: getAppLocalizations(context).nodes_doesnt_find_view_title,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              DescriptionText(text: getAppLocalizations(context).nodes_doesnt_find_view_description_1),
              const SizedBox(height: 16),
              DescriptionText(text: getAppLocalizations(context).nodes_doesnt_find_view_description_2),
            ],
          ),
          footer: PrimaryButton(
            text: getAppLocalizations(context).scan_again_button,
            onPress: () {},
          ),
        ),
      );
  }
}