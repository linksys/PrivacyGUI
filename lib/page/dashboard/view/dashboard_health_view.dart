
import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';


class DashboardHealthView extends StatefulWidget {
  const DashboardHealthView({Key? key}) : super(key: key);

  @override
  State<DashboardHealthView> createState() => _DashboardHealthViewState();
}

class _DashboardHealthViewState extends State<DashboardHealthView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      scrollable: true,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }
}
