
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/common_widget.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import 'bloc/dhcp_reservations_cubit.dart';
import 'bloc/dhcp_reservations_state.dart';

class DHCPReservationsView extends ArgumentsConsumerStatelessView {
  const DHCPReservationsView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

class DHCPReservationsContentView extends ArgumentsConsumerStatefulView {
  const DHCPReservationsContentView({super.key, super.next, super.args});

  @override
  ConsumerState<DHCPReservationsContentView> createState() =>
      _SinglePortForwardingContentViewState();
}

class _SinglePortForwardingContentViewState
    extends ConsumerState<DHCPReservationsContentView> {
  late final DHCPReservationsCubit _cubit;


  @override
  void initState() {
    _cubit = context.read<DHCPReservationsCubit>();
    _cubit.fetch();

    super.initState();
  }

  @override
  void dispose() {
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
