import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:moab_poc/page/components/base_components/base_page_view.dart';
import 'package:moab_poc/page/components/base_components/button/primary_button.dart';
import 'package:moab_poc/page/components/base_components/text/description_text.dart';
import 'package:moab_poc/page/components/base_components/text/title_text.dart';
import 'package:moab_poc/page/components/layouts/basic_header.dart';
import 'package:moab_poc/page/components/layouts/basic_layout.dart';

class SetupFinishedView extends StatelessWidget {
  SetupFinishedView({
    Key? key,
    required this.wifiSsid,
    required this.wifiPassword,
    required this.onNext,
  }) : super(key: key);

  final String wifiSsid;
  final String wifiPassword;
  final void Function() onNext;

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
                child: TitleText(text: wifiSsid),
              ),
              Text(
                wifiPassword,
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
          onPress: onNext,
        ),
        alignment: CrossAxisAlignment.start,
      ),
    );
  }
}