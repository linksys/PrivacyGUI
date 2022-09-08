import 'package:flutter/material.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_security_view.dart';

class SecurityMarketingView extends StatelessWidget {
  const SecurityMarketingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: MoabColor.placeholderGrey,
            height: 52,
            alignment: Alignment.center,
            child: Text(
              '{30 days left on Linksys Secure trial}',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          box48(),
          Text(
            'Linksys Secure',
            style: Theme.of(context).textTheme.headline1?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          box16(),
          Text(
            'Protect your family and most valued information with Linksys Secure',
            style: Theme.of(context).textTheme.headline2?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Container(
            alignment: Alignment.center,
            child: Image.asset('assets/images/shield_outline.png'),
          ),
          box24(),
          PrimaryButton(
            text: 'Get Linksys Secure',
            onPress: () {
              //TODO: Go to next page
            },
          ),
          const SizedBox(
            height: 30,
          ),
          Text(
            '\$X.XX per month',
            style: Theme.of(context).textTheme.headline2?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            'Billed annually',
            style: Theme.of(context).textTheme.headline4?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          box36(),
          Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.\n\nUt enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
            style: Theme.of(context).textTheme.headline3?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          box48(),
          TitleWithIcons(
            text: Text(
              'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            leadingIcon: Image.asset('assets/images/icon_check_dark_green.png'),
          ),
          box16(),
          TitleWithIcons(
            text: Text(
              'Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat.',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            leadingIcon: Image.asset('assets/images/icon_check_dark_green.png'),
          ),
          box16(),
          TitleWithIcons(
            text: Text(
              'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur.',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            leadingIcon: Image.asset('assets/images/icon_check_dark_green.png'),
          ),
          box48(),
          Text(
            'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
            style: Theme.of(context).textTheme.headline3?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          box48(),
          PrimaryButton(
            text: 'Get Linksys Secure',
            onPress: () {
              //TODO: Go to next page
            },
          ),
        ],
      ),
    );
  }
}
