import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/connectivity/state.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';
import 'package:linksys_moab/utils.dart';

class OverlayInfoView extends StatefulWidget {
  const OverlayInfoView({super.key});

  @override
  State<OverlayInfoView> createState() => _OverlayInfoViewState();
}

class _OverlayInfoViewState extends State<OverlayInfoView> {
  bool _isMqttConnected = false;
  @override
  void initState() {
    context.read<RouterRepository>().addMqttConnectionCallback((isConnected) {
      setState(() {
        _isMqttConnected = isConnected;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) => Container(
          padding: EdgeInsets.all(12),
          width: Utils.getScreenWidth(context) / 2,
              height: Utils.getScreenHeight(context)/ 10,
              decoration: BoxDecoration(
                color: Color(0x66000000),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Router: ${state.connectivityInfo.routerType.name}'),
                  Text('Connectivity: ${state.connectivityInfo.type.name}'),
                  Text('Gateway IP: ${state.connectivityInfo.gatewayIp}'),
                  Text('SSID: ${state.connectivityInfo.ssid}'),
                ],
              ),
            ));
  }
}
