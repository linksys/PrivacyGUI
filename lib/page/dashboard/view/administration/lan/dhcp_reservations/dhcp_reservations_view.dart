import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/page/dashboard/view/administration/port_forwarding/single_port_forwarding/bloc/single_port_forwarding_list_cubit.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'bloc/dhcp_reservations_cubit.dart';
import 'bloc/dhcp_reservations_state.dart';

class DHCPReservationsView extends ArgumentsStatelessView {
  const DHCPReservationsView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DHCPReservationsCubit>(
      create: (context) =>
          DHCPReservationsCubit(repository: context.read<RouterRepository>()),
      child: DHCPReservationsContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class DHCPReservationsContentView extends ArgumentsStatefulView {
  const DHCPReservationsContentView({super.key, super.next, super.args});

  @override
  State<DHCPReservationsContentView> createState() =>
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends State<DHCPReservationsContentView> {
  late final DHCPReservationsCubit _cubit;

  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<DHCPReservationsCubit>();
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
    return BlocBuilder<DHCPReservationsCubit, DHCPReservationsState>(
        builder: (context, state) {
      return StyledLinksysPageView(
        scrollable: true,
        title: getAppLocalizations(context).dhcp_reservations,
        child: LinksysBasicLayout(
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const LinksysGap.semiBig(),
              administrationSection(
                  title: getAppLocalizations(context).reserved_addresses,
                  content: SizedBox(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        LinksysTertiaryButton.noPadding(
                          getAppLocalizations(context).add_device_reservations,
                          onTap: () {},
                        ),
                      ],
                    ),
                  )),
              const LinksysGap.semiBig(),
              administrationSection(
                title: getAppLocalizations(context).dhcp_list,
                headerAction: LinksysTertiaryButton.noPadding(
                  getAppLocalizations(context).add,
                  onTap: () {},
                ),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinksysTertiaryButton.noPadding(
                      getAppLocalizations(context).add_device_reservations,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}
