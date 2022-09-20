import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/setup/view/parent_scan_qrcode_view.dart';
import 'package:linksys_moab/route/_route.dart';


import '../../../bloc/connectivity/cubit.dart';
import '../../components/base_components/button/primary_button.dart';
import 'android_manually_connect_view.dart';
import 'android_qr_choice_view.dart';
import 'package:linksys_moab/route/model/_model.dart';

class PermissionsPrimerView extends StatefulWidget {
  PermissionsPrimerView({
    Key? key,
  }) : super(key: key);

  @override
  State<PermissionsPrimerView> createState() => _PermissionsPrimerViewState();
}

class _PermissionsPrimerViewState extends State<PermissionsPrimerView> {
  // Replace this to svg if the svg image is fixed
  final Widget checkIcon = Image.asset('assets/images/permission_check.png');
  final Widget imgContent = Image.asset('assets/images/permission_dialog.png');

  bool isUnderAndroidTen = false;
  bool isSupportEasyConnect = false;

  Future<void> _initAndroidSupport() async {
    isUnderAndroidTen = context.read<ConnectivityCubit>().isAndroid9;
    isSupportEasyConnect = context.read<ConnectivityCubit>().isAndroid10AndSupportEasyConnect;
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
        scrollable: true,
        child: BasicLayout(
          header: BasicHeader(
            spacing: 11,
            title: getAppLocalizations(context).permissions_primer_title,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (Platform.isIOS)
                CheckPermissionView(
                    checkIcon: checkIcon,
                    text: getAppLocalizations(context).camera_access),
              CheckPermissionView(
                  checkIcon: checkIcon,
                  text: getAppLocalizations(context).local_network_access),
              if (Platform.isIOS)
                CheckPermissionView(
                    checkIcon: checkIcon,
                    text: getAppLocalizations(context).location),
              const SizedBox(
                height: 24,
              ),
              imgContent,
            ],
          ),
          footer: PrimaryButton(
            text: getAppLocalizations(context).got_it,
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
            width: 13,
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
