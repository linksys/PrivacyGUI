import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/dashboard/view/dashboard_security_view.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/model/security_path.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import '../../../../bloc/subscription/subscription_cubit.dart';

class SecurityMarketingView extends ConsumerWidget {
  const SecurityMarketingView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePageView(
      scrollable: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: MoabColor.dashboardBottomBackground,
            height: 52,
            alignment: Alignment.centerLeft,
            child: Text(
              '30 days left on Linksys Secure trial',
              style: Theme.of(context).textTheme.headline3?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
          box36(),
          Text(
            'Linksys Secure',
            style: Theme.of(context).textTheme.headline1?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          box12(),
          Container(
            alignment: Alignment.center,
            child: Image.asset(
              'assets/images/shield_outline.png',
              height: 160,
              width: 160,
            ),
          ),
          box16(),
          Text(
            'Protect your family and most valued information with Linksys Secure',
            style: Theme.of(context).textTheme.headline2?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          box24(),
          PrimaryButton(
            text: 'Get Linksys Secure',
            onPress: () {
              ref
                  .read(navigationsProvider.notifier)
                  .push(SecuritySubscribePath());
            },
          ),
          const SizedBox(
            height: 30,
          ),
          Text(
            '${context.read<SubscriptionCubit>().state.products?.first.price} per month',
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
            'Cyberthreat protection',
            style: Theme.of(context).textTheme.headline2?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          box12(),
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
          box48(),
          Text(
            'Content Filters',
            style: Theme.of(context).textTheme.headline2?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          box12(),
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
              ref
                  .read(navigationsProvider.notifier)
                  .push(SecuritySubscribePath());
            },
          ),
        ],
      ),
    );
  }
}
