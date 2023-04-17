import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/internet_check/cubit.dart';
import 'package:linksys_moab/bloc/internet_check/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/option_card.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/internet_check_path.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

class NoInternetOptionsView extends ArgumentsConsumerStatefulView {
  const NoInternetOptionsView({Key? key, super.next, super.args})
      : super(key: key);

  @override
  ConsumerState<NoInternetOptionsView> createState() =>
      _NoInternetOptionsViewState();
}

class _NoInternetOptionsViewState extends ConsumerState<NoInternetOptionsView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InternetCheckCubit, InternetCheckState>(
        builder: (context, state) {
      return BasePageView(
        scrollable: true,
        child: BasicLayout(
          header: BasicHeader(
            title: getAppLocalizations(context).no_internet_connection_title,
          ),
          content: Column(
            children: [
              Offstage(
                offstage: !state.afterPlugModemBack,
                child: Column(
                  children: [
                    OptionCard(
                      title: getAppLocalizations(context)
                          .contact_linksys_support_card_title,
                      description: getAppLocalizations(context)
                          .contact_linksys_support_card_description,
                      onPress: () {
                        ref
                            .read(navigationsProvider.notifier)
                            .push(LinksysSupportRegionPath());
                      },
                    ),
                    const SizedBox(
                      height: 18,
                    ),
                  ],
                ),
              ),
              OptionCard(
                title: getAppLocalizations(context).restart_modem_card_title,
                description:
                    getAppLocalizations(context).restart_modem_card_description,
                onPress: () {
                  ref
                      .read(navigationsProvider.notifier)
                      .push(UnplugModemPath());
                },
              ),
              const SizedBox(
                height: 64,
              ),
              Text(
                getAppLocalizations(context).no_internet_alternative,
                style: Theme.of(context)
                    .textTheme
                    .headline3
                    ?.copyWith(color: Theme.of(context).primaryColor),
              ),
              const SizedBox(
                height: 18,
              ),
              OptionCard(
                title: getAppLocalizations(context).pppoe,
                description:
                    getAppLocalizations(context).pppoe_card_description,
                onPress: () {
                  ref
                      .read(navigationsProvider.notifier)
                      .push(EnterIspSettingsPath());
                },
              ),
              const SizedBox(
                height: 16,
              ),
              OptionCard(
                title: getAppLocalizations(context).static_ip_address,
                description:
                    getAppLocalizations(context).static_ip_card_description,
                onPress: () {
                  ref
                      .read(navigationsProvider.notifier)
                      .push(EnterStaticIpPath());
                },
              ),
            ],
            crossAxisAlignment: CrossAxisAlignment.start,
          ),
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    });
  }
}
