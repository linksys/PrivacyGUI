import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class IOSLocationPermissionDenied extends StatelessWidget {
  const IOSLocationPermissionDenied(
      {Key? key, required this.onNext, required this.onQuit})
      : super(key: key);

  final VoidCallback onNext;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).local_permission_denied_title,
        ),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 27),
            DescriptionText(text: getAppLocalizations(context).local_permission_denied_subtitle),
            const SizedBox(height: 21),
            DescriptionText(text: getAppLocalizations(context).local_permission_denied_step1),
            const SizedBox(height: 3),
            DescriptionText(text: getAppLocalizations(context).local_permission_denied_step2),
            const SizedBox(height: 3),
            DescriptionText(text: getAppLocalizations(context).local_permission_denied_step3),
          ],
        ),
        footer: Column(
          children: [
            PrimaryButton(text: getAppLocalizations(context).enabled_local_access, onPress: onNext),
            const SizedBox(height: 11),
            SecondaryButton(text: getAppLocalizations(context).quit_setup, onPress: onQuit)
          ],
        ),
      ),
    );
  }
}
