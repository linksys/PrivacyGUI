import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:moab_poc/util/connectivity.dart';

import 'cubit.dart';
import 'state.dart';

class MeshPage extends StatelessWidget {
  const MeshPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    String ip = ConnectivityUtil.gatewayIp;

    return BlocProvider(
      create: (BuildContext context) => MeshCubit(
          repo: LocalDeviceRepository(
              OpenWRTClient(Device(address: ip, port: '80')))),
      child: Builder(builder: (context) => _buildPage(context)),
    );
  }

  Widget _buildPage(BuildContext context) {
    final cubit = BlocProvider.of<MeshCubit>(context);

    return Container();
  }
}
