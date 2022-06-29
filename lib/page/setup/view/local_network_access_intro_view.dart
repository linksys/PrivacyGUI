import 'package:flutter/material.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';

import '../../components/base_components/base_page_view.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class LocalNetworkAccessIntroView extends StatelessWidget {
  const LocalNetworkAccessIntroView({
    Key? key,
    required this.onNext,
  }) : super(key: key);

  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
            title:
                AppLocalizations.of(context)!.local_network_access_intro_title),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                AppLocalizations.of(context)!
                    .local_network_access_intro_description,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 21),
            Text(AppLocalizations.of(context)!.local_network_access_step,
                style: Theme.of(context)
                    .textTheme
                    .headline4
                    ?.copyWith(color: Theme.of(context).colorScheme.primary)
                ?.copyWith(height: 2)
            )
          ],
        ),
        footer: PrimaryButton(
            text: AppLocalizations.of(context)!.enable_local_network,
            onPress: onNext),
      ),
    );
  }
}
