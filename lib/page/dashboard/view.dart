import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:moab_poc/page/dashboard/dashboard_view.dart';

import '../../util/connectivity.dart';
import 'cubit.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  static const routeName = '/dashboard_page';

  @override
  Widget build(BuildContext context) {
    String ip = ConnectivityUtil.latest.gatewayIp;

    return BlocProvider(
      create: (BuildContext context) => DashboardCubit(
          repo: LocalDeviceRepository(
              OpenWRTClient(Device(address: ip, port: '80')))),
      child: Builder(builder: (context) => _buildPage(context)),
    );
  }

  Widget _buildPage(BuildContext context) {
    final cubit = BlocProvider.of<DashboardCubit>(context);
    cubit.getSSID();
    return const DashboardView();
  }
}
