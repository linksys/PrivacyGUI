import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/tile/setting_tile.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/shortcuts/snack_bar.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/page/dashboard/view/administration/ip_details/bloc/state.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/util/logger.dart';

import '../common_widget.dart';
import 'bloc/cubit.dart';

class IpDetailsView extends ArgumentsStatelessView {
  const IpDetailsView({super.key, super.next, super.args});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => IpDetailsCubit(context.read<RouterRepository>()),
      child: IpDetailsContentView(
        next: super.next,
        args: super.args,
      ),
    );
  }
}

class IpDetailsContentView extends ArgumentsStatefulView {
  const IpDetailsContentView({super.key, super.next, super.args});

  @override
  State<IpDetailsContentView> createState() => _IpDetailsContentViewState();
}

class _IpDetailsContentViewState extends State<IpDetailsContentView> {
  late final IpDetailsCubit _cubit;

  bool _isBehindRouter = false;
  StreamSubscription? _subscription;

  @override
  void initState() {
    _cubit = context.read<IpDetailsCubit>();
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
    return BlocBuilder<IpDetailsCubit, IpDetailsState>(
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
        ),
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          content: Column(
            children: [
              box24(),
              _wanSection(state),
              box24(),
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
          administrationTwoLineTile(
            title: Text(getAppLocalizations(context).connection_type),
            value: Text(state.ipv4WANType),
          ),
          administrationTwoLineTile(
            title: Text(getAppLocalizations(context).connection_type),
            value: Text(state.ipv6WANType),
          ),
          administrationTileDesc(
            title: Text(getAppLocalizations(context).ip_address),
            value: _checkIpIsRenewIng(state),
            description: Text(state.ipv4WANAddress),
          ),
          administrationTileDesc(
            title: Text(getAppLocalizations(context).ipv6_address),
            value: _checkIpv6IsRenewIng(state),
            description: Text(state.ipv6WANAddress),
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
    return SimpleTextButton.noPadding(
      text: getAppLocalizations(context).release_and_renew,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onTertiary,
      ),
      onPressed: _isBehindRouter
          ? () {
              _cubit.renewIp(isIPv6).then((value) => showSuccessSnackBar(context, getAppLocalizations(context).ip_address_renewed));
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
        box8(),
        Text(getAppLocalizations(context).ip_renewing),
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
      return administrationTile(
          title:
              Text(getAppLocalizations(context).release_ip_description(ssid)),
          value: Center());
    }
    return Center();
  }

  Widget _lanSection(IpDetailsState state) {
    return administrationSection(
        title: getAppLocalizations(context).node_detail_label_lan,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            administrationTwoLineTile(
              title: Text(getAppLocalizations(context).ip_address),
              value: Text(state.masterNode?.connections.firstOrNull?.ipAddress ?? ''),
            ),
          ],
        ));
  }

  Widget _sectionTitle({required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color.fromRGBO(0, 0, 0, 0.5),
        ),
      ),
    );
  }

  Widget _ipDetailTile({
    required String title,
    required String value,
    Widget? button,
    double spacing = 4,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
      color: const Color.fromRGBO(0, 0, 0, 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15),
              ),
              const Spacer(),
              if (button != null) button,
            ],
          ),
          box(spacing),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color.fromRGBO(102, 102, 102, 1.0),
            ),
          ),
        ],
      ),
    );
  }
}
