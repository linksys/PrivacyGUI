import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SelectProtocolView extends ArgumentsConsumerStatelessView {
  const SelectProtocolView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SelectProtocolContentView(
      next: super.next,
      args: super.args,
    );
  }
}

class SelectProtocolContentView extends ArgumentsConsumerStatefulView {
  const SelectProtocolContentView({super.key, super.next, super.args});

  @override
  ConsumerState<SelectProtocolContentView> createState() =>
      _SelectProtocolContentViewState();
}

class _SelectProtocolContentViewState
    extends ConsumerState<SelectProtocolContentView> {
  StreamSubscription? _subscription;

  late String _selected;
  static const List<String> _keys = ['UDP', 'TCP', 'BOTH'];

  @override
  void initState() {
    _subscription = context.read<ConnectivityCubit>().stream.listen((state) {
      logger.d('IP detail royterType: ${state.connectivityInfo.routerType}');
    });

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
    return StyledLinksysPageView(
      title: getAppLocalizations(context).single_port_forwarding,
      child: LinksysBasicLayout(
        content: Column(
          children: [
            const LinksysGap.semiBig(),
            ..._keys.map((e) => InkWell(
                  onTap: () {
                    setState(() {
                      _selected = e;
                    });
                    ref
                        .read(navigationsProvider.notifier)
                        .popWithResult(_selected);
                  },
                  child: AppPanelWithValueCheck(
                    title: getProtocolTitle(e),
                    valueText: ' ',
                    isChecked: _selected == e,
                  ),
                )),
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
