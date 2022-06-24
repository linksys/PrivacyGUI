import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/base_components/text/title_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';
import 'package:moab_poc/route/route.dart';

class SetupFinishedView extends ArgumentsStatelessView {

  SetupFinishedView({
    Key? key, super.args
  }) : super(key: key) {
    _ssid = args!['ssid'];
    _password = args!['password'];
  }

  late String _ssid;
  late String _password;

  //TODO: The svg image must be replaced
  final Widget image = SvgPicture.asset(
    'assets/images/linksys_logo_large_white.svg',
    semanticsLabel: 'Setup Finished',
  );

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Your WiFi is ready',
        ),
        content: Center(
          child: Column(
            children: [
              image,
              const SizedBox(
                height: 45,
              ),
              const DescriptionText(text: 'Connect your devices to'),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: TitleText(text: _ssid),
              ),
              Text(
                _password,
                style: Theme.of(context).textTheme.headline3?.copyWith(
                  color: Theme.of(context).colorScheme.primary
                ),
              )
            ],
            mainAxisAlignment: MainAxisAlignment.center,
          ),
        ),
        footer: PrimaryButton(
          text: 'Go to the dashboard',
          onPress: () => NavigationCubit.of(context).popTo(HomePath()),
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}