import 'package:flutter/material.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/button/primary_button.dart';
import 'package:linksys_moab/page/components/base_components/text/description_text.dart';
import 'package:linksys_moab/route/route.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/route/model/model.dart';

class GetWiFiUpView extends StatelessWidget {
  GetWiFiUpView({
    Key? key,
  }) : super(key: key);

  static const routeName = '/get_wifi_up';

  //TODO: This svg file does not work
  // final Widget image = SvgPicture.asset(
  //   'assets/images/get_wifi_up_image.svg',
  //   semanticsLabel: 'Get Wifi Up',
  // );

  // Remove this if the upper svg image is fixed
  final Widget image = Image.asset('assets/images/get_wifi_up_image.png');

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: BasicHeader(
          title: getAppLocalizations(context).welcome_eula_title,
        ),
        content: _content(context),
        footer: PrimaryButton(
          text: getAppLocalizations(context).accept,
          onPress: () => NavigationCubit.of(context).push(SetupParentPlugPath()),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 38,
        ),
        image,
        const SizedBox(
          height: 39,
        ),
        DescriptionText(
            // TODO: Use rich text here
            text: getAppLocalizations(context).welcome_eula_content
        ),
      ],
    );
  }
}
