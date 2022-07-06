import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';

import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/route/model/model.dart';

class AddingNodesView extends StatefulWidget {
  const AddingNodesView({Key? key}) : super(key: key);

  @override
  State<AddingNodesView> createState() => _AddingNodesViewState();
}

class _AddingNodesViewState extends State<AddingNodesView> {

  @override
  void initState() {
    Future.delayed(const Duration(seconds: 2), (){
      NavigationCubit.of(context).push(SetupNodesDonePath());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).adding_nodes,
          description: getAppLocalizations(context).adding_nodes_description,
        ),
        content: Flex(direction: Axis.vertical),
        footer: Text(getAppLocalizations(context).adding_nodes_more_info),
      ),
    );
  }
}