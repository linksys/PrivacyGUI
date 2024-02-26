import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';

class DashboardSupportView extends ConsumerStatefulWidget {
  const DashboardSupportView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardSupportView> createState() =>
      _DashboardSupportViewState();
}

class _DashboardSupportViewState extends ConsumerState<DashboardSupportView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      backState: StyledBackState.none,
      title: 'Support',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [],
      ),
    );
  }
}
