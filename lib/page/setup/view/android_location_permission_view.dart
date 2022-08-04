import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/button/secondary_button.dart';
import 'package:linksys_moab/page/components/base_components/text/description_text.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:linksys_moab/util/permission.dart';
import 'package:linksys_moab/route/model/model.dart';

class AndroidLocationPermissionPrimer extends StatefulWidget {
  AndroidLocationPermissionPrimer({Key? key}) : super(key: key);

  @override
  State<AndroidLocationPermissionPrimer> createState() =>
      _AndroidLocationPermissionPrimerState();
}

class _AndroidLocationPermissionPrimerState
    extends State<AndroidLocationPermissionPrimer> with Permissions {
  bool isLocationPermissionGranted = false;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _checkLocationPermission() async {
    await checkLocationPermissions().then((value) {
      setState(() {
        isLocationPermissionGranted = value;
      });
      if (isLocationPermissionGranted) {
        NavigationCubit.of(context).push(CheckNodeInternetPath());
      } else {
        NavigationCubit.of(context)
            .push(SetupParentLocationPermissionDeniedPath());
      }
    });
  }

  final Widget img =
      Image.asset('assets/images/android_location_permission.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
            title: getAppLocalizations(context)
                .android_location_permission_view_title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DescriptionText(
                text: getAppLocalizations(context)
                    .android_location_permission_view_description),
            const SizedBox(height: 27),
            img
          ],
        ),
        footer: Column(
          children: [
            PrimaryButton(
                text: getAppLocalizations(context).text_continue,
                onPress: () {
                  _checkLocationPermission();
                }),
            const SizedBox(height: 11),
            SecondaryButton(
                text: getAppLocalizations(context).quit_setup,
                onPress: () => NavigationCubit.of(context).popTo(HomePath()))
          ],
        ),
      ),
    );
  }
}
