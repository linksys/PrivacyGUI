import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/connectivity/cubit.dart';
import 'package:linksys_moab/bloc/connectivity/state.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_moab/util/permission.dart';
import 'package:linksys_widgets/theme/theme.dart';
import 'package:linksys_widgets/widgets/base/gap.dart';
import 'package:linksys_widgets/widgets/base/icon.dart';
import 'package:linksys_widgets/widgets/text/app_text.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../route/navigations_notifier.dart';

class NetworkCheckView extends ConsumerStatefulWidget {
  const NetworkCheckView(
      {Key? key, required this.description, required this.button})
      : super(key: key);

  final String description;
  final Widget button;

  @override
  ConsumerState<NetworkCheckView> createState() => _NetworkCheckViewState();
}

class _NetworkCheckViewState extends ConsumerState<NetworkCheckView>
    with Permissions {
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
        ref.read(navigationsProvider.notifier).pop();
      } else {
        context.read<ConnectivityCubit>().forceUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectivityCubit, ConnectivityState>(
        builder: (context, state) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinksysText.screenName(
                  widget.description,
                ),
                const LinksysGap.regular(),
                AppIcon(icon: getCharactersIcons(context).wifiDefault),
                const LinksysGap.semiSmall(),
                LinksysText.descriptionMain(
                  state.connectivityInfo.ssid ?? '',
                ),
                const Spacer(),
                widget.button,
              ],
            ));
  }
}
