import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/logger.dart';


class SelectProtocolView extends ArgumentsStatelessView {
  const SelectProtocolView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return SelectProtocolContentView(
      next: super.next,
      args: super.args,
    );
  }
}

class SelectProtocolContentView extends ArgumentsStatefulView {
  const SelectProtocolContentView({super.key, super.next, super.args});

  @override
  State<SelectProtocolContentView> createState() =>
      _SelectProtocolContentViewState();
}

class _SelectProtocolContentViewState extends State<SelectProtocolContentView> {
  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  late String _selected;
  static const List<String> _keys = ['UDP', 'TCP', 'BOTH'];

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

    _selected = widget.args['selected'] ?? 'UDP';
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
          getAppLocalizations(context).single_port_forwarding,
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
            ..._keys.map((e) => ListTile(
              title: Text(getProtocolTitle(e)),
              trailing: SizedBox(
                child: e == _selected
                    ? Image.asset('assets/images/icon_check_black.png')
                    : null,
                height: 36,
                width: 36,
              ),
              contentPadding: const EdgeInsets.only(bottom: 24),
              onTap: () {
                setState(() {
                  _selected = e;
                });
                NavigationCubit.of(context).popWithResult(_selected);
              },
            ))
          ],
        ),
      ),
    );
  }

  String getProtocolTitle(String key) {
    if (key == 'UDP') {
      return getAppLocalizations(context).udp;
    } else if (key == 'TCP') {
      return getAppLocalizations(context).tcp;
    } else {
      return getAppLocalizations(context).udp_and_tcp;
    }
  }
}
