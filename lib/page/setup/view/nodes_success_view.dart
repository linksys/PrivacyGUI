import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/setup/event.dart';
import 'package:linksys_moab/bloc/setup/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/text/description_text.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/_route.dart';


import '../../../bloc/setup/bloc.dart';
import '../../components/base_components/button/primary_button.dart';
import '../../components/base_components/button/simple_text_button.dart';
import 'package:linksys_moab/route/model/_model.dart';

class NodesSuccessView extends StatefulWidget {
  const NodesSuccessView({
    Key? key,
  }) : super(key: key);

  @override
  State<NodesSuccessView> createState() => _NodesSuccessViewState();
}

class _NodesSuccessViewState extends State<NodesSuccessView> {
  @override
  void initState() {
      super.initState();
      context.read<SetupBloc>().add(const ResumePointChanged(status: SetupResumePoint.addChildNode));
  }

  @override
  Widget build(BuildContext context) {
    double width = 200;
    return BasePageView(
      scrollable: true,
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).good_work,
          description: getAppLocalizations(context).nodes_success_multi_description,
        ),
        content: Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 57),
              Center(
                  child: GestureDetector(
                      onTap: () {
                          NavigationCubit.of(context).push(SetupParentLocationPath());
                      },
                      child: Image.asset(
                        'assets/images/nodes_topology.png',
                        width: width,
                        height: width,
                      ))),
              Padding(
                padding: const EdgeInsets.fromLTRB(0, 48, 0, 48), // TODO
                child: Center(
                  child: SimpleTextButton(
                      text: getAppLocalizations(context).add_a_node,
                      onPressed: (){
                        int index = NavigationCubit.of(context).state.configs.indexWhere((element) => element is SetupNthChildPlacePath);
                        if (index >= 0) {
                          NavigationCubit.of(context).popTo(
                              SetupNthChildPlacePath());
                        } else {
                          NavigationCubit.of(context).push(
                              SetupNthChildPlacePath());
                        }
                      }),
                ),
              ),
            ],
          ),
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: getAppLocalizations(context)
                  .nodes_success_multi_add_wifi_name_button_text,
              onPress: () => NavigationCubit.of(context).push(SetupCustomizeSSIDPath()),
            ),
          ],
        ),
        crossAxisAlignment: CrossAxisAlignment.start,
      ),
    );
  }
}
