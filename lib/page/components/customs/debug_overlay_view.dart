import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/connectivity/state.dart';
import 'package:linksys_moab/utils.dart';

class OverlayInfoView extends StatelessWidget {
  const OverlayInfoView({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) => Container(
          padding: EdgeInsets.all(24),
          width: Utils.getScreenWidth(context) / 2,
              height: Utils.getScreenHeight(context)/ 6,
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
