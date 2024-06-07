import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/connectivity/_connectivity.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/util/permission.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

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
    // if (!kIsWeb) {
    //   checkLocationPermissions().then((value) {
    //     ref.read(connectivityProvider.notifier).forceUpdate();
    //   });
    // }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectivityProvider);
    return Container(
      padding: const EdgeInsets.all(12),
      width: ResponsiveLayout.isMobileLayout(context)
          ? MediaQueryUtils.getScreenWidth(context) / 2
          : MediaQueryUtils.getScreenWidth(context) / 3,
      height: 130,
      decoration: const BoxDecoration(
        color: Color(0x33000000),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppText.bodyMedium('Envrionment: ${cloudEnvTarget.name}'),
            AppText.bodyMedium(
                'Router: ${state.connectivityInfo.routerType.name}'),
            AppText.bodyMedium(
                'Connectivity: ${state.connectivityInfo.type.name}'),
            AppText.bodyMedium(
                'Gateway IP: ${state.connectivityInfo.gatewayIp}'),
            AppText.bodyMedium('SSID: ${state.connectivityInfo.ssid}'),
          ],
        ),
      ),
    );
  }
}
