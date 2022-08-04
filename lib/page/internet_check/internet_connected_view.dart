import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';

import '../../route/model/setup_path.dart';
import '../../route/navigation_cubit.dart';

class InternetConnectedView extends StatefulWidget {
  InternetConnectedView({Key? key}) : super(key: key);

  @override
  State<InternetConnectedView> createState() => _InternetConnectedViewState();
}

class _InternetConnectedViewState extends State<InternetConnectedView> {
  // TODO: Replace this to svg
  final Widget image = Image.asset('assets/images/connected_check.png');


  @override
  void initState() {
    Future.delayed(Duration(seconds: 2), () {
      NavigationCubit.of(context).push(SetupAddingNodesPath());
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).internet_connected_title,
        ),
        content: Center(
          child: image,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}
