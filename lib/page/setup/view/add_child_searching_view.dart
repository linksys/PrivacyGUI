import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_moab/bloc/add_nodes/cubit.dart';
import 'package:linksys_moab/bloc/add_nodes/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/indeterminate_progressbar.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';

import '../../../design/colors.dart';
import 'package:linksys_moab/route/model/_model.dart';

class AddChildSearchingView extends ArgumentsStatelessView {
  const AddChildSearchingView({
    super.key,
    super.next,
    super.args,
  });

  @override
  Widget build(BuildContext context) {
    return AddChildSearchingContentView(
      next: super.next,
      args: super.args,
    );
  }
}

class AddChildSearchingContentView extends ArgumentsStatefulView {
  const AddChildSearchingContentView({Key? key, super.next, super.args})
      : super(key: key);

  @override
  State<AddChildSearchingContentView> createState() =>
      _AddChildSearchingContentViewState();
}

class _AddChildSearchingContentViewState
    extends State<AddChildSearchingContentView> {
  bool _hasFound = false;
  late final AddNodesCubit _cubit;

  @override
  void initState() {
    _cubit = context.read<AddNodesCubit>();
    super.initState();
    _cubit.findingNodes();
    // _fakeInternetChecking();
  }

  @override
  void dispose() {
    _cubit.finish();
    super.dispose();
  }
  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  _fakeInternetChecking() async {
    await Future.delayed(const Duration(seconds: 5));
    setState(() {
      _hasFound = true;
    });
    await Future.delayed(const Duration(seconds: 3));
    NavigationCubit.of(context).popToAndPush(
      SetupNodeListPath(),
      LoadingTransitionPath()
        ..next = (SetupNodeListPath()
          ..next = widget.next
          ..args = (Map.from(widget.args)..addAll({'init': false}))),
      include: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AddNodesCubit, AddNodesState>(
        listener: (context, state) {
      if (state.status == AddNodesStatus.noNodesFound) {
        NavigationCubit.of(context)
            .push(NodesDoesntFindPath()..next = widget.next);
      } else if (state.status == AddNodesStatus.addingNodes) {
        _cubit.addingNodes();
      } else if (state.status == AddNodesStatus.someDone) {
        NavigationCubit.of(context)
            .push(NodesNotAllAddedPath()..next = widget.next);
      } else if (state.status == AddNodesStatus.allDone) {
        NavigationCubit.of(context).popToAndPush(
          SetupNodeListPath(),
          LoadingTransitionPath()
            ..next = (SetupNodeListPath()
              ..next = widget.next
              ..args = (Map.from(widget.args)..addAll({'init': false}))),
          include: true,
        );
      }
    }, builder: (context, state) {
      return BasePageView.noNavigationBar(
        child: BasicLayout(
          header: BasicHeader(
            title: _hasFound
                ? getAppLocalizations(context).found_it
                : getAppLocalizations(context).looking_for_your_node,
          ),
          content: Center(
            child: Column(
              children: [
                _hasFound
                    ? const Icon(
                        Icons.check,
                        color: MoabColor.listItemCheck,
                        size: 200,
                      )
                    : image,
                const SizedBox(
                  height: 130,
                ),
                if (!_hasFound) const IndeterminateProgressBar(),
              ],
              mainAxisAlignment: MainAxisAlignment.center,
            ),
          ),
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    });
  }
}
