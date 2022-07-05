import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:moab_poc/bloc/connectivity/connectivity_info.dart';
import 'package:moab_poc/bloc/connectivity/cubit.dart';
import 'package:moab_poc/route/navigation_cubit.dart';
import 'package:moab_poc/util/permission.dart';
import 'package:permission_handler/permission_handler.dart';

class NetworkCheckView extends StatefulWidget {
  const NetworkCheckView({Key? key, required this.description, required this.button }) : super(key: key);

  final String description;
  final Widget button;

  @override
  State<NetworkCheckView> createState() => _NetworkCheckViewState();
}

class _NetworkCheckViewState extends State<NetworkCheckView> with Permissions {

  @override
  void initState() {
    super.initState();
    _initConnectivity();
  }


  @override
  void dispose() {
    super.dispose();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _initConnectivity() async {
    await checkLocationPermissions().then((value) {
      if (!value) {
        openAppSettings();
        NavigationCubit.of(context).pop();
      } else {
        context.read<ConnectivityCubit>().forceUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityInfo>(
        builder: (context, info) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.description,
                  style: Theme.of(context)
                      .textTheme
                      .headline3
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(
                  height: 8,
                ),
                Image.asset('assets/images/icon_wifi.png'),
                const SizedBox(
                  height: 12,
                ),
                Text(
                  info.ssid,
                  style: Theme.of(context)
                      .textTheme
                      .headline3
                      ?.copyWith(color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(
                  height: 43,
                ),
                widget.button,
              ],
            ));
  }
}
