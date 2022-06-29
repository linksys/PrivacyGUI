import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import '../../components/base_components/button/primary_button.dart';

class PermissionsPrimerView extends StatelessWidget {
  PermissionsPrimerView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final VoidCallback onNext;

  // Replace this to svg if the svg image is fixed
  final Widget checkIcon = Image.asset('assets/images/icon_check.png');
  final Widget imgContent = Image.asset('assets/images/permission_dialog.png');

  @override
  Widget build(BuildContext context) {
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
            if (Platform.isIOS) CheckPermissionView(
                checkIcon: checkIcon, text: AppLocalizations.of(context)!.camera_access),
            CheckPermissionView(
                checkIcon: checkIcon, text: AppLocalizations.of(context)!.local_network_access),
            if (Platform.isIOS) CheckPermissionView(
                checkIcon: checkIcon, text: AppLocalizations.of(context)!.location)
          ],
        ),
        footer: PrimaryButton(
          text: AppLocalizations.of(context)!.got_it,
          onPress: onNext,
        ),
      ),
    );
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
            style: Theme.of(context)
                .textTheme
                .headline2
                ?.copyWith(color: Theme.of(context).colorScheme.primary),
          ),
        ],
      ),
    );
  }
}
