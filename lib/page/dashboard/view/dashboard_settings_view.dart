import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/network/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/customs/enabled_with_opacity_widget.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';

import 'package:linksys_moab/util/logger.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef OnMenuItemClick = void Function(int index, DashboardSettingsItem item);

class DashboardSettingsView extends ConsumerStatefulWidget {
  const DashboardSettingsView({Key? key}) : super(key: key);

  @override
  ConsumerState<DashboardSettingsView> createState() =>
      _DashboardSettingsViewState();
}

class _DashboardSettingsViewState extends ConsumerState<DashboardSettingsView> {
  late final AuthBloc _authBloc;

  @override
  void initState() {
    _authBloc = context.read<AuthBloc>();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NetworkCubit, NetworkState>(
      builder: (context, state) {
        return LinksysPageView.noNavigationBar(
            scrollable: true,
            child: EnabledOpacityWidget(
              enabled: state.selected?.deviceInfo != null,
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const LinksysGap.semiBig(),
                    _title(),
                    const LinksysGap.semiBig(),
                    _section(
                      _networkSettingsSection(context),
                      (index, item) {
                        logger.d('MenuItem click $index');
                        ref.read(navigationsProvider.notifier).push(item.path);
                      },
                    ),
                    const LinksysGap.semiBig(),
                    _section(
                      _youSettingsSection(),
                      (index, item) {
                        logger.d('MenuItem click $index');
                        ref.read(navigationsProvider.notifier).push(item.path);
                      },
                    ),
                    const LinksysGap.semiBig(),
                    LinksysTertiaryButton.noPadding('Log out', onTap: () {
                      context.read<AuthBloc>().add(Logout());
                    }),
                    const LinksysGap.semiBig(),
                    FutureBuilder(
                        future: PackageInfo.fromPlatform()
                            .then((value) => value.version),
                        initialData: '-',
                        builder: (context, data) {
                          return LinksysText.label(
                            'version ${data.data}',
                          );
                        }),
                  ],
                ),
              ),
            ));
      },
    );
  }

  Widget _title() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.start,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: const [
            LinksysText.screenName(
              'Settings',
            )
          ],
        ),
      ],
    );
  }

  Widget _section(
      DashboardSettingsSection sectionItem, OnMenuItemClick onItemClick) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinksysText.tags(
          sectionItem.title,
        ),
        const LinksysGap.small(),
        ...sectionItem.items.map((e) => InkWell(
              onTap: () => onItemClick(sectionItem.items.indexOf(e), e),
              child: AppSimplePanel(
                title: e.title,
                icon: getCharactersIcons(context).getByName(e.iconId),
              ),
            )),
      ],
    );
  }

  _networkSettingsSection(BuildContext context) => DashboardSettingsSection(
        title: 'NETWORK',
        items: [
          DashboardSettingsItem(
            title: 'WiFi',
            iconId: 'wifiDefault',
            path: WifiSettingsOverviewPath(),
          ),
          DashboardSettingsItem(
            title: getAppLocalizations(context).administration,
            iconId: 'administrationDefault',
            path: AdministrationViewPath(),
          ),
          DashboardSettingsItem(
            title: 'Priority',
            iconId: 'priorityDefault',
            path: UnknownPath(),
          ),
          DashboardSettingsItem(
            title: 'Internet schedule',
            iconId: 'clockRound',
            path: UnknownPath(),
          ),
          DashboardSettingsItem(
            title: 'Safe browsing',
            iconId: 'filterDefault',
            path: UnknownPath(),
          ),
          DashboardSettingsItem(
            title: 'Profiles',
            iconId: 'profileDefault',
            path: UnknownPath(),
          ),
        ],
      );

//
  _youSettingsSection() => DashboardSettingsSection(
        title: 'YOU',
        items: [
          DashboardSettingsItem(
            title: 'Account',
            iconId: 'profileDefault',
            path: AccountDetailPath(),
          ),
          DashboardSettingsItem(
            title: 'Privacy and legal',
            iconId: 'infoRound',
            path: UnknownPath(),
          ),
          DashboardSettingsItem(
            title: 'Support',
            iconId: 'helpRound',
            path: UnknownPath(),
          ),
        ],
      );
}

class DashboardSettingsSection {
  DashboardSettingsSection({required this.title, required this.items});

  final String title;
  final List<DashboardSettingsItem> items;
}

class DashboardSettingsItem {
  DashboardSettingsItem({
    required this.title,
    required this.iconId,
    required this.path,
  });

  final String title;
  final String iconId;
  final BasePath path;
}
