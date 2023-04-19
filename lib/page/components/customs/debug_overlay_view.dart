import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/connectivity/_connectivity.dart';
import 'package:linksys_moab/bloc/connectivity/connectivity_provider.dart';
import 'package:linksys_moab/bloc/connectivity/connectivity_state.dart';
import 'package:linksys_moab/util/permission.dart';
import 'package:linksys_moab/utils.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

import '../../../constants/build_config.dart';

class OverlayInfoView extends ConsumerStatefulWidget {
  const OverlayInfoView({super.key});

  @override
  ConsumerState<OverlayInfoView> createState() => _OverlayInfoViewState();
}

class _OverlayInfoViewState extends ConsumerState<OverlayInfoView>
    with Permissions {
  @override
  void initState() {
    super.initState();
    checkLocationPermissions().then((value) {
      ref.read(connectivityProvider.notifier).forceUpdate();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectivityProvider);
    return Container(
      padding: EdgeInsets.all(12),
      width: Utils.getScreenWidth(context) / 2,
      height: 130,
      decoration: BoxDecoration(
        color: Color(0x33000000),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LinksysText.descriptionSub('Envrionment: ${cloudEnvTarget.name}'),
            LinksysText.descriptionSub(
                'Router: ${state.connectivityInfo.routerType.name}'),
            LinksysText.descriptionSub(
                'Connectivity: ${state.connectivityInfo.type.name}'),
            LinksysText.descriptionSub(
                'Gateway IP: ${state.connectivityInfo.gatewayIp}'),
            LinksysText.descriptionSub('SSID: ${state.connectivityInfo.ssid}'),
          ],
        ),
      ),
    );
  }
}
