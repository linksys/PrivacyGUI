import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class PortForwardingView extends ArgumentsStatelessView {
  const PortForwardingView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return PortForwardingContentView(
      next: super.next,
      args: super.args,
    );
  }
}

class PortForwardingContentView extends ArgumentsStatefulView {
  const PortForwardingContentView({super.key, super.next, super.args});

  @override
  State<PortForwardingContentView> createState() =>
      _PortForwardingContentViewState();
}

class _PortForwardingContentViewState extends State<PortForwardingContentView> {
  StreamSubscription? _subscription;

  @override
  void initState() {
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
    return StyledLinksysPageView(
      title: getAppLocalizations(context).port_forwarding,
      child: LinksysBasicLayout(
        content: Column(
          children: [
            const LinksysGap.semiBig(),
            AppSimplePanel(
              title: getAppLocalizations(context).single_port_forwarding,
              onTap: () {
                NavigationCubit.of(context)
                    .push(SinglePortForwardingListPath());
              },
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).port_range_forwarding,
              onTap: () {
                NavigationCubit.of(context).push(PortRangeForwardingListPath());
              },
            ),
            AppSimplePanel(
              title: getAppLocalizations(context).port_range_triggering,
              onTap: () {
                NavigationCubit.of(context).push(PortRangeTriggeringListPath());
              },
            ),
          ],
        ),
      ),
    );
  }
}
