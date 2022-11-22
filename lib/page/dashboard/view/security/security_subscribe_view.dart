import 'dart:io';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/security/bloc.dart';
import 'package:linksys_moab/bloc/security/event.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:styled_text/styled_text.dart';

import '../../../../bloc/network/cubit.dart';
import '../../../../bloc/subscription/subscription_cubit.dart';
import '../../../../bloc/subscription/subscription_state.dart';
import '../../../../route/model/dashboard_path.dart';
import '../../../../util/logger.dart';

class SecuritySubscribeView extends StatelessWidget {
  const SecuritySubscribeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BasePageView(
        scrollable: true,
        child: BasicLayout(
          crossAxisAlignment: CrossAxisAlignment.start,
          header: BasicHeader(
            title: 'Linksys Secure',
            titleTextStyle: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onPrimary),
          ),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua.',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              box16(),
              Text(
                '${context.read<SubscriptionCubit>().state.products?.first.price} billed annually',
                style: Theme.of(context).textTheme.headline2?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              box36(),
              BlocListener<SubscriptionCubit, SubscriptionState>(
                listener: (context, state) {
                  if (state.subscriptionOrderResponse != null &&
                      state.networkEntitlementResponse != null) {
                    context.read<SecurityBloc>().add(SetFormalActiveEvent());
                    context
                        .read<NavigationCubit>()
                        .popTo(DashboardSecurityPath());
                  }
                },
                child: PrimaryButton(
                  text: 'Subscribe',
                  onPress: () {
                    final item =
                        context.read<SubscriptionCubit>().state.products?.first;
                    logger.d(
                        'subscription products : ${context.read<SubscriptionCubit>().state.products?.first.title}');
                    final cubit = context.read<NetworkCubit>();
                    String? serialNumber = cubit.getSerialNumber();
                    if (item != null && serialNumber != null) {
                      context.read<SubscriptionCubit>().buy(item, serialNumber);
                    }
                  },
                ),
              ),
              const SizedBox(
                height: 44,
              ),
              Text(
                'What’s included in my subscription?',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              box16(),
              Text(
                'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              box16(),
              Text(
                'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              box16(),
              Text(
                'Cancel anytime',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              box16(),
              Text(
                'Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
                style: Theme.of(context).textTheme.headline3?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
              ),
              box24(),
              StyledText(
                  text:
                      'By continuing, you agree to the Linksys Secure <link1 href="https://flutter.dev">Terms of Service</link1> and <link2 href="https://flutter.dev">End-User License Agreement</link2>. View our <link3 href="https://flutter.dev">Privacy Policy</link3>.',
                  style: Theme.of(context).textTheme.headline3?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimary),
                  tags: {
                    'link1': StyledTextActionTag(
                        (String? text, Map<String?, String?> attrs) {
                      String? link = attrs['href'];
                      print('The "$link" link is tapped.');
                    }, style: const TextStyle(color: Colors.blue)),
                    'link2': StyledTextActionTag(
                        (String? text, Map<String?, String?> attrs) {
                      String? link = attrs['href'];
                      print('The "$link" link is tapped.');
                    }, style: const TextStyle(color: Colors.blue)),
                    'link3': StyledTextActionTag(
                        (String? text, Map<String?, String?> attrs) {
                      String? link = attrs['href'];
                      print('The "$link" link is tapped.');
                    }, style: const TextStyle(color: Colors.blue)),
                  }),
            ],
          ),
        ));
  }
}
