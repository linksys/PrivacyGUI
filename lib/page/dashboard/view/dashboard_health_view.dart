import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';

class DashboardHealthView extends ConsumerStatefulWidget {
  const DashboardHealthView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardHealthView> createState() =>
      _DashboardHealthViewState();
}

class _DashboardHealthViewState extends ConsumerState<DashboardHealthView> {
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
