import 'dart:io';

import 'package:connecting_wifi_plugin/connecting_wifi_plugin.dart';
import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/customs/qr_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/logger.dart';

import 'package:linksys_moab/util/permission.dart';
import 'package:linksys_moab/util/wifi_credential.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../components/base_components/button/primary_button.dart';
import 'package:linksys_moab/route/model/_model.dart';

class ParentScanQRCodeView extends StatefulWidget {
  const ParentScanQRCodeView({
    Key? key,
  }) : super(key: key);

  @override
  State<ParentScanQRCodeView> createState() => _ParentScanQRCodeViewState();
}

class _ParentScanQRCodeViewState extends State<ParentScanQRCodeView>
    with Permissions {

  bool _isLoading = false;

  @override
  void initState() {
    _checkCameraPermission();
    super.initState();
  }

  Future<void> _checkCameraPermission() async {
    await checkCameraPermissions().then((value) {
      if (!value) {
        NavigationCubit.of(context).push(SetupParentManualEnterSSIDPath());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).scan_qrcode_view_title,
        ),
        content: Center(
          child: Stack(
            children: [
              Container(
                width: double.infinity,
                height: 300,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomQRView(
                    onResult: (Barcode code) =>
                        _handleScanResult(context, code),
                  ),
                ),
              ),
            ],
          ),
        ),
        footer: Column(
          children: [
            PrimaryButton(
              text: getAppLocalizations(context).scan_qrcode_view_button_text,
              onPress: () {
                if (Platform.isAndroid) {
                  NavigationCubit.of(context).push(
                      AndroidLocationPermissionPrimerPath());
                } else if (Platform.isIOS) {
                  NavigationCubit.of(context).push(CheckNodeInternetPath());
                }
              },
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }

  _handleScanResult(BuildContext context, Barcode code) async {
    setState(() {
      _isLoading = true;
    });
    logger.d('Scanned code: ${code.rawValue ?? ''}');
    if (Platform.isAndroid) {
      NavigationCubit.of(context).push(
          AndroidLocationPermissionPrimerPath());
    } else if (Platform.isIOS) {
      // NavigationCubit.of(context).push(CheckNodeInternetPath());
      final cred = WiFiCredential.parse(code.rawValue ?? '');
      logger.d('WiFi Credentials: ssid: ${cred.ssid}, ${cred.password}');
      final isConnected = await ConnectingWifiPlugin().connectToWiFi(ssid: cred.ssid, password: cred.password);
      setState(() {
        _isLoading = false;
      });
      if (isConnected) {
        NavigationCubit.of(context).push(CheckNodeInternetPath());
      } else {
        // TODO error handling and restart scanning
      }
    }
  }
}
