import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/route.dart';

import '../../components/base_components/button/primary_button.dart';
import '../../components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/route/model/model.dart';

class NodesSuccessView extends StatelessWidget {
  const NodesSuccessView({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    double width = 220;
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: AppLocalizations.of(context)!.good_work,
        ),
        content: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                  child: GestureDetector(
                      onTap: () {
                          NavigationCubit.of(context).push(SetupParentLocationPath());
                      },
                      child: Image.asset(
                        'assets/images/nodes_topology.png',
                        width: width,
                      ))),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 48, 0, 48), // TODO
                child: Center(
                  child: SimpleTextButton(
                      text: AppLocalizations.of(context)!.add_a_node,
                      onPressed: (){
                          NavigationCubit.of(context).push(SetupNthChildPlacePath());
                      }),
                ),
              ),
              DescriptionText(
                  text: AppLocalizations.of(context)!
                      .nodes_success_multi_description),
            ],
          ),
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: AppLocalizations.of(context)!
                  .nodes_success_multi_add_wifi_name_button_text,
              onPress: () => NavigationCubit.of(context).push(SetupCustomizeSSIDPath()),
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
