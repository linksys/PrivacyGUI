import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/bloc/single_port_forwarding_list_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SinglePortForwardingListView extends ArgumentsStatelessView {
  const SinglePortForwardingListView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SinglePortForwardingListCubit>(
      create: (context) => SinglePortForwardingListCubit(
          repository: context.read<RouterRepository>()),
      child: SinglePortForwardingListContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class SinglePortForwardingListContentView extends ArgumentsStatefulView {
  const SinglePortForwardingListContentView(
      {super.key, super.next, super.args});

  @override
  State<SinglePortForwardingListContentView> createState() =>
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends State<SinglePortForwardingListContentView> {
  late final SinglePortForwardingListCubit _cubit;

  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<SinglePortForwardingListCubit>();
    _cubit.fetch();
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
    });

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SinglePortForwardingListCubit,
        SinglePortForwardingListState>(builder: (context, state) {
      return StyledLinksysPageView(
        title: getAppLocalizations(context).single_port_forwarding,
        actions: [
          LinksysTertiaryButton(
            getAppLocalizations(context).edit,
            onTap: () {
              // TODO
            },
          ),
        ],
        scrollable: true,
        child: LinksysBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LinksysGap.semiBig(),
              LinksysText.descriptionMain(getAppLocalizations(context)
                  .single_port_forwarding_description),
              if (!_cubit.isExceedMax())
                LinksysTertiaryButton(
                  getAppLocalizations(context).add_rule,
                  onTap: () {
                    NavigationCubit.of(context)
                        .pushAndWait(SinglePortForwardingRulePath()
                          ..args = {'rules': state.rules})
                        .then((value) {
                      if (value ?? false) {
                        _cubit.fetch();
                      }
                    });
                  },
                ),
              const LinksysGap.semiBig(),
              ...state.rules.map(
                (e) => AppPanelWithInfo(
                  title: e.description,
                  infoText: e.isEnabled
                      ? getAppLocalizations(context).on
                      : getAppLocalizations(context).off,
                  forcedHidingAccessory: true,
                  onTap: () {
                    NavigationCubit.of(context)
                        .pushAndWait(SinglePortForwardingRulePath()
                          ..args = {'rules': state.rules, 'edit': e})
                        .then((value) {
                      if (value ?? false) {
                        _cubit.fetch();
                      }
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
