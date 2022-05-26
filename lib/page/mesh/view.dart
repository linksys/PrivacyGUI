import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:moab_poc/page/mesh/bloc.dart';
import 'package:moab_poc/page/mesh/mesh_view.dart';
import 'package:moab_poc/util/connectivity.dart';


class MeshPage extends StatelessWidget {
  const MeshPage({Key? key}) : super(key: key);

  static const routeName = '/mesh';

  @override
  Widget build(BuildContext context) {
    String ip = ConnectivityUtil.latest.gatewayIp;

    return BlocProvider<MeshBloc>(
      create: (BuildContext context) => MeshBloc(
          repo: LocalDeviceRepository(
              OpenWRTClient(Device(address: ip, port: '80')))),
      child: Builder(builder: (context) => _buildPage(context)),
    );
  }

  Widget _buildPage(BuildContext context) {
    return const MeshView();
  }
}
