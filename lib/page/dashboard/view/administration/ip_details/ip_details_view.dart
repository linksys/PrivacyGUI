import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/provider/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/styled/styled_page_view.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/ip_details/bloc/state.dart';
import 'package:linksys_moab/core/jnap/router_repository.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

import '../common_widget.dart';
import 'bloc/cubit.dart';

class IpDetailsView extends ArgumentsConsumerStatelessView {
  const IpDetailsView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BlocProvider(
      create: (context) => IpDetailsCubit(context.read<RouterRepository>()),
      child: IpDetailsContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class IpDetailsContentView extends ArgumentsConsumerStatefulView {
  const IpDetailsContentView({super.key, super.next, super.args});

  @override
  ConsumerState<IpDetailsContentView> createState() =>
      _IpDetailsContentViewState();
}

class _IpDetailsContentViewState extends ConsumerState<IpDetailsContentView> {
  late final IpDetailsCubit _cubit;

  bool _isBehindRouter = false;

  @override
  void initState() {
    _cubit = context.read<IpDetailsCubit>();
    _cubit.fetch();

    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final connectivityState = ref.watch(connectivityProvider);
    _isBehindRouter = connectivityState.connectivityInfo.routerType ==
        RouterType.behindManaged;
    return BlocBuilder<IpDetailsCubit, IpDetailsState>(
        builder: (context, state) {
      return StyledAppPageView(
        scrollable: true,
        title: getAppLocalizations(context).ip_details,
        child: AppBasicLayout(
          content: Column(
            children: [
              const AppGap.semiBig(),
              _wanSection(state),
              const AppGap.semiBig(),
              _lanSection(state),
            ],
          ),
        ),
      );
    });
  }

  Widget _wanSection(IpDetailsState state) {
    return administrationSection(
      title: getAppLocalizations(context).node_detail_label_wan,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppSimplePanel(
            title: getAppLocalizations(context).connection_type,
            description: state.ipv4WANType,
          ),
          AppSimplePanel(
            title: getAppLocalizations(context).connection_type,
            description: state.ipv6WANType,
          ),
          AppPanelWithTrailWidget(
            title: getAppLocalizations(context).ip_address,
            description: state.ipv4WANAddress,
            trailing: _checkIpIsRenewIng(state),
          ),
          AppPanelWithTrailWidget(
            title: getAppLocalizations(context).ipv6_address,
            description: state.ipv6WANAddress,
            trailing: _checkIpv6IsRenewIng(state),
          ),
          _checkRenewAvailable(),
        ],
      ),
    );
  }

  Widget _checkIpIsRenewIng(IpDetailsState state) {
    if (state.ipv4Renewing) {
      return _buildRenewingSpinner();
    } else {
      return _buildRenewButton(false);
    }
  }

  Widget _checkIpv6IsRenewIng(IpDetailsState state) {
    if (state.ipv6Renewing) {
      return _buildRenewingSpinner();
    } else {
      return _buildRenewButton(true);
    }
  }

  _buildRenewButton(bool isIPv6) {
    return AppTertiaryButton.noPadding(
      getAppLocalizations(context).release_and_renew,
      onTap: _isBehindRouter
          ? () {
              _cubit.renewIp(isIPv6).then((value) => showSuccessSnackBar(
                  context, getAppLocalizations(context).ip_address_renewed));
            }
          : null,
    );
  }

  _buildRenewingSpinner() {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const SizedBox(
            width: 18, height: 18, child: CircularProgressIndicator()),
        const AppGap.semiSmall(),
        AppText.descriptionSub(
          getAppLocalizations(context).ip_renewing,
          color: AppTheme.of(context).colors.ctaPrimaryDisable,
        ),
      ],
    );
  }

  Widget _checkRenewAvailable() {
    if (!_isBehindRouter) {
      final ssid = context
              .read<NetworkCubit>()
              .state
              .selected
              ?.radioInfo
              ?.first
              .settings
              .ssid ??
          '';
      return AppText.descriptionMain(
          getAppLocalizations(context).release_ip_description(ssid));
    }
    return const Center();
  }

  Widget _lanSection(IpDetailsState state) {
    return administrationSection(
        title: getAppLocalizations(context).node_detail_label_lan,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSimplePanel(
              title: getAppLocalizations(context).ip_address,
              description:
                  state.masterNode?.connections.firstOrNull?.ipAddress ?? '',
            ),
          ],
        ));
  }
}
