import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/port_range_triggering/bloc/port_range_triggering_list_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortRangeTriggeringListView extends ArgumentsStatelessView {
  const PortRangeTriggeringListView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<PortRangeTriggeringListCubit>(
      create: (context) => PortRangeTriggeringListCubit(
          repository: context.read<RouterRepository>()),
      child: PortRangeTriggeringListContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class PortRangeTriggeringListContentView extends ArgumentsStatefulView {
  const PortRangeTriggeringListContentView({super.key, super.next, super.args});

  @override
  State<PortRangeTriggeringListContentView> createState() =>
      _PortRangeTriggeringContentViewState();
}

class _PortRangeTriggeringContentViewState
    extends State<PortRangeTriggeringListContentView> {
  late final PortRangeTriggeringListCubit _cubit;

  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<PortRangeTriggeringListCubit>();
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
    return BlocBuilder<PortRangeTriggeringListCubit,
        PortRangeTriggeringListState>(builder: (context, state) {
      return StyledLinksysPageView(
        scrollable: true,
        title: getAppLocalizations(context).port_range_triggering,
        actions: [
          LinksysTertiaryButton(
            getAppLocalizations(context).edit,
            onTap: () {
              // TODO
            },
          ),
        ],
        child: LinksysBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LinksysGap.semiBig(),
              LinksysText.descriptionMain(getAppLocalizations(context)
                  .port_range_triggering_description),
              if (!_cubit.isExceedMax())
                LinksysTertiaryButton(
                  getAppLocalizations(context).add_rule,
                  onTap: () {
                    NavigationCubit.of(context)
                        .pushAndWait(PortRangeTriggeringRulePath()
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
