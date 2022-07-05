import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/page/setup/view/parent_scan_qrcode_view.dart';
import 'package:moab_poc/route/route.dart';

import '../../../channel/wifi_connect_channel.dart';
import '../../components/base_components/button/primary_button.dart';
import 'android_manually_connect_view.dart';
import 'android_qr_choice_view.dart';

class PermissionsPrimerView extends StatefulWidget {
  PermissionsPrimerView({
    Key? key,
  }) : super(key: key);

  @override
  State<PermissionsPrimerView> createState() => _PermissionsPrimerViewState();
}

class _PermissionsPrimerViewState extends State<PermissionsPrimerView> {
  // Replace this to svg if the svg image is fixed
  final Widget checkIcon = Image.asset('assets/images/icon_check.png');
  final Widget imgContent = Image.asset('assets/images/permission_dialog.png');

  bool isUnderAndroidTen = false;
  bool isSupportEasyConnect = false;

  Future<void> _initAndroidSupport() async {
    isUnderAndroidTen =
    await NativeConnectWiFiChannel().isAndroidVersionUnderTen();
    isSupportEasyConnect = isUnderAndroidTen ? false :
    await NativeConnectWiFiChannel().isAndroidTenAndSupportEasyConnect();
  }

  @override
  void initState() {
    super.initState();
    _initAndroidSupport();
  }

  @override
  Widget build(BuildContext context) {
    if (Platform.isIOS) {
      return BasePageView(
        child: BasicLayout(
          header: BasicHeader(
            spacing: 11,
            title: AppLocalizations.of(context)!.permissions_primer_title,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 14,
              ),
              imgContent,
              const SizedBox(height: 50),
              if (Platform.isIOS)
                CheckPermissionView(
                    checkIcon: checkIcon,
                    text: AppLocalizations.of(context)!.camera_access),
              CheckPermissionView(
                  checkIcon: checkIcon,
                  text: AppLocalizations.of(context)!.local_network_access),
              if (Platform.isIOS)
                CheckPermissionView(
                    checkIcon: checkIcon,
                    text: AppLocalizations.of(context)!.location)
            ],
          ),
          footer: PrimaryButton(
            text: AppLocalizations.of(context)!.got_it,
            onPress: () => NavigationCubit.of(context).push(SetupParentQrCodeScanPath()),
          ),
        ),
      );
    } else {
      if (isUnderAndroidTen) {
        return const ParentScanQRCodeView();
      } else if (isSupportEasyConnect) {
        return AndroidQRChoiceView();
      } else {
        return AndroidManuallyConnectView();
      }
    }
  }
}

class CheckPermissionView extends StatelessWidget {
  const CheckPermissionView(
      {Key? key, required this.checkIcon, required this.text})
      : super(key: key);

  final Widget checkIcon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          checkIcon,
          const SizedBox(
            width: 8.5,
          ),
          _content(context, text),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, String text) {
    return Flexible(
      child: Column(
        children: [
          const SizedBox(
            height: 9,
          ),
          Text(
            text,
            style: Theme
                .of(context)
                .textTheme
                .headline2
                ?.copyWith(color: Theme
                .of(context)
                .colorScheme
                .primary),
          ),
        ],
      ),
    );
  }
}
