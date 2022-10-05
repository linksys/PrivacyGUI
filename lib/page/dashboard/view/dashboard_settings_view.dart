import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/bloc/auth/event.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';

import 'package:linksys_moab/util/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

typedef OnMenuItemClick = void Function(int index, DashboardSettingsItem item);

class DashboardSettingsView extends StatefulWidget {
  const DashboardSettingsView({Key? key}) : super(key: key);

  @override
  State<DashboardSettingsView> createState() => _DashboardSettingsViewState();
}

class _DashboardSettingsViewState extends State<DashboardSettingsView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.noNavigationBar(
      scrollable: true,
      child: SizedBox(
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(),
            box36(),
            _section(
              _networkSettingsSection(context),
              (index, item) {
                logger.d('MenuItem click $index');
                NavigationCubit.of(context).push(item.path);
              },
            ),
            box36(),
            _section(
              _youSettingsSection(),
              (index, item) {
                logger.d('MenuItem click $index');
                NavigationCubit.of(context).push(item.path);
              },
            ),
            box36(),
            SimpleTextButton(
                text: 'Log out',
                onPressed: () {
                  context.read<AuthBloc>().add(Logout());
                }),
            box36(),
            FutureBuilder(
                future:
                    PackageInfo.fromPlatform().then((value) => value.version),
                initialData: '-',
                builder: (context, data) {
                  return Text('version ${data.data}',
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                            fontWeight: FontWeight.w700,
                          ));
                }),
          ],
        ),
      ),
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
          children: [
            Text(
              'Settings',
              style: Theme.of(context)
                  .textTheme
                  .headline1
                  ?.copyWith(fontSize: 32, fontWeight: FontWeight.w400),
              textAlign: TextAlign.center,
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
        Text(
          sectionItem.title,
          style: Theme.of(context)
              .textTheme
              .headline4
              ?.copyWith(fontWeight: FontWeight.w700, color: Colors.black),
        ),
        const SizedBox(
          height: 4,
        ),
        ...sectionItem.items.map((e) => InkWell(
              onTap: () => onItemClick(sectionItem.items.indexOf(e), e),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Text(
                  e.title,
                  style: Theme.of(context).textTheme.button,
                ),
              ),
            )),
      ],
    );
  }
}

_networkSettingsSection(BuildContext context) => DashboardSettingsSection(
      title: 'NETWORK',
      items: [
        DashboardSettingsItem(title: 'WiFi', path: WifiSettingsOverviewPath()),
        DashboardSettingsItem(
          title: 'Internet schedule',
          path: ProfileListPath()..args = {'category': PService.internetSchedule},
        ),
        DashboardSettingsItem(
          title: 'Content filters',
          path: ProfileListPath()..args = {'category': PService.contentFilter},
        ),
        DashboardSettingsItem(title: 'Profiles', path: ProfileListPath()),
        DashboardSettingsItem(title: 'Priority', path: UnknownPath()),
        DashboardSettingsItem(title: getAppLocalizations(context).administration, path: AdministrationViewPath()),
        DashboardSettingsItem(title: 'Smart home', path: UnknownPath()),
      ],
    );
//
_youSettingsSection() => DashboardSettingsSection(
      title: 'YOU',
      items: [
        DashboardSettingsItem(title: 'Account', path: AccountDetailPath()),
        DashboardSettingsItem(title: 'Notifications', path: UnknownPath()),
        DashboardSettingsItem(title: 'Privacy and legal', path: UnknownPath()),
      ],
    );

class DashboardSettingsSection {
  DashboardSettingsSection({required this.title, required this.items});

  final String title;
  final List<DashboardSettingsItem> items;
}

class DashboardSettingsItem {
  DashboardSettingsItem({required this.title, required this.path});

  final String title;
  final BasePath path;
}
