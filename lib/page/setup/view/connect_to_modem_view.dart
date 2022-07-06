import 'package:flutter/cupertino.dart';
import 'package:moab_poc/localization/localization_hook.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/setup/view/show_me_how_view.dart';
import 'package:moab_poc/route/route.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import '../../components/base_components/button/primary_button.dart';
import '../../components/base_components/button/simple_text_button.dart';
import 'package:moab_poc/route/model/model.dart';

class ConnectToModemView extends StatelessWidget {
  ConnectToModemView({
    Key? key,
  }) : super(key: key);

  //TODO: This svg file does not work
  // final Widget image = SvgPicture.asset(
  //   'assets/images/connect_to_modem.svg',
  // );

  // Remove this if the upper svg image is fixed
  final Widget image = Image.asset('assets/images/connect_to_modem.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: BasicHeader(
          title: getAppLocalizations(context).connect_to_modem_view_title,
          description:
              getAppLocalizations(context).connect_to_modem_view_description,
        ),
        content: _content(context),
        footer: PrimaryButton(
          text: getAppLocalizations(context).next,
          onPress: () => NavigationCubit.of(context).push(SetupParentPlacePath()),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        image,
        const SizedBox(
          height: 104,
        ),
        Align(
          alignment: Alignment.topLeft,
          child: SimpleTextButton(
            text: getAppLocalizations(context).show_me_how,
            onPressed: () => _goToShowMeHowPage(context),
          ),
        )
      ],
    );
  }

  void _goToShowMeHowPage(BuildContext context) {
    showCupertinoModalPopup(
        context: context,
        builder: (context) {
          return const ShowMeHowView();
        });
  }
}
