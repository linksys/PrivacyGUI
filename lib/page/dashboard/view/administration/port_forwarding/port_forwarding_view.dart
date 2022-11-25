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
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';

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

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
      _isBehindRouter =
          state.connectivityInfo.routerType == RouterType.behindManaged;
    });
    _isBehindRouter =
        context.read<ConnectivityCubit>().state.connectivityInfo.routerType ==
            RouterType.behindManaged;

    super.initState();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // iconTheme:
        // IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
        title: Text(
          getAppLocalizations(context).port_forwarding,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      child: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          children: [
            box24(),
            administrationTile(
              title:
              title(getAppLocalizations(context).single_port_forwarding),
              onPress: () {
                NavigationCubit.of(context).push(SinglePortForwardingListPath());
              },
            ),
            administrationTile(
                title:
                title(getAppLocalizations(context).port_range_forwarding),
                onPress: () {
                  NavigationCubit.of(context).push(PortRangeForwardingListPath());
                }),
            administrationTile(
                title:
                title(getAppLocalizations(context).port_range_triggering),
                onPress: () {
                  NavigationCubit.of(context).push(PortRangeTriggeringListPath());
                }),
          ],
        ),
      ),
    );
  }
}
