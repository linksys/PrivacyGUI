import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/secondary_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../components/base_components/button/primary_button.dart';

class AndroidLocationPermissionDenied extends StatelessWidget {
  AndroidLocationPermissionDenied({Key? key, required this.onNext, required this.onQuit}) : super(key: key);

  final VoidCallback onNext;
  final VoidCallback onQuit;

  @override
  Widget build(BuildContext context) {
      return BasePageView(
        child: BasicLayout(
          header: BasicHeader(
            title: AppLocalizations.of(context)!.android_location_permission_denied_view_title,
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DescriptionText(text: AppLocalizations.of(context)!.android_location_permission_denied_view_description),
              const SizedBox(height: 16),
              DescriptionText(text: AppLocalizations.of(context)!.android_location_permission_denied_view_step1),
              const SizedBox(height: 3),
              DescriptionText(text: AppLocalizations.of(context)!.android_location_permission_denied_view_step2),
              const SizedBox(height: 3),
              DescriptionText(text: AppLocalizations.of(context)!.android_location_permission_denied_view_step3),
            ],
          ),
          footer: Column(
            children: [
              PrimaryButton(text: AppLocalizations.of(context)!.enable_location, onPress: onNext),
              const SizedBox(height: 11),
              SecondaryButton(text: AppLocalizations.of(context)!.quit_setup, onPress: onQuit)
            ],
          ),
        ),
      );
  }
}