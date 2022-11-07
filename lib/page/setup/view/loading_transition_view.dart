import 'package:flutter/material.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';

import '../../components/views/arguments_view.dart';

// A transition page for add nodes
class LoadingTransitionView extends ArgumentsStatefulView {
  const LoadingTransitionView({
    Key? key,
    super.next,
    super.args,
  }) : super(key: key);

  @override
  State<LoadingTransitionView> createState() => _AddChildFinishedViewState();
}

class _AddChildFinishedViewState extends State<LoadingTransitionView> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2)).then((value) =>
        NavigationCubit.of(context).push(widget.next ?? UnknownPath()));
  }

  @override
  Widget build(BuildContext context) {
    return const BasePageView(
      child: FullScreenSpinner(),
    );
  }
}
