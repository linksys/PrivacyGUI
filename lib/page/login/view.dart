import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/packages/openwrt/openwrt.dart';
import 'package:moab_poc/packages/repository/device_repository/device_repository.dart';
import 'package:moab_poc/page/login/login_page.dart';

import 'cubit.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({Key? key}) : super(key: key);

  static const routeName = '/login';

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>;
    final ip = args['ip'] ?? "";
    final ssid = args['ssid'] ?? "";

    log('LoginPage: $ip, $ssid');
    return BlocProvider(
      create: (BuildContext context) => LoginCubit(
          repository: LocalDeviceRepository(
              OpenWRTClient(Device(address: ip, port: '80')))),
      child: Builder(builder: (context) => _buildPage(context)),
    );
  }

  Widget _buildPage(BuildContext context) {
    final cubit = BlocProvider.of<LoginCubit>(context);

    return LoginView();
  }
}
