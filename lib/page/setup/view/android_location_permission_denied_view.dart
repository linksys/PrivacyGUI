import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:moab_poc/route/model/internet_check_path.dart';
import 'package:moab_poc/route/route.dart';

import '../../../util/permission.dart';
import '../../components/base_components/button/primary_button.dart';
import 'package:moab_poc/route/model/model.dart';

class AndroidLocationPermissionDenied extends StatefulWidget {
  const AndroidLocationPermissionDenied(
      {Key? key})
      : super(key: key);

  @override
  State<AndroidLocationPermissionDenied> createState() =>
      _AndroidLocationPermissionDeniedState();
}

class _AndroidLocationPermissionDeniedState
    extends State<AndroidLocationPermissionDenied> with Permissions {
  bool isLocationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
    _checkLocationPermission();
  }

  Future<void> _checkLocationPermission() async {
    await checkLocationPermissions().then((value) {
      setState(() {
        isLocationPermissionGranted = value;
      });
      if (isLocationPermissionGranted) {
        NavigationCubit.of(context).push(CheckNodeInternetPath());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context)
              .android_location_permission_denied_view_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DescriptionText(
                text: getAppLocalizations(context)
                    .android_location_permission_denied_view_description),
            const SizedBox(height: 16),
            DescriptionText(
                text: getAppLocalizations(context)
                    .android_location_permission_denied_view_step1),
            const SizedBox(height: 3),
            DescriptionText(
                text: getAppLocalizations(context)
                    .android_location_permission_denied_view_step2),
            const SizedBox(height: 3),
            DescriptionText(
                text: getAppLocalizations(context)
                    .android_location_permission_denied_view_step3),
          ],
        ),
        footer: Column(
          children: [
            PrimaryButton(
                text: getAppLocalizations(context).enable_location,
                onPress: (){
                  _checkLocationPermission();
                }),
            const SizedBox(height: 11),
            SecondaryButton(
                text: getAppLocalizations(context).quit_setup,
                onPress: (){
                  NavigationCubit.of(context).popTo(HomePath());
                })
          ],
        ),
      ),
    );
  }
}
