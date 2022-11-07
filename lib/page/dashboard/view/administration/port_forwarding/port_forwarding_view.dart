import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

import 'bloc/cubit.dart';
import 'bloc/state.dart';

class PortForwardingView extends ArgumentsStatelessView {
  const PortForwardingView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PortForwardingCubit(context.read<RouterRepository>()),
      child: PortForwardingContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class PortForwardingContentView extends ArgumentsStatefulView {
  const PortForwardingContentView({super.key, super.next, super.args});

  @override
  State<PortForwardingContentView> createState() => _PortForwardingContentViewState();
}

class _PortForwardingContentViewState extends State<PortForwardingContentView> {
  late final PortForwardingCubit _cubit;

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<PortForwardingCubit>();
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
    return BlocBuilder<PortForwardingCubit, PortForwardingState>(
        builder: (context, state) {
      return BasePageView(
        padding: EdgeInsets.zero,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          // iconTheme:
          // IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          title: Text(
            getAppLocalizations(context).ip_details,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          actions: [
            SimpleTextButton(
              text: getAppLocalizations(context).save,
              onPressed: () {},
            ),
          ],
        ),
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Column(
            children: [
              box24(),

            ],
          ),
        ),
      );
    });
  }
}
