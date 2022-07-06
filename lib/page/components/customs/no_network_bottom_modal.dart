import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/route/route.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class NoInternetConnectionModal extends StatelessWidget {
  const NoInternetConnectionModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(

      onWillPop: () async { return false; },
      child: BasePageView.bottomSheetModal(bottomSheet: Container(
          color: Colors.white,
          height: 240,
          padding: const EdgeInsets.all(24),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      getAppLocalizations(context).prompt_no_internet_connection,
                      style: Theme.of(context).textTheme.headline1,
                    ),
                    const SizedBox(
                      height: 36,
                    ),
                    Text(
                      getAppLocalizations(context).prompt_no_internet_connection_description,
                      style: Theme.of(context).textTheme.bodyText1,
                    )
                  ],
                ),
              ),
              Container(
                alignment: Alignment.topRight,
                child: IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    NavigationCubit.of(context).pop();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
