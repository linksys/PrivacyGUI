import 'package:flutter/material.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class InfoSetupSSIDView extends StatelessWidget {
  InfoSetupSSIDView({Key? key}) : super(key: key);

  final Widget img = Image.asset("assets/images/info_setup_ssid.png");

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      appBar: _appBar(context),
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).info_setup_ssid_view_title,
        ),
        content: Center(
          child: img,
        ),
      ),
    );
  }

  AppBar _appBar(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      iconTheme: IconThemeData(color: Theme.of(context).colorScheme.primary),
      elevation: 0,
      automaticallyImplyLeading: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        )
      ],
    );
  }
}
