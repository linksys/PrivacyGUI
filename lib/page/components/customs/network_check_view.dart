import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';
import 'package:privacy_gui/util/permission.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/gap/gap.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';
import 'package:permission_handler/permission_handler.dart';

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
        context.pop();
      } else {
        ref.read(connectivityProvider.notifier).forceUpdate();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(connectivityProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleLarge(
          widget.description,
        ),
        const AppGap.medium(),
        const Icon(LinksysIcons.wifi),
        const AppGap.small2(),
        AppText.bodyLarge(
          state.connectivityInfo.ssid ?? '',
        ),
        const Spacer(),
        widget.button,
      ],
    );
  }
}
