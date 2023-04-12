import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class SelectOnlineDeviceView extends ArgumentsStatelessView {
  const SelectOnlineDeviceView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return SelectOnlineDeviceContentView(
      next: super.next,
      args: super.args,
    );
  }
}

class SelectOnlineDeviceContentView extends ArgumentsStatefulView {
  const SelectOnlineDeviceContentView({super.key, super.next, super.args});

  @override
  State<SelectOnlineDeviceContentView> createState() =>
      _SelectOnlineDeviceContentViewState();
}

class _SelectOnlineDeviceContentViewState
    extends State<SelectOnlineDeviceContentView> {
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
      title: getAppLocalizations(context).single_port_forwarding,
      child: LinksysBasicLayout(
        content: Column(
          children: [
            const LinksysGap.semiBig(),
            AppPanelWithInfo(
              title: getAppLocalizations(context).single_port_forwarding,
              infoText: '',
              onTap: () {},
            ),
            AppPanelWithInfo(
              title: getAppLocalizations(context).port_range_forwarding,
              infoText: '',
              onTap: () {},
            ),
            AppPanelWithInfo(
              title: getAppLocalizations(context).port_range_triggering,
              infoText: '',
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}
