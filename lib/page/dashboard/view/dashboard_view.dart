import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/landing/view/home_view.dart';
import 'package:linksys_moab/route/model/model.dart';
import 'package:linksys_moab/route/route.dart';

class DashboardView extends ArgumentsStatefulView {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {}

  @override
  Widget build(BuildContext context) {
    return _contentView();
  }

  Widget _contentView() {
    return BasePageView.noNavigationBar(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Dashboard',
        ),
        content: Column(
          children: [
            SizedBox(
              height: 200,
              child: Container(
                decoration:
                    const BoxDecoration(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Container(
                decoration:
                const BoxDecoration(color: Colors.white60),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(text: 'Log out', onPress: () { NavigationCubit.of(context).clearAndPush(HomePath());},)
          ],
        ),
      ),
    );
  }
}
