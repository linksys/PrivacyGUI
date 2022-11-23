import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_forwarding/bloc/port_range_forwarding_list_cubit.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/bloc/single_port_forwarding_list_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';

class PortRangeForwardingListView extends ArgumentsStatelessView {
  const PortRangeForwardingListView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PortRangeForwardingListCubit>(
      create: (context) => PortRangeForwardingListCubit(
          repository: context.read<RouterRepository>()),
      child: PortRangeForwardingListContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class PortRangeForwardingListContentView extends ArgumentsStatefulView {
  const PortRangeForwardingListContentView(
      {super.key, super.next, super.args});

  @override
  State<PortRangeForwardingListContentView> createState() =>
      _PortRangeForwardingContentViewState();
}

class _PortRangeForwardingContentViewState
    extends State<PortRangeForwardingListContentView> {
  late final PortRangeForwardingListCubit _cubit;

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<PortRangeForwardingListCubit>();
    _cubit.fetch();
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
      _isBehindRouter =
          state.connectivityInfo.routerType == RouterType.managedMoab;
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.managedMoab;

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PortRangeForwardingListCubit,
        PortRangeForwardingListState>(builder: (context, state) {
      return BasePageView(
        scrollable: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          title: Text(
            getAppLocalizations(context).port_range_forwarding,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SimpleTextButton(
              text: getAppLocalizations(context).edit,
              onPressed: () {
                // TODO
              },
            ),
          ],
        ),
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              box24(),
              Text(getAppLocalizations(context)
                  .port_range_forwarding_description),
              if (!_cubit.isExceedMax())
                SimpleTextButton(
                  text: getAppLocalizations(context).add_rule,
                  onPressed: () {
                    NavigationCubit.of(context)
                        .pushAndWait(
                            PortRangeForwardingRulePath()..args = {'rules': state.rules})
                        .then((value) {
                      if (value ?? false) {
                        _cubit.fetch();
                      }
                    });
                  },
                ),
              box24(),
              ...state.rules.map(
                (e) => administrationTile(
                    title: title(e.description),
                    value: subTitle(
                      e.isEnabled
                          ? getAppLocalizations(context).on
                          : getAppLocalizations(context).off,
                    ),
                    onPress: () {
                      NavigationCubit.of(context)
                          .pushAndWait(SinglePortForwardingRulePath()
                            ..args = {'rules': state.rules, 'edit': e})
                          .then((value) {
                        if (value ?? false) {
                          _cubit.fetch();
                        }
                      });
                    }),
              )
            ],
          ),
        ),
      );
    });
  }
}
