import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/customs/qr_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:moab_poc/util/permission.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../components/base_components/button/primary_button.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/model/model.dart';

class ParentScanQRCodeView extends StatefulWidget {
  const ParentScanQRCodeView({
    Key? key,
  }) : super(key: key);

  @override
  State<ParentScanQRCodeView> createState() => _ParentScanQRCodeViewState();
}

class _ParentScanQRCodeViewState extends State<ParentScanQRCodeView> with Permissions{
  @override
  void initState() {
    _checkCameraPermission();
  }
  
  Future<void> _checkCameraPermission() async{
    await checkCameraPermissions().then((value) {
      if(!value) {
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
          description: 'The code is on the bottom of your node',
        ),
        content: Center(
          child: Stack(
            children: [
              Container(
                margin: EdgeInsets.only(top: 30),
                width: double.infinity,
                height: 300,
                alignment: Alignment.center,
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: CustomQRView(
                    onResult: (Barcode code) => _handleScanResult(context, code),
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
              onPress: () => NavigationCubit.of(context).push(AndroidLocationPermissionPrimerPath()),
            ),
          ],
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }

  _handleScanResult(BuildContext context, Barcode code) {
    print('Scanned code: ${code.rawValue ?? ''}');
    NavigationCubit.of(context).push(AndroidLocationPermissionPrimerPath());
  }
}
